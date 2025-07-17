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
    public type FactId = Nat;
    
    public type FactStatus = {
        #PendingReview;
        #Verified;
        #Disputed;
        #Deprecated;
    };

    public type ClaimClassification = {
        // Factual Accuracy Verdicts
        #True;
        #MostlyTrue;
        #HalfTruth;
        #MisleadingContext;
        #False;
        #MostlyFalse;
        #Unsubstantiated;
        #Outdated;
        // Intent/Origin/Style Classifications
        #Misinformation;
        #Disinformation;
        #Satire;
        #Opinion;
        #Propaganda;
        #FabricatedContent;
        #ImposterContent;
        #ManipulatedContent;
        #Deepfake;
        #ConspiracyTheory;
        // Other classifications can be added here
    };

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
    stable var nextId : FactId = 1;
    stable var factsEntries : [(FactId, Fact)] = [];
    stable var versionHistory : [(FactId, [FactId])] = [];

    // In-memory storage
    private var facts = HashMap.HashMap<FactId, Fact>(
        0, 
        Nat.equal, 
        Hash.hash
    );

    private var factVersions = HashMap.HashMap<FactId, [FactId]>(
        0,
        Nat.equal,
        Hash.hash
    );

    // System initialization after upgrade
    system func preupgrade() {
        factsEntries := Iter.toArray(facts.entries());
        versionHistory := Iter.toArray(factVersions.entries());
    };

    system func postupgrade() {
        facts := HashMap.fromIter<FactId, Fact>(
            factsEntries.vals(), 
            0, 
            Nat.equal, 
            Hash.hash
        );
        factVersions := HashMap.fromIter<FactId, [FactId]>(
            versionHistory.vals(),
            0,
            Nat.equal,
            Hash.hash
        );
        factsEntries := [];
        versionHistory := [];
    };

    // Add a new fact to the ledger
    public shared (msg) func addFact(request : AddFactRequest) : async Result.Result<Fact, Text> {
        let currentTime = Time.now();
        let newId = nextId;

        let newFact : Fact = {
            id = newId;
            content = request.content;
            status = #PendingReview;
            claimClassification = null;
            evidence = request.evidence;
            verdicts = [];
            version = {
                version = 1;
                previousVersion = null;
                timestamp = currentTime;
            };
            publicProof = request.publicProof;
            created = currentTime;
            lastUpdated = currentTime;
        };

        facts.put(newId, newFact);
        factVersions.put(newId, [newId]);
        nextId += 1;

        #ok(newFact)
    };

    // Create a new version of an existing fact
    public shared (msg) func updateFact(request : UpdateFactRequest) : async Result.Result<Fact, Text> {
        switch (facts.get(request.id)) {
            case (null) { #err("Fact not found") };
            case (?currentFact) {
                let currentTime = Time.now();
                let newId = nextId;

                // Create new version of the fact
                let updatedFact : Fact = {
                    id = newId;
                    content = request.newContent;
                    status = request.newStatus;
                    claimClassification = request.newClaimClassification;
                    evidence = request.newEvidence;
                    verdicts = request.newVerdicts;
                    version = {
                        version = currentFact.version.version + 1;
                        previousVersion = ?currentFact.id;
                        timestamp = currentTime;
                    };
                    publicProof = request.newPublicProof;
                    created = currentFact.created;
                    lastUpdated = currentTime;
                };

                // Update storage
                facts.put(newId, updatedFact);
                
                // Update version history
                let currentHistory = Option.get(factVersions.get(request.id), [request.id]);
                let newHistory = Array.append(currentHistory, [newId]);
                factVersions.put(request.id, newHistory);
                
                nextId += 1;

                #ok(updatedFact)
            };
        }
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

    public query func getFactsByStatus(status : FactStatus) : async [Fact] {
        Iter.toArray(
            Iter.filter(
                facts.vals(),
                func(fact : Fact) : Bool { fact.status == status }
            )
        )
    };

    public query func getFactsByClassification(classification : ClaimClassification) : async [Fact] {
        Iter.toArray(
            Iter.filter(
                facts.vals(),
                func(fact : Fact) : Bool {
                    switch (fact.claimClassification) {
                        case (?cc) { cc == classification };
                        case null { false };
                    }
                }
            )
        )
    };

    // Additional helper methods
    public query func getFactCount() : async Nat {
        facts.size()
    };

    public query func getLatestVersion(id : FactId) : async ?Fact {
        switch (factVersions.get(id)) {
            case (null) { null };
            case (?versions) {
                let lastIndex = versions.size() - 1;
                if (lastIndex >= 0) {
                    facts.get(versions[lastIndex])
                } else {
                    null
                }
            };
        }
    };
};