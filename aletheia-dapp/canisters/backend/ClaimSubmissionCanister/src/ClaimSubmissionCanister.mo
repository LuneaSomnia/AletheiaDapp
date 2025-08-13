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
    // Import common types
    import T "mo:base/Text";
    import Types "../common/Types";
    
    // Configuration
    let MAX_TEXT_LENGTH = 5000; // 5000 characters
    let MAX_RETRIES = 3;
    let RETRY_DELAY_NS = 300_000_000_000; // 5 minutes in nanoseconds
    
    // Stable storage
    stable var dataVersion : Nat = 1;
    stable var claimsEntries : [(Text, Types.Claim)] = [];
    stable var retryQueueEntries : [(Text, (Nat, Int))] = []; // (claimId, (retryCount, nextAttempt))
    
    let claims = HashMap.HashMap<Text, Types.Claim>(0, T.equal, T.hash);
    let retryQueue = HashMap.HashMap<Text, (Nat, Int)>(0, T.equal, T.hash);

    type ClaimResult = Result.Result<Text, Text>;
    type ClaimSubmission = {
        content : { #text : Text; #blob : Blob; #url : Text };
        claimType : Text;
        context : ?Text;
        source : ?Text;
    };
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
        retryQueueEntries := Iter.toArray(retryQueue.entries());
    };

    system func postupgrade() {
        claims := HashMap.fromIter<Text, Types.Claim>(claimsEntries.vals(), 0, T.equal, T.hash);
        retryQueue := HashMap.fromIter<Text, (Nat, Int)>(retryQueueEntries.vals(), 0, T.equal, T.hash);
        claimsEntries := [];
        retryQueueEntries := [];
    };

    // Background task to retry failed operations
    public func retryFailedOperations() : async () {
        let now = Time.now();
        for ((claimId, (count, nextAttempt)) in retryQueue.entries()) {
            if (now >= nextAttempt) {
                try {
                    await processClaim(claimId);
                    retryQueue.delete(claimId);
                } catch (e) {
                    let newCount = count + 1;
                    if (newCount >= MAX_RETRIES) {
                        // Mark claim as failed
                        switch (claims.get(claimId)) {
                            case (?claim) {
                                claims.put(claimId, { claim with status = #Rejected });
                            };
                            case null {};
                        };
                        retryQueue.delete(claimId);
                    } else {
                        retryQueue.put(claimId, (newCount, now + RETRY_DELAY_NS));
                    };
                };
            };
        };
    };

    func processClaim(claimId : Text) : async () {
        // Implementation would retry AI and Dispatch calls
        // Update status and handle errors
    };

    // Submit a new claim with enhanced type handling
    public shared ({caller}) func submitClaim(submission : ClaimSubmission) : async ClaimResult {
        try {
            // Validate claim type with proper switch syntax
            let claimType : Types.ClaimType = switch (submission.claimType) {
                case "text" #Text;
                case "image" #Image;
                case "video" #Video;
                case "audio" #Audio;
                case "url" #URL;
                case "fakeSite" #FakeSite;
                case "other" #Other("");
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

            // Generate cryptographic ID
            let claimId = await generateClaimId();
            
            // Get anonymous ID from UserAccountCanister
            let anonymousId = await userAccountCanister.getAnonymousId();
            
            // Sanitize and store content
            let (contentHash, text) = switch (submission.content) {
                case (#text(t)) {
                    let cleanText = sanitizeText(t);
                    (null, ?cleanText)
                };
                case (#blob(b)) {
                    if (b.size() > MAX_BLOB_SIZE) {
                        throw Error.reject("File exceeds size limit of " # Nat.toText(MAX_BLOB_SIZE) # " bytes");
                    };
                    let cid = await IPFS_Adapter.upload(b);
                    (?cid, null)
                };
                case (#url(u)) {
                    if (not isValidUrl(u)) {
                        throw Error.reject("Invalid URL format");
                    };
                    (null, ?sanitizeText(u))
                };
            };

            // Create claim object
            let newClaim : Types.Claim = {
                id = claimId;
                submitter = caller;
                anonymousSubmitterId = Option.get(anonymousId, "");
                claimType = claimType;
                text = text;
                contentHash = contentHash;
                sourceUrl = submission.source;
                tags = [];
                status = #Pending;
                createdAt = Time.now();
                updatedAt = Time.now();
                assignedAletheians = [];
                aiQuestions = null;
                metadata = [];
                retryCount = 0;
            };

            // Store claim
            claims.put(claimId, newClaim);

            // Store blob in decentralized storage if needed
            switch (validatedContent) {
                case (#blob(b)) {
                    switch (fileHash) {
                        case (?cid) {
                            // Store to IPFS
                            ignore await IPFS_Adapter.upload(b);
                        };
                        case null {};
                    };
                };
                case _ {};
            };

            // Store claim first to ensure we have it before downstream calls
            claims.put(claimId, newClaim);
            
            // Async processing with error handling
            try {
                // Initiate AI question generation
                let aiResult = await aiCanister.generateQuestions({
                    id = claimId;
                    content = switch (text) {
                        case (?t) t;
                        case null "Media file: " # Option.get(contentHash, "");
                    };
                    claimType = submission.claimType;
                    source = submission.source;
                    context = submission.context;
                });
                
                // Update with AI results
                let updatedClaim = {
                    newClaim with
                    aiQuestions = switch (aiResult) {
                        case (#ok(q)) ?q.questions;
                        case (#err(_)) null;
                    };
                    status = #Assigned;
                    updatedAt = Time.now();
                };
                claims.put(claimId, updatedClaim);

                // Dispatch to Aletheians
                let dispatchResult = await dispatchCanister.assignClaim({
                    id = claimId;
                    content = Option.get(text, "");
                    claimType = submission.claimType;
                    tags = [];
                    locationHint = null;
                    timestamp = Time.now();
                });
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
    func generateClaimId() : async Text {
        let random = await Random.blob();
        let bytes = Blob.toArray(random);
        let hashBytes = Array.tabulate<Nat8>(16, func(i) { 
            if (i < bytes.size()) bytes[i] else 0 
        });
        Hex.encode(hashBytes)
    };

    // Robust input sanitization
    func sanitizeText(input : Text) : Text {
        let strippedHtml = T.replace(input, #regex("<[^>]*>"), "");
        let normalized = T.map(strippedHtml, func (c : Char) {
            if (Char.isWhitespace(c)) ' ' else c
        });
        let trimmed = T.trim(normalized, #char ' ');
        T.slice(trimmed, 0, MAX_TEXT_LENGTH)
    };

    func isValidUrl(url : Text) : Bool {
        let sanitized = T.trim(url, #char ' ');
        if (T.size(sanitized) > 200) return false;
        T.startsWith(sanitized, #text "http://") or T.startsWith(sanitized, #text "https://")
    };

    func generateClaimId() : async Text {
        let random = await Random.blob();
        let bytes = Blob.toArray(random);
        let hashBytes = Array.tabulate<Nat8>(16, func(i) { 
            if (i < bytes.size()) bytes[i] else 0 
        });
        Hex.encode(hashBytes)
    };

    // Get claim by ID (user can only access their own claims)
    public shared query ({caller}) func getClaim(claimId : Text) : async Result.Result<Types.Claim, Text> {
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
