import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";

actor FactLedgerCanister {
    // --- Configuration and Permissions ---
    private stable var controller : Principal = Principal.fromText("aaaaa-aa"); // Initial placeholder
    private stable var authorizedCallers : [(Principal, Bool)] = [];
    private stable var dataVersion : Nat = 1;
    
    // --- Core Data Types ---
    public type ClaimId = Text;
    public type AnonymousId = Text;
    
    public type FactEntry = {
        claimId : ClaimId;
        version : Nat;
        timestamp : Int;
        verdict : Bool;
        evidenceHashes : [Text];
        aletheianIds : [AnonymousId];
    };

    // Temporary storage for claim text matching (stub implementation)
    private stable var claimTextEntries : [(ClaimId, Text)] = [];
    private var claimTextMap = HashMap.HashMap<ClaimId, Text>(1, Text.equal, Text.hash);

    public type Evidence = {
        hash : Text;          // Content hash (IPFS CID or similar)
        storageType : Text;   // "IPFS", "Arweave", "HTTPS", etc.
        url : ?Text;          // Optional access URL
        timestamp : Int;
        provider : Principal; // Submitter principal
    };

    public type Verdict = {
        classification : ClaimClassification; // Granular classification
        timestamp : Int;
        verifier : Principal;                 // Aletheian principal
        explanation : Text;
    };

    public type FactVersion = {
        version : Nat;
        previousVersion : ?FactId;
        timestamp : Int;
    };

    public type PublicProof = {
        proofType : Text;     // e.g., "ALETHEIA_CONSENSUS"
        content : Text;       // Proof metadata or signature
    };

    public type Fact = {
        id : FactId;
        content : Text;
        status : FactStatus;
        claimClassification : ?ClaimClassification; // Final classification
        evidence : [Evidence];
        verdicts : [Verdict];                      // Individual verdicts
        version : FactVersion;
        publicProof : PublicProof;
        created : Int;
        lastUpdated : Int;
    };

    public type AddFactRequest = {
        content : Text;
        evidence : [Evidence];
        publicProof : PublicProof;
    };

    public type UpdateFactRequest = {
        id : FactId;
        newContent : Text;
        newStatus : FactStatus;
        newClaimClassification : ?ClaimClassification;
        newEvidence : [Evidence];
        newVerdicts : [Verdict];
        newPublicProof : PublicProof;
    };

    // Stable variables for canister upgrades
    // --- Versioned Fact History Storage ---
    stable var factHistoryEntries : [(ClaimId, [FactEntry])] = [];
    private var factHistory = HashMap.HashMap<ClaimId, [FactEntry]>(1, Text.equal, Text.hash);
    
    // --- Authorized Callers Storage ---
    private stable var authorizedCallers : [(Principal, Bool)] = [];
    private var authCallers = HashMap.fromIter<Principal, Bool>(
        authorizedCallers.vals(), 
        1, 
        Principal.equal, 
        Principal.hash
    );

    // System initialization after upgrade
    system func preupgrade() {
        factHistoryEntries := Iter.toArray(factHistory.entries());
        authorizedCallers := Iter.toArray(authCallers.entries());
        claimTextEntries := Iter.toArray(claimTextMap.entries());
    };

    system func postupgrade() {
        factHistory := HashMap.fromIter<Text, [FactEntry]>(
            factHistoryEntries.vals(), 
            1, 
            Text.equal, 
            Text.hash
        );
        authCallers := HashMap.fromIter<Principal, Bool>(
            authorizedCallers.vals(), 
            0, 
            Principal.equal, 
            Principal.hash
        );
        claimTextMap := HashMap.fromIter<Text, Text>(
            claimTextEntries.vals(),
            1,
            Text.equal,
            Text.hash
        );
        factHistoryEntries := [];
        authorizedCallers := [];
        claimTextEntries := [];
    };

    // --- Admin Functions ---
    public shared (msg) func authorizeCaller(principal: Principal) : async () {
        assert msg.caller == controller;
        authCallers.put(principal, true);
    };

    public shared (msg) func revokeCaller(principal: Principal) : async () {
        assert msg.caller == controller;
        authCallers.delete(principal);
    };

    // --- Core API ---
    public shared (msg) func appendVersion(
        claimId: Text,
        verdict: Bool,
        evidenceHashes: [Text],
        aletheianIds: [Text]
    ) : async Result.Result<FactEntry, Text> {
        // Authorization check
        if (not authCallers.get(msg.caller)) {
            return #err("Unauthorized caller");
        };

        let currentTime = Time.now();
        let existingEntries = Option.get(factHistory.get(claimId), []);
        let newVersion = existingEntries.size() + 1;

        let newEntry : FactEntry = {
            claimId = claimId;
            version = newVersion;
            timestamp = currentTime;
            verdict = verdict;
            evidenceHashes = evidenceHashes;
            aletheianIds = aletheianIds;
        };

        factHistory.put(claimId, Array.append(existingEntries, [newEntry]));
        #ok(newEntry)
    };

    public shared (msg) func storeOriginalClaimText(claimId: Text, text: Text) : async Result.Result<(), Text> {
        // Authorization check
        if (not authCallers.get(msg.caller)) {
            return #err("Unauthorized caller");
        };

        if (claimTextMap.get(claimId) != null) {
            return #err("Claim text already stored");
        };

        claimTextMap.put(claimId, text);
        #ok(())
    };

    // --- Query API ---
    public query func queryByClaimText(queryText: Text) : async [Text] {
        let matches = Buffer.Buffer<Text>(0);
        for ((id, text) in claimTextMap.entries()) {
            if (Text.contains(text, #text queryText)) {
                matches.add(id);
            }
        };
        Buffer.toArray(matches)
    };

    public query func readFullHistory(claimId: Text) : async ?[FactEntry] {
        factHistory.get(claimId)
    };

    // --- Maintenance API ---
    public query func getDataVersion() : async Nat {
        dataVersion
    };

    // Query methods
    public query func getFact(id : FactId) : async ?Fact {
        facts.get(id)
    };

    public query func getAllFacts() : async [Fact] {
        Iter.toArray(facts.vals())
    };

    public query func getFactHistory(id : FactId) : async ?[Fact] {
        switch (factVersions.get(id)) {
            case (null) { null };
            case (?versionIds) {
                // Fixed: Using buffer for safe index access
                let buffer = Buffer.Buffer<Fact>(0);
                for (vid in versionIds.vals()) {
                    switch (facts.get(vid)) {
                        case (?fact) { buffer.add(fact) };
                        case null { };
                    };
                };
                ?Buffer.toArray(buffer)
            };
        }
    };

};
