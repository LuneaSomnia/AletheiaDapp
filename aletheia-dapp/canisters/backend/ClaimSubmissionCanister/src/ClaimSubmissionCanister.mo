import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import SHA256 "mo:sha256/SHA256";

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
    let claims = HashMap.HashMap<Text, Claim>(0, Text.equal, Text.hash);

    // Configuration
    let MAX_TEXT_LENGTH = 5000; // 5000 characters
    let MAX_BLOB_SIZE = 3_000_000; // 3MB
    let VALID_URL_PREFIXES = ["http://", "https://"];

    // Canister references
    let aiCanister : actor {
        generateQuestions : (claimId : Text) -> async Text;
    } = actor ("aiaaa-aaaaa-aaaab-qai4q-cai");

    let dispatchCanister : actor {
        assignClaim : (claimId : Text) -> async Bool;
    } = actor ("dtcaa-aaaaa-aaaab-qai5q-cai");

    let notificationCanister : actor {
        notifyUser : (userId : Principal, message : Text) -> async Bool;
    } = actor ("ntfaa-aaaaa-aaaab-qai6q-cai");

    let storageCanister : actor {
        storeBlob : (hash : Text, blob : Blob) -> async Bool;
    } = actor ("stgaa-aaaaa-aaaab-qaiaa-cai");

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
            // Validate claim type
            let claimType = switch (submission.claimType) {
                case "text" #text;
                case "image" #image;
                case "video" #video;
                case "audio" #audio;
                case "articleLink" #articleLink;
                case "fakeNewsUrl" #fakeNewsUrl;
                case "other" #other;
                case _ throw Error.reject("Invalid claim type");
            };

            // Validate content based on type
            let validatedContent = switch (submission.content) {
                case (#text(t)) {
                    if (t.size() > MAX_TEXT_LENGTH) {
                        throw Error.reject("Text exceeds maximum length");
                    };
                    #text(t);
                };
                case (#blob(b)) {
                    if (b.size() > MAX_BLOB_SIZE) {
                        throw Error.reject("File exceeds 3MB limit");
                    };
                    #blob(b);
                };
                case (#url(u)) {
                    if (not isValidUrl(u)) {
                        throw Error.reject("Invalid URL format");
                    };
                    #url(u);
                };
            };

            // Generate unique ID
            let claimId = generateId(caller);

            // Calculate hash for files
            let fileHash = switch (validatedContent) {
                case (#blob(b)) ?(SHA256.fromBlob(#sha224, b).toText())
                case _ null;
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
            ignore await aiCanister.generateQuestions(claimId);
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

    // Helper functions
    func generateId(userId : Principal) : Text {
        let random = (Time.now() % 1000000).toText();
        Principal.toText(userId) # "-" # random;
    };

    func isValidUrl(url : Text) : Bool {
        Array.some(VALID_URL_PREFIXES, func (prefix : Text) : Bool {
            Text.startsWith(url, #text prefix)
        });
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
        // In actual implementation, add authorization check for Aletheians
        switch (claims.get(claimId)) {
            case (?claim) #ok(claim.content);
            case null #err("Claim not found");
        }
    };
};