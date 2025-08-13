import AI "canister:AI_IntegrationCanister";
import T "mo:base/Text";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

actor MockAdapter {
    public func sendForProcessing(req : AI.Types.AIAdapterRequest) : async AI.Types.AIAdapterResponse {
        #Success("{\"questions\":[{\"questionText\":\"Test question\",\"rationale\":\"Test rationale\",\"priority\":1}]}")
    };
    
    public func getEmbedding(text : Text) : async AI.Types.AIAdapterEmbeddingResponse {
        #Success([0.1, 0.2, 0.3])
    };
    
    public func fetchURL(url : Text) : async AI.Types.AIAdapterFetchResponse {
        #Success("{\"score\":80,\"reason\":\"Credible source\"}")
    };
};

let testPrincipal = Principal.fromText("aaaaa-aa");
let testClaimMeta = {
    mediaType = "text";
    sourceUrl = null;
    ipfsHash = null;
    submittedBy = testPrincipal;
    submittedAt = 0;
};

await AI.setAdapterPrincipal(Principal.fromActor(MockAdapter));

// Test PII redaction
let (redacted, applied) = AI.redactTextForPII("test@example.com 1234567");
assert applied == true;
assert T.contains(redacted, #text "[REDACTED]");
assert applied == true;
assert T.contains(redacted, #text "[REDACTED]");

// Test question generation
let result = await AI.generateQuestionMirror("test1", "Test claim", testClaimMeta);
switch result {
    case (#ok(res)) assert res.questions.size() > 0;
    case (#err(e)) assert false;
};

// Test rate limiting
var i = 0;
var limitHit = false;
while (i < 65) {
    let res = await AI.generateQuestionMirror("test" # Nat.toText(i), "Test claim", testClaimMeta);
    if (Result.isErr(res) and T.contains(Result.errOption(res).!, #text "RateLimitExceeded")) {
        limitHit := true;
        break;
    };
    i += 1;
};
assert limitHit == true;
