import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Result "mo:base/Result";

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
  let paymentPool: ICP = 0;
  let xpTotals = HashMap.HashMap<AletheianId, Nat>(0, Principal.equal, Principal.hash);
  let monthlyTotals = HashMap.HashMap<Nat, Nat>(0, Nat.equal, Nat.hash); // Month -> Total XP
  
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
      Float.fromInt(totalXP) / Float.fromInt(totalSystemXP) 
      else 0.0;
    
    let earningsICP = paymentPool * share;
    let earningsUSD = earningsICP * currentExchangeRate(); // Would fetch from oracle
    
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
        let transactionId = "tx_" # Time.now().toText();
        
        // Update earnings
        let updated: Earnings = {
          e with
          earningsICP = e.earningsICP - amount;
          paymentHistory = Array.append(e.paymentHistory, [{
            date = Time.now();
            amountICP = amount;
            amountUSD = amount * currentExchangeRate();
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
    paymentPool += amount;
  };
  
  // Internal function to get current exchange rate
  func currentExchangeRate() : Float {
    // Would fetch from an oracle in production
    30.0 // $30 per ICP
  };
};