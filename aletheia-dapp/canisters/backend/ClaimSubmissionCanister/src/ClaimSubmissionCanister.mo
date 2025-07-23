import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Nat8 "mo:base/Nat8";
// SHA256 not available in Motoko 0.9.8 base library. Use a stub or plug in a compatible library.

actor ClaimSubmissionCanister {
    type ClaimType = {
        #text;
        #image;
        #video;
        #audio;
        #articleLink;
        #fakeNewsUrl;
        #other;
    };

    type ClaimContent = {
        #text : Text;
        #blob : Blob;
        #url : Text;
    };

    type Claim = {
        id : Text;
        userId : Principal;
        content : ClaimContent;
        claimType : ClaimType;
        context : ?Text;
        source : ?Text;
        timestamp : Int;
        status : Text;
        fileHash : ?Text; // SHA-256 hash for uploaded files
    };

    type ClaimResult = Result.Result<Text, Text>;
    type ClaimSubmission = {
        content : ClaimContent;
        claimType : Text;
        context : ?Text;
        source : ?Text;
    };

    // Stable storage
    stable var claimsEntries : [(Text, Claim)] = [];
    var claims = HashMap.HashMap<Text, Claim>(0, Text.equal, Text.hash);

    // Configuration
    let MAX_TEXT_LENGTH = 5000; // 5000 characters
    let MAX_BLOB_SIZE = 3_000_000; // 3MB
    let VALID_URL_PREFIXES = ["http://", "https://"];

    // Canister references
    let aiCanister = actor ("AI_IntegrationCanister") : actor {
        generateQuestions : (claim : {
            id : Text;
            content : Text;
            claimType : Text;
            source : ?Text;
            context : ?Text;
        }) -> async Result.Result<{
            claimId : Text;
            questions : [Text];
            explanations : [Text];
        }, Text>;
    };

    let dispatchCanister = actor ("AletheianDispatchCanister") : actor {
        assignClaim : (claim : {
            id : Text;
            content : Text;
            claimType : Text;
            tags : [Text];
            locationHint : ?Text;
            timestamp : Int;
        }) -> async Result.Result<[Principal], Text>;
    };

    let notificationCanister = actor ("NotificationCanister") : actor {
        sendNotification : (userId : Principal, title : Text, message : Text, notifType : Text) -> async Nat;
    };

    let userAccountCanister = actor ("UserAccountCanister") : actor {
        recordActivity : (userId : Principal, activity : {
            claimId : Text;
            timestamp : Int;
            activityType : { #claimSubmitted; #factChecked; #learningCompleted };
        }) -> async ();
    };

    system func preupgrade() {
        claimsEntries := Iter.toArray(claims.entries());
    };

    system func postupgrade() {
        claims := HashMap.fromIter<Text, Claim>(claimsEntries.vals(), 0, Text.equal, Text.hash);
        claimsEntries := [];
    };

    // Submit a new claim with enhanced type handling
    public shared ({caller}) func submitClaim(submission : ClaimSubmission) : async ClaimResult {
        try {
            // Validate claim type with proper switch syntax
            let claimType = switch (submission.claimType) {
                case "text" { #text };
                case "image" { #image };
                case "video" { #video };
                case "audio" { #audio };
                case "articleLink" { #articleLink };
                case "fakeNewsUrl" { #fakeNewsUrl };
                case "other" { #other };
                case (_) { throw Error.reject("Invalid claim type") };
            };

            // Validate content based on type
            let validatedContent = switch (submission.content) {
                case (#text(t)) {
                    if (t.size() > MAX_TEXT_LENGTH) {
                        throw Error.reject("Text exceeds maximum length of " # Int.toText(MAX_TEXT_LENGTH) # " characters");
                    };
                    #text(t);
                };
                case (#blob(b)) {
                    if (b.size() > MAX_BLOB_SIZE) {
                        throw Error.reject("File exceeds size limit of " # Int.toText(MAX_BLOB_SIZE) # " bytes");
                    };
                    #blob(b);
                };
                case (#url(u)) {
                    if (not isValidUrl(u)) {
                        throw Error.reject("Invalid URL format. Must start with http:// or https://");
                    };
                    #url(u);
                };
            };

            // Generate unique ID
            let claimId = generateId(caller);

            // Calculate hash for files (stubbed for Motoko 0.9.8)
            let fileHash = switch (validatedContent) {
                case (#blob(b)) {
                    // TODO: Implement SHA256 hashing for Motoko 0.9.8 or plug in a compatible library
                    ?"placeholder_hash";
                };
                case _ { null };
            };

            // Create claim object
            let newClaim : Claim = {
                id = claimId;
                userId = caller;
                content = validatedContent;
                claimType = claimType;
                context = submission.context;
                source = submission.source;
                timestamp = Time.now();
                status = "submitted";
                fileHash = fileHash;
            };

            // Store claim
            claims.put(claimId, newClaim);

            // Store blob in decentralized storage if needed
            switch (validatedContent) {
                case (#blob(b)) {
                    switch (fileHash) {
                        case (?hash) {
                            ignore await storageCanister.storeBlob(hash, b);
                        };
                        case null {};
                    };
                };
                case _ {};
            };

            // Initiate AI question generation
            let claimForAI = {
                id = claimId;
                content = switch (validatedContent) {
                    case (#text(t)) { t };
                    case (#url(u)) { u };
                    case (#blob(_)) { "Media file uploaded" };
                };
                claimType = submission.claimType;
                source = submission.source;
                context = submission.context;
            };
            ignore await aiCanister.generateQuestions(claimForAI);
            ignore await notificationCanister.sendNotification(caller, "Claim Received", "Claim received. Processing...", "claim_update");

            // Dispatch to Aletheians
            let claimForDispatch = {
                id = claimId;
                content = switch (validatedContent) {
                    case (#text(t)) { t };
                    case (#url(u)) { u };
                    case (#blob(_)) { "Media file" };
                };
                claimType = submission.claimType;
                tags = [];
                locationHint = null;
                timestamp = Time.now();
            };
            let dispatchResult = await dispatchCanister.assignClaim(claimForDispatch);
            switch (dispatchResult) {
                case (#err(msg)) { throw Error.reject("Failed to dispatch claim: " # msg) };
                case (#ok(_)) {};
            };

            // Record activity
            await userAccountCanister.recordActivity(caller, {
                claimId = claimId;
                timestamp = Time.now();
                activityType = #claimSubmitted;
            });

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

    // Helper functions
    func generateId(userId : Principal) : Text {
        let random = Int.toText(Time.now() % 1_000_000);
        Principal.toText(userId) # "-" # random;
    };

    func isValidUrl(url : Text) : Bool {
        var found = false;
        for (prefix in VALID_URL_PREFIXES.vals()) {
            if (Text.startsWith(url, #text prefix)) { found := true };
        };
        found
    };

    // Get claim by ID (user can only access their own claims)
    public shared query ({caller}) func getClaim(claimId : Text) : async Result.Result<Claim, Text> {
        switch (claims.get(claimId)) {
            case (?claim) {
                if (claim.userId != caller) {
                    #err("Unauthorized access");
                } else {
                    #ok(claim);
                }
            };
            case null #err("Claim not found");
        }
    };

    // Get claim content for verification (Aletheians can access)
    public shared ({caller}) func getClaimContent(claimId : Text) : async Result.Result<ClaimContent, Text> {
        // Authorization should be added for Aletheians in actual implementation
        switch (claims.get(claimId)) {
            case (?claim) #ok(claim.content);
            case null #err("Claim not found");
        }
    };
    
    // Hex encoding module for SHA256 output
    module Hex {
        public func encode(array : [Nat8]) : Text {
            var text = "";
            for (byte in array.vals()) {
                text := text # toChar(byte >> 4) # toChar(byte & 0x0F);
            };
            text;
        };

        func toChar(n : Nat8) : Text {
            let chars = "0123456789abcdef";
            let iter = Text.toIter(chars);
            var arr : [var Char] = [var '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0'];
            var i = 0;
            label l for (c in iter) {
                if (i < 16) { arr[i] := c; i += 1 } else { break l };
            };
            Text.fromChar(arr[Nat8.toNat(n)]);
        };
    };
};