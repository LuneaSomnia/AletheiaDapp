import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Array "mo:base/Array";

actor {
  // --- Type Definitions ---
  type AletheianId = Principal;
  type ICP = Nat;    // Using Nat for ICP (e.g., smallest unit like e8s)
  type USD = Nat;    // Using Nat for USD cents to avoid floating-point errors


  type Payment = {
    date: Time.Time;
    amountICP: ICP;
    amountUSD: USD;
  };

  type Earnings = {
    var totalXP: Nat;
    var monthlyXP: Nat;
    var earningsICP: ICP;
    var earningsUSD: USD;
    var paymentHistory: [Payment];
  };

  // --- Canister State ---
  private var earnings: TrieMap.TrieMap<AletheianId, Earnings> = TrieMap.TrieMap(
    Principal.equal,
    Principal.hash
  );

  private var totalSystemXP: Nat = 0;
  private var paymentPool: ICP = 0;
  private let icpToUSDCentsRate: Nat = 3000; // $30.00

  // --- Record earned XP ---
  public shared func recordXp(aletheianId: AletheianId, xpEarned: Nat) : async () {
    let aletheianEarnings = switch (earnings.get(aletheianId)) {
      case (?e) e;
      case null {
        let newRecord : Earnings = {
          var totalXP = 0;
          var monthlyXP = 0;
          var earningsICP = 0;
          var earningsUSD = 0;
          var paymentHistory = [];
        };
        earnings.put(aletheianId, newRecord);
        newRecord;
      };
    };

    aletheianEarnings.totalXP += xpEarned;
    aletheianEarnings.monthlyXP += xpEarned;
    totalSystemXP += xpEarned;
  };

  // --- Distribute payment pool ---
  public shared func distributePaymentPool() : async () {
    if (paymentPool == 0 or totalSystemXP == 0) return;

    for ((aletheianId, aletheianEarnings) in earnings.entries()) {
      if (aletheianEarnings.totalXP > 0) {
        let share: ICP = (paymentPool * aletheianEarnings.totalXP) / totalSystemXP;
        aletheianEarnings.earningsICP += share;
        aletheianEarnings.earningsUSD += share * icpToUSDCentsRate;
      };
    };

    paymentPool := 0;
    totalSystemXP := 0;
  };

  // --- Withdraw earnings ---
  public shared ({ caller }) func withdraw(amount: ICP) : async Result.Result<Text, Text> {
    switch (earnings.get(caller)) {
      case null {
        return #err("No earnings record found.");
      };
      case (?earningRecord) {
        if (amount > earningRecord.earningsICP) {
          return #err("Insufficient funds.");
        };

        earningRecord.earningsICP -= amount;
        let amountUSD = amount * icpToUSDCentsRate;
        earningRecord.earningsUSD -= amountUSD;


        let newPayment: Payment = {
          date = Time.now();
          amountICP = amount;
          amountUSD = amountUSD;
        };

        earningRecord.paymentHistory := Array.append(earningRecord.paymentHistory, [newPayment]);

        let txId = "tx_" # Nat.toText(Int.abs(Time.now()));

        return #ok(txId);
      };
    };
  };

  // --- Add funds to the payment pool ---
  public shared func addToPool(amount: ICP) : async () {
    paymentPool += amount;
  };
};
