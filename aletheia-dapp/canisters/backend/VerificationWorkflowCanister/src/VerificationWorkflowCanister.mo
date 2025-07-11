import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Text "mo:base/Text";
import AletheianProfileCanister "canister:AletheianProfileCanister";
import FactLedgerCanister "canister:FactLedgerCanister";
import AI_Adapter "canister:AI_Adapter";
import Error "mo:base/Error";
import Nat "mo:base/Nat";

actor {
  type ClaimId = Nat;
  type Claim = {
    content : Text;
    submitter : Principal;
    timestamp : Time.Time;
    status : { #pending; #verified; #escalated; #disputed };
    // ... other fields
  };

  type Source = {
    url : Text;
    author : Text;
    publisher : Text;
    date : Time.Time;
    lastUpdated : ?Time.Time;
    citations : [Text];
  };

  type CRAAPScore = {
    currency : Float;
    relevance : Float;
    authority : Float;
    accuracy : Float;
    purpose : Float;
    total : Float;
  };

  private var claims = HashMap.HashMap<ClaimId, Claim>(0, Nat.equal, Hash.hash);
  private var nextClaimId : ClaimId = 0;

  public shared ({ caller }) func submitClaim(content : Text) : async Result.Result<ClaimId, Text> {
    let claimId = nextClaimId;
    nextClaimId += 1;
    
    claims.put(claimId, {
      content = content;
      submitter = caller;
      timestamp = Time.now();
      status = #pending;
    });
    
    // Dispatch to Aletheians
    await dispatchToAletheians(claimId);
    
    #ok(claimId);
  };

  private func dispatchToAletheians(claimId : ClaimId) : async () {
    // Implementation logic
  };

  // CRAAP Evaluation Functions
  public func evaluateSource(source : Source, claimContent : Text) : CRAAPScore {
    let currencyScore = calculateCurrencyScore(source.date, source.lastUpdated);
    let relevanceScore = calculateRelevanceScore(source, claimContent);
    let authorityScore = calculateAuthorityScore(source);
    let accuracyScore = calculateAccuracyScore(source);
    let purposeScore = calculatePurposeScore(source);
    
    let total = (currencyScore + relevanceScore + authorityScore + accuracyScore + purposeScore) / 5.0;
    
    {
      currency = currencyScore;
      relevance = relevanceScore;
      authority = authorityScore;
      accuracy = accuracyScore;
      purpose = purposeScore;
      total = total;
    }
  };

  private func calculateCurrencyScore(date : Time.Time, lastUpdated : ?Time.Time) : Float {
    let now = Time.now();
    let secondsPerYear = 365 * 24 * 60 * 60;
    let ageSeconds = (now - date) / 1_000_000_000;
    let ageYears = Float.fromInt(ageSeconds) / Float.fromInt(secondsPerYear);
    
    if (ageYears <= 1.0) 1.0
    else if (ageYears <= 3.0) 0.7
    else if (ageYears <= 5.0) 0.3
    else 0.0
  };

  private func calculateRelevanceScore(source : Source, claimContent : Text) : Float {
    // Simplified implementation - would use NLP in production
    let sourceWords = Text.split(source.url, #char '/');
    let claimWords = Text.split(claimContent, #char ' ');
    
    var matchCount = 0;
    for (word in claimWords.vals()) {
      if (Text.contains(source.url, #text word)) {
        matchCount += 1;
      }
    };
    
    Float.fromInt(matchCount) / Float.fromInt(claimWords.size())
  };

  private func calculateAuthorityScore(source : Source) : Float {
    // Check for known authoritative domains
    let authoritativeDomains = [
      "who.int", "cdc.gov", "nih.gov", "nature.com", "sciencemag.org",
      "reuters.com", "apnews.com", "bbc.co.uk"
    ];
    
    for (domain in authoritativeDomains.vals()) {
      if (Text.contains(source.url, #text domain)) {
        return 1.0;
      }
    };
    
    // Check for academic domains
    if (Text.contains(source.url, #text ".edu") or
        Text.contains(source.url, #text ".ac.")) {
      return 0.8;
    };
    
    0.3; // Default score for unknown sources
  };

  private func calculateAccuracyScore(source : Source) : Float {
    // Count number of citations as proxy for accuracy
    let citationCount = source.citations.size();
    
    if (citationCount > 5) 1.0
    else if (citationCount > 3) 0.8
    else if (citationCount > 1) 0.6
    else 0.3
  };

  private func calculatePurposeScore(source : Source) : Float {
    // Check for commercial/advertising indicators
    if (Text.contains(source.url, #text "advert") or
        Text.contains(source.url, #text "commerce") or
        Text.contains(source.url, #text "shop")) {
      return 0.4;
    };
    
    // Check for educational/non-profit indicators
    if (Text.contains(source.url, #text ".edu") or
        Text.contains(source.url, #text ".org") or
        Text.contains(source.url, #text "nonprofit")) {
      return 0.9;
    };
    
    0.7; // Neutral score
  };

  public shared ({ caller }) func escalateClaim(claimId : ClaimId) : async Result.Result<Text, Text> {
    switch (claims.get(claimId)) {
      case (null) { #err("Claim not found") };
      case (?claim) {
        try {
          let requiredBadges = getRequiredExpertise(claim.content);
          let seniors = await AletheianProfileCanister.findAvailableSeniors(requiredBadges);
          
          if (seniors.size() < 3) {
            let council = await AletheianProfileCanister.getCouncilMembers();
            if (council.size() > 0) {
              // Assign to council
              #ok("Assigned to council of elders")
            } else {
              #err("Insufficient qualified reviewers available")
            }
          } else {
            // Assign to seniors
            #ok("Assigned to senior Aletheians")
          }
        } catch (e) {
          #err("Escalation failed: " # Error.message(e))
        }
      }
    }
  };

  private func getRequiredExpertise(content : Text) : [Text] {
    let expertise : [Text] = switch (Text.contains(content, #text "COVID") or Text.contains(content, #text "vaccine")) {
      case true ["Health"];
      case false switch (Text.contains(content, #text "election") or Text.contains(content, #text "vote")) {
        case true ["Politics"];
        case false ["General"];
      };
    };
    expertise
  }
}