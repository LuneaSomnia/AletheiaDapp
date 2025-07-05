import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

actor AI_IntegrationCanister {
    type ClaimId = Text;
    type Claim = Text;
    type Question = {
        question: Text;
        explanation: Text;
    };
    
    type ResearchResult = {
        source: Text;
        url: Text;
        credibilityScore: Float;
        summary: Text;
    };
    
    type SynthesisInput = {
        verdict: Text;
        explanation: Text;
    };
    
    type SynthesisResult = {
        verdict: Text;
        explanation: Text;
        evidenceHighlights: [Text];
    };
    
    // In-memory storage for demonstration
    private var questionStore = HashMap.HashMap<ClaimId, [Question]>(0, Text.equal, Text.hash);
    private var researchStore = HashMap.HashMap<ClaimId, [ResearchResult]>(0, Text.equal, Text.hash);
    
    // Generate "Right Questions" for a claim
    public shared func generateQuestions(claimId: ClaimId, claim: Claim) : async [Question] {
        // Simulated AI-generated questions
        let questions = [
            {
                question = "What scientific evidence supports this claim from reputable sources?";
                explanation = "Medical claims require scientific backing.";
            },
            {
                question = "Who is making this claim, and what are their qualifications or potential biases?";
                explanation = "Source credibility is key.";
            },
            {
                question = "Are there any peer-reviewed studies that confirm this claim?";
                explanation = "Peer-reviewed studies are a high standard of evidence.";
            }
        ];
        
        questionStore.put(claimId, questions);
        questions
    };
    
    // Retrieve information for a claim
    public shared func retrieveInformation(claimId: ClaimId, claim: Claim) : async [ResearchResult] {
        // Simulated AI research
        let results = [
            {
                source = "World Health Organization";
                url = "https://www.who.int/health-topics";
                credibilityScore = 9.8;
                summary = "Official guidelines debunking the claim.";
            },
            {
                source = "Scientific Journal: Nature";
                url = "https://www.nature.com/articles";
                credibilityScore = 9.5;
                summary = "Peer-reviewed study refuting the claim.";
            }
        ];
        
        researchStore.put(claimId, results);
        results
    };
    
    // Synthesize a report from multiple verifications
    public shared func synthesizeReport(
        claimId: ClaimId,
        verifications: [SynthesisInput],
        evidence: [ResearchResult]
    ) : async SynthesisResult {
        // For simplicity, we take the most common verdict
        var verdictCounts = HashMap.HashMap<Text, Nat>(0, Text.equal, Text.hash);
        for (v in verifications.vals()) {
            let count = Option.get(verdictCounts.get(v.verdict), 0);
            verdictCounts.put(v.verdict, count + 1);
        };
        
        // Find the verdict with the highest count
        var maxVerdict: Text = "";
        var maxCount: Nat = 0;
        for ((verdict, count) in verdictCounts.entries()) {
            if (count > maxCount) {
                maxVerdict := verdict;
                maxCount := count;
            };
        };
        
        // Create evidence highlights
        let highlights = Array.map<ResearchResult, Text>(
            evidence,
            func(r) = "[" # r.source # "] " # r.summary
        );
        
        {
            verdict = maxVerdict;
            explanation = "Consensus reached by " # Nat.toText(verifications.size()) # " Aletheians";
            evidenceHighlights = highlights;
        }
    };
    
    // Get stored questions
    public query func getQuestions(claimId: ClaimId) : async ?[Question] {
        questionStore.get(claimId)
    };
    
    // Get stored research
    public query func getResearch(claimId: ClaimId) : async ?[ResearchResult] {
        researchStore.get(claimId)
    };
};