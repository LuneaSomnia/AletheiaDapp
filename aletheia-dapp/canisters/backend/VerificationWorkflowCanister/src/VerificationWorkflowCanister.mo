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
import Types "../../common/Types";

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
    
    // ======== STABLE STORAGE ========
    stable var tasksEntries : [(ClaimId, VerificationTask)] = [];
    stable var nextTaskId : Nat = 1;

    // ======== STATE ========
    let tasks = TrieMap.TrieMap<ClaimId, VerificationTask>(Text.equal, Text.hash);
    
    // ======== CANISTER REFERENCES ========
    let factLedger : actor {
        findSimilarClaims : (content : Text) -> async [ClaimId];
        getClaim : (ClaimId) -> async ?{ content : Text };
        getVerifiedFact : (ClaimId) -> async ?{ verdict : Text; explanation : Text; evidence : [Text] };
        storeResult : (claimId : ClaimId, verdict : Text, explanation : Text, evidence : [Text]) -> async Bool;
    } = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai"); // Replace with actual FactLedger canister ID

    // --- BREAK CIRCULAR DEPENDENCY: Use interface type for AletheianProfileCanister ---
    type AletheianProfileInterface = actor {
        getAletheianRank : (AletheianId) -> async Text;
        getAletheianExpertise : (AletheianId) -> async [Text];
        updateReputation : (AletheianId, Int) -> async Bool;
    };
    let aletheianProfile = actor ("rrkah-fqaaa-aaaaa-aaaaq-cai") : AletheianProfileInterface; // Replace with actual canister ID

    let escalation : actor {
        escalateClaim : (claimId : ClaimId, reason : Text) -> async Bool;
    } = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai"); // Replace with actual Escalation canister ID

    let aiIntegration : actor {
        generateQuestions : (claim : Text) -> async [Text];
        researchClaim : (claim : Text) -> async [Text];
    } = actor ("r7inp-6aaaa-aaaaa-aaabq-cai"); // Replace with actual AI canister ID

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

    // ======== API ========
    // Create a new verification task
    public shared ({ caller }) func createTask(claimId : ClaimId, aletheians : [AletheianId]) : async Result.Result<(), Text> {
        if (aletheians.size() != 3) {
            return #err("Exactly 3 Aletheians must be assigned");
        };

        let newTask : VerificationTask = {
            claimId = claimId;
            assignedAletheians = aletheians;
            findings = [];
            status = #assigned;
            duplicateOf = null;
            createdAt = Time.now();
        };

        tasks.put(claimId, newTask);
        #ok(())
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

    // ======== CORE LOGIC ========
    // Check for consensus among Aletheians
    func checkConsensus(claimId : ClaimId) : async () {
        switch (tasks.get(claimId)) {
            case null { /* Task not found, ignore */ };
            case (?task) {
                // Check for duplicate claims first
                switch (await detectDuplicate(claimId, task)) {
                    case (#ok(originalId, verdict, explanation, evidence)) {
                        // Duplicate detected and handled
                        let _ = await finalizeTask(claimId, verdict, explanation, evidence, true);
                    };
                    case (#err _) {
                        // Not a duplicate, proceed with consensus
                        switch (calculateConsensus(task.findings)) {
                            case (#ok(verdict, explanation, evidence)) {
                                let _ = await finalizeTask(claimId, verdict, explanation, evidence, false);
                            };
                            case (#err(reason)) {
                                // Consensus not reached, escalate
                                let escalated = await escalation.escalateClaim(claimId, reason);
                                if (escalated) {
                                    let updatedTask = { task with status = #disputed };
                                    tasks.put(claimId, updatedTask);
                                };
                            };
                        };
                    };
                };
            };
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
                    let stored = await factLedger.storeResult(claimId, verdict, explanation, evidence);
                    if (not stored) {
                        return false;
                    };
                };
                
                // Update Aletheian reputations
                for (aletheian in task.assignedAletheians.vals()) {
                    ignore await aletheianProfile.updateReputation(aletheian, 10); // Base XP
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

    // ======== QUERY INTERFACE ========
    public query func getTask(claimId : ClaimId) : async ?VerificationTask {
        tasks.get(claimId)
    };

    public query func getActiveTasks() : async [VerificationTask] {
        Iter.toArray(tasks.vals())
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