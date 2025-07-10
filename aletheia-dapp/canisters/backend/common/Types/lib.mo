module {
    public type Assignment = {
        verifierId: Principal;
        task: TaskDetails;
        status: { #Assigned; #Completed; #Rejected };
        timestamp: Int;
        result: ?VerificationResult;
    };

    public type TaskDetails = {
        claimId: Text;
        deadline: Int;
        complexity: { #Low; #Medium; #High };
    };

    public type VerificationResult = {
        verdict: Text;
        evidence: [Text];
        comments: ?Text;
    };

    public type VerifierId = Principal;
};