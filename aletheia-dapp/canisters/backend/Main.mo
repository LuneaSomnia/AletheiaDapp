import UserAccount "canister:UserAccountCanister";
import ClaimSubmission "canister:ClaimSubmissionCanister";
import AletheianDispatch "canister:AletheianDispatchCanister";
import VerificationWorkflow "canister:VerificationWorkflowCanister";
import FactLedger "canister:FactLedgerCanister";
import Notification "canister:NotificationCanister";
import AI_Integration "canister:AI_IntegrationCanister";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Result "mo:base/Result";

actor Main {

  public shared ({ caller }) func submit_claim(
    claimType : Text,
    source : ?Text,
    context : ?Text,
    tags : [Text]
  ) : async Text {
    // Register user if not exists
    let _ = await UserAccount.register();
    
    // Create claim submission
    let submission = {
      content = #text(claimType);
      claimType = "text";
      context = context;
      source = source;
    };
    
    // Submit claim
    let claimResult = await ClaimSubmission.submitClaim(submission);
    let claimId = switch (claimResult) {
      case (#ok(id)) { id };
      case (#err(msg)) { throw Error.reject("Claim submission failed: " # msg) };
    };
    
    // Generate AI questions
    let claim = {
      id = claimId;
      content = claimType;
      claimType = "text";
      source = source;
      context = context;
    };
    let _ = await AI_Integration.generateQuestions(claim);
    
    // Create verification task
    let aletheians = []; // Will be populated by dispatch
    let _ = await VerificationWorkflow.createTask(claimId, aletheians);
    
    // Send notification
    let _ = await Notification.sendNotification(
      caller,
      "Claim Submitted",
      "Your claim has been submitted and is being verified"
    );
    
    claimId
  };

  public query func get_claim_status(claimId : Text) : async ?{ status : Text; verdict : ?Text; explanation : ?Text } {
    switch (await VerificationWorkflow.getTask(claimId)) {
      case (?task) {
        let status = switch (task.status) {
          case (#assigned) { "assigned" };
          case (#inProgress) { "in_progress" };
          case (#consensusReached(verdict)) { "completed" };
          case (#disputed) { "disputed" };
          case (#completed) { "completed" };
        };
        ?{ status = status; verdict = null; explanation = null }
      };
      case null { null };
    };
  };

  public shared func verify_claim(claimId : Text) : async () {
    // This will be called by the verification workflow when consensus is reached
    // Implementation handled by VerificationWorkflowCanister
  };
}

    
    // Verify claim
    let results = await VerificationWorkflow.verify_claim(claimId);
    
    // Store result
    await FactLedger.store_fact(
      claimId,
      claim.content,
      results.verdict,
      results.explanation,
      results.evidence
    );
    
    // Notify user
    await Notification.send_notification(
      claim.submitter,
      "claim_verified",
      "Your claim has been verified: " # results.verdict
    );
    
    // Clean up
    await ClaimSubmission.process_claim(claimId);
  };
};