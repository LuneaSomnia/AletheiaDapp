import UserAccount "canister:UserAccountCanister";
import ClaimSubmission "canister:ClaimSubmissionCanister";
import AletheianDispatch "canister:AletheianDispatchCanister";
import VerificationWorkflow "canister:VerificationWorkflowCanister";
import FactLedger "canister:FactLedgerCanister";
import Notification "canister:NotificationCanister";

actor Main {
  public shared ({ caller }) func submit_claim(
    claimType : ClaimSubmission.ClaimType,
    source : ?Text,
    context : ?Text,
    tags : [Text]
  ) : async Text {
    // Verify user identity
    let user = await UserAccount.get_user(caller);
    
    // Submit claim
    let claimId = await ClaimSubmission.submit_claim(claimType, source, context, tags);
    
    // Record submission in user profile
    await UserAccount.record_claim_submission(caller, claimId);
    
    // Assign to Aletheians
    await AletheianDispatch.assign_claim(claimId);
    
    // Notify user
    await Notification.send_notification(
      caller,
      #claim_submitted,
      "Your claim has been submitted and is being verified"
    );
    
    claimId
  };

  public shared func verify_claim(claimId : Text) : async () {
    // Get claim data
    let claim = await ClaimSubmission.get_claim(claimId);
    
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
      #claim_verified,
      "Your claim has been verified: " # results.verdict
    );
    
    // Clean up
    await ClaimSubmission.process_claim(claimId);
  };
};