import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Iter "mo:base/Iter";

actor FactLedgerCanister {
  type ClaimId = Text;
  type Evidence = {
    sourceUrl: Text;
    contentHash: Text;
    credibilityScore: Nat;
  };
  
  type Verdict = {
    #True;
    #MostlyTrue;
    #HalfTruth;
    #MisleadingContext;
    #False;
    #MostlyFalse;
    #Unsubstantiated;
    #Outdated;
    #Satire;
    #Opinion;
  };
  
  type FactRecord = {
    claim: Text;
    verdict: Verdict;
    explanation: Text;
    evidence: [Evidence];
    verifiedAt: Int;
    aletheians: [Principal];
    version: Nat;
    previousVersion: ?FactRecord;
  };
  
  let facts = HashMap.HashMap<ClaimId, FactRecord>(0, Text.equal, Text.hash);
  let claimHistory = HashMap.HashMap<ClaimId, [FactRecord]>(0, Text.equal, Text.hash);
  
  // Store a verified fact
  public shared ({ caller }) func storeFact(
    claimId: ClaimId,
    claim: Text,
    verdict: Verdict,
    explanation: Text,
    evidence: [Evidence],
    aletheians: [Principal]
  ) : async Result.Result<(), Text> {
    let newRecord: FactRecord = {
      claim = claim;
      verdict = verdict;
      explanation = explanation;
      evidence = evidence;
      verifiedAt = Time.now();
      aletheians = aletheians;
      version = 1;
      previousVersion = null;
    };
    
    switch (facts.get(claimId)) {
      case (?existing) {
        let updatedRecord: FactRecord = {
          newRecord with
          version = existing.version + 1;
          previousVersion = ?existing;
        };
        facts.put(claimId, updatedRecord);
        
        // Update history
        let history = switch (claimHistory.get(claimId)) {
          case (?h) Array.append(h, [updatedRecord]);
          case null [updatedRecord];
        };
        claimHistory.put(claimId, history);
      };
      case null {
        facts.put(claimId, newRecord);
        claimHistory.put(claimId, [newRecord]);
      };
    };
    
    #ok(())
  };
  
  // Get the latest fact by claim ID
  public shared query func getFact(claimId: ClaimId) : async ?FactRecord {
    facts.get(claimId)
  };
  
  // Get history of a claim
  public shared query func getClaimHistory(claimId: ClaimId) : async [FactRecord] {
    switch (claimHistory.get(claimId)) {
      case (?history) history;
      case null [];
    }
  };
  
  // Search for facts
  public shared query func searchClaims(searchquery: Text) : async [FactRecord] {
    // Simplified implementation - would use full-text search in production
    Array.filter<FactRecord>(
      Iter.toArray(facts.vals()),
      func(record) { Text.contains(record.claim, #text searchquery) }
    )
  };
};