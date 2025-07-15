import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";

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
    
    // Stable state variables
    stable var revenuePool : Nat64 = 0;
    stable var earningsEntries : [(Principal, Nat64)] = [];
    stable var lastDistributionTime : Int = 0;
    stable var totalStaked : Nat64 = 0;
    stable var stakedEntries : [(Principal, Nat64)] = [];
    
    // Mutable state
    var earnings = Trie.empty<Principal, Nat64>();
    var staked = Trie.empty<Principal, Nat64>();
    
    // Constants
    let FEE : Nat64 = 10_000; // 0.0001 ICP
    let DISTRIBUTION_INTERVAL : Int = 1_209_600_000_000_000; // 14 days in nanoseconds
    let DECIMALS : Nat64 = 100_000_000; // 1 ICP = 100,000,000 e8s
    
    // Initialize from stable state
    system func postupgrade() {
        earnings := Trie.fromArray(earningsEntries, Principal.equal, Principal.hash);
        staked := Trie.fromArray(stakedEntries, Principal.equal, Principal.hash);
    };
    
    system func preupgrade() {
        earningsEntries := Trie.toArray(earnings);
        stakedEntries := Trie.toArray(staked);
    };
    
    // Internal: Get ledger actor
    let ledger : Ledger.Service = actor(Principal.toText(ledgerCanisterId));
    
    // Internal: Calculate account identifier
    func accountIdentifier(principal : Principal, subaccount : ?Blob) : AccountIdentifier {
        let sub = switch (subaccount) {
            case (null) { Blob.fromArrayMut(Array.init(32, 0 : Nat8)) };
            case (?sa) { sa };
        };
        
        let hash = SHA224("\x0Aaccount-id");
        hash.write("\x0A");
        hash.write(Principal.toBlob(principal));
        hash.write(sub);
        let hashSum = hash.sum();
        let crc = CRC32.ofArray(hashSum);
        Blob.fromArray(Array.append(crc, hashSum));
    };
    
    // Internal: Convert Nat to Nat64 safely
    func toNat64(n : Nat) : Nat64 {
        Nat64.fromNat(n);
    };
    
    // Internal: Convert Nat64 to Nat
    func fromNat64(n : Nat64) : Nat {
        Nat64.toNat(n);
    };
    
    // Add funds to revenue pool
    public shared({ caller }) func deposit(amount : Nat64) : async () {
        // In a real implementation, this would verify actual transfer
        revenuePool += amount;
    };
    
    // Calculate earnings based on staked amount
    public shared({ caller }) func calculateEarnings() : async () {
        if (Time.now() < lastDistributionTime + DISTRIBUTION_INTERVAL) {
            Debug.print("Earnings calculation too soon");
            return;
        };
        
        if (revenuePool == 0 or totalStaked == 0) {
            Debug.print("No revenue or stake to distribute");
            return;
        };
        
        let distributionAmount = revenuePool / 2; // Distribute half the pool
        revenuePool -= distributionAmount;
        
        Trie.iter(staked, func(principal : Principal, amount : Nat64) {
            let share = (amount * distributionAmount) / totalStaked;
            let current = Trie.get(earnings, key(principal), Principal.equal);
            let newAmount = switch (current) {
                case (null) { share };
                case (?a) { a + share };
            };
            earnings := Trie.put(earnings, key(principal), Principal.equal, newAmount).0;
        });
        
        lastDistributionTime := Time.now();
    };
    
    // Withdraw earnings to user's account
    public shared({ caller }) func withdraw(amount : Nat64) : async TransferResult {
        let account = accountIdentifier(caller, null);
        let current = Trie.get(earnings, key(caller), Principal.equal);
        
        switch (current) {
            case (null) {
                return #err(#Other({ 
                    error_message = "No earnings available"; 
                    error_code = 404 
                }));
            };
            case (?available) {
                if (available < amount) {
                    return #err(#InsufficientFunds({ 
                        balance = { e8s = available } 
                    }));
                };
                
                // Deduct fee from amount
                let transferAmount = amount - FEE;
                if (transferAmount <= 0) {
                    return #err(#BadFee({ 
                        expected_fee = { e8s = FEE } 
                    }));
                };
                
                let args : Ledger.TransferArgs = {
                    memo = 0;
                    amount = { e8s = transferAmount };
                    fee = { e8s = FEE };
                    from_subaccount = null;
                    to = account;
                    created_at_time = ?{ timestamp_nanos = Nat64.fromIntWrap(Time.now()) };
                };
                
                let result = await ledger.transfer(args);
                
                switch (result) {
                    case (#Ok blockIndex) {
                        // Update earnings balance
                        let newBalance = available - amount;
                        earnings := Trie.put(earnings, key(caller), Principal.equal, newBalance).0;
                        #ok(blockIndex);
                    };
                    case (#Err err) { #err(err) };
                };
            };
        };
    };
    
    // Record staked amount (called by staking contract)
    public shared({ caller }) func updateStake(principal : Principal, amount : Nat64) : async () {
        let current = Trie.get(staked, key(principal), Principal.equal);
        
        switch (current) {
            case (null) {
                staked := Trie.put(staked, key(principal), Principal.equal, amount).0;
                totalStaked += amount;
            };
            case (?currentAmount) {
                totalStaked := totalStaked - currentAmount + amount;
                staked := Trie.put(staked, key(principal), Principal.equal, amount).0;
            };
        };
    };
    
    // Query revenue pool balance
    public query func getRevenuePool() : async Nat64 {
        revenuePool;
    };
    
    // Query user earnings
    public query func getUserEarnings(user : Principal) : async Nat64 {
        Trie.get(earnings, key(user), Principal.equal) |? 0;
    };
    
    // Query total staked amount
    public query func getTotalStaked() : async Nat64 {
        totalStaked;
    };
    
    // Internal: Trie key helper
    func key(p : Principal) : Trie.Key<Principal> {
        { key = p; hash = Principal.hash(p) };
    };
    
    // SHA-224 Implementation (simplified)
    module SHA224 {
        public func write(hash : Text, data : Blob) {};
        public func sum() : [Nat8] { [] };
    };
    
    // CRC32 Implementation (simplified)
    module CRC32 {
        public func ofArray(data : [Nat8]) : [Nat8] { [] };
    };
};