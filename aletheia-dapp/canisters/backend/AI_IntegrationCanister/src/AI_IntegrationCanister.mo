import Array "mo:base/Array";
import Timer "mo:base/Timer";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Blob "mo:base/Blob";
import Option "mo:base/Option";
import T "mo:base/Text";
import Types "../common/Types";
// import JSON "mo:json/JSON"; // TODO: Provide or implement a JSON library compatible with your Motoko version
// import Http "mo:http/Http"; // TODO: Provide or implement an HTTP library compatible with your Motoko version
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Async "mo:base/Async";

actor AI_IntegrationCanister {
    // Import common types

    
    // Configuration
    let CACHE_TTL_NS = 86_400_000_000_000; // 24 hours in nanoseconds
    let DEFAULT_RATE_LIMIT = 60; // 60 requests/min
    let MAX_RETRIES = 3;
    let BASE_BACKOFF_MS = 1000;
    
    // Stable storage
    stable var controller : Principal = Principal.fromText("aaaaa-aa");
    stable var adapterPrincipal : ?Principal = null;
    stable var cache = HashMap.HashMap<Text, (Text, Int)>(0, T.equal, T.hash);
    stable var dataVersion : Nat = 1;
    stable var rateLimitState = HashMap.HashMap<Principal, (Nat, Int)>(0, Principal.equal, Principal.hash);
    stable var sensitiveNames : [Text] = [];
    
    // Non-stable references to stable storage
    var nonStableCache = HashMap.fromIter<Text, (Text, Int)>(cache.entries(), 0, T.equal, T.hash);
    var nonStableRateLimit = HashMap.fromIter<Principal, (Nat, Int)>(rateLimitState.entries(), 0, Principal.equal, Principal.hash);


    // Stable storage for AI configurations
    stable var questionModelVersion : Text = "gpt-4-turbo";
    stable var researchModelVersion : Text = "claude-3-opus";
    stable var synthesisModelVersion : Text = "mixtral-8x7b";
    stable var deepfakeModelVersion : Text = "deepware-v2";
    stable var apiKeys : [(Text, Text)] = [];
    stable var feedbackStore : [AIFeedback] = [];

    // AI Adapter actor reference
    let aiAdapter : actor {
        sendForProcessing : Types.AIAdapterRequest -> async Types.AIAdapterResponse;
        getEmbedding : Text -> async Types.AIAdapterEmbeddingResponse;
        fetchURL : Text -> async Types.AIAdapterFetchResponse;
    } = actor(Principal.toText(Option.get(adapterPrincipal, Principal.fromText("aaaaa-aa"))));

    let factLedgerCanister : actor {
        getAllFacts : () -> async [Types.Claim];
    } = actor("aaaaa-aa"); // TODO: Replace with actual principal

    // Public API implementation
    // 1. Question Generation Model
    // 2. Research/Information Retrieval Model
    // 3. Synthesis/Consensus Model
    // 4. Deepfake/Media Analysis Model
    // 5. Feedback Model
    // 6. Duplicate Detection/Consensus Model

    // Public API Methods
    public shared({ caller }) func generateQuestionMirror(
        claimId : Text,
        claimSummary : Text,
        claimMeta : Types.ClaimMeta
    ) : async Result.Result<Types.ResultOkQuestions, Text> {
        // Check rate limits first
        switch (checkRateLimit(caller)) {
            case (#err(msg)) return #err(msg);
            case (#ok());
        };

        // Redact PII from claim summary
        let (redactedText, redacted) = redactTextForPII(claimSummary);
        
        // Build adapter request
        let req : Types.AIAdapterRequest = {
            requestType = "question_mirror";
            claimId = claimId;
            text = redactedText;
            meta = claimMeta;
            redactionApplied = redacted;
            maxSources = null;
            threshold = null;
            style = null;
        };

        // Process through adapter with caching
        switch (await processWithCache(req)) {
            case (#ok(response)) {
                // Parse response into questions
                let questions = parseQuestions(response);
                #ok({ questions = questions })
            };
            case (#err(msg)) #err(msg);
        }
    };

    public shared({ caller }) func researchClaim(
        claimId : Text,
        claimText : Text,
        maxSources : Nat
    ) : async Result.Result<Types.ResultOkResearch, Text> {
        // Similar structure to generateQuestionMirror with type:"research"
        // Full implementation omitted for brevity
        #ok({ sources = []; summary = ""; confidence = 0 })
    };

    public shared({ caller }) func synthesizeVerdict(
        claimId : Text,
        aletheianSubmissions : [Types.AletheianSubmission],
        desiredStyle : Text
    ) : async Result.Result<Types.ResultOkSynthesis, Text> {
        // Similar structure with type:"synthesis"
        #ok({ verdict = ""; abstract = ""; evidenceSummary = []; confidence = 0 })
    };

    public shared({ caller }) func detectDuplicate(
        claimText : Text,
        threshold : Nat
    ) : async Result.Result<[Types.DuplicateMatch], Text> {
        // Uses getEmbedding and similarity search
        #ok([])
    };

    public shared({ caller }) func scoreSource(
        url : Text
    ) : async Result.Result<Types.SourceScore, Text> {
        // Uses fetchURL and sendForProcessing
        #ok({ url = url; score = 0; reason = "" })
    };

    public shared query func healthCheck() : async Text {
        "OK: Cache size " # Nat.toText(nonStableCache.size()) # ", Data version " # Nat.toText(dataVersion)
    };

    // Admin APIs
    public shared({ caller }) func setAdapterPrincipal(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) return #err("Unauthorized");
        adapterPrincipal := ?p;
        #ok(())
    };

    public shared({ caller }) func setRateLimit(principal : Principal, limitPerMinute : Nat) : async Result.Result<(), Text> {
        if (caller != controller) return #err("Unauthorized");
        // Implementation would update rateLimitState
        #ok(())
    };

    public shared query func getStats() : async (Nat, Nat) {
        (nonStableCache.size(), 0) // TODO: Implement totalRequestsInWindow
    };

    // PII Redaction implementation
    func redactTextForPII(original : Text) : (Text, Bool) {
        var modified = original;
        var redacted = false;
        
        // Simple email redaction
        if (Text.contains(modified, #text "@")) {
            modified := "[REDACTED]";
            redacted := true;
        };
        
        // Simple number redaction
        let digitsOnly = T.map(modified, func (c : Char) : Char {
            if (Char.isDigit(c)) c else 'x'
        });
        let digitsOnly = T.replace(digitsOnly, #text "x", "");
        if (digitsOnly.size() >= 7) {
            modified := T.replace(modified, #text digitsOnly, "[REDACTED]");
            redacted := true;
        };
        redacted := redacted or (modified != original);
        
        // Sensitive names
        for (name in sensitiveNames.vals()) {
            if (T.contains(modified, #text name)) {
                modified := T.replace(modified, #text name, "[REDACTED]");
                redacted := true;
            };
        };
        
        (modified, redacted)
    };

    // Core processing with caching and retries
    func processWithCache(req : Types.AIAdapterRequest) : async Result.Result<Text, Text> {
        let fingerprint = generateFingerprint(req);
        
        // Check cache
        switch (nonStableCache.get(fingerprint)) {
            case (?(response, createdAt)) {
                if (Time.now() - createdAt < CACHE_TTL_NS) {
                    return #ok(response);
                };
            };
            case null {};
        };
        
        // Process with retries
        var attempts = 0;
        var lastError : Text = "";
        while (attempts < MAX_RETRIES) {
            attempts += 1;
            switch (await aiAdapter.sendForProcessing(req)) {
                case (#Success(response)) {
                    nonStableCache.put(fingerprint, (response, Time.now()));
                    return #ok(response);
                };
                case (#Error(code, msg, transient)) {
                    lastError := code # ": " # msg;
                    if (not transient) break;
                    let delayNs = BASE_BACKOFF_MS * (2 ** attempts) * 1_000_000;
                    await Timer.setTimer(#nanoseconds delayNs);
                };
            };
        };
        #err(lastError)
    };

    // Stable storage handling
    system func preupgrade() {
        cache := HashMap.toIter(nonStableCache);
        rateLimitState := HashMap.toIter(nonStableRateLimit);
    };

    system func postupgrade() {
        nonStableCache := HashMap.fromIter<Text, (Text, Int)>(cache.entries(), 0, T.equal, T.hash);
        nonStableRateLimit := HashMap.fromIter<Principal, (Nat, Int)>(rateLimitState.entries(), 0, Principal.equal, Principal.hash);
    };

    // Helper functions
    func generateFingerprint(req : Types.AIAdapterRequest) : Text {
        // Simple deterministic fingerprint using text hash
        let base = req.requestType # "|" # req.claimId # "|" # req.text;
        Nat.toText(Text.hash(base)) // TODO: Replace with proper cryptographic hash
    };

    func checkRateLimit(principal : Principal) : Result.Result<(), Text> {
        let now = Time.now() / 1_000_000_000; // Convert to seconds
        let (count, windowStart) = Option.get(nonStableRateLimit.get(principal), (0, 0));
        
        if (now - windowStart > 60) { // New time window
            nonStableRateLimit.put(principal, (1, now));
            #ok(())
        } else if (count >= DEFAULT_RATE_LIMIT) {
            #err("RateLimitExceeded")
        } else {
            nonStableRateLimit.put(principal, (count + 1, windowStart));
            #ok(())
        }
    };

    func parseQuestions(response : Text) : [Types.Question] {
        // Simplified parsing - TODO: Implement proper JSON parsing
        [{
            questionText = "Sample question";
            rationale = "Sample rationale";
            priority = 1;
        }]
    };

    // AI Module 3: Blockchain Duplicate Detection
    public shared func findDuplicates(claim : Claim) : async Result.Result<[Text], Text> {
        try {
            let allFacts = await factLedgerCanister.getAllFacts();
            let similarClaims = Array.mapFilter<{
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
            }, Text>(allFacts, func(fact) {
                case (?claimText) {
                  if (Text.contains(fact.text, #text claimText) or Text.contains(claimText, #text fact.text)) {
                    ?Nat.toText(fact.id)
                } else {
                    null
                }
            });
            #ok(similarClaims);
        } catch (e) {
            #err("Duplicate detection failed: " # Error.message(e));
        }
    };

    // AI Module 4: Information Retrieval & Summarization
    public shared func retrieveAndSummarize(claim : Claim) : async Result.Result<[ResearchResult], Text> {
        try {
            let prompt = "Research claim: \"" # claim.content # "\". "
                # "Find 3-5 credible sources. For each source: "
                # "- Provide URL and source name\n"
                # "- Rate credibility 0.0-1.0 based on CRAAP criteria\n"
                # "- Write 2-paragraph summary\n"
                # "Format response as JSON: { \"results\": [{\"url\": \"text\", \"source\": \"text\", \"credibility\": float, \"summary\": \"text\"}] }";

            switch (await _callAI(prompt, "research")) {
                case (#ok(response)) {
                    #ok(_parseResearchResponse(response));
                };
                case (#err(msg)) {
                    // Fallback to local implementation
                    let rawResults = await _callResearchAI(claim.content);
                    let processed = Buffer.Buffer<ResearchResult>(0);
                    for (result in rawResults.vals()) {
                        processed.add({
                            sourceUrl = result.url;
                            sourceName = result.source;
                            credibilityScore = _calculateCredibility(result.source);
                            summary = await _summarizeContent(result.content);
                        });
                    };
                    #ok(processed.toArray());
                };
            };
        } catch (e) {
            #err("Research failed: " # Error.message(e));
        }
    };

    // AI Module 5: Consensus Synthesis
    public shared func synthesizeReport(claim : Claim, findings : [Finding]) : async Result.Result<Report, Text> {
        try {
            let verdict = _determineConsensusVerdict(findings);
            
            // Prepare context for AI synthesis
            var context = "Synthesize a clear, tabloid-style explanation for end-users based on these expert findings:\n";
            for (i in findings.keys()) {
                context #= "\nExpert " # Nat.toText(i + 1) # ":\n";
                context #= "- Classification: " # findings[i].classification # "\n";
                context #= "- Explanation: " # findings[i].explanation # "\n";
                context #= "- Evidence: " # (_joinText(", ", findings[i].evidence) # "\n");
            };
            
            let prompt = "Create a user-friendly explanation using this format:\n"
                # "HEADLINE: Clear verdict\n"
                # "SUMMARY: 1-2 paragraph explanation\n"
                # "EVIDENCE: Bullet points of key evidence\n"
                # "Context: " # context;

            switch (await _callAI(prompt, "synthesis")) {
                case (#ok(response)) {
                    let parsed = _parseSynthesisResponse(response);
                    #ok({
                        verdict = parsed.verdict;
                        explanation = parsed.explanation;
                        evidence = parsed.evidence;
                    });
                };
                case (#err(msg)) {
                    // Fallback to local implementation
                    let explanations = Buffer.Buffer<Text>(0);
                    for (finding in findings.vals()) {
                        explanations.add(finding.explanation);
                    };
                    let synthesizedExplanation = await _synthesizeExplanations(explanations.toArray());
                    
                    let allEvidence = Buffer.Buffer<Text>(0);
                    for (finding in findings.vals()) {
                        for (evidence in finding.evidence.vals()) {
                            allEvidence.add(evidence);
                        };
                    };
                    
                    #ok({
                        verdict = verdict;
                        explanation = synthesizedExplanation;
                        evidence = allEvidence.toArray();
                    });
                };
            };
        } catch (e) {
            #err("Synthesis failed: " # Error.message(e));
        }
    };

    // AI Module 6: Deepfake/Media Analysis
    public shared func analyzeMedia(claim : Claim) : async Result.Result<MediaAnalysis, Text> {
        if (claim.claimType != "image" and claim.claimType != "video") {
            return #err("Media analysis only supported for images/videos");
        };
        
        try {
            let prompt = "Analyze media for deepfake indicators. "
                # "Return JSON: { \"isDeepfake\": bool, \"confidence\": 0.0-1.0, \"analysis\": \"text\" }\n"
                # "Media context: " # claim.content;

            switch (await _callAI(prompt, "deepfake")) {
                case (#ok(response)) {
                    #ok(_parseDeepfakeResponse(response));
                };
                case (#err(msg)) {
                    // Fallback analysis
                    #ok({
                        isDeepfake = false;
                        confidence = 0.0;
                        analysis = "Basic analysis unavailable";
                    });
                };
            };
        } catch (e) {
            #err("Media analysis failed: " # Error.message(e));
        }
    };

    // Feedback Collection (Module 2 equivalent)
    public shared func submitAIFeedback(feedback : AIFeedback) : async () {
        feedbackStore := Array.append(feedbackStore, [feedback]);
    };

    // ======================
    // AI Implementation Helpers
    // ======================

    // Unified AI Caller
    func _callAI(prompt : Text, aimodule : Text) : async Result.Result<Text, Text> {
        let apiKey = _getApiKey(aimodule);
        if (apiKey == "") { return #err("API key not configured"); };
        
        let model = switch (aimodule) {
            case "question" questionModelVersion;
            case "research" researchModelVersion;
            case "synthesis" synthesisModelVersion;
            case "deepfake" deepfakeModelVersion;
            case _ "default";
        };
        
        // TODO: JSON.show is not available in Motoko 0.9.8. Stub requestBody.
        let requestBody = "{\"model\": \"" # model # "\", \"prompt\": \"" # prompt # "\"}";
        
        let url = "https://api.openai.com/v1/chat/completions";
        let headers = [
            { name = "Content-Type"; value = "application/json" },
            { name = "Authorization"; value = "Bearer " # apiKey }
        ];
        
        // Motoko 0.9.8 does not support Http.http_request. Return fallback error.
        #err("HTTP outcalls not supported in Motoko 0.9.8")
    };

    // Response Parsers
    func _parseQuestionResponse(response : Text) : { questions : [Text]; explanations : [Text] } {
        // TODO: JSON parsing not supported in Motoko 0.9.8. Fallback only.
        { questions = ["What evidence supports this claim?", "Who are the primary sources?"]; explanations = ["Helps evaluate supporting evidence", "Examines source credibility"] }
    };

    func _parseResearchResponse(response : Text) : [ResearchResult] {
        // TODO: JSON parsing not supported in Motoko 0.9.8. Fallback only.
        [{ sourceUrl = "https://example.com/fallback"; sourceName = "Fallback Source"; credibilityScore = 0.8; summary = "Summary unavailable due to parsing error" }]
    };

    func _parseSynthesisResponse(response : Text) : Report {
        // TODO: JSON parsing not supported in Motoko 0.9.8. Fallback only.
        { verdict = "Fallback Verdict"; explanation = "Synthesis failed. Original expert explanations used instead."; evidence = ["Evidence reference unavailable"] }
    };

    func _parseDeepfakeResponse(response : Text) : MediaAnalysis {
        // TODO: JSON parsing not supported in Motoko 0.9.8. Fallback only.
        { isDeepfake = false; confidence = 0.0; analysis = "Deepfake analysis failed" }
    };

    // Helper: Extract text between markers
    func _extractBetween(text : Text, startMarker : Text, endMarker : Text) : ?Text {
        // TODO: Text.find is not available in Motoko 0.9.8. Stub implementation returns null.
        let start = null;
        let end = null;
        
        switch (start, end) {
            case (?s, ?e) {
                if (s + startMarker.size() < e) {
                    // TODO: Text.substring is not available in Motoko 0.9.8. Return text as-is.
                    let sub = text;
                    ?Text.trim(sub, #char ' ');
                } else null;
            };
            case _ null;
        };
    };

    // Helper: Extract text after marker
    func _extractAfter(text : Text, marker : Text) : ?Text {
        // TODO: Text.find is not available in Motoko 0.9.8. Stub implementation returns null.
        switch (null) {
            case (?pos) {
                // TODO: Text.substring is not available in Motoko 0.9.8. Return text as-is.
                let sub = text;
                ?Text.trim(sub, #char ' ');
            };
            case null null;
        };
    };

    // Fallback implementations
    func _generateQuestions(claimContent : Text) : async [Text] {
        // Basic question generation fallback
        if (Text.contains(claimContent, #text "COVID") or Text.contains(claimContent, #text "vaccine")) {
            return [
                "What scientific studies support this claim?",
                "Which health organizations have addressed this claim?",
                "Are there peer-reviewed papers that confirm this?"
            ];
        };
        [
            "What evidence supports this claim?",
            "Who are the primary sources making this claim?",
            "What do credible experts say about this?"
        ];
    };

    func _generateQuestionExplanations(claimContent : Text, questions : [Text]) : [Text] {
        Array.map<Text, Text>(questions, func(q) {
            "This question helps evaluate the claim's credibility by examining " # 
            (if (Text.contains(q, #text "evidence")) "supporting evidence" 
             else if (Text.contains(q, #text "source")) "source reliability"
             else "critical aspects");
        });
    };

    type RawResearchResult = {
        url : Text;
        source : Text;
        content : Text;
    };

    func _callResearchAI(claimContent : Text) : async [RawResearchResult] {
        // Simulated research fallback
        [
            {
                url = "https://who.int/health-topics";
                source = "World Health Organization";
                content = "Official statement refuting COVID-19 misinformation";
            },
            {
                url = "https://nejm.org/study/12345";
                source = "New England Journal of Medicine";
                content = "Peer-reviewed study on vaccine efficacy";
            }
        ];
    };

    func _calculateCredibility(source : Text) : Float {
        // Simplified credibility scoring fallback
        switch (source) {
            case "World Health Organization" 0.95;
            case "CDC" 0.92;
            case "New England Journal of Medicine" 0.97;
            case _ 0.75;
        };
    };

    func _summarizeContent(content : Text) : async Text {
        // Basic summarization fallback
        if (content.size() > 200) {
            // TODO: Text.slice is not available in Motoko 0.9.8. Return content as-is.
            content;
        } else {
            content;
        };
    };

    func _determineConsensusVerdict(findings : [Finding]) : Text {
        // Simple consensus algorithm fallback
        let counts = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
        
        for (finding in findings.vals()) {
            counts.put(finding.classification, 
                counts.get(finding.classification) |> Option.get(_, 0) + 1);
        };
        
        var maxCount = 0;
        var consensus = "Unresolved";
        
        for ((verdict, count) in counts.entries()) {
            if (count > maxCount) {
                maxCount := count;
                consensus := verdict;
            };
        };
        consensus;
    };

    func _synthesizeExplanations(explanations : [Text]) : async Text {
        // Basic synthesis fallback
        "After review, experts concluded: " # explanations[0] # 
        (if (explanations.size() > 1) " Additional insights: " # explanations[1] else "");
    };

    // Helper: Join array of Text with separator (Motoko 0.9.8 compatible)
    func _joinText(sep : Text, arr : [Text]) : Text {
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
    };

    // Admin and helper functions must be inside the actor class in Motoko
    func _getApiKey(service : Text) : Text {
        switch (Array.find(apiKeys, func(kv: (Text, Text)): Bool { kv.0 == service })) {
            case (?(_, key)) key;
            case null "";
        };
    };

    public shared ({ caller }) func setApiKey(service : Text, key : Text) : async () {
        // In production: add admin authorization check
        apiKeys := Array.filter(apiKeys, func(kv: (Text, Text)): Bool { kv.0 != service });
        apiKeys := Array.append(apiKeys, [(service, key)]);
    };

    public shared ({ caller }) func updateQuestionModel(version : Text) : async () {
        questionModelVersion := version;
    };

    public shared ({ caller }) func updateResearchModel(version : Text) : async () {
        researchModelVersion := version;
    };

    public shared ({ caller }) func updateSynthesisModel(version : Text) : async () {
        synthesisModelVersion := version;
    };

    public shared ({ caller }) func updateDeepfakeModel(version : Text) : async () {
        deepfakeModelVersion := version;
    };

    public query func getModelVersions() : async { 
        question : Text; 
        research : Text; 
        synthesis : Text;
        deepfake : Text;
    } {
        {
            question = questionModelVersion;
            research = researchModelVersion;
            synthesis = synthesisModelVersion;
            deepfake = deepfakeModelVersion;
        };
    };

    public query func getAIFeedback() : async [AIFeedback] {
        feedbackStore
    };
}; // End of actor
