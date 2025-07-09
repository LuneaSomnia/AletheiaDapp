import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Types "../../../common/Types";  // Correct path for your project

actor VerificationWorkflowCanister {
    type Assignment = {
  verifierId: Principal;
  task: Types.TaskDetails;
  status: {#Assigned; #Completed; #Rejected; #Active};
  timestamp: Time.Time;
  
};
    type VerifierId = Principal;
    
    // Storing assignments with verifierId as key
    let assignments = HashMap.HashMap<VerifierId, Assignment>(0, Principal.equal, Principal.hash);
    
    // Original method causing error - fixed with proper type handling
    public shared ({ caller }) func isVerifierAuthorized(verifierId: Principal) : async Bool {
        switch (assignments.get(verifierId)) {
            case (null) { false };
            case (?assignment) { 
                // Add any additional authorization checks here
                assignment.status == #Active
            };
        }
    };
    
    // Additional context from original file
    public func assignVerificationTask(verifierId: Principal, taskDetails: Types.TaskDetails) : async Result.Result<(), Text> {
        // Original logic preserved
        switch (assignments.get(verifierId)) {
            case (null) {
                let newAssignment: Assignment = {
                    verifierId = verifierId;
                    task = taskDetails;
                    status = #Assigned;
                    timestamp = Time.now();
                };
                assignments.put(verifierId, newAssignment);
                #ok(())
            };
            case (?existing) {
                #err("Verifier already has an active assignment")
            };
        }
    };
    
    public func completeVerificationTask(verifierId: Principal, result: Types.VerificationResult) : async Result.Result<(), Text> {
        switch (assignments.get(verifierId)) {
            case (null) { #err("No assignment found") };
            case (?assignment) {
                // Update assignment status
                let updatedAssignment: Assignment = {
                    assignment with 
                    status = #Completed;
                    result = ?result;
                };
                assignments.put(verifierId, updatedAssignment);
                #ok(())
            };
        }
    };
    
    // More methods from original implementation...
    public query func getAssignment(verifierId: Principal) : async ?Assignment {
        assignments.get(verifierId)
    };
    
    public func resetAssignments() : async () {
        for (entry in assignments.entries()) {
            assignments.delete(entry.0);
        };
    };
};