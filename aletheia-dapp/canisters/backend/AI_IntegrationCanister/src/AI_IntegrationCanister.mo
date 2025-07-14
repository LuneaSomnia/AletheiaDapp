import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import FactRecord from "aletheia-dapp/canisters/backend/FactLedgerCanister/src/FactLedgerCanister";

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

    // Canister references
    let factLedgerCanister : actor {
        searchSimilarClaims : (content : Text) -> async [Text];
        getFact : (claimId : Text) -> async ?FactRecord;
    } = actor ("fctaa-aaaaa-aaaab-qai7q-cai"); // Replace with actual FactLedger ID

    // Stable storage for AI models and configurations
    stable var questionModelVersion : Text = "v1.0";
    stable var researchModelVersion : Text = "v1.2";
    stable var synthesisModelVersion : Text = "v1.1";

    // AI Module 1: Question Mirror (Question Generation)
    public shared func generateQuestions(claim : Claim) : async Result.Result<QuestionSet, Text> {
        try {
            // AI logic to generate critical thinking questions
            let questions = await _generateQuestions(claim.content);
            
            #ok({
                claimId = claim.id;
                questions = questions;
                explanations = _generateQuestionExplanations(claim.content, questions);
            });
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
            // External AI service call for research
            let rawResults = await _callResearchAI(claim.content);
            
            // Process and summarize results
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
        } catch (e) {
            #err("Research failed: " # Error.message(e));
        }
    };

    // AI Module 5: Consensus Synthesis
    public shared func synthesizeReport(claim : Claim, findings : [Finding]) : async Result.Result<Report, Text> {
        try {
            // Determine consensus verdict
            let verdict = _determineConsensusVerdict(findings);
            
            // Synthesize explanations
            let explanations = Buffer.Buffer<Text>(0);
            for (finding in findings.vals()) {
                explanations.add(finding.explanation);
            };
            
            let synthesizedExplanation = await _synthesizeExplanations(explanations.toArray());
            
            // Compile evidence
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
        } catch (e) {
            #err("Synthesis failed: " # Error.message(e));
        }
    };

    // ======================
    // AI Implementation Helpers
    // ======================

    // Question Generation AI (Module 1)
    func _generateQuestions(claimContent : Text) : async [Text] {
        // Actual implementation would call an AI model
        // This is a simplified version for demonstration
        if (Text.contains(claimContent, #text "COVID") or Text.contains(claimContent, #text "vaccine")) {
            return [
                "What scientific studies support this claim?",
                "Which health organizations have addressed this claim?",
                "Are there peer-reviewed papers that confirm this?"
            ];
        } else if (Text.contains(claimContent, #text "election") or Text.contains(claimContent, #text "vote")) {
            return [
                "What official election results are available?",
                "Which government agencies have verified this claim?",
                "Are there independent audits supporting this?"
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

    // Research AI (Module 4)
    type RawResearchResult = {
        url : Text;
        source : Text;
        content : Text;
    };

    func _callResearchAI(claimContent : Text) : async [RawResearchResult] {
        // Simulated research results
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
            },
            {
                url = "https://cdc.gov/guidelines";
                source = "CDC";
                content = "Public health guidelines regarding COVID-19 treatments";
            }
        ];
    };

    func _calculateCredibility(source : Text) : Float {
        // Simplified credibility scoring
        switch (source) {
            case "World Health Organization" 0.95;
            case "CDC" 0.92;
            case "New England Journal of Medicine" 0.97;
            case _ 0.75;
        };
    };

    func _summarizeContent(content : Text) : async Text {
        // Actual implementation would use summarization AI
        if (content.size() > 200) {
            Text.slice(content, 0, 200) # "...";
        } else {
            content;
        };
    };

    // Synthesis AI (Module 5)
    func _determineConsensusVerdict(findings : [Finding]) : Text {
        // Simple consensus algorithm
        let verdictCounts = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
        
        for (finding in findings.vals()) {
            let count = switch (verdictCounts.get(finding.classification)) {
                case (?c) c + 1;
                case null 1;
            };
            verdictCounts.put(finding.classification, count);
        };
        
        var maxCount = 0;
        var consensus = "Unresolved";
        
        for ((verdict, count) in verdictCounts.entries()) {
            if (count > maxCount) {
                maxCount := count;
                consensus := verdict;
            };
        };
        
        consensus;
    };

    func _synthesizeExplanations(explanations : [Text]) : async Text {
        // Actual implementation would use AI synthesis
        "After reviewing multiple expert analyses, the consensus is that " # 
        explanations[0] # " This is supported by evidence showing " # 
        (if (explanations.size() > 1) explanations[1] else "conclusive findings") # ".";
    };

    // ======================
    // Admin Functions
    // ======================
    
    public shared ({ caller }) func updateQuestionModel(version : Text) : async () {
        // Add authentication in real implementation
        questionModelVersion := version;
    };

    public shared ({ caller }) func updateResearchModel(version : Text) : async () {
        researchModelVersion := version;
    };

    public shared ({ caller }) func updateSynthesisModel(version : Text) : async () {
        synthesisModelVersion := version;
    };

    public query func getModelVersions() : async { 
        question : Text; 
        research : Text; 
        synthesis : Text 
    } {
        {
            question = questionModelVersion;
            research = researchModelVersion;
            synthesis = synthesisModelVersion;
        };
    };
};