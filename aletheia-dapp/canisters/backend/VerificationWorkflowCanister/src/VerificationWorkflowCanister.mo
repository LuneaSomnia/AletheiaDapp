import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

actor VerificationWorkflowCanister {
  type ClaimId = Text;
  type AletheianId = Principal;
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
  
  type Assignment = {
    claimId: ClaimId;
    assignedTo: [AletheianId];
    deadline: Int;
    status: {
      #Pending;
      #InProgress;
      #Completed;
      #Escalated;
    };
    verifications: [Verification];
  };
  
  type Verification = {
    aletheianId: AletheianId;
    verdict: Verdict;
    explanation: Text;
    submittedAt: Int;
  };
  
  let assignments = HashMap.HashMap<ClaimId, Assignment>(0, Text.equal, Text.hash);
  let aletheianAssignments = HashMap.HashMap<AletheianId, [ClaimId]>(0, Principal.equal, Principal.hash);
  
  // Assign a claim to Aletheians
  public shared func assignClaim(
    claimId: ClaimId,
    aletheianIds: [AletheianId],
    deadline: Int
  ) : async Result.Result<(), Text> {
    let assignment: Assignment = {
      claimId = claimId;
      assignedTo = aletheianIds;
      deadline = deadline;
      status = #Pending;
      verifications = [];
    };
    
    assignments.put(claimId, assignment);
    
    for (id in aletheianIds.vals()) {
      let current = switch (aletheianAssignments.get(id)) {
        case (?ids) ids;
        case null [];
      };
      aletheianAssignments.put(id, Array.append(current, [claimId]));
    };
    
    #ok(())
  };
  
  // Submit verification
  public shared ({ caller }) func submitVerification(
    claimId: ClaimId,
    verdict: Verdict,
    explanation: Text
  ) : async Result.Result<(), Text> {
    let aletheianId = caller;
    
    switch (assignments.get(claimId)) {
      case (?assignment) {
        if (not Array.find<Principal>(assignment.assignedTo, func(p) { p == aletheianId })) {
          return #err("Not assigned to this claim");
        };
        
        let verification: Verification = {
          aletheianId = aletheianId;
          verdict = verdict;
          explanation = explanation;
          submittedAt = Time.now();
        };
        
        let updatedVerifications = Array.append(assignment.verifications, [verification]);
        let updatedAssignment: Assignment = {
          assignment with
          verifications = updatedVerifications;
          status = #InProgress;
        };
        
        assignments.put(claimId, updatedAssignment);
        #ok(())
      };
      case null { #err("Assignment not found") };
    }
  };
  
  // Check for consensus
  public shared query func checkConsensus(claimId: ClaimId) : async ?Bool {
    switch (assignments.get(claimId)) {
      case (?assignment) {
        if (assignment.verifications.size() < assignment.assignedTo.size()) {
          return null; // Not all verifications submitted
        };
        
        let firstVerdict = assignment.verifications[0].verdict;
        for (v in assignment.verifications.vals()) {
          if (v.verdict != firstVerdict) {
            return ?false; // Disagreement
          }
        };
        ?true // Consensus
      };
      case null null;
    }
  };
  
  // Get assignments for an Aletheian
  public shared query ({ caller }) func getAssignments() : async [Assignment] {
    switch (aletheianAssignments.get(caller)) {
      case (?claimIds) {
        Array.mapFilter<ClaimId, Assignment>(
          claimIds,
          func(claimId) { assignments.get(claimId) }
        )
      };
      case null [];
    }
  };
};