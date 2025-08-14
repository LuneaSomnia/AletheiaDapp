import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import _ "mo:base/List";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Error "mo:base/Error";

actor AletheianDispatchCanister {
    // Configuration constants
    let TARGET_ALETHEIANS_PER_CLAIM = 3;
    let SELECTION_TIMEOUT_NS = 5_000_000_000; // 5 seconds
    let COOLDOWN_PERIOD_NS = 3600_000_000_000; // 1 hour
    let MAX_EVENTS = 1000;
    
    // Stable storage with versioning
    stable var dataVersion : Nat = 1;
    stable var controller : Principal = caller;
    stable var profileCanister : Principal = Principal.fromText("aaaaa-aa");
    stable var verificationCanister : Principal = Principal.fromText("aaaaa-aa");
    stable var notificationCanister : Principal = Principal.fromText("aaaaa-aa");
    stable var authorizedCallers : [Principal] = [];
    stable var assignmentsEntries : [(Text, Assignment)] = [];
    stable var events : [Text] = [];
    stable var lastAssignedEntries : [(Principal, Int)] = [];

    let assignments = HashMap.HashMap<Text, Assignment>(0, Text.equal, Text.hash);
    let lastAssigned = HashMap.HashMap<Principal, Int>(0, Principal.equal, Principal.hash);

    type ClaimMeta = {
        category : Text;
        geo : ?Text;
        complexity : Nat;
        tags : [Text];
    };

    type AssignmentStatus = {
        #Pending;
        #Assigned;
        #PartiallyAssigned;
        #Failed;
    };

    type Assignment = {
        claimId : Text;
        createdAt : Int;
        selected : [Principal];
        scores : [(Principal, Nat)];
        status : AssignmentStatus;
        notes : ?Text;
    };

    type AssignmentResult = Result.Result<[Principal], Text>;

    // Stable storage
    stable var profilesEntries : [(Principal, AletheianProfile)] = [];
    stable var assignmentsEntries : [(Text, [Principal])] = [];
    
    let profiles = HashMap.HashMap<Principal, AletheianProfile>(0, Principal.equal, Principal.hash);
    let assignments = HashMap.HashMap<Text, [Principal]>(0, Text.equal, Text.hash);

    // Admin management
    public shared({ caller }) func setController(newController : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized");
        };
        controller := newController;
        #ok(())
    };

    public shared({ caller }) func setProfileCanister(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized");
        };
        profileCanister := p;
        #ok(())
    };

    public shared({ caller }) func setVerificationCanister(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized");
        };
        verificationCanister := p;
        #ok(())
    };

    public shared({ caller }) func setNotificationCanister(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized");
        };
        notificationCanister := p;
        #ok(())
    };

    public shared({ caller }) func authorizeCaller(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized");
        };
        if (not Array.find<Principal>(authorizedCallers, func(principal) { principal == p }) != null) {
            authorizedCallers := Array.append(authorizedCallers, [p]);
        };
        #ok(())
    };

    public shared({ caller }) func revokeCaller(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized");
        };
        authorizedCallers := Array.filter<Principal>(authorizedCallers, func(principal) { principal != p });
        #ok(())
    };

    let verificationWorkflow = actor ("VerificationWorkflowCanister") : actor {
        createTask : (claimId : Text, aletheians : [Principal]) -> async Result.Result<(), Text>;
    };

    let notification = actor ("NotificationCanister") : actor {
        sendNotification : (userId : Principal, title : Text, message : Text, notifType : Text) -> async Nat;
    };

    system func preupgrade() {
        profilesEntries := Iter.toArray(profiles.entries());
        assignmentsEntries := Iter.toArray(assignments.entries());
    };

   system func postupgrade() {
    for (id in profiles.keys()) {
        profiles.delete(id);
    };
    for ((id, profile) in profilesEntries.vals()) {
        profiles.put(id, profile);
    };
    for (claimId in assignments.keys()) {
        assignments.delete(claimId);
    };
    for ((claimId, aletheians) in assignmentsEntries.vals()) {
        assignments.put(claimId, aletheians);
    };
    profilesEntries := [];
    assignmentsEntries := [];
};

    // Main dispatch function
    public shared func assignClaim(claim : Claim) : async AssignmentResult {
        try {
            // Get all eligible Aletheians
            let candidates = Buffer.Buffer<AletheianProfile>(0);
            for (profile in profiles.vals()) {
                if (isEligible(profile)) {
                    candidates.add(profile);
                }
            };

            if (candidates.size() < 3) {
                return #err("Insufficient eligible Aletheians");
            };

            // Score and sort candidates
            let scored = Buffer.map<AletheianProfile, (AletheianProfile, Nat)>(candidates, func(p) {
                (p, calculateScore(p, claim))
            });
            scored.sort(func(a, b) { Nat.compare(b.1, a.1) });

            // Select top 3 unique profiles
            let selected = selectAletheians(scored, claim);

            if (selected.size() < 3) {
                return #err("Failed to find 3 qualified Aletheians");
            };

            // Update assignments and workloads
            assignments.put(claim.id, Buffer.toArray(selected));
            
            // Create verification task
            let taskResult = await verificationWorkflow.createTask(claim.id, Buffer.toArray(selected));
            switch (taskResult) {
                case (#err(msg)) { return #err("Failed to create verification task: " # msg) };
                case (#ok()) {};
            };

            // Notify assigned Aletheians
            for (aletheianId in selected.vals()) {
                ignore await notification.sendNotification(
                    aletheianId,
                    "New Claim Assignment",
                    "You have been assigned a new claim to verify: " # claim.id,
                    "new_assignment"
                );
            };

            #ok(Buffer.toArray(selected));
        } catch (e) {
            #err("Assignment failed: " # Error.message(e));
        }
    };

    // Eligibility check
    func isEligible(profile : AletheianProfile) : Bool {
        profile.online and 
        profile.workload < 5 and // Max 5 concurrent claims
        Time.now() - profile.lastActive < 300_000_000_000 // 5 minutes
    };

    // Scoring algorithm
    func calculateScore(profile : AletheianProfile, claim : Claim) : Nat {
        var score : Nat = 0;
        
        // Expertise match (50% weight)
        let expertiseMatch = calculateExpertiseMatch(profile.expertise, claim.tags);
        score += expertiseMatch * 5;
        
        // Geo-relevance (20% weight)
        switch (profile.location, claim.locationHint) {
            case (?loc, ?hint) if (loc == hint) { score += 20 };
            case _ {};
        };
        
        // Workload (lower is better - 20% weight)
        score += (5 - profile.workload) * 4;
        
        // Reputation (10% weight)
        score += Nat.min(profile.reputation / 100, 10);
        
        score
    };

    func calculateExpertiseMatch(aletheianBadges : [Text], claimTags : [Text]) : Nat {
        var matches : Nat = 0;
        for (tag in claimTags.vals()) {
            if (Array.find<Text>(aletheianBadges, func(b) { b == tag }) != null) {
                matches += 1;
            }
        };
        matches
    };

    // Selection with diversity
    func selectAletheians(
        scored : Buffer.Buffer<(AletheianProfile, Nat)>,
        claim : Claim
    ) : Buffer.Buffer<Principal> {
        let selected = Buffer.Buffer<Principal>(3);

        // Step 1: If claim has location hint, pick best available local expert
        if (claim.locationHint != null) {
            for (i in Iter.range(0, scored.size() - 1)) {
                let (profile, _) = scored.get(i);
                switch (profile.location, claim.locationHint) {
                    case (?loc, ?hint) if (loc == hint) {
                        if (not Buffer.contains<Principal>(selected, profile.id, Principal.equal)) {
                            selected.add(profile.id);
                            if (selected.size() == 3) return selected;
                        };
                    };
                    case _ {};
                };
            };
        };

        // Step 2: Fill remaining spots with best overall matches
        var i = 0;
        while (i < scored.size() and selected.size() < 3) {
            let (profile, _) = scored.get(i);
            if (not Buffer.contains<Principal>(selected, profile.id, Principal.equal)) {
                selected.add(profile.id);
            };
            i += 1;
        };
        
        selected
    };

    // Update when assignment completes
    public shared func completeAssignment(claimId : Text) : async Bool {
        switch (assignments.get(claimId)) {
            case (?aletheians) {
                assignments.delete(claimId);
                true
            };
            case null false;
        }
    };

    // Profile management
    public shared ({caller}) func updateProfile(
        online : Bool,
        expertise : [Text],
        location : ?Text
    ) : async Bool {
        switch (profiles.get(caller)) {
            case (?profile) {
                let updated = {
                    profile with
                    online;
                    expertise;
                    location;
                    lastActive = Time.now();
                };
                profiles.put(caller, updated);
                true
            };
            case null false;
        }
    };

    public shared ({caller}) func registerProfile(
        expertise : [Text],
        location : ?Text
    ) : async Bool {
        let newProfile : AletheianProfile = {
            id = caller;
            online = true;
            workload = 0;
            reputation = 0;
            expertise;
            location;
            lastActive = Time.now();
        };
        profiles.put(caller, newProfile);
        true
    };
};
