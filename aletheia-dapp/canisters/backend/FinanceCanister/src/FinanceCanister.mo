import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";


// Interface for the ICP Ledger
module Ledger {
    public type AccountIdentifier = Blob;
    public type SubAccount = Blob;
    public type ICP = { e8s : Nat64 };
    public type Memo = Nat64;
    public type Timestamp = { timestamp_nanos : Nat64 };
    public type Duration = { secs : Nat64 };
    public type TransferArgs = {
        memo : Memo;
        amount : ICP;
        fee : ICP;
        from_subaccount : ?SubAccount;
        to : AccountIdentifier;
        created_at_time : ?Timestamp;
    };
    public type TransferError = {
        #BadFee : { expected_fee : ICP };
        #InsufficientFunds : { balance : ICP };
        #TxTooOld : { allowed_window_nanos : Nat64 };
        #TxCreatedInFuture;
        #TxDuplicate : { duplicate_of : Nat64 };
        #Other : { error_message : Text; error_code : Nat64 };
    };
    public type TransferResult = Result.Result<Nat64, TransferError>;
    
    public type Service = actor {
        transfer : (TransferArgs) -> async TransferResult;
    };
};

actor class FinanceCanister() = this {
    let ledgerCanisterId = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"); // ICP Ledger canister ID

    type AccountIdentifier = Ledger.AccountIdentifier;
    type ICP = Ledger.ICP;
    type TransferResult = Ledger.TransferResult;
    type TransferError = Ledger.TransferError;
    
    // Admin management
    var admins : [Principal] = [];
    let isAdmin = func (p : Principal) : Bool {
        Option.isSome(Array.find(admins, func (admin : Principal) : Bool { admin == p }))
    };
    
    // Canister references
    let aletheianProfile = actor ("AletheianProfileCanister") : actor {
        getProfile : (aletheian : Principal) -> async ?{
            id : Principal;
            rank : { #Trainee; #Junior; #Associate; #Senior; #Expert; #Master };
            xp : Int;
            expertiseBadges : [Text];
            location : ?Text;
            status : { #Active; #Suspended; #Retired };
            warnings : Nat;
            accuracy : Float;
            claimsVerified : Nat;
            completedTraining : [Text];
            createdAt : Int;
            lastActive : Int;
        };
    };

    let notification = actor ("NotificationCanister") : actor {
        sendNotification : (userId : Principal, title : Text, message : Text, notifType : Text) -> async Nat;
    };

    // Stable state variables - version 2
    stable var dataVersion : Nat = 1;
    stable var payoutCyclesEntries : [(Text, PayoutCycle)] = [];
    stable var pendingBalancesEntries : [(Principal, Nat64)] = [];
    stable var platformReserve : Nat64 = 0;
    stable var carryoverPool : Nat64 = 0;
    stable var controller : Principal = initializer;
    stable var dip20Canister : ?Principal = null;
    stable var dip20Enabled : Bool = false;
    
    // Configuration
    stable var config : Config = {
        platformFeePercent = 0;
        minimumPayout = 10_000; // 0.0001 ICP by default
        carryoverBehavior = #carryover;
        paymentPool = 0;
    };

    // Type definitions
    public type PayoutInstruction = { recipient : Principal; amountE8s : Nat64; memo : Text };
    public type XPEntry = { principal : Principal; xp : Nat };
    public type XPSnapshot = { periodId : Text; entries : [XPEntry] };
    public type PayoutCycle = {
        periodId : Text;
        poolAmount : Nat64;
        timestamp : Nat64;
        snapshotHash : Text;
        computed : ?[PayoutInstruction];
        distributed : Bool;
        feeTaken : Nat64;
    };

    // Mutable state
    var payoutCycles = HashMap.HashMap<Text, PayoutCycle>(0, Text.equal, Text.hash);
    var pendingBalances = HashMap.HashMap<Principal, Nat64>(0, Principal.equal, Principal.hash);
    
    // Types
    public type Transaction = {
        #deposit : { amount : Nat64; timestamp : Int };
        #withdrawal : { principal : Principal; amount : Nat64; timestamp : Int; blockIndex : ?Nat64 };
        #distribution : { amount : Nat64; totalXP : Nat; timestamp : Int };
    };
    
    public type Config = {
        distributionPercentage : Nat;
        distributionInterval : Int;
        fee : Nat64;
    };
    
    // Mutable state
    var earnings = Trie.empty<Principal, Nat64>();
    var monthlyXP = Trie.empty<Principal, Nat>();
    
    // Constants
    let DECIMALS : Nat64 = 100_000_000; // 1 ICP = 100,000,000 e8s
    
    // Initialize from stable state
    system func preupgrade() {
        // Save new storage structures
        payoutCyclesEntries := Iter.toArray(payoutCycles.entries());
        pendingBalancesEntries := Iter.toArray(pendingBalances.entries());
        
        // Migrate legacy storage
        let earningsBuf = Buffer.Buffer<(Principal, Nat64)>(0);
        for ((p, n) in Trie.iter(earnings)) {
            earningsBuf.add((p, n));
        };
        earningsEntries := earningsBuf.toArray();
        
        let xpBuf = Buffer.Buffer<(Principal, Nat)>(0);
        for ((p, n) in Trie.iter(monthlyXP)) {
            xpBuf.add((p, n));
        };
        monthlyXPEntries := xpBuf.toArray();
    };

    system func postupgrade() {
        // Restore new storage structures
        payoutCycles := HashMap.fromIter<Text, PayoutCycle>(
            payoutCyclesEntries.vals(), 0, Text.equal, Text.hash
        );
        pendingBalances := HashMap.fromIter<Principal, Nat64>(
            pendingBalancesEntries.vals(), 0, Principal.equal, Principal.hash
        );
        
        // Restore legacy storage
        earnings := Trie.empty();
        for ((p, n) in earningsEntries.vals()) {
            earnings := Trie.put(earnings, key(p), Principal.equal, n : Nat64).0;
        };
        monthlyXP := Trie.empty();
        for ((p, n) in monthlyXPEntries.vals()) {
            monthlyXP := Trie.put(monthlyXP, key(p), Principal.equal, n : Nat).0;
        };
        
        // Data migration
        if (dataVersion < 2) {
            platformReserve := 0;
            carryoverPool := 0;
            dataVersion := 2;
        };
    };

    func _computeSnapshotHash(snapshot : XPSnapshot) : Text {
        // Simple hash implementation - TODO: Replace with proper hash function
        let entriesText = Array.foldLeft<XPEntry, Text>(
            snapshot.entries,
            "",
            func(acc : Text, e : XPEntry) : Text {
                acc # Principal.toText(e.principal) # ":" # Nat.toText(e.xp) # ";"
            }
        );
        Text.map(entriesText, Prim.charToUpper)
    };

    func _calculateTotalXP(snapshot : XPSnapshot) : Nat {
        Array.foldLeft<XPEntry, Nat>(
            snapshot.entries,
            0,
            func(acc : Nat, e : XPEntry) : Nat { acc + e.xp }
        )
    };
    
    system func preupgrade() {
        let earningsBuf = Buffer.Buffer<(Principal, Nat64)>(0);
        for ((p, n) in Trie.iter(earnings)) {
            earningsBuf.add((p, n));
        };
        earningsEntries := earningsBuf.toArray();
        let xpBuf = Buffer.Buffer<(Principal, Nat)>(0);
        for ((p, n) in Trie.iter(monthlyXP)) {
            xpBuf.add((p, n));
        };
        monthlyXPEntries := xpBuf.toArray();
    };
    
    // Internal: Get ledger actor
    let ledger : Ledger.Service = actor(Principal.toText(ledgerCanisterId));
    
    // Internal: Calculate account identifier (placeholder - use production implementation)
    func accountIdentifier(principal : Principal, subaccount : ?Blob) : AccountIdentifier {
        let sub = switch (subaccount) {
            case (null) { Blob.fromArray(Array.tabulate<Nat8>(32, func(_ : Nat) : Nat8 { 0 })) };
            case (?sa) { sa };
        };
        
        // Production should use proper SHA224/CRC32 implementation
        let principalBytes = Blob.toArray(Principal.toBlob(principal));
        let subBytes = Blob.toArray(sub);
        let allBytes = Array.append(principalBytes, subBytes);
        Blob.fromArray(Array.tabulate(32, func(i : Nat) : Nat8 {
            if (i < allBytes.size()) allBytes[i] else 0
        }));
    };
    
    // Internal: Convert Nat to Nat64 safely
    func toNat64(n : Nat) : Nat64 {
        Nat64.fromNat(n);
    };
    
    // Internal: Convert Nat64 to Nat
    func fromNat64(n : Nat64) : Nat {
        Nat64.toNat(n);
    };
    
    // Add funds to revenue pool (admin only)
    public shared({ caller }) func deposit(amount : Nat64) : async () {
        assert isAdmin(caller);
        revenuePool += amount;
        addTransaction(#deposit { amount = amount; timestamp = Time.now() });
    };
    
    // Update XP for a user (called by reputation system)
    public shared({ caller }) func updateXP(user : Principal, xp : Nat) : async () {
        assert isAdmin(caller);
        
        let current = Trie.get(monthlyXP, key(user), Principal.equal);
        let currentXP = Option.get(current, 0);
        
        totalMonthlyXP := totalMonthlyXP - currentXP + xp;
        monthlyXP := Trie.put(monthlyXP, key(user), Principal.equal, xp).0;
    };
    
    // XP Snapshot handling
    public shared({ caller }) func submitXPSnapshot(snapshot : XPSnapshot) : async Result.Result<(), Text> {
        if (not isController(caller) and not isReputationLogic(caller)) {
            return #err("Unauthorized");
        };
        
        let hash = _computeSnapshotHash(snapshot);
        let cycle = switch (payoutCycles.get(snapshot.periodId)) {
            case (?c) { c with snapshotHash = hash };
            case null { 
                { 
                    periodId = snapshot.periodId; 
                    poolAmount = 0; 
                    timestamp = Time.now(); 
                    snapshotHash = hash; 
                    computed = null; 
                    distributed = false; 
                    feeTaken = 0 
                } 
            };
        };
        
        payoutCycles.put(snapshot.periodId, cycle);
        #ok()
    };

    // Payout calculation
    public shared({ caller }) func calculatePayouts(periodId : Text) : async Result.Result<[PayoutInstruction], Text> {
        let cycle = switch (payoutCycles.get(periodId)) {
            case (?c) c;
            case null return #err("Payout cycle not found");
        };
        
        let snapshot = switch (cycle.snapshotHash) {
            case "" return #err("No snapshot for this cycle");
            case _ {};
        };
        
        let totalXP = _calculateTotalXP(snapshot);
        if (totalXP == 0) {
            carryoverPool += cycle.poolAmount;
            return #err("Total XP is zero - pool carried over");
        };
        
        let (instructions, feeTaken) = _calculatePayoutsInternal(cycle.poolAmount, snapshot, config.platformFeePercent);
        let updatedCycle = { cycle with computed = ?instructions; feeTaken };
        payoutCycles.put(periodId, updatedCycle);
        
        #ok(instructions)
    };

    func _calculatePayoutsInternal(poolAmount : Nat64, snapshot : XPSnapshot, feePercent : Nat) : ([PayoutInstruction], Nat64) {
        let fee = (poolAmount * Nat64.fromNat(feePercent)) / 100;
        let distributablePool = poolAmount - fee;
        let totalXP = _calculateTotalXP(snapshot);
        
        var remaining = distributablePool;
        var instructions : [PayoutInstruction] = [];
        var remainders : [(Principal, Nat64, Nat64)] = []; // (principal, amount, remainder)
        
        // First pass - calculate base amounts
        for (entry in snapshot.entries.vals()) {
            let rawShare = (Nat64.fromNat(entry.xp) * distributablePool) / Nat64.fromNat(totalXP);
            let remainder = (Nat64.fromNat(entry.xp) * distributablePool) % Nat64.fromNat(totalXP);
            
            remainders := Array.append(remainders, [(entry.principal, rawShare, remainder)]);
            remaining -= rawShare;
        };
        
        // Sort remainders for largest remainder method
        let sortedRemainders = Array.sort(remainders, func(a : (Principal, Nat64, Nat64), b : (Principal, Nat64, Nat64)) : Order.Order {
            switch (Nat64.compare(b.2, a.2)) {
                case (#less) #less;
                case (#greater) #greater;
                case (#equal) Text.compare(Principal.toText(a.0), Principal.toText(b.0));
            }
        });
        
        // Distribute remaining units
        var i : Nat = 0;
        while (remaining > 0 and i < sortedRemainders.size()) {
            let (principal, amount, _) = sortedRemainders[i];
            let newAmount = amount + 1;
            remaining -= 1;
            
            // Update the remainders array
            remainders := Array.map(remainders, func(r : (Principal, Nat64, Nat64)) : (Principal, Nat64, Nat64) {
                if (r.0 == principal) (principal, newAmount, 0) else r
            });
            i += 1;
        };
        
        // Build final instructions
        for ((principal, amount, _) in remainders.vals()) {
            if (amount >= config.minimumPayout) {
                instructions := Array.append(instructions, [{
                    recipient = principal;
                    amountE8s = amount;
                    memo = "Payout for " # periodId;
                }]);
            } else {
                switch (config.carryoverBehavior) {
                    case (#carryover) { carryoverPool += amount };
                    case (#pending) {
                        let current = Option.get(pendingBalances.get(principal), 0);
                        pendingBalances.put(principal, current + amount);
                    };
                }
            }
        };
        
        (instructions, fee)
    };
        
    
    // Payout distribution
    public shared({ caller }) func distributePayouts(periodId : Text) : async Result.Result<[PayoutInstruction], Text> {
        assert isController(caller);
        
        let cycle = switch (payoutCycles.get(periodId)) {
            case (?c) c;
            case null return #err("Payout cycle not found");
        };
        
        let instructions = switch (cycle.computed) {
            case (?ins) ins;
            case null return #err("Payouts not calculated");
        };
        
        if (dip20Enabled) {
            switch (dip20Canister) {
                case (?dip20) {
                    let dip20Actor : DIP20TokenCanister.DIP20Token = actor(Principal.toText(dip20));
                    for (inst in instructions.vals()) {
                        let result = await dip20Actor.transfer(inst.recipient, Nat64.toNat(inst.amountE8s));
                        switch (result) {
                            case (#Ok _) {};
                            case (#Err e) {
                                // TODO: Handle partial failures
                                return #err("DIP20 transfer failed: " # debug_show(e));
                            };
                        }
                    };
                };
                case null return #err("DIP20 not configured");
            }
        };
        
        // Update state
        let updatedCycle = { cycle with distributed = true };
        payoutCycles.put(periodId, updatedCycle);
        platformReserve += cycle.feeTaken;
        
        // TODO: Send notifications
        #ok(instructions)
    };

    // Withdraw individual pending balance (for users)
    public shared({ caller }) func withdrawPending() : async TransferResult {
        let account = accountIdentifier(caller, null);
        let current = Trie.get(earnings, key(caller), Principal.equal);
        
        switch (current) {
            case (null) {
                return #err(#Other { 
                    error_message = "No earnings available"; 
                    error_code = 404 
                });
            };
            case (?available) {
                if (available < amount) {
                    return #err(#InsufficientFunds { 
                        balance = { e8s = available } 
                    });
                };
                
                // Deduct fee from amount
                if (amount <= config.fee) {
                    return #err(#BadFee { 
                        expected_fee = { e8s = config.fee } 
                    });
                };
                
                let transferAmount = amount - config.fee;
                
                let args : Ledger.TransferArgs = {
                    memo = 0;
                    amount = { e8s = transferAmount };
                    fee = { e8s = config.fee };
                    from_subaccount = null;
                    to = account;
                    created_at_time = ?{ timestamp_nanos = toNat64(Int.abs(Time.now())) };
                };
                
                let result = await ledger.transfer(args);
                
                switch (result) {
                    case (#Ok blockIndex) {
                        // Update earnings balance
                        let newBalance = available - amount;
                        earnings := Trie.put(earnings, key(caller), Principal.equal, newBalance).0;
                        
                        addTransaction(#withdrawal { 
                            principal = caller; 
                            amount = amount; 
                            timestamp = Time.now();
                            blockIndex = ?blockIndex;
                        });
                        
                        // Notify user of successful withdrawal
                        ignore await notification.sendNotification(
                            caller,
                            "Withdrawal Successful",
                            "Your withdrawal of " # Nat64.toText(transferAmount) # " e8s has been processed",
                            "payment_received"
                        );
                        
                        #ok(blockIndex);
                    };
                    case (#Err err) { 
                        // Log failed transaction
                        addTransaction(#withdrawal { 
                            principal = caller; 
                            amount = amount; 
                            timestamp = Time.now();
                            blockIndex = null;
                        });
                        #err(err) 
                    };
                };
            };
        };
    };
    
    // Admin API functions
    public shared({ caller }) func setController(newController : Principal) : async () {
        assert isController(caller);
        controller := newController;
    };

    public shared({ caller }) func setPaymentPool(periodId : Text, amountE8s : Nat64) : async () {
        assert isController(caller);
        let cycle = switch (payoutCycles.get(periodId)) {
            case (?c) { c with poolAmount = amountE8s };
            case null { 
                { 
                    periodId; 
                    poolAmount = amountE8s; 
                    timestamp = 0; 
                    snapshotHash = ""; 
                    computed = null; 
                    distributed = false; 
                    feeTaken = 0 
                } 
            };
        };
        payoutCycles.put(periodId, cycle);
    };

    public shared({ caller }) func setPlatformFeePercent(percent : Nat) : async () {
        assert isController(caller);
        assert percent <= 100;
        config := { config with platformFeePercent = percent };
    };

    public shared({ caller }) func setMinimumPayout(minE8s : Nat64) : async () {
        assert isController(caller);
        config := { config with minimumPayout = minE8s };
    };

    public shared({ caller }) func setCarryoverBehavior(behavior : { #carryover; #pending }) : async () {
        assert isController(caller);
        config := { config with carryoverBehavior = behavior };
    };

    public shared({ caller }) func setDIP20Canister(canister : Principal) : async () {
        assert isController(caller);
        dip20Canister := ?canister;
    };

    public shared({ caller }) func enableDIP20(enabled : Bool) : async () {
        assert isController(caller);
        dip20Enabled := enabled;
    };

    // Permission checks
    func isController(caller : Principal) : Bool {
        caller == controller
    };

    func isReputationLogic(caller : Principal) : Bool {
        // Implement proper principal check for ReputationLogicCanister
        Principal.toText(caller) == Principal.toText(Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai")) // TODO: Replace with actual principal
    };
    
    // Query functions
    public query func getRevenuePool() : async Nat64 {
        revenuePool;
    };
    
    public query func getUserEarnings(user : Principal) : async Nat64 {
        Option.get(Trie.get(earnings, key(user), Principal.equal), 0 : Nat64)
    };
    
    public query func getMonthlyXP(user : Principal) : async Nat {
        Option.get(Trie.get(monthlyXP, key(user), Principal.equal), 0 : Nat)
    };
    
    public query func getTotalMonthlyXP() : async Nat {
        totalMonthlyXP;
    };
    
    public query func getTransactions(since : Int) : async [Transaction] {
        Array.filter(transactions, func (t : Transaction) : Bool {
            let ts = switch (t) {
                case (#deposit d) d.timestamp;
                case (#withdrawal w) w.timestamp;
                case (#distribution d) d.timestamp;
            };
            ts >= since
        });
    };
    
    public query func getConfig() : async Config {
        config;
    };
    
    public query func getAdmins() : async [Principal] {
        admins;
    };
    
    // Internal utilities
    func key(p : Principal) : Trie.Key<Principal> {
        { key = p; hash = Principal.hash(p) };
    };
    
    func addTransaction(tx : Transaction) {
        transactions := Array.append(transactions, [tx]);
    };
}
