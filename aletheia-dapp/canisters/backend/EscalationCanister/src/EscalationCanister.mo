import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

actor EscalationCanister {
    type ClaimId = Text;
    type Verdict = Text;
    type Finding = {
        verdict : Verdict;
        explanation : Text;
        evidence : [Text];
    };
    
    type EscalatedClaim = {
        claimId : ClaimId;
        initialFindings : [(Principal, Finding)]; // Original Aletheian findings
        seniorFindings : [(Principal, Finding)]; // Senior Aletheian findings
        councilFindings : [(Principal, Finding)]; // Council of Elders findings
        status : {
            #seniorReview;
            #councilReview;
            #resolved : Verdict;
        };
        timestamp : Int;
    };

    // Stable storage
    stable var escalatedClaims : [(ClaimId, EscalatedClaim)] = [];
    let claims = HashMap.HashMap<ClaimId, EscalatedClaim>(10, Text.equal, Text.hash);

    // Canister references
    let aletheianProfile : actor {
        getSeniorAletheians : () -> async [Principal];
        getCouncilOfElders : () -> async [Principal];
        getAletheianRank : (Principal) -> async Text;
    } = actor ("apaaa-aaaaa-aaaab-qai2q-cai"); // Replace with actual ID

    let factLedger : actor {
        storeResult : (claimId : ClaimId, verdict : Verdict) -> async Bool;
        updateFact : (claimId : ClaimId, newVerdict : Verdict) -> async Bool;
    } = actor ("fctaa-aaaaa-aaaab-qai7q-cai"); // Replace with actual ID

    let reputation : actor {
        updateReputation : (aletheianId : Principal, xpChange : Int) -> async Bool;
        issueWarning : (aletheianId : Principal) -> async Bool;
    } = actor ("repaa-aaaaa-aaaab-qai8q-cai"); // Replace with actual ID

    let notification : actor {
        notifyAletheian : (aletheianId : Principal, message : Text) -> async Bool;
    } = actor ("ntfaa-aaaaa-aaaab-qai6q-cai"); // Replace with actual ID

    system func preupgrade() {
        escalatedClaims := Iter.toArray(claims.entries());
    };

    system func postupgrade() {
        var claims = HashMap.fromIter<ClaimId, EscalatedClaim>(
            escalatedClaims.vals(), 
            10, 
            Text.equal, 
            Text.hash
        );
        escalatedClaims := [];
    };

    // ================== PUBLIC INTERFACE ================== //

    // Called by VerificationWorkflow when consensus fails
    public shared func escalateClaim(
        claimId : ClaimId, 
        initialFindings : [(Principal, Finding)]
    ) : async Result.Result<(), Text> {
        try {
            // Check if already escalated
            if (Option.isSome(claims.get(claimId))) {
                return #err("Claim already escalated");
            };

            // Create new escalated claim
            let newClaim : EscalatedClaim = {
                claimId;
                initialFindings;
                seniorFindings = [];
                councilFindings = [];
                status = #seniorReview;
                timestamp = Time.now();
            };

            claims.put(claimId, newClaim);

            // Assign to senior Aletheians
            await assignToSeniorReviewers(claimId);

            #ok();
        } catch (e) {
            #err("Escalation failed: " # Error.message(e));
        }
    };

    // Senior Aletheians submit their findings
    public shared ({ caller }) func submitSeniorFinding(
        claimId : ClaimId, 
        finding : Finding
    ) : async Result.Result<(), Text> {
        try {
            switch (claims.get(claimId)) {
                case null { #err("Claim not found") };
                case (?claim) {
                    // Validate senior status
                    let rank = await aletheianProfile.getAletheianRank(caller);
                    if (not Text.contains(rank, #text "Senior") and not Text.contains(rank, #text "Expert")) {
                        return #err("Only senior Aletheians can submit findings");
                    };

                    // Add/update finding
                    let newFindings = Array.filter<(Principal, Finding)>(
                        claim.seniorFindings, 
                        func ((id, _)) = id != caller
                    );
                    let updatedFindings = Array.append(newFindings, [(caller, finding)]);
                    
                    // Update claim
                    let updatedClaim = {
                        claim with 
                        seniorFindings = updatedFindings;
                    };
                    claims.put(claimId, updatedClaim);

                    // Check if all findings submitted
                    if (updatedFindings.size() == 3) {
                        await processSeniorConsensus(claimId, updatedClaim);
                    };

                    #ok();
                };
            };
        } catch (e) {
            #err("Failed to submit finding: " # Error.message(e));
        }
    };

    // Council members submit their findings
    public shared ({ caller }) func submitCouncilFinding(
        claimId : ClaimId, 
        finding : Finding
    ) : async Result.Result<(), Text> {
        try {
            switch (claims.get(claimId)) {
                case null { #err("Claim not found") };
                case (?claim) {
                    // Validate council status
                    let council = await aletheianProfile.getCouncilOfElders();
                    if (Option.isNull(Array.find<Principal>(council, func id = id == caller))) {
                        return #err("Only Council members can submit findings");
                    };

                    // Add/update finding
                    let newFindings = Array.filter<(Principal, Finding)>(
                        claim.councilFindings, 
                        func ((id, _)) = id != caller
                    );
                    let updatedFindings = Array.append(newFindings, [(caller, finding)]);
                    
                    // Update claim
                    let updatedClaim = {
                        claim with 
                        councilFindings = updatedFindings;
                    };
                    claims.put(claimId, updatedClaim);

                    // Check if all findings submitted
                    if (updatedFindings.size() == council.size()) {
                        await processCouncilDecision(claimId, updatedClaim);
                    };

                    #ok();
                };
            };
        } catch (e) {
            #err("Failed to submit finding: " # Error.message(e));
        }
    };

    // ================== PRIVATE WORKFLOWS ================== //

    // Assign claim to senior reviewers
    func assignToSeniorReviewers(claimId : ClaimId) : async () {
        let seniors = await aletheianProfile.getSeniorAletheians();
        if (seniors.size() < 3) {
            // Fallback to council if not enough seniors
            await assignToCouncil(claimId);
            return;
        };

        // Select 3 random seniors (in production, use expertise matching)
        let selected = Array.tabulate<Principal>(3, func i {
            seniors[Int.abs(Time.now()) % seniors.size()] 
        });

        // Notify selected seniors
        for (senior in selected.vals()) {
            ignore await notification.notifyAletheian(
                senior, 
                "New escalated claim assigned: " # claimId
            );
        };
    };

    // Process consensus after all senior findings submitted
    func processSeniorConsensus(claimId : ClaimId, claim : EscalatedClaim) : async () {
        let verdict = findConsensusVerdict(claim.seniorFindings);
        
        switch (verdict) {
            case (?v) {
                // Consensus reached
                await finalizeClaim(claimId, v);
                await updateSeniorReputations(claimId, claim.seniorFindings, v);
                await updateInitialReputations(claimId, claim.initialFindings, v);
            };
            case null {
                // No consensus - escalate to council
                await assignToCouncil(claimId);
            };
        };
    };

    // Assign claim to Council of Elders
    func assignToCouncil(claimId : ClaimId) : async () {
        switch (claims.get(claimId)) {
            case null {};
            case (?claim) {
                // Update status
                let updatedClaim = {
                    claim with 
                    status = #councilReview;
                };
                claims.put(claimId, updatedClaim);

                // Notify council members
                let council = await aletheianProfile.getCouncilOfElders();
                for (member in council.vals()) {
                    ignore await notification.notifyAletheian(
                        member, 
                        "Council review required for claim: " # claimId
                    );
                };
            };
        };
    };

    // Process final council decision
    func processCouncilDecision(claimId : ClaimId, claim : EscalatedClaim) : async () {
        let verdict = findMajorityVerdict(claim.councilFindings);
        
        switch (verdict) {
            case (?v) {
                await finalizeClaim(claimId, v);
                await updateCouncilReputations(claimId, claim.councilFindings, v);
                await updateSeniorReputations(claimId, claim.seniorFindings, v);
                await updateInitialReputations(claimId, claim.initialFindings, v);
            };
            case null {
                // Even council can't decide - use plurality or first found
                let verdicts = extractVerdicts(claim.councilFindings);
                let v = if (verdicts.size() > 0) verdicts[0] else "Unresolved";
                await finalizeClaim(claimId, v);
            };
        };
    };

    // Finalize claim with verdict
    func finalizeClaim(claimId : ClaimId, verdict : Verdict) : async () {
        // Store in fact ledger
        ignore await factLedger.storeResult(claimId, verdict);
        
        // Update claim status
        switch (claims.get(claimId)) {
            case (?claim) {
                claims.put(claimId, {
                    claim with 
                    status = #resolved(verdict);
                });
            };
            case null {};
        };
    };

    // ================== REPUTATION MANAGEMENT ================== //

    // Update initial Aletheians' reputations based on correctness
    func updateInitialReputations(
        claimId : ClaimId,
        findings : [(Principal, Finding)],
        finalVerdict : Verdict
    ) : async () {
        for ((id, finding) in findings.vals()) {
            let correct = finding.verdict == finalVerdict;
            let xpChange = if correct then 5 else -20;
            
            // Update XP
            ignore await reputation.updateReputation(id, xpChange);
            
            // Issue warning if incorrect
            if (not correct) {
                ignore await reputation.issueWarning(id);
                ignore await notification.notifyAletheian(
                    id, 
                    "Your finding for claim " # claimId # " was incorrect. Correct verdict: " # finalVerdict
                );
            };
        };
    };

    // Update senior reviewers' reputations
    func updateSeniorReputations(
        claimId : ClaimId,
        findings : [(Principal, Finding)],
        finalVerdict : Verdict
    ) : async () {
        for ((id, finding) in findings.vals()) {
            let correct = finding.verdict == finalVerdict;
            let xpChange = if correct then 15 else 0; // Only reward correct assessments
            
            ignore await reputation.updateReputation(id, xpChange);
        };
    };

    // Update council members' reputations
    func updateCouncilReputations(
        claimId : ClaimId,
        findings : [(Principal, Finding)],
        finalVerdict : Verdict
    ) : async () {
        for ((id, finding) in findings.vals()) {
            let correct = finding.verdict == finalVerdict;
            let xpChange = if correct then 25 else 10; // Base reward + bonus for correctness
            
            ignore await reputation.updateReputation(id, xpChange);
        };
    };

    // ================== UTILITIES ================== //

    // Find consensus verdict (at least 2/3 agreement)
    func findConsensusVerdict(findings : [(Principal, Finding)]) : ?Verdict {
        let verdicts = Buffer.Buffer<Verdict>(3);
        for ((_, finding) in findings.vals()) {
            verdicts.add(finding.verdict);
        };
        
        // Count occurrences
        let counts = HashMap.HashMap<Verdict, Nat>(3, Text.equal, Text.hash);
        for (v in verdicts.vals()) {
            counts.put(v, Option.get(counts.get(v), 0) + 1);
        };
        
        // Find verdict with majority
        for ((verdict, count) in counts.entries()) {
            if (count >= 2) {
                return ?verdict;
            };
        };
        
        null
    };

    // Find majority verdict (for council)
    func findMajorityVerdict(findings : [(Principal, Finding)]) : ?Verdict {
        let counts = HashMap.HashMap<Verdict, Nat>(5, Text.equal, Text.hash);
        for ((_, finding) in findings.vals()) {
            counts.put(finding.verdict, Option.get(counts.get(finding.verdict), 0) + 1);
        };
        
        var maxVerdict : ?Verdict = null;
        var maxCount : Nat = 0;
        
        for ((verdict, count) in counts.entries()) {
            if (count > maxCount) {
                maxVerdict := ?verdict;
                maxCount := count;
            };
        };
        
        maxVerdict
    };

    // Extract all verdicts
    func extractVerdicts(findings : [(Principal, Finding)]) : [Verdict] {
        let buffer = Buffer.Buffer<Verdict>(findings.size());
        for ((_, finding) in findings.vals()) {
            buffer.add(finding.verdict);
        };
        buffer.toArray()
    };

    // ================== QUERY INTERFACE ================== //

    public query func getEscalatedClaim(claimId : ClaimId) : async ?EscalatedClaim {
        claims.get(claimId)
    };

    public query func getAllEscalatedClaims() : async [(ClaimId, EscalatedClaim)] {
        Iter.toArray(claims.entries())
    };
};