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

    public type Verdict = { 
        #True; #MostlyTrue; #HalfTruth; #Misleading; #False; 
        #Unsubstantiated; #Propaganda; #Satire; #InsufficientEvidence; 
        #Deepfake; #Other: Text 
    };

    public type WorkflowState = { 
        #Pending; #ConsensusReached; #Escalated; #TimedOut; 
        #ErrorPersisting; #Reopened 
    };

    public type Submission = {
        aletheian: Principal;
        verdict: Verdict;
        evidence: [Text];
        notes: Text;
        submittedAt: Int;
    };

    public type WorkflowEntry = {
        claimId: Text;
        assigned: [Principal];
        submissions: [(Principal, Submission)];
        state: WorkflowState;
        createdAt: Int;
        lastUpdatedAt: Int;
        attempts: Nat;
        dataVersion: Nat;
        history: [Text];
    };

    public type WorkflowSummary = {
        claimId: Text;
        state: WorkflowState;
        lastUpdatedAt: Int;
        submissionsCount: Nat;
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

    // AI Integration Types
    public type ClaimMeta = {
        mediaType : Text;
        sourceUrl : ?Text;
        ipfsHash : ?Text;
        submittedBy : Principal;
        submittedAt : Int;
    };

    public type Question = { 
        questionText : Text; 
        rationale : Text; 
        priority: Nat8 
    };
    
    public type ResultOkQuestions = { 
        questions : [Question] 
    };

    public type ResearchSource = { 
        url: Text; 
        title: Text; 
        summary: Text; 
        credibilityScore: Nat8; 
        snippet: Text 
    };
    
    public type ResultOkResearch = { 
        sources : [ResearchSource]; 
        summary : Text; 
        confidence: Nat8 
    };

    public type AletheianSubmission = { 
        aletheianId : Text; 
        verdict : Text; 
        rationale : Text; 
        evidenceHashes: [Text] 
    };
    
    public type ResultOkSynthesis = { 
        verdict : Text; 
        abstract : Text; 
        evidenceSummary : [Text]; 
        confidence: Nat8 
    };

    public type DuplicateMatch = { 
        claimId: Text; 
        similarityPct: Nat8; 
        snippet: Text; 
        evidencePointer: ?Text 
    };
    
    public type SourceScore = { 
        url: Text; 
        score: Nat8; 
        reason: Text 
    };

    public type AIFeedback = {
        userId: Principal;
        timestamp: Int;
        module: Text;
        rating: Nat8;
        comments: ?Text;
    };

    public type ResearchResult = {
        sourceUrl: Text;
        sourceName: Text;
        credibilityScore: Float;
        summary: Text;
    };

    public type MediaAnalysis = {
        isDeepfake: Bool;
        confidence: Float;
        analysis: Text;
    };

    public type Finding = {
        classification: Text;
        explanation: Text;
        evidence: [Text];
    };

    // AI Adapter Types
    public type AIAdapterRequest = {
        requestType: Text;
        claimId: Text;
        text: Text;
        meta: ClaimMeta;
        redactionApplied: Bool;
        maxSources: ?Nat;
        threshold: ?Nat;
        style: ?Text;
    };

    public type AIAdapterResponse = {
        #Success: Text;
        #Error: (code: Text, message: Text, transient: Bool);
    };

    public type AIAdapterEmbeddingResponse = {
        #Success: [Float];
        #Error: Text;
    };

    public type AIAdapterFetchResponse = {
        #Success: Text;
        #Error: Text;
    };

    public type AIAdapterSearchResponse = {
        #Success: [{docId: Text; score: Float; snippet: Text}];
        #Error: Text;
    };

    public type AIAdapterUpsertResponse = {
        #Success: Text;
        #Error: Text;
    };

    public type AIAdapterStoreResponse = {
        #Success: Text; // CID
        #Error: Text;
    };

    public type FetchOptions = {
        headers: ?[(Text, Text)];
        method: ?Text;
        body: ?[Nat8];
        transform: ?{
            function : Principal;
            context : [Nat8];
        };
        max_response_bytes: ?Nat;
    };

    public type DeploymentMode = {
        #Direct;
        #Bridge: {
            bridgePrincipal: Principal;
            maxRetries: Nat;
        };
    };

    // Gamified Learning Types
    public type ModuleId = Text;
    public type LessonId = Text;
    public type ProgressId = Text;
    public type XP = Nat;
    
    public type Module = {
        id : ModuleId;
        title : Text;
        description : Text;
        lessons : [Lesson];
        xpReward : XP;
        requiredForBadges : [Text];
        isPublished : Bool;
        createdAt : Int;
        updatedAt : Int;
        createdBy : Principal;
    };

    public type Lesson = {
        id : LessonId;
        title : Text;
        contentHash : Text;
        contentType : Text;
        order : Nat;
        quiz : ?Quiz;
    };

    public type Quiz = {
        questions : [Question];
        passPercentage : Nat;
    };

    public type Question = {
        id : Text;
        prompt : Text;
        options : [Text];
        correctIndexes : [Nat];
        maxScore : Nat;
    };

    public type UserProgress = {
        progressId : ProgressId;
        user : Principal;
        moduleId : ModuleId;
        lessonIndex : Nat;
        lessonStatuses : [Bool];
        progressPercent : Nat;
        enrolledAt : Int;
        completedAt : ?Int;
        xpAwarded : Bool;
    };

    public type ModuleInput = {
        title : Text;
        description : Text;
        lessons : [Lesson];
        xpReward : XP;
        requiredForBadges : [Text];
    };

    public type ModuleSummary = {
        id : ModuleId;
        title : Text;
        description : Text;
        xpReward : XP;
        lessonCount : Nat;
        isPublished : Bool;
    };
};
