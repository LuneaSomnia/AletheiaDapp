import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Debug "mo:base/Debug";
import _ "mo:base/Result";
import Nat "mo:base/Nat";

actor DIP20Token {
    type Token = {
        symbol : Text;
        decimals : Nat8;
        name : Text;
    };
    
    type TransferResult = {
        #Ok : Nat;
        #Err : TransferError;
    };
    
    type TransferError = {
        #InsufficientBalance;
        #InsufficientAllowance;
        #Unauthorized;
        #Other : Text;
    };
    
    private let token : Token = {
        symbol = "AUTH";
        decimals = 8;
        name = "Aletheia Truth Token";
    };
    
    private var totalSupply : Nat = 1_000_000_000_000_000;
    private let balances = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);
    
    public query func symbol() : async Text { token.symbol };
    public query func decimals() : async Nat8 { token.decimals };
    public query func name() : async Text { token.name };
    public query func getTotalSupply() : async Nat { totalSupply };
    
    public shared ({ caller = _ }) func transfer(to : Principal, amount : Nat) : async TransferResult {
        Debug.print("Mock transfer: " # Nat.toText(amount) # " to " # Principal.toText(to));
        #Ok(12345) // Mock successful transfer index
    };
    
    public query func balanceOf(owner : Principal) : async Nat {
        switch (balances.get(owner)) {
            case (null) 0;
            case (?balance) balance;
        }
    };
    
    public shared ({ caller = _ }) func mint(to : Principal, amount : Nat) : async () {
        let current = await balanceOf(to);
        balances.put(to, current + amount);
        totalSupply += amount;
    };
};