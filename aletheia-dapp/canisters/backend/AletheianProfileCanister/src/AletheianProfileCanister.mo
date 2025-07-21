import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Types "../../common/Types";

// --- BREAK CIRCULAR DEPENDENCY: Use interface type for ReputationLogicCanister ---
type ReputationLogicInterface = actor {
    getReputation: (principal: Principal) -> async ?Types.VerificationResult; // Adjust type as needed
    // Add only the methods you actually call
};
// Example usage (replace with actual canister ID):
// let reputationLogic = actor ("<ReputationLogicCanister_canister_id>") : ReputationLogicInterface;

actor AletheianProfileCanister {
    type Rank = {
        #Trainee;
        #Junior;
        #Associate;
        #Senior;
        #Expert;
        #Master;
    };

    type AletheianProfile = {
        id : Principal;
        rank : Rank;
        xp : Int;  // Experience points
        expertiseBadges : [Text];  // e.g., ["Health", "Deepfake Analysis"]
        location : ?Text;  // Optional geo-location
        status : { #Active; #Suspended; #Retired };
        warnings : Nat;  // Number of warnings received
        accuracy : Float;  // Historical accuracy percentage
        claimsVerified : Nat;  // Total claims verified
        completedTraining : [Text];  // IDs of completed training modules
        createdAt : Int;  // Timestamp
        lastActive : Int;  // Timestamp
    };

    type RegistrationRequest = {
        principal : Principal;
        location : ?Text;
        testResults : [Nat];  // Scores from vetting tests
    };

    // Stable storage for upgrades
    stable var profilesEntries : [(Principal, AletheianProfile)] = [];
    stable var requestsEntries : [(Principal, RegistrationRequest)] = [];
    stable var trainingModules : [Text] = [
        "critical-thinking-101",
        "bias-identification",
        "craap-model",
        "aletheia-guidelines"
    ];

    var profiles = HashMap.HashMap<Principal, AletheianProfile>(
        0, Principal.equal, Principal.hash
    );
    
    var registrationRequests = HashMap.HashMap<Principal, RegistrationRequest>(
        0, Principal.equal, Principal.hash
    );

    // Rank thresholds based on XP
    let RANK_THRESHOLDS = [
        (0, #Junior),
        (250, #Associate),
        (750, #Senior),
        (2000, #Expert),
        (5000, #Master)
    ];

    // Training module XP rewards
    let TRAINING_XP = [
        ("critical-thinking-101", 10),
        ("bias-identification", 15),
        ("craap-model", 20),
        ("aletheia-guidelines", 25)
    ];

    // System initialization
    system func preupgrade() {
        profilesEntries := Iter.toArray(profiles.entries());
        requestsEntries := Iter.toArray(registrationRequests.entries());
    };

    system func postupgrade() {
        profiles := HashMap.fromIter<Principal, AletheianProfile>(
            profilesEntries.vals(), 0, Principal.equal, Principal.hash
        );
        registrationRequests := HashMap.fromIter<Principal, RegistrationRequest>(
            requestsEntries.vals(), 0, Principal.equal, Principal.hash
        );
        profilesEntries := [];
        requestsEntries := [];
    };

    // ======================
    // Onboarding & Vetting
    // ======================
    
    /// Step 1: Submit registration request with test results
    public shared ({ caller }) func submitRegistration(
        location : ?Text, 
        testResults : [Nat]
    ) : async Result.Result<Text, Text> {
        if (profiles.get(caller) != null) {
            return #err("You're already registered as an Aletheian");
        };
        
        if (registrationRequests.get(caller) != null) {
            return #err("Registration request already pending");
        };
        
        // Basic vetting: Must pass all training modules
        if (testResults.size() != trainingModules.size()) {
            return #err("Invalid test results format");
        };
        
        for (score in testResults.vals()) {
            if (score < 80) { // 80% passing score
                return #err("Vetting failed: Insufficient test scores");
            };
        };
        
        let request : RegistrationRequest = {
            principal = caller;
            location = location;
            testResults = testResults;
        };
        
        registrationRequests.put(caller, request);
        #ok("Registration request submitted. Awaiting approval.");
    };
    
    /// Step 2: Admin approves registration (to be called by admin)
    public shared ({ caller }) func approveRegistration(
        applicant : Principal
    ) : async Result.Result<Text, Text> {
        // In real implementation, add admin check here
        switch (registrationRequests.get(applicant)) {
            case null { #err("No registration request found") };
            case (?request) {
                // Create initial profile
                let newProfile : AletheianProfile = {
                    id = applicant;
                    rank = #Trainee;
                    xp = 0;
                    expertiseBadges = [];
                    location = request.location;
                    status = #Active;
                    warnings = 0;
                    accuracy = 100.0; // Starting accuracy
                    claimsVerified = 0;
                    completedTraining = trainingModules; // Auto-complete required training
                    createdAt = Time.now();
                    lastActive = Time.now();
                };
                
                // Award XP for completed training
                var totalXp = 0;
                for (trainingmodule in trainingModules.vals()) {
                    switch (Array.find(TRAINING_XP, func ((m, x) : (Text, Nat)) : Bool = m == trainingmodule)) {
                        case (?(_, xp)) { totalXp += xp };
                        case null {};
                    };
                };
                
                let updatedProfile = updateXp(newProfile, totalXp);
                profiles.put(applicant, updatedProfile);
                registrationRequests.delete(applicant);
                
                #ok("Aletheian approved and onboarded successfully");
            };
        };
    };
    
    // ======================
    // Reputation & XP System
    // ======================
    
    /// Update XP and automatically adjust rank
    func updateXp(profile : AletheianProfile, xpChange : Int) : AletheianProfile {
        let newXp = profile.xp + xpChange;
        let newRank = calculateRank(newXp);
        
        {
            profile with
            xp = newXp;
            rank = newRank;
            lastActive = Time.now();
        }
    };
    
    /// Calculate rank based on XP thresholds
    func calculateRank(xp : Int) : Rank {
        var currentRank : Rank = #Trainee;
        for ((threshold, rank) in RANK_THRESHOLDS.vals()) {
            if (xp >= threshold) {
                currentRank := rank;
            } else {
                return currentRank;
            };
        };
        currentRank
    };
    
    /// Public function to update XP (called by other canisters)
    public shared ({ caller }) func updateAletheianXp(
        aletheian : Principal,
        xpChange : Int,
        accuracyImpact : ?Float
    ) : async Result.Result<(), Text> {
        switch (profiles.get(aletheian)) {
            case null { #err("Aletheian not found") };
            case (?profile) {
                var updatedProfile = updateXp(profile, xpChange);
                
                // Update accuracy if provided
                updatedProfile := switch (accuracyImpact) {
                    case (?impact) {
                        let newAccuracy = 
                            (profile.accuracy * Float.fromInt(profile.claimsVerified) 
                            + impact) / Float.fromInt(profile.claimsVerified + 1);
                        { updatedProfile with 
                            claimsVerified = profile.claimsVerified + 1;
                            accuracy = newAccuracy;
                        }
                    };
                    case null updatedProfile;
                };
                
                profiles.put(aletheian, updatedProfile);
                #ok();
            };
        };
    };
    
    /// Apply warning with XP penalty
    public shared ({ caller }) func issueWarning(
        aletheian : Principal,
        severity : { #Minor; #Major }
    ) : async Result.Result<(), Text> {
        switch (profiles.get(aletheian)) {
            case null { #err("Aletheian not found") };
            case (?profile) {
                let xpPenalty = switch (severity) {
                    case (#Minor) -5;
                    case (#Major) -20;
                };
                
                let warningCount = profile.warnings + 1;
                var updatedProfile = updateXp(profile, xpPenalty);
                updatedProfile := { updatedProfile with warnings = warningCount };
                
                // Apply suspension for multiple warnings
                if (warningCount >= 3) {
                    updatedProfile := { updatedProfile with status = #Suspended };
                };
                
                profiles.put(aletheian, updatedProfile);
                #ok();
            };
        };
    };
    
    // ======================
    // Badge Management
    // ======================
    
    // Custom function to compare ranks
   func rankIsHigher(rank1: Rank, rank2: Rank): Bool {
  if (rank1 == #Master) return true;
  if (rank1 == #Expert and rank2 != #Master) return true;
  if (rank1 == #Senior and rank2 != #Master and rank2 != #Expert) return true;
  if (rank1 == #Associate and rank2 != #Master and rank2 != #Expert and rank2 != #Senior) return true;
  if (rank1 == #Junior and rank2 != #Master and rank2 != #Expert and rank2 != #Senior and rank2 != #Associate) return true;
  return false;
};

    /// Apply for an expertise badge
    public shared ({ caller }) func applyForBadge(
        badge : Text,
        evidence : [Text]  // Links to verified claims in this domain
    ) : async Result.Result<Text, Text> {
        switch (profiles.get(caller)) {
            case null { #err("Profile not found") };
            case (?profile) {
                // Check rank requirement (Senior+)
                if (not rankIsHigher(profile.rank, #Senior)) {
                    return #err("Requires Senior rank or higher");
                };
                
                // Check if already has badge
                if (Array.find(profile.expertiseBadges, func (b : Text) : Bool = b == badge) != null) {
                    return #err("Already has this badge");
                };
                
                // Basic validation - in real system would verify evidence
                if (evidence.size() < 5) { // Require 5 verified claims
                    return #err("Insufficient evidence for badge application");
                };
                
                // Add badge to profile
                let newBadges = Array.append(profile.expertiseBadges, [badge]);
                let updatedProfile = {
                    profile with
                    expertiseBadges = newBadges;
                    lastActive = Time.now();
                };
                
                profiles.put(caller, updatedProfile);
                #ok("Badge application submitted for review");
            };
        };
    };
    
    /// Admin approves badge (to be called by admin)
    public shared ({ caller }) func grantBadge(
        aletheian : Principal,
        badge : Text
    ) : async Result.Result<(), Text> {
        switch (profiles.get(aletheian)) {
            case null { #err("Aletheian not found") };
            case (?profile) {
                if (Array.find(profile.expertiseBadges, func (b : Text) : Bool = b == badge) != null) {
                    return #err("Already has this badge");
                };
                
                let newBadges = Array.append(profile.expertiseBadges, [badge]);
                let updatedProfile = {
                    profile with
                    expertiseBadges = newBadges;
                    lastActive = Time.now();
                };
                
                profiles.put(aletheian, updatedProfile);
                #ok();
            };
        };
    };
    
    // ======================
    // Profile Management
    // ======================
    
    /// Get profile (public view)
    public query func getProfile(aletheian : Principal) : async ?AletheianProfile {
        profiles.get(aletheian)
    };
    
    /// Update profile information (location only for now)
    public shared ({ caller }) func updateProfile(
        location : ?Text
    ) : async Result.Result<(), Text> {
        switch (profiles.get(caller)) {
            case null { #err("Profile not found") };
            case (?profile) {
                let updatedProfile = {
                    profile with
                    location = location;
                    lastActive = Time.now();
                };
                profiles.put(caller, updatedProfile);
                #ok();
            };
        };
    };
    
    /// Admin updates status (activate/suspend/retire)
    public shared ({ caller }) func updateStatus(
        aletheian : Principal,
        status : { #Active; #Suspended; #Retired }
    ) : async Result.Result<(), Text> {
        // In real implementation, add admin check here
        switch (profiles.get(aletheian)) {
            case null { #err("Aletheian not found") };
            case (?profile) {
                let updatedProfile = {
                    profile with
                    status = status;
                    lastActive = Time.now();
                };
                profiles.put(aletheian, updatedProfile);
                #ok();
            };
        };
    };

    /// Activity heartbeat to track availability
    public shared ({ caller }) func heartbeat() : async () {
        switch (profiles.get(caller)) {
            case null { };
            case (?profile) {
                let updatedProfile = { profile with lastActive = Time.now() };
                ignore profiles.replace(caller, updatedProfile);
            };
        };
    };
    
    // ======================
    // Query Functions
    // ======================
    
    public query func getAllAletheians() : async [AletheianProfile] {
        Iter.toArray(profiles.vals())
    };
    
    public query func getAletheiansByRank(minRank : Rank) : async [AletheianProfile] {
        let buffer = Buffer.Buffer<AletheianProfile>(0);
        for (profile in profiles.vals()) {
            if (not rankIsHigher(minRank, profile.rank)) {
                buffer.add(profile);
            };
        };
        Buffer.toArray(buffer)
    };
    
    public query func getAletheiansWithBadge(badge : Text) : async [AletheianProfile] {
        let buffer = Buffer.Buffer<AletheianProfile>(0);
        for (profile in profiles.vals()) {
            if (Array.find(profile.expertiseBadges, func (b : Text) : Bool = b == badge) != null) {
                buffer.add(profile);
            };
        };
        Buffer.toArray(buffer)
    };
    
    public query func getPendingRegistrations() : async [RegistrationRequest] {
        Iter.toArray(registrationRequests.vals())
    };
    
    // ======================
    // Maintenance Functions
    // ======================
    
    /// Clean up inactive profiles (called periodically)
    public shared ({ caller }) func purgeInactiveAletheians(inactiveDays : Nat) : async () {
        // In real implementation, add admin check
        let now = Time.now();
        let secondsInDay = 24 * 60 * 60 * 1_000_000_000; // nanoseconds in a day

        for ((principal, profile) in profiles.entries()) {
            if (profile.status == #Active) {
                let timeDiff = now - profile.lastActive;
                let daysInactive = timeDiff / secondsInDay;
                
                if (daysInactive > inactiveDays) {
                    // Mark as retired after prolonged inactivity
                    let updatedProfile = {
                        profile with
                        status = #Retired;
                    };
                    profiles.put(principal, updatedProfile);
                };
            };
        };
    };
};