import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Result "mo:base/Result";
import DIP20 "canister:DIP20Token"; // Updated import
import ReputationLogic "canister:ReputationLogic";

actor {
  type AletheianId = Principal;
  type Token = { #ICP; #USD };
  
  private var monthlyRevenue : Nat = 0;
  private var revenuePool : Nat = 0;
  private var lastPayout : Time.Time = 0;
  
  private let aletheianBalances = HashMap.HashMap<AletheianId, Nat>(0, Principal.equal, Principal.hash);
  
  // Set monthly revenue (called by admin)
  public shared ({ caller }) func setMonthlyRevenue(amount : Nat) : async () {
    // Add authentication in production
    monthlyRevenue := amount;
    revenuePool += amount;
  };
  
  // Run monthly payout to Aletheians
  public shared func runMonthlyPayout() : async Result.Result<Text, Text> {
    if (revenuePool == 0) {
      return #err("No revenue available for payout");
    };
    
    let totalXP = await ReputationLogic.getTotalMonthlyXP();
    if (totalXP == 0) {
      return #err("No XP earned this month");
    };
    
    let xpValue = Float.fromInt(revenuePool) / Float.fromInt(totalXP);
    let aletheians = await ReputationLogic.getActiveAletheians();
    
    var totalDistributed = 0;
    var successCount = 0;
    var failCount = 0;
    
    for (aletheian in aletheians.vals()) {
      let xp = await ReputationLogic.getMonthlyXP(aletheian);
      let amount = Float.toInt(Float.fromInt(xp) * xpValue);
      
      if (amount > 0) {
        switch (await transferToAletheian(aletheian, amount)) {
          case (#ok) {
            totalDistributed += amount;
            successCount += 1;
          };
          case (#err(msg)) {
            failCount += 1;
            // Log error
          };
        };
      };
    };
    
    revenuePool -= totalDistributed;
    lastPayout := Time.now();
    
    #ok("Distributed " # Nat.toText(totalDistributed) # " tokens to " 
      # Nat.toText(successCount) # " Aletheians. " 
      # Nat.toText(failCount) # " failed transfers.");
  };
  
  private func transferToAletheian(aletheian : Principal, amount : Nat) : async Result.Result<(), Text> {
    try {
      let transferResult = await DIP20.transfer(aletheian, amount);
      switch (transferResult) {
        case (#Ok(index)) { #ok() };
        case (#Err(err)) { #err("Transfer error: " # err) };
      };
    } catch (e) {
      #err("Exception: " # Error.message(e));
    };
  };
  
  // Withdraw funds for Aletheian
  public shared ({ caller }) func withdraw(amount : Nat) : async Result.Result<Nat, Text> {
    switch (aletheianBalances.get(caller)) {
      case (null) { #err("No balance available") };
      case (?balance) {
        if (balance < amount) {
          #err("Insufficient balance");
        } else {
          switch (await transferToAletheian(caller, amount)) {
            case (#ok) {
              let newBalance = balance - amount;
              aletheianBalances.put(caller, newBalance);
              #ok(newBalance);
            };
            case (#err(msg)) { #err(msg) };
          };
        };
      };
    };
  };
};