import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Option "mo:base/Option";

actor EscalationCanister {
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
  
  type Escalation = {
    claimId: ClaimId;
    originalAssignments: [AletheianId];
    seniorAssignments: [AletheianId];
    originalVerifications: [Verification];
    seniorVerifications: [Verification];
    finalVerdict: ?Verdict;
    resolvedAt: ?Int;
  };
  
  type Verification = {
    aletheianId: AletheianId;
    verdict: Verdict;
    explanation: Text;
    submittedAt: Int;
  };
  
  let escalations = HashMap.HashMap<ClaimId, Escalation>(0, Text.equal, Text.hash);
  
  // Create a new escalation
  public shared func createEscalation(
    claimId: ClaimId,
    originalAssignments: [AletheianId],
    originalVerifications: [Verification],
    seniorAssignments: [AletheianId]
  ) : async Result.Result<(), Text> {
    if (escalations.get(claimId) != null) {
      return #err("Escalation already exists for this claim");
    };
    
    let escalation: Escalation = {
      claimId = claimId;
      originalAssignments = originalAssignments;
      seniorAssignments = seniorAssignments;
      originalVerifications = originalVerifications;
      seniorVerifications = [];
      finalVerdict = null;
      resolvedAt = null;
    };
    
    escalations.put(claimId, escalation);
    #ok(())
  };
  
  // Submit senior verification
public shared ({ caller }) func submitSeniorVerification(
  claimId: ClaimId,
  verdict: Verdict,
  explanation: Text
) : async Result.Result<(), Text> {
  switch (escalations.get(claimId)) {
    case (?escalation) {
      if (not Option.isSome(Array.find<Principal>(escalation.seniorAssignments, func(p) {
        caller == p
      }))) {
        return #err("Not assigned to this escalation");
      };

      let verification: Verification = {
        aletheianId = caller;
        verdict = verdict;
        explanation = explanation;
        submittedAt = Time.now();
      };

      let updatedVerifications = Array.append(escalation.seniorVerifications, [verification]);
      let updatedEscalation: Escalation = {
        escalation with
        seniorVerifications = updatedVerifications;
      };

      escalations.put(claimId, updatedEscalation);
      #ok(())
    };
    case null { #err("Escalation not found") };
  }
};

  // Finalize escalation
  public shared func finalizeEscalation(claimId: ClaimId, finalVerdict: Verdict) : async Result.Result<(), Text> {
    switch (escalations.get(claimId)) {
      case (?escalation) {
        let updatedEscalation: Escalation = {
          escalation with
          finalVerdict = ?finalVerdict;
          resolvedAt = ?Time.now();
        };
        
        escalations.put(claimId, updatedEscalation);
        #ok(())
      };
      case null { #err("Escalation not found") };
    }
  };
};