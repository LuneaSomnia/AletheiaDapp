import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Int "mo:base/Int";

actor ClaimSubmissionCanister {
    type Claim = {
        id : Text;
        userId : Principal;
        content : Text;
        claimType : Text; // "text", "image", "video", etc.
        source : ?Text;
        context : ?Text;
        timestamp : Int;
        status : Text; // "submitted", "processing", "completed"
    };

    type ClaimResult = Result.Result<Text, Text>;

    // Stable storage
    stable var claimsEntries : [(Text, Claim)] = [];
    let claims = HashMap.HashMap<Text, Claim>(0, Text.equal, Text.hash);

    // Canister references
    let aiCanister : actor {
        generateQuestions : (claim : Text) -> async Text;
    } = actor ("aiaaa-aaaaa-aaaab-qai4q-cai"); // Replace with actual AI canister ID

    let dispatchCanister : actor {
        assignClaim : (claimId : Text) -> async Bool;
    } = actor ("dtcaa-aaaaa-aaaab-qai5q-cai"); // Replace with actual Dispatch canister ID

    let notificationCanister : actor {
        notifyUser : (userId : Principal, message : Text) -> async Bool;
    } = actor ("ntfaa-aaaaa-aaaab-qai6q-cai"); // Replace with actual Notification canister ID

    system func preupgrade() {
        claimsEntries := Iter.toArray(claims.entries());
    };

    system func postupgrade() {
        var claims := HashMap.fromIter<Text, Claim>(claimsEntries.vals(), 0, Text.equal, Text.hash);
        claimsEntries := [];
    };

    // Submit a new claim
    public shared ({caller}) func submitClaim(content : Text, claimType : Text, source : ?Text, context : ?Text) : async ClaimResult {
        try {
            let claimId = generateId(caller);
            let newClaim : Claim = {
                id = claimId;
                userId = caller;
                content;
                claimType;
                source;
                context;
                timestamp = Time.now();
                status = "submitted";
            };

            claims.put(claimId, newClaim);

            // Process with AI
            let questions = await aiCanister.generateQuestions(content);
            ignore await notificationCanister.notifyUser(caller, "Claim received. Processing...");

            // Dispatch to Aletheians
            let dispatchSuccess = await dispatchCanister.assignClaim(claimId);
            if (not dispatchSuccess) {
                throw Error.reject("Failed to dispatch claim to Aletheians");
            };

            // Update status
            let updatedClaim = {
                newClaim with status = "processing"
            };
            claims.put(claimId, updatedClaim);

            #ok(claimId);
        } catch (e) {
            #err("Submission failed: " # Error.message(e));
        }
    };

    // Helper to generate unique claim ID
    func generateId(userId : Principal) : Text {
    let random = (Time.now() : Int) % 1000000;
    Principal.toText(userId) # "-" # Int.toText(random);
};

    public query func getClaim(claimId : Text) : async ?Claim {
        claims.get(claimId);
    };
}