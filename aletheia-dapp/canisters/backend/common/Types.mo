module {
    public type ClaimType = { 
        #Text; 
        #Image; 
        #Video; 
        #Audio; 
        #URL; 
        #FakeSite; 
        #Other : Text 
    };
    
    public type ClaimStatus = {
        #Pending; 
        #Assigned; 
        #InReview; 
        #Verified; 
        #Escalated; 
        #Duplicate; 
        #Rejected;
    };

    public type Claim = {
        id: Text;
        submitter: Principal;
        anonymousSubmitterId: Text;
        claimType: ClaimType;
        text: ?Text;
        contentHash: ?Text;
        sourceUrl: ?Text;
        tags: [Text];
        status: ClaimStatus;
        createdAt: Nat;
        updatedAt: Nat;
        assignedAletheians: [Principal];
        aiQuestions: ?[Text];
        metadata: [(Text, Text)];
        retryCount: Nat;
    };

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
