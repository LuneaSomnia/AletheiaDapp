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
    // ------ Core Types ------
    public type Verdict = {
        #True; #MostlyTrue; #HalfTruth; #Misleading; #False;
        #Unsubstantiated; #Opinion; #Propaganda;
    };
    
    public type ReviewerOutcome = {
        reviewer : Principal;
        vote : Verdict;
        reasoning : Text;
        evidence : [Text];
        submittedAt : Int;
        anonymized : Bool;
    };
    
    public type EscalationStatus = {
        #Open; 
        #InSeniorReview; 
        #InCouncil; 
        #Finalized; 
        #PublishedUnresolved; 
        #Cancelled;
    };
    
    public type EscalationRecord = {
        escalationId : Text;
        claimId : Text;
        initiatedBy : Principal;
        initiatedAt : Int;
        reason : Text;
        status : EscalationStatus;
        seniorReviewers : [Principal];
        councilReviewers : [Principal];
        seniorReviews : [ReviewerOutcome];
        councilReviews : [ReviewerOutcome];
        finalVerdict : ?Verdict;
        finalExplanation : ?Text;
        finalizedAt : ?Int;
        dataVersion : Nat;
    };
    
    // ------ Configuration ------
    let REQUIRED_SENIORS : Nat = 3;
    let REQUIRED_COUNCIL : Nat = 3;
    let SENIOR_BADGE : Text = "Senior";
    
    // ------ Stable Storage ------
    stable var escalations : [(Text, EscalationRecord)] = [];
    stable var authorizedCallers : [Principal] = [];
    stable var councilMembers : [Principal] = [];
    stable var controller : Principal = Principal.fromText("aaaaa-aa");
    stable var dataVersion : Nat = 1;
    
    // ------ Mutable State ------
    let escalationMap = HashMap.HashMap<Text, EscalationRecord>(10, Text.equal, Text.hash);
    let authorizedCallerSet = HashSet.fromIter<Principal>(authorizedCallers.vals(), 10, Principal.equal, Principal.hash);
    let councilMemberSet = HashSet.fromIter<Principal>(councilMembers.vals(), 10, Principal.equal, Principal.hash);

    // Canister references
    let aletheianProfile = actor ("AletheianProfileCanister") : actor {
        getAletheiansByRank : (minRank : { #Trainee; #Junior; #Associate; #Senior; #Expert; #Master }) -> async [{
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
        }];
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
        issueWarning : (aletheian : Principal, severity : { #Minor; #Major }) -> async Result.Result<(), Text>;
    };

    let factLedger = actor ("FactLedgerCanister") : actor {
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

    let notification = actor ("NotificationCanister") : actor {
        sendNotification : (userId : Principal, title : Text, message : Text, notifType : Text) -> async Nat;
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

    system func preupgrade() {
        escalations := Iter.toArray(escalationMap.entries());
        authorizedCallers := HashSet.toArray(authorizedCallerSet);
        councilMembers := HashSet.toArray(councilMemberSet);
    };

    system func postupgrade() {
        escalationMap := HashMap.fromIter<Text, EscalationRecord>(
            escalations.vals(), 
            10, 
            Text.equal, 
            Text.hash
        );
        authorizedCallerSet := HashSet.fromIter<Principal>(authorizedCallers.vals(), 10, Principal.equal, Principal.hash);
        councilMemberSet := HashSet.fromIter<Principal>(councilMembers.vals(), 10, Principal.equal, Principal.hash);
        escalations := [];
        authorizedCallers := [];
        councilMembers := [];
    };

    // ================== PUBLIC API ================== //
    
    public shared({ caller }) func initiateEscalation(
        claimId : Text,
        reason : Text
    ) : async Result.Result<Text, Text> {
        // Authorization check
        if (not _isAuthorized(caller)) {
            return #err("Unauthorized caller");
        };
        
        let escalationId = _generateEscalationId();
        let now = Time.now();
        
        let newRecord : EscalationRecord = {
            escalationId;
            claimId;
            initiatedBy = caller;
            initiatedAt = now;
            reason;
            status = #Open;
            seniorReviewers = [];
            councilReviewers = [];
            seniorReviews = [];
            councilReviews = [];
            finalVerdict = null;
            finalExplanation = null;
            finalizedAt = null;
            dataVersion;
        };
        
        escalationMap.put(escalationId, newRecord);
        _assignSeniorReviewers(escalationId);
        
        #ok(escalationId)
    };
    
    public shared({ caller }) func submitSeniorReview(
        escalationId : Text,
        vote : Verdict,
        reasoning : Text,
        evidence : [Text]
    ) : async Result.Result<(), Text> {
        switch (escalationMap.get(escalationId)) {
            case null { #err("Escalation not found") };
            case (?record) {
                // Permission check
                if (not Array.find<Principal>(record.seniorReviewers, func(p) = p == caller) != null) {
                    return #err("Not assigned as senior reviewer");
                };
                
                // Check for existing submission
                if (Array.find<ReviewerOutcome>(record.seniorReviews, func(ro) = ro.reviewer == caller) != null) {
                    return #err("Already submitted review");
                };
                
                let newReview : ReviewerOutcome = {
                    reviewer = caller;
                    vote;
                    reasoning;
                    evidence;
                    submittedAt = Time.now();
                    anonymized = false;
                };
                
                let updatedRecord = {
                    record with
                    seniorReviews = Array.append(record.seniorReviews, [newReview]);
                };
                
                escalationMap.put(escalationId, updatedRecord);
                await _computeSeniorOutcome(escalationId);
                #ok()
            };
        };
    };
    
    // ================== PRIVATE LOGIC ================== //
    
    func _assignSeniorReviewers(escalationId : Text) : async () {
        switch (escalationMap.get(escalationId)) {
            case (?record) {
                let seniors = await aletheianProfile.getTopSeniorsByBadge(REQUIRED_SENIORS, SENIOR_BADGE);
                let updatedRecord = {
                    record with
                    seniorReviewers = seniors;
                    status = #InSeniorReview;
                };
                escalationMap.put(escalationId, updatedRecord);
                
                // Notify seniors
                for (senior in seniors.vals()) {
                    ignore await notification.sendNotification(
                        senior,
                        "Escalation Assignment",
                        "New escalation requires your review: " # escalationId,
                        "escalation_assignment"
                    );
                };
            };
            case null {};
        };
    };
    
    func _computeSeniorOutcome(escalationId : Text) : async () {
        switch (escalationMap.get(escalationId)) {
            case (?record) {
                if (record.seniorReviews.size() < REQUIRED_SENIORS) return;
                
                let (consensusVerdict, voteCounts) = _calculateConsensus(record.seniorReviews);
                
                switch (consensusVerdict) {
                    case (?v) {
                        await _finalizeEscalation(escalationId, v, "Senior consensus reached");
                    };
                    case null {
                        // No consensus - escalate to council
                        let updatedRecord = {
                            record with
                            status = #InCouncil;
                        };
                        escalationMap.put(escalationId, updatedRecord);
                        await _assignCouncilReviewers(escalationId);
                    };
                };
            };
            case null {};
        };
    };
    
    func _assignCouncilReviewers(escalationId : Text) : async () {
        switch (escalationMap.get(escalationId)) {
            case (?record) {
                // Use configured council or fallback to top elders
                let council = if (councilMemberSet.size() >= REQUIRED_COUNCIL) {
                    Array.take(HashSet.toArray(councilMemberSet), REQUIRED_COUNCIL);
                } else {
                    await aletheianProfile.getTopElders(REQUIRED_COUNCIL);
                };
                
                let updatedRecord = {
                    record with
                    councilReviewers = council;
                };
                escalationMap.put(escalationId, updatedRecord);
                
                // Notify council members
                for (member in council.vals()) {
                    ignore await notification.sendNotification(
                        member,
                        "Council Escalation",
                        "Escalation requires council review: " # escalationId,
                        "council_assignment"
                    );
                };
            };
            case null {};
        };
    };
    
    func _finalizeEscalation(
        escalationId : Text,
        verdict : Verdict,
        explanation : Text
    ) : async () {
        switch (escalationMap.get(escalationId)) {
            case (?record) {
                let now = Time.now();
                let updatedRecord = {
                    record with
                    status = #Finalized;
                    finalVerdict = ?verdict;
                    finalExplanation = ?explanation;
                    finalizedAt = ?now;
                };
                escalationMap.put(escalationId, updatedRecord);
                
                // Persist to FactLedger
                ignore await factLedger.appendEscalationResult(
                    record.claimId,
                    "Escalation resolved with verdict: " # debug_show(verdict)
                );
                
                // Update reputations
                ignore await reputationLogic.applyEscalationOutcome(
                    escalationId,
                    verdict,
                    Array.append(record.seniorReviews, record.councilReviews)
                );
                
                // Notify participants
                let allParticipants = Array.append(record.seniorReviewers, record.councilReviewers);
                for (participant in allParticipants.vals()) {
                    ignore await notification.sendNotification(
                        participant,
                        "Escalation Resolved",
                        "Escalation " # escalationId # " resolved with verdict: " # debug_show(verdict),
                        "escalation_resolved"
                    );
                };
            };
            case null {};
        };
    };
    
    // ================== UTILITIES ================== //
    
    func _isAuthorized(caller : Principal) : Bool {
        caller == controller or HashSet.mem(authorizedCallerSet, caller)
    };
    
    func _generateEscalationId() : Text {
        let randomBytes = Random.blob(16);
        Hex.encode(Blob.toArray(randomBytes));
    };
    
    func _calculateConsensus(reviews : [ReviewerOutcome]) : (?Verdict, [(Verdict, Nat)]) {
        let voteCounts = HashMap.HashMap<Verdict, Nat>(7, Verdict.equal, Verdict.hash);
        
        for (review in reviews.vals()) {
            let count = Option.get(voteCounts.get(review.vote), 0);
            voteCounts.put(review.vote, count + 1);
        };
        
        var maxVerdict : ?Verdict = null;
        var maxCount : Nat = 0;
        for ((verdict, count) in voteCounts.entries()) {
            if (count > maxCount) {
                maxVerdict := ?verdict;
                maxCount := count;
            };
        };
        
        let threshold = (reviews.size() / 2) + 1;
        if (maxCount >= threshold) {
            (maxVerdict, Iter.toArray(voteCounts.entries()))
        } else {
            (null, Iter.toArray(voteCounts.entries()))
        };
    };
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
        let seniors = await aletheianProfile.getAletheiansByRank(#Senior);
        if (seniors.size() < 3) {
            // Fallback to council if not enough seniors
            await assignToCouncil(claimId);
            return;
        };

        // Select 3 active seniors
        let activeSeniors = Array.filter(seniors, func(s) { s.status == #Active });
        let selected = Array.tabulate<Principal>(Int.min(3, activeSeniors.size()), func i {
            activeSeniors[i].id
        });

        // Notify selected seniors
        for (senior in selected.vals()) {
            ignore await notification.sendNotification(
                senior,
                "Escalation Review",
                "New escalated claim assigned: " # claimId,
                "escalation_assignment"
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
                let council = await aletheianProfile.getAletheiansByRank(#Master);
                for (member in council.vals()) {
                    ignore await notification.sendNotification(
                        member.id,
                        "Council Review",
                        "Council review required for claim: " # claimId,
                        "council_review"
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
                // Even council can't reach majority - mark as inconclusive
                let inconclusive = "Inconclusive";
                await finalizeClaim(claimId, inconclusive);
                await updateCouncilReputations(claimId, claim.councilFindings, inconclusive);
                // Do not update senior/initial reputations for inconclusive claims
            };
        };
    };

    // Finalize claim with verdict
    func finalizeClaim(claimId : ClaimId, verdict : Verdict) : async () {
        // Store in fact ledger with proper structure
        let factRequest = {
            content = claimId; // In production, get actual claim content
            evidence = [];
            publicProof = { proofType = "ESCALATION_RESOLUTION"; content = verdict };
        };
        ignore await factLedger.addFact(factRequest);
        
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
        // Skip reputation updates for inconclusive verdicts
        if (finalVerdict == "Inconclusive") return;
        
        for ((id, finding) in findings.vals()) {
            let correct = finding.verdict == finalVerdict;
            let xpChange = if correct { 5 } else { -20 };
            
            // Update XP and issue warning if incorrect
            ignore await aletheianProfile.updateAletheianXp(id, xpChange, null);
            
            if (not correct) {
                ignore await aletheianProfile.issueWarning(id, #Minor);
                ignore await notification.sendNotification(
                    id, 
                    "Verification Feedback",
                    "Your finding for claim " # claimId # " was incorrect. Correct verdict: " # finalVerdict,
                    "feedback"
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
        // Skip reputation updates for inconclusive verdicts
        if (finalVerdict == "Inconclusive") return;
        
        for ((id, finding) in findings.vals()) {
            let correct = finding.verdict == finalVerdict;
            let xpChange = if correct { 15 } else { 0 }; // Only reward correct assessments
            
            ignore await aletheianProfile.updateAletheianXp(id, xpChange, null);
        };
    };

    // Update council members' reputations
    func updateCouncilReputations(
        claimId : ClaimId,
        findings : [(Principal, Finding)],
        finalVerdict : Verdict
    ) : async () {
        for ((id, finding) in findings.vals()) {
            // Always award 25 XP for council participation
            ignore await aletheianProfile.updateAletheianXp(id, 25, null);
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

    // Find majority verdict (absolute majority required)
    func findMajorityVerdict(findings : [(Principal, Finding)]) : ?Verdict {
        let counts = HashMap.HashMap<Verdict, Nat>(5, Text.equal, Text.hash);
        let total = findings.size();
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
        
        // Require absolute majority (> total/2)
        if (maxCount > total / 2) {
            maxVerdict
        } else {
            null
        }
    };

    // Extract all verdicts
    func extractVerdicts(findings : [(Principal, Finding)]) : [Verdict] {
        let buffer = Buffer.Buffer<Verdict>(findings.size());
        for ((_, finding) in findings.vals()) {
            buffer.add(finding.verdict);
        };
        buffer.toArray()
    };

    // ================== ADMIN API ================== //
    
    public shared({ caller }) func authorizeCaller(principal : Principal) : async () {
        assert caller == controller;
        authorizedCallerSet.add(principal);
    };
    
    public shared({ caller }) func revokeCaller(principal : Principal) : async () {
        assert caller == controller;
        authorizedCallerSet.delete(principal);
    };
    
    public shared({ caller }) func setCouncilMembers(members : [Principal]) : async () {
        assert caller == controller;
        councilMemberSet := HashSet.fromIter<Principal>(members.vals(), 10, Principal.equal, Principal.hash);
    };
    
    public shared({ caller }) func forceFinalize(
        escalationId : Text,
        verdict : Verdict,
        explanation : Text
    ) : async Result.Result<(), Text> {
        assert caller == controller;
        await _finalizeEscalation(escalationId, verdict, explanation);
        #ok()
    };
    
    // ================== QUERY INTERFACE ================== //
    
    public query func getEscalationStatus(escalationId : Text) : async ?EscalationRecord {
        _redactForPublic(escalationMap.get(escalationId))
    };
    
    public query func getEscalationDetails(escalationId : Text) : async ?EscalationRecord {
        // Only controller can see unredacted details
        if (caller == controller) {
            escalationMap.get(escalationId)
        } else {
            _redactForPublic(escalationMap.get(escalationId))
        }
    };
    
    func _redactForPublic(record : ?EscalationRecord) : ?EscalationRecord {
        switch (record) {
            case (?r) {
                ?{
                    r with
                    seniorReviews = Array.map<ReviewerOutcome, ReviewerOutcome>(
                        r.seniorReviews,
                        func(ro) { { ro with reviewer = Principal.fromText("anonymous") } }
                    );
                    councilReviews = Array.map<ReviewerOutcome, ReviewerOutcome>(
                        r.councilReviews,
                        func(ro) { { ro with reviewer = Principal.fromText("anonymous") } }
                    );
                }
            };
            case null null;
        };
    };
};
