import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";

actor FinanceCanister {
  type AletheianId = Principal;
  type ICP = Nat;
  type USD = Float;
  
  type Payment = {
    date: Int;
    amountICP: ICP;
    amountUSD: USD;
  };
  
  type Earnings = {
    totalXP: Nat;
    monthlyXP: Nat;
    earningsICP: ICP;
    earningsUSD: USD;
    paymentHistory: [Payment];
  };
  
  let earnings = HashMap.HashMap<AletheianId, Earnings>(0, Principal.equal, Principal.hash);
  var paymentPool: ICP = 0;
  let xpTotals = HashMap.HashMap<AletheianId, Nat>(0, Principal.equal, Principal.hash);
  let monthlyTotals = HashMap.HashMap<Nat, Nat>(0, Nat.equal, Hash.hash);
  
  // Update earnings based on XP
  public shared func updateEarnings(aletheianId: AletheianId, xpEarned: Nat) : async () {
    let current = switch (earnings.get(aletheianId)) {
      case (?e) e;
      case null {
        {
          totalXP = 0;
          monthlyXP = 0;
          earningsICP = 0;
          earningsUSD = 0.0;
          paymentHistory = [];
        }
      };
    };
    
    let totalXP = current.totalXP + xpEarned;
    let monthlyXP = current.monthlyXP + xpEarned;
    
    // Update XP totals
    xpTotals.put(aletheianId, totalXP);
    
    // Calculate new earnings
    let totalSystemXP = Array.foldLeft<Nat, Nat>(
      Iter.toArray(xpTotals.vals()), 0, func(acc, xp) { acc + xp }
    );
    
    let share = if (totalSystemXP > 0) 
      Float.fromIntWrap(Int.abs(Int.sub(Int.fromNat(totalXP), 0))) / Float.fromIntWrap(Int.fromNat(totalSystemXP))
      else 0.0;
    
    let earningsICP = Nat64.toNat(Nat64.fromIntWrap(Int.abs(Int.mul(Int.fromFloat(share), Int.fromNat(paymentPool)))));
    let earningsUSD = Float.fromIntWrap(Int.abs(Int.fromNat(earningsICP))) * currentExchangeRate(); // Would fetch from oracle
    
    let updated: Earnings = {
      totalXP = totalXP;
      monthlyXP = monthlyXP;
      earningsICP = earningsICP;
      earningsUSD = earningsUSD;
      paymentHistory = current.paymentHistory;
    };
    
    earnings.put(aletheianId, updated);
  };
  
  // Withdraw earnings
  public shared ({ caller }) func withdraw(amount: ICP) : async Result.Result<Text, Text> {
    switch (earnings.get(caller)) {
      case (?e) {
        if (amount > e.earningsICP) {
          return #err("Insufficient funds");
        };
        
        // In production: Transfer ICP to caller's wallet
        let transactionId = "tx_" # Int.toText(Time.now());
        
        // Update earnings
        let updated: Earnings = {
          e with
          earningsICP = e.earningsICP - amount;
          paymentHistory = Array.append(e.paymentHistory, [{
            date = Int.abs(Time.now());
            amountICP = amount;
            amountUSD = Float.fromInt(Int.abs(Int.fromNat(amount))) * currentExchangeRate();
          }]);
        };
        
        earnings.put(caller, updated);
        #ok(transactionId)
      };
      case null { #err("No earnings record found") };
    }
  };
  
  // Add to payment pool (called by revenue system)
  public shared func addToPool(amount: ICP) : async () {
    paymentPool := paymentPool + amount;
  };
  
  // Internal function to get current exchange rate
  func currentExchangeRate() : Float {
    // Would fetch from an oracle in production
    30.0 // $30 per ICP
  };
};

