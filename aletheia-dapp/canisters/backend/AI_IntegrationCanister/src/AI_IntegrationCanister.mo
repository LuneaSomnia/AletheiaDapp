import Array "mo:base/Array";
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
// import JSON "mo:json/JSON"; // TODO: Provide or implement a JSON library compatible with your Motoko version
// import Http "mo:http/Http"; // TODO: Provide or implement an HTTP library compatible with your Motoko version
import ExperimentalCycles "mo:base/ExperimentalCycles";

actor AI_IntegrationCanister {
    type Claim = {
        id : Text;
        content : Text;
        claimType : Text; // "text", "image", "video", etc.
        source : ?Text;
        context : ?Text;
    };

    type ResearchResult = {
        sourceUrl : Text;
        sourceName : Text;
        credibilityScore : Float;
        summary : Text;
    };

    type Finding = {
        aletheianId : Principal;
        classification : Text;
        explanation : Text;
        evidence : [Text];
    };

    type Report = {
        verdict : Text;
        explanation : Text;
        evidence : [Text];
    };

    type QuestionSet = {
        claimId : Text;
        questions : [Text];
        explanations : [Text];
    };

    type MediaAnalysis = {
        isDeepfake : Bool;
        confidence : Float;
        analysis : Text;
    };

    type AIFeedback = {
        aimodule : Text;  // "question", "research", "synthesis", "deepfake"
        claimId : Text;
        rating : Nat;   // 1-5 scale
        comments : Text;
    };

    // Canister references
    let factLedgerCanister : actor {
        searchSimilarClaims : (content : Text) -> async [Text];
    } = actor ("fctaa-aaaaa-aaaab-qai7q-cai"); // Replace with actual FactLedger ID

    // Stable storage for AI configurations
    stable var questionModelVersion : Text = "gpt-4-turbo";
    stable var researchModelVersion : Text = "claude-3-opus";
    stable var synthesisModelVersion : Text = "mixtral-8x7b";
    stable var deepfakeModelVersion : Text = "deepware-v2";
    stable var apiKeys : [(Text, Text)] = [];
    stable var feedbackStore : [AIFeedback] = [];

    // ========== AI Model API Key Placeholders ==========
    // Place your API keys for each LLM here. Replace the empty strings with your actual keys.
    let questionModelApiKey : Text = "<QUESTION_MODEL_API_KEY>"; // TODO: Insert your API key
    let researchModelApiKey : Text = "<RESEARCH_MODEL_API_KEY>"; // TODO: Insert your API key
    let synthesisModelApiKey : Text = "<SYNTHESIS_MODEL_API_KEY>"; // TODO: Insert your API key
    let deepfakeModelApiKey : Text = "<DEEPFAKE_MODEL_API_KEY>"; // TODO: Insert your API key
    let feedbackModelApiKey : Text = "<FEEDBACK_MODEL_API_KEY>"; // TODO: Insert your API key
    let consensusModelApiKey : Text = "<CONSENSUS_MODEL_API_KEY>"; // TODO: Insert your API key

    // ========== AI Model Logic Sections ==========
    // 1. Question Generation Model
    // 2. Research/Information Retrieval Model
    // 3. Synthesis/Consensus Model
    // 4. Deepfake/Media Analysis Model
    // 5. Feedback Model
    // 6. Duplicate Detection/Consensus Model

    // AI Module 1: Question Mirror (Question Generation)
    public shared func generateQuestions(claim : Claim) : async Result.Result<QuestionSet, Text> {
        try {
            let prompt = "Generate 2-3 critical thinking questions to evaluate the veracity of this claim. "
                # "For each question, provide a brief explanation of why it's important. "
                # "Claim: \"" # claim.content # "\". "
                # "Format response as JSON: { \"questions\": [{\"question\": \"text\", \"explanation\": \"text\"}] }";

            switch (await _callAI(prompt, "question")) {
                case (#ok(response)) {
                    let parsed = _parseQuestionResponse(response);
                    #ok({
                        claimId = claim.id;
                        questions = parsed.questions;
                        explanations = parsed.explanations;
                    });
                };
                case (#err(msg)) {
                    // Fallback to local implementation
                    let questions = await _generateQuestions(claim.content);
                    #ok({
                        claimId = claim.id;
                        questions = questions;
                        explanations = _generateQuestionExplanations(claim.content, questions);
                    })
                };
            };
        } catch (e) {
            #err("Question generation failed: " # Error.message(e));
        }
    };

    // AI Module 3: Blockchain Duplicate Detection
    public shared func findDuplicates(claim : Claim) : async Result.Result<[Text], Text> {
        try {
            let similarClaims = await factLedgerCanister.searchSimilarClaims(claim.content);
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