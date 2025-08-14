import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Types "../common/Types";

actor VerificationWorkflowCanister {
    // ======== TYPE DEFINITIONS ========
    public type ClaimId = Text;
    public type AletheianId = Principal;
    public type Finding = {
        verdict : Text;
        explanation : Text;
        evidence : [Text];
        timestamp : Int;
    };
    public type VerificationTask = {
        claimId : ClaimId;
        assignedAletheians : [AletheianId];
        findings : [(AletheianId, Finding)];
        status : {
            #assigned;
            #inProgress;
            #consensusReached : Text; // Final verdict
            #disputed;
            #completed;
        };
        duplicateOf : ?ClaimId; // Track original claim ID for duplicates
        createdAt : Int;
    };
    
    // ======== HELPER FUNCTIONS ========
    func isController(caller: Principal) : Bool {
        caller == controller
    };

    func isAuthorized(caller: Principal) : Bool {
        isController(caller) or Option.isSome(authorizedCanisters.get(caller))
    };

    func isAssignedAletheian(claimId: ClaimId, caller: Principal) : Bool {
        switch(workflows.get(claimId)) {
            case (?entry) { Array.find<Principal>(entry.assigned, func(p) { p == caller }) != null };
            case null { false }
        }
    };

    func updateWorkflowHistory(claimId: ClaimId, message: Text) : () {
        switch(workflows.get(claimId)) {
            case (?entry) {
                let newHistory = Array.append(entry.history, [Time.toText(Time.now()) # " - " # message]);
                let updatedEntry = { entry with 
                    history = newHistory;
                    lastUpdatedAt = Time.now();
                };
                workflows.put(claimId, updatedEntry);
            };
            case null {};
        };
    };

    // ======== SYSTEM FUNCTIONS ========
    system func preupgrade() {
        workflowsEntries := Iter.toArray(workflows.entries());
        authorizedCanistersEntries := Iter.toArray(authorizedCanisters.entries());
    };

    system func postupgrade() {
        workflows := TrieMap.fromEntries<ClaimId, Types.WorkflowEntry>(workflowsEntries.vals(), Text.equal, Text.hash);
        authorizedCanisters := HashMap.fromIter<Principal, Bool>(authorizedCanistersEntries.vals(), 1, Principal.equal, Principal.hash);
        
        if (dataVersion < INITIAL_DATA_VERSION) {
            // Future migration logic here
            dataVersion := INITIAL_DATA_VERSION;
        };
    };
    
    // ======== CANISTER REFERENCES ========
    let factLedger = actor ("FactLedgerCanister") : actor {
        getFact : (id : Nat) -> async ?{
            id : Nat;
            content : Text;
            status : { #PendingReview; #Verified; #Disputed; #Deprecated };
            claimClassification : ?{ #True; #False; #MisleadingContext; #Unsubstantiated };
            evidence : [{ hash : Text; storageType : Text; url : ?Text; timestamp : Int; provider : Principal }];
            verdicts : [{ classification : { #True; #False; #MisleadingContext; #Unsubstantiated }; timestamp : Int; verifier : Principal; explanation : Text }];
            version : { version : Nat; previousVersion : ?Nat; timestamp : Int };
            publicProof : { proofType : Text; content : Text };
            created : Int;
            lastUpdated : Int;
        };
        addFact : (request : {
            content : Text;
            evidence : [{ hash : Text; storageType : Text; url : ?Text; timestamp : Int; provider : Principal }];
            publicProof : { proofType : Text; content : Text };
        }) -> async Result.Result<{
            id : Nat;
            content : Text;
            status : { #PendingReview; #Verified; #Disputed; #Deprecated };
            claimClassification : ?{ #True; #False; #MisleadingContext; #Unsubstantiated };
            evidence : [{ hash : Text; storageType : Text; url : ?Text; timestamp : Int; provider : Principal }];
            verdicts : [{ classification : { #True; #False; #MisleadingContext; #Unsubstantiated }; timestamp : Int; verifier : Principal; explanation : Text }];
            version : { version : Nat; previousVersion : ?Nat; timestamp : Int };
            publicProof : { proofType : Text; content : Text };
            created : Int;
            lastUpdated : Int;
        }, Text>;
    };

    let aletheianProfile = actor ("AletheianProfileCanister") : actor {
        getProfile : (aletheian : Principal) -> async ?{
            id : Principal;
            rank : { #Trainee; #Junior; #Associate; #Senior; #Expert; #Master };
            xp : Int;
            expertiseBadges : [Text];
            location : ?Text;
            status : { #Active; #Suspended; #Retired };
            warnings : Nat;
            accuracy : Float;
            claimsVerified : Nat;
            completedTraining : [Text];
            createdAt : Int;
            lastActive : Int;
        };
        updateAletheianXp : (aletheian : Principal, xpChange : Int, accuracyImpact : ?Float) -> async Result.Result<(), Text>;
    };

    let escalation = actor ("EscalationCanister") : actor {
        escalateClaim : (claimId : Text, initialFindings : [(Principal, {
            verdict : Text;
            explanation : Text;
            evidence : [Text];
            timestamp : Int;
        })]) -> async Result.Result<(), Text>;
    };

    let aiIntegration = actor ("AI_IntegrationCanister") : actor {
        synthesizeReport : (claim : {
            id : Text;
            content : Text;
            claimType : Text;
            source : ?Text;
            context : ?Text;
        }, findings : [{
            aletheianId : Principal;
            classification : Text;
            explanation : Text;
            evidence : [Text];
        }]) -> async Result.Result<{
            verdict : Text;
            explanation : Text;
            evidence : [Text];
        }, Text>;
    };

    let notification = actor ("NotificationCanister") : actor {
        sendNotification : (userId : Principal, title : Text, message : Text, notifType : Text) -> async Nat;
    };

    // ======== INITIALIZATION ========
    system func preupgrade() {
        tasksEntries := Iter.toArray(tasks.entries());
    };

    system func postupgrade() {
        for ((id, task) in tasksEntries.vals()) {
            tasks.put(id, task);
        };
        tasksEntries := [];
    };

    // ======== CORE API ========
    public shared ({ caller }) func assignClaim(claimId: ClaimId, assigned: [Principal]) : async Result.Result<(), Text> {
        // Authorization check
        if (not isAuthorized(caller)) {
            return #err("Unauthorized");
        };

        // Validate assignment
        if (assigned.size() != 3) {
            return #err("Exactly 3 Aletheians must be assigned");
        };

        let uniquePrincipals = Array.filter<Principal>(assigned, func(p, i) { 
            Array.indexOf<Principal>(p, assigned, Principal.equal) == ?i 
        });
        if (uniquePrincipals.size() < 3) {
            return #err("Duplicate Aletheians in assignment");
        };

        let newEntry : Types.WorkflowEntry = {
            claimId = claimId;
            assigned = assigned;
            submissions = [];
            state = #Pending;
            createdAt = Time.now();
            lastUpdatedAt = Time.now();
            attempts = 0;
            dataVersion = INITIAL_DATA_VERSION;
            history = ["Claim assigned to: " # Principal.toText(assigned[0]) # ", " 
                      # Principal.toText(assigned[1]) # ", " # Principal.toText(assigned[2])];
        };

        workflows.put(claimId, newEntry);
        
        // Notify assigned Aletheians
        ignore await notification.notifyAletheians(
            assigned, 
            "New claim assigned: " # claimId
        );

        #ok()
    };

    public shared ({ caller }) func submitVerification(
        claimId: ClaimId,
        verdict: Types.Verdict,
        evidence: [Text],
        notes: Text
    ) : async Result.Result<(), Text> {
        // Authorization check
        if (not isAssignedAletheian(claimId, caller) and not isController(caller)) {
            return #err("Not assigned to this claim");
        };

        let submission : Types.Submission = {
            aletheian = caller;
            verdict = verdict;
            evidence = evidence;
            notes = notes;
            submittedAt = Time.now();
        };

        switch(workflows.get(claimId)) {
            case (?entry) {
                // Update submissions map
                let newSubmissions = Array.filter<(Principal, Types.Submission)>(
                    entry.submissions, 
                    func((p, _)) { p != caller }
                );
                let updatedSubmissions = Array.append(newSubmissions, [(caller, submission)]);
                
                let updatedEntry = { entry with
                    submissions = updatedSubmissions;
                    lastUpdatedAt = Time.now();
                };
                workflows.put(claimId, updatedEntry);

                // Log to history
                updateWorkflowHistory(claimId, "Submission by " # Principal.toText(caller) # ": " # debug_show(verdict));

                // Check for consensus
                await checkConsensus(claimId);
                #ok()
            };
            case null {
                #err("Claim not found")
            };
        }
    };

    // Submit a finding by an Aletheian
    public shared ({ caller }) func submitFinding(
        claimId : ClaimId,
        verdict : Text,
        explanation : Text,
        evidence : [Text],
        isDuplicate : Bool,
        originalClaimId : ?ClaimId
    ) : async Result.Result<(), Text> {
        switch (tasks.get(claimId)) {
            case null { return #err("Claim not found") };
            case (?task) {
                // Verify caller is assigned to this claim
                if (Option.isNull(Array.find<AletheianId>(task.assignedAletheians, func(a) { a == caller }))) {
                    return #err("Aletheian not assigned to this claim");
                };

                // Check for duplicate findings
                if (Option.isSome(Array.find<(AletheianId, Finding)>(task.findings, func((a, _)) { a == caller }))) {
                    return #err("Finding already submitted for this claim");
                };

                let newFinding : Finding = {
                    verdict;
                    explanation;
                    evidence;
                    timestamp = Time.now();
                };

                let updatedFindings = Array.append(task.findings, [(caller, newFinding)]);
                let newStatus = if (updatedFindings.size() == 3) {
                    // All findings submitted, check consensus
                    #inProgress
                } else {
                    task.status
                };

                let updatedTask = {
                    task with
                    findings = updatedFindings;
                    status = newStatus;
                    duplicateOf = if (isDuplicate) { originalClaimId } else { null };
                };

                tasks.put(claimId, updatedTask);

                // Check for consensus if all 3 submitted
                if (updatedFindings.size() == 3) {
                    await checkConsensus(claimId);
                };

                #ok(())
            }
        }
    };

    // ======== CONSENSUS LOGIC ========
    func checkConsensus(claimId: ClaimId) : async () {
        switch(workflows.get(claimId)) {
            case (?entry) {
                if (entry.submissions.size() < 3) return;

                // Group submissions by verdict
                let verdictCounts = HashMap.HashMap<Text, Nat>(3, Text.equal, Text.hash);
                let allEvidence = Buffer.Buffer<Text>(0);
                
                for ((_, submission) in entry.submissions.vals()) {
                    let verdictText = debug_show(submission.verdict);
                    verdictCounts.put(verdictText, Option.get(verdictCounts.get(verdictText), 0) + 1);
                    allEvidence.append(submission.evidence);
                };

                // Check for consensus (>=2 matching verdicts)
                var finalVerdict : ?Text = null;
                for ((verdict, count) in verdictCounts.entries()) {
                    if (count >= 2) {
                        finalVerdict := ?verdict;
                    };
                };

                switch(finalVerdict) {
                    case (?v) {
                        await finalizeConsensus(claimId, v, Buffer.toArray(allEvidence));
                    };
                    case null {
                        await escalateClaim(claimId);
                    };
                };
            };
            case null {};
        };
    };

    func finalizeConsensus(claimId: ClaimId, verdict: Text, evidence: [Text]) : async () {
        var attempts = 0;
        var success = false;
        
        while (attempts < MAX_RETRY_ATTEMPTS and not success) {
            try {
                // Record fact with retries
                let result = await factLedger.recordFact(
                    claimId,
                    verdict,
                    evidence,
                    entry.assigned,
                    "Consensus reached via verification workflow"
                );
                
                switch(result) {
                    case (#ok()) {
                        success := true;
                        // Update reputation
                        let xpUpdates = Array.map<Principal, (Principal, Int)>(
                            entry.assigned,
                            func(p) { (p, 10) } // Base XP award
                        );
                        ignore await reputationLogic.applyBatchXP(xpUpdates);
                        
                        // Update workflow state
                        let updatedEntry = { entry with
                            state = #ConsensusReached;
                            lastUpdatedAt = Time.now();
                        };
                        workflows.put(claimId, updatedEntry);
                        updateWorkflowHistory(claimId, "Consensus reached: " # verdict);
                    };
                    case (#err(msg)) {
                        attempts += 1;
                        if (attempts < MAX_RETRY_ATTEMPTS) {
                            await async { ignore await Timer.sleep(RETRY_DELAY) };
                        };
                    };
                };
            } catch (e) {
                attempts += 1;
                if (attempts < MAX_RETRY_ATTEMPTS) {
                    await async { ignore await Timer.sleep(RETRY_DELAY) };
                };
            };
        };

        if (not success) {
            let updatedEntry = { entry with
                state = #ErrorPersisting;
                lastUpdatedAt = Time.now();
            };
            workflows.put(claimId, updatedEntry);
            updateWorkflowHistory(claimId, "Failed to persist consensus after " # Nat.toText(attempts) # " attempts");
        };
    };

    func escalateClaim(claimId: ClaimId) : async () {
        switch(workflows.get(claimId)) {
            case (?entry) {
                // Prepare escalation data
                let submissionsData = Array.map<(Principal, Types.Submission), (Principal, Text, [Text], Text)>(
                    entry.submissions,
                    func((p, s)) { 
                        (p, debug_show(s.verdict), s.evidence, s.notes) 
                    }
                );

                // Call escalation canister
                let result = await escalation.startEscalation(
                    claimId,
                    submissionsData,
                    "Escalated due to lack of consensus"
                );

                // Update workflow state
                let updatedEntry = { entry with
                    state = #Escalated;
                    lastUpdatedAt = Time.now();
                };
                workflows.put(claimId, updatedEntry);
                updateWorkflowHistory(claimId, "Escalated to senior review");
            };
            case null {};
        };
    };

    // Detect duplicate claims using AI and blockchain
    func detectDuplicate(claimId : ClaimId, task : VerificationTask) : async Result.Result<(ClaimId, Text, Text, [Text]), Text> {
        // Get claim content
        let claimContent = switch (await factLedger.getClaim(claimId)) {
            case null { return #err("Claim content not found") };
            case (?claim) { claim.content };
        };

        // Find similar claims
        let similarClaims = await factLedger.findSimilarClaims(claimContent);
        if (similarClaims.size() > 0) {
            // Check if any Aletheian flagged as duplicate
            var duplicateFlagged = false;
            var originalId : ClaimId = "";
            
            for ((aletheian, finding) in task.findings.vals()) {
                if (finding.verdict == "Duplicate" and finding.evidence.size() > 0) {
                    duplicateFlagged := true;
                    originalId := finding.evidence[0];
                };
            };

            if (duplicateFlagged) {
                // Get existing verified fact
                switch (await factLedger.getVerifiedFact(originalId)) {
                    case null { #err("Original claim not verified") };
                    case (?originalFact) {
                        #ok((
                            originalId, 
                            originalFact.verdict, 
                            originalFact.explanation, 
                            originalFact.evidence
                        ))
                    };
                }
            } else {
                #err("Similar claims found but not flagged as duplicate")
            };
        } else {
            #err("No similar claims found")
        }
    };

    // Calculate consensus among findings
    func calculateConsensus(findings : [(AletheianId, Finding)]) : Result.Result<(Text, Text, [Text]), Text> {
        if (findings.size() != 3) {
            return #err("Incomplete findings");
        };

        let verdictCounts = HashMap.HashMap<Text, Nat>(3, Text.equal, Text.hash);
        let evidenceBuffer = Buffer.Buffer<Text>(0);
        let explanations = Buffer.Buffer<Text>(0);

        // Count verdicts and collect evidence
        for ((_, finding) in findings.vals()) {
            let count = Option.get(verdictCounts.get(finding.verdict), 0);
            verdictCounts.put(finding.verdict, count + 1);
            
            // Collect evidence
            for (ev in finding.evidence.vals()) {
                evidenceBuffer.add(ev);
            };
            
            // Collect explanations
            explanations.add(finding.explanation);
        };

        // Check for consensus (at least 2/3 agreement)
        var consensusVerdict : ?Text = null;
        for ((verdict, count) in verdictCounts.entries()) {
            if (count >= 2) {
                consensusVerdict := ?verdict;
            };
        };

        switch (consensusVerdict) {
            case null {
                #err("No consensus reached among Aletheians")
            };
            case (?verdict) {
                // Combine explanations
                let explanationArr = Buffer.toArray<Text>(explanations);
                let combinedExplanation = joinText("\n\n", explanationArr);
                #ok((
                    verdict, 
                    combinedExplanation, 
                    Buffer.toArray(evidenceBuffer)
                ))
            };
        };
    };

    // Finalize task with consensus result
    func finalizeTask(
        claimId : ClaimId,
        verdict : Text,
        explanation : Text,
        evidence : [Text],
        isDuplicate : Bool
    ) : async Bool {
        switch (tasks.get(claimId)) {
            case null { false };
            case (?task) {
                // Only store new facts for non-duplicates
                if (not isDuplicate) {
                    let factRequest = {
                        content = claimId; // In production, get actual claim content
                        evidence = Array.map<Text, { hash : Text; storageType : Text; url : ?Text; timestamp : Int; provider : Principal }>(
                            evidence, 
                            func(ev) {
                                {
                                    hash = ev;
                                    storageType = "HTTPS";
                                    url = ?ev;
                                    timestamp = Time.now();
                                    provider = Principal.fromText("aaaaa-aa");
                                }
                            }
                        );
                        publicProof = { proofType = "ALETHEIA_CONSENSUS"; content = verdict };
                    };
                    let storeResult = await factLedger.addFact(factRequest);
                    switch (storeResult) {
                        case (#err(_)) { return false };
                        case (#ok(_)) {};
                    };
                };
                
                // Update Aletheian reputations
                for (aletheian in task.assignedAletheians.vals()) {
                    ignore await aletheianProfile.updateAletheianXp(aletheian, 10, null); // Base XP
                };

                // Notify user of completion
                switch (tasks.get(claimId)) {
                    case (?t) {
                        // Get submitter from claim data - simplified for now
                        ignore await notification.sendNotification(
                            Principal.fromText("aaaaa-aa"), // Replace with actual submitter
                            "Claim Verified",
                            "Your claim has been verified: " # verdict,
                            "claim_verified"
                        );
                    };
                    case null {};
                };
                
                // Update task status
                let updatedTask = { 
                    task with 
                    status = #consensusReached(verdict);
                    duplicateOf = if (isDuplicate) { task.duplicateOf } else { null };
                };
                tasks.put(claimId, updatedTask);
                true
            }
        }
    };

    // ======== ADMIN API ========
    public shared ({ caller }) func markTimedOut(claimId: ClaimId, timedOutPrincipal: Principal) : async Result.Result<(), Text> {
        if (not isAuthorized(caller)) {
            return #err("Unauthorized");
        };

        switch(workflows.get(claimId)) {
            case (?entry) {
                // Get replacement
                let replacementResult = await aletheianDispatch.reassignAletheian(claimId, timedOutPrincipal);
                switch(replacementResult) {
                    case (#ok(newAletheian)) {
                        let newAssigned = Array.map<Principal, Principal>(
                            entry.assigned,
                            func(p) { if (p == timedOutPrincipal) newAletheian else p }
                        );
                        
                        let updatedEntry = { entry with
                            assigned = newAssigned;
                            lastUpdatedAt = Time.now();
                            attempts = entry.attempts + 1;
                        };
                        workflows.put(claimId, updatedEntry);
                        
                        updateWorkflowHistory(claimId, "Timed out: " # Principal.toText(timedOutPrincipal) 
                            # " replaced by " # Principal.toText(newAletheian));
                        
                        // Notify new Aletheian
                        ignore await notification.notifyAletheians(
                            [newAletheian],
                            "Reassigned to claim: " # claimId
                        );
                        #ok()
                    };
                    case (#err(msg)) {
                        #err("Reassignment failed: " # msg)
                    };
                };
            };
            case null {
                #err("Claim not found")
            };
        }
    };

    public shared ({ caller }) func forceFinalizeAsController(claimId: ClaimId, verdict: Text) : async Result.Result<(), Text> {
        if (not isController(caller)) {
            return #err("Controller only");
        };

        switch(workflows.get(claimId)) {
            case (?entry) {
                let updatedEntry = { entry with
                    state = #ConsensusReached;
                    lastUpdatedAt = Time.now();
                };
                workflows.put(claimId, updatedEntry);
                updateWorkflowHistory(claimId, "Force finalized by controller with verdict: " # verdict);
                #ok()
            };
            case null {
                #err("Claim not found")
            };
        }
    };

    public shared ({ caller }) func reopenClaim(claimId: ClaimId) : async Result.Result<(), Text> {
        if (not isController(caller)) {
            return #err("Controller only");
        };

        switch(workflows.get(claimId)) {
            case (?entry) {
                let updatedEntry = { entry with
                    state = #Reopened;
                    lastUpdatedAt = Time.now();
                    attempts = 0;
                };
                workflows.put(claimId, updatedEntry);
                updateWorkflowHistory(claimId, "Reopened by controller");
                #ok()
            };
            case null {
                #err("Claim not found")
            };
        }
    };

    // ======== QUERY INTERFACE ========
    public query func getWorkflowSummary(claimId: ClaimId) : async ?Types.WorkflowSummary {
        switch(workflows.get(claimId)) {
            case (?entry) {
                ?{
                    claimId = entry.claimId;
                    state = entry.state;
                    lastUpdatedAt = entry.lastUpdatedAt;
                    submissionsCount = entry.submissions.size();
                }
            };
            case null { null }
        }
    };

    public query func getWorkflowForAdmin(claimId: ClaimId) : async ?Types.WorkflowEntry {
        switch(workflows.get(claimId)) {
            case (?entry) { ?entry };
            case null { null }
        }
    };

    public query func getAuthorizedCanisters() : async [Principal] {
        Iter.toArray(authorizedCanisters.keys())
    };
};

// Helper: Join array of Text with separator (Motoko 0.9.8 compatible)
func joinText(sep : Text, arr : [Text]) : Text {
    var result = "";
    var first = true;
    for (t in arr.vals()) {
        if (first) {
            result #= t;
            first := false;
        } else {
            result #= sep # t;
        }
    };
    result
}
