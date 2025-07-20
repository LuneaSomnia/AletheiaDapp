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

actor class FinanceCanister(ledgerCanisterId : Principal) = this {
    type AccountIdentifier = Ledger.AccountIdentifier;
    type ICP = Ledger.ICP;
    type TransferResult = Ledger.TransferResult;
    type TransferError = Ledger.TransferError;
    
    // Admin management
    var admins : [Principal] = [];
    let isAdmin = func (p : Principal) : Bool {
        Option.isSome(Array.find(admins, func (admin : Principal) : Bool { admin == p }))
    };
    
    // Stable state variables
    stable var revenuePool : Nat64 = 0;
    stable var earningsEntries : [(Principal, Nat64)] = [];
    stable var lastDistributionTime : Int = 0;
    stable var totalMonthlyXP : Nat = 0;
    stable var monthlyXPEntries : [(Principal, Nat)] = [];
    stable var transactions : [Transaction] = [];
    stable var config : Config = {
        distributionPercentage = 50; // 50% of revenue pool
        distributionInterval = 30 * 24 * 60 * 60 * 1_000_000_000; // 30 days in nanoseconds
        fee = 10_000; // 0.0001 ICP
    };
    
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
    system func postupgrade() {
        earnings := Trie.empty();
        for ((p, n) in earningsEntries.vals()) {
            earnings := Trie.put(earnings, key(p), Principal.equal, n : Nat64).0;
        };
        monthlyXP := Trie.empty();
        for ((p, n) in monthlyXPEntries.vals()) {
            monthlyXP := Trie.put(monthlyXP, key(p), Principal.equal, n : Nat).0;
        };
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
    
    // Calculate and distribute earnings (admin or automated)
    public shared({ caller }) func distributeMonthlyPool() : async () {
        assert isAdmin(caller) or Time.now() >= lastDistributionTime + config.distributionInterval;
        
        if (revenuePool == 0 or totalMonthlyXP == 0) {
            Debug.print("No revenue or XP to distribute");
            return;
        };
        
        let distributionAmount : Nat64 = (revenuePool * toNat64(config.distributionPercentage)) / 100;
        revenuePool -= distributionAmount;
        
        var distributed : Nat64 = 0;
        var recipientCount = 0;
        
        for ((user, xp) in Trie.iter(monthlyXP)) {
            if (xp > 0) {
                let share : Nat64 = (distributionAmount * toNat64(xp)) / toNat64(totalMonthlyXP);
                distributed += share;
                
                let current = Trie.get(earnings, key(user), Principal.equal);
                let newAmount : Nat64 = Option.get(current, 0 : Nat64) + share;
                earnings := Trie.put(earnings, key(user), Principal.equal, newAmount).0;
                recipientCount += 1;
            };
        };
        
        // Reset monthly XP
        monthlyXP := Trie.empty();
        totalMonthlyXP := 0;
        lastDistributionTime := Time.now();
        
        addTransaction(#distribution { 
            amount = distributed; 
            totalXP = totalMonthlyXP; 
            timestamp = Time.now() 
        });
        
        Debug.print("Distributed " # debug_show(distributed) # " to " # debug_show(recipientCount) # " users");
    };
    
    // Withdraw earnings to user's account
    public shared({ caller }) func withdraw(amount : Nat64) : async TransferResult {
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
    
    // Admin functions
    public shared({ caller }) func addAdmin(newAdmin : Principal) : async () {
        assert isAdmin(caller);
        if (Option.isNull(Array.find(admins, func (a : Principal) : Bool { a == newAdmin }))) {
            admins := Array.append(admins, [newAdmin]);
        };
    };
    
    shared({ caller }) func updateConfig(newConfig : Config) : async () {
        assert isAdmin(caller);
        config := newConfig;
    };
    
    // Query functions
    query func getRevenuePool() : async Nat64 {
        revenuePool;
    };
    
    query func getUserEarnings(user : Principal) : async Nat64 {
        Option.get(Trie.get(earnings, key(user), Principal.equal), 0 : Nat64)
    };
    
    query func getMonthlyXP(user : Principal) : async Nat {
        Option.get(Trie.get(monthlyXP, key(user), Principal.equal), 0 : Nat)
    };
    
    query func getTotalMonthlyXP() : async Nat {
        totalMonthlyXP;
    };
    
    query func getTransactions(since : Int) : async [Transaction] {
        Array.filter(transactions, func (t : Transaction) : Bool {
            let ts = switch (t) {
                case (#deposit d) d.timestamp;
                case (#withdrawal w) w.timestamp;
                case (#distribution d) d.timestamp;
            };
            ts >= since
        });
    };
    
    query func getConfig() : async Config {
        config;
    };
    
    query func getAdmins() : async [Principal] {
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
