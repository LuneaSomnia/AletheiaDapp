import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Iter "mo:base/Iter";

actor FactLedgerCanister {
    public type FactId = Nat;
    
    public type Classification = {
        #Verified;
        #Disputed;
        #PendingReview;
        #Deprecated;
    };

    public type Evidence = {
        content : Text;
        timestamp : Int;
        provider : Principal;
    };

    public type Verdict = {
        decision : Bool; // true = accepted, false = rejected
        timestamp : Int;
        verifier : Principal;
        explanation : Text;
    };

    public type FactVersion = {
        version : Nat;
        previousVersion : ?FactId;
        timestamp : Int;
    };

    public type PublicProof = {
        proofType : Text;
        content : Text;
    };

    public type Fact = {
        id : FactId;
        content : Text;
        classification : Classification;
        evidence : [Evidence];
        verdicts : [Verdict];
        version : FactVersion;
        publicProof : PublicProof;
        created : Int;
        lastUpdated : Int;
    };

    public type AddFactRequest = {
        content : Text;
        classification : Classification;
        evidence : [Evidence];
        publicProof : PublicProof;
    };

    public type UpdateFactRequest = {
        id : FactId;
        newContent : Text;
        newClassification : Classification;
        newEvidence : [Evidence];
        newPublicProof : PublicProof;
    };

    public type AddVerdictRequest = {
        factId : FactId;
        decision : Bool;
        explanation : Text;
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
            classification = request.classification;
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
        let caller = msg.caller;
        switch (facts.get(request.id)) {
            case (null) { #err("Fact not found") };
            case (?currentFact) {
                // Verify caller is the original creator (optional security check)
                // if (Principal.notEqual(caller, currentFact.creator)) {
                //     return #err("Unauthorized: Only fact creator can update");
                // }

                let currentTime = Time.now();
                let newId = nextId;

                // Create new version of the fact
                let updatedFact : Fact = {
                    id = newId;
                    content = request.newContent;
                    classification = request.newClassification;
                    evidence = request.newEvidence;
                    verdicts = []; // Reset verdicts for new version
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
                let currentHistory = Option.get(factVersions.get(currentFact.id), [currentFact.id]);
                let newHistory = Array.append(currentHistory, [newId]);
                factVersions.put(currentFact.id, newHistory);
                
                nextId += 1;

                #ok(updatedFact)
            };
        }
    };

    // Add a verdict to a fact
    public shared (msg) func addVerdict(request : AddVerdictRequest) : async Result.Result<Fact, Text> {
        switch (facts.get(request.factId)) {
            case (null) { #err("Fact not found") };
            case (?fact) {
                let caller = msg.caller;
                let currentTime = Time.now();

                let newVerdict : Verdict = {
                    decision = request.decision;
                    timestamp = currentTime;
                    verifier = caller;
                    explanation = request.explanation;
                };

                // Add to existing verdicts
                let updatedVerdicts = Array.append(fact.verdicts, [newVerdict]);
                
                // Determine new classification based on verdicts
                let acceptedCount = Array.filter(updatedVerdicts, func(v : Verdict) : Bool { v.decision }).size();
                let rejectedCount = updatedVerdicts.size() - acceptedCount;
                
                let newClassification = if (acceptedCount >= 3 and acceptedCount > rejectedCount * 2) {
                    #Verified
                } else if (rejectedCount >= 3 and rejectedCount > acceptedCount * 2) {
                    #Disputed
                } else {
                    #PendingReview
                };

                let updatedFact : Fact = {
                    id = fact.id;
                    content = fact.content;
                    classification = newClassification;
                    evidence = fact.evidence;
                    verdicts = updatedVerdicts;
                    version = fact.version;
                    publicProof = fact.publicProof;
                    created = fact.created;
                    lastUpdated = currentTime;
                };

                facts.put(fact.id, updatedFact);
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
                Array.mapFilter(versionIds, func(id : FactId) : ?Fact { facts.get(id) })
            };
        }
    };

    public query func getFactsByClassification(classification : Classification) : async [Fact] {
        Iter.toArray(
            Iter.filter(
                facts.vals(),
                func(fact : Fact) : Bool { fact.classification == classification }
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
                facts.get(versions[lastIndex])
            };
        }
    };
};