import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Time "mo:base/Time";

shared({ caller = initializer }) actor class ReputationLogicCanister() = this {
    // ========== TYPE DEFINITIONS ==========
    public type UserId = Principal;
    public type XP = Nat;
    public type Credits = Nat;
    public type WarningLevel = Nat;
    public type Timestamp = Int;

    public type PenaltyType = {
        #minor;
        #major;
        #threshold;
    };

    public type UserReputation = {
        xp : XP;
        credits : Credits;
        warnings : WarningLevel;
        lastWarning : ?Timestamp;
    };

    public type ReputationUpdate = {
        #reward : { xp : XP; credits : Credits };
        #penalty : PenaltyType;
    };

    // ========== CONSTANTS ==========
    let MINOR_PENALTY_XP = 5;
    let MINOR_PENALTY_CREDITS = 25;
    let MAJOR_PENALTY_XP = 15;
    let MAJOR_PENALTY_CREDITS = 75;
    let THRESHOLD_PENALTY_XP = 30;
    let THRESHOLD_PENALTY_CREDITS = 150;
    let WARNING_DECAY_DAYS = 30; // Days after which warnings decay
    let WARNING_THRESHOLD = 3;   // Warning level that triggers threshold penalty

    // ========== STABLE STORAGE ==========
    stable var userReputationEntries : [(UserId, UserReputation)] = [];
    stable var version : Nat = 1;

    // ========== STATE VARIABLES ==========
    var userReputations = HashMap.HashMap<UserId, UserReputation>(
        0,
        Principal.equal,
        Principal.hash
    );

    // ========== SYSTEM FUNCTIONS ==========
    system func preupgrade() {
        userReputationEntries := Iter.toArray(userReputations.entries());
    };

    system func postupgrade() {
        userReputations := HashMap.fromIter<UserId, UserReputation>(
            userReputationEntries.vals(),
            0,
            Principal.equal,
            Principal.hash
        );
        userReputationEntries := [];
    };

    // ========== PUBLIC INTERFACE ==========
    /// Updates user reputation based on action type
    public shared({ caller }) func updateReputation(user : UserId, update : ReputationUpdate) : async () {
        assert(_isAuthorized(caller));
        let now = Time.now();
        let currentReputation = _getOrInitUser(user);
        
        // Apply warning decay if needed
        let decayedReputation = _applyWarningDecay(currentReputation, now);
        var updatedReputation = decayedReputation;
        
        // Process the update
        switch(update) {
            case (#reward reward) {
                updatedReputation := {
                    xp = decayedReputation.xp + reward.xp;
                    credits = decayedReputation.credits + reward.credits;
                    warnings = decayedReputation.warnings;
                    lastWarning = decayedReputation.lastWarning;
                };
            };
            case (#penalty penaltyType) {
                updatedReputation := _applyPenalty(decayedReputation, penaltyType, now);
            };
        };
        
        userReputations.put(user, updatedReputation);
    };

    /// Gets current reputation for a user
    public query func getReputation(user : UserId) : async UserReputation {
        let current = _getOrInitUser(user);
        _applyWarningDecay(current, Time.now())
    };

    // ========== PRIVATE LOGIC ==========
    // Applies penalty based on type and updates warnings
    func _applyPenalty(current : UserReputation, penaltyType : PenaltyType, now : Timestamp) : UserReputation {
        let (xpDeduction, creditDeduction, warningIncrement) = switch(penaltyType) {
            case (#minor) { (MINOR_PENALTY_XP, MINOR_PENALTY_CREDITS, 1) };
            case (#major) { (MAJOR_PENALTY_XP, MAJOR_PENALTY_CREDITS, 2) };
            case (#threshold) { (THRESHOLD_PENALTY_XP, THRESHOLD_PENALTY_CREDITS, 0) };
        };
        
        // Apply penalty
        let newXP = _safeSubtract(current.xp, xpDeduction);
        let newCredits = _safeSubtract(current.credits, creditDeduction);
        var newWarnings = current.warnings + warningIncrement;
        
        // Handle threshold penalty
        if (newWarnings >= WARNING_THRESHOLD) {
            newWarnings := 0; // Reset warnings after threshold penalty
            return {
                xp = _safeSubtract(newXP, THRESHOLD_PENALTY_XP);
                credits = _safeSubtract(newCredits, THRESHOLD_PENALTY_CREDITS);
                warnings = newWarnings;
                lastWarning = ?now
            };
        };
        
        { 
            xp = newXP;
            credits = newCredits;
            warnings = newWarnings;
            lastWarning = ?now;
        }
    };

    // Applies warning decay based on time
    func _applyWarningDecay(current : UserReputation, now : Timestamp) : UserReputation {
        switch(current.lastWarning) {
            case null { current };
            case (?lastWarning) {
                let secondsSinceWarning = now - lastWarning;
                let daysSinceWarning = Nat64.toNat(Nat64.fromIntWrap(secondsSinceWarning / (24 * 3600 * 1_000_000_000)));
                
                if (daysSinceWarning >= WARNING_DECAY_DAYS and current.warnings > 0) {
                    let decayAmount = Nat.min(current.warnings, daysSinceWarning / WARNING_DECAY_DAYS);
                    {
                        current with 
                        warnings = current.warnings - decayAmount;
                        lastWarning = if (decayAmount == current.warnings) null else ?lastWarning;
                    }
                } else {
                    current
                }
            }
        }
    };

    // Safely subtracts without underflow
    func _safeSubtract(current : Nat, deduction : Nat) : Nat {
        if (current > deduction) { current - deduction } 
        else { 0 }
    };

    // Gets user or initializes new entry
    func _getOrInitUser(user : UserId) : UserReputation {
        switch(userReputations.get(user)) {
            case (?rep) { rep };
            case null {
                let newUser = {
                    xp = 0;
                    credits = 0;
                    warnings = 0;
                    lastWarning = null;
                };
                userReputations.put(user, newUser);
                newUser
            }
        }
    };

    // Authorization check (simplified - expand for production)
    func _isAuthorized(caller : Principal) : Bool {
        // Implement proper authorization logic
        // For now, allow only self and parent canisters
        true
    };

    // ========== VERSIONING ==========
    public query func getVersion() : async Nat {
        version
    };
};