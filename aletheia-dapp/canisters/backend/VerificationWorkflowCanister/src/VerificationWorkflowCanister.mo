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
        storeResult : (claimId : ClaimId, verdict : Text, explanation : Text, evidence : [Text]) -> async Bool;
    } = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai"); // Replace with actual FactLedger canister ID

    let aletheianProfile : actor {
        getAletheianExpertise : (AletheianId) -> async [Text];
        updateReputation : (AletheianId, Int) -> async Bool;
    } = actor ("rrkah-fqaaa-aaaaa-aaaaq-cai"); // Replace with actual AletheianProfile canister ID

    let escalation : actor {
        escalateClaim : (claimId : ClaimId, reason : Text) -> async Bool;
    } = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai"); // Replace with actual Escalation canister ID

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
                    case (#ok verdict) {
                        // Duplicate detected and handled
                        let _ = await finalizeTask(claimId, verdict, "Duplicate claim detected", []);
                    };
                    case (#err _) {
                        // Not a duplicate, proceed with consensus
                        switch (calculateConsensus(task.findings)) {
                            case (#ok(verdict, explanation, evidence)) {
                                let _ = await finalizeTask(claimId, verdict, explanation, evidence);
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
    func detectDuplicate(claimId : ClaimId, task : VerificationTask) : async Result.Result<Text, Text> {
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
            var duplicateVerdict : Text = "";
            
            for ((aletheian, finding) in task.findings.vals()) {
                if (finding.verdict == "Duplicate" and Option.isSome(finding.evidence.get(0))) {
                    duplicateFlagged := true;
                    duplicateVerdict := "Duplicate";
                };
            };

            if (duplicateFlagged) {
                #ok(duplicateVerdict)
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
        var evidenceBuffer = Buffer.Buffer<Text>(0);
        var explanations = Buffer.Buffer<Text>(0);

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
                let combinedExplanation = Text.join("\n\n", Buffer.toArray(explanations));
                #ok(verdict, combinedExplanation, Buffer.toArray(evidenceBuffer))
            };
        };
    };

    // Finalize task with consensus result
    func finalizeTask(
        claimId : ClaimId,
        verdict : Text,
        explanation : Text,
        evidence : [Text]
    ) : async Bool {
        switch (tasks.get(claimId)) {
            case null { false };
            case (?task) {
                // Store result in blockchain
                let stored = await factLedger.storeResult(claimId, verdict, explanation, evidence);
                if (stored) {
                    // Update Aletheian reputations
                    for (aletheian in task.assignedAletheians.vals()) {
                        ignore await aletheianProfile.updateReputation(aletheian, 10); // Base XP
                    };
                    
                    // Update task status
                    let updatedTask = { 
                        task with 
                        status = #consensusReached(verdict) 
                    };
                    tasks.put(claimId, updatedTask);
                    true
                } else {
                    false
                }
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