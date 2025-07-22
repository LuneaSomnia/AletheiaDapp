import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Types "../common/Types";

// --- BREAK CIRCULAR DEPENDENCY: Use interface type for VerificationWorkflowCanister ---
type VerificationWorkflowInterface = actor {
    getTask: (claimId: Text) -> async ?Types.Assignment; // Adjust type as needed
    // Add only the methods you actually call
};
// Example usage (replace with actual canister ID):
// let verificationWorkflow = actor ("<VerificationWorkflowCanister_canister_id>") : VerificationWorkflowInterface;

shared({ caller = initializer }) actor class ReputationLogicCanister() = this {
    // ========== TYPE DEFINITIONS ==========
    public type UserId = Principal;
    public type XP = Nat;
    public type Credits = Nat;
    public type WarningLevel = Nat;
    public type Timestamp = Int;

    public type PenaltyType = {
        #incorrectVerification;      // -20 XP
        #minorBreach;                // -5 XP
        #repeatedMinorBreach;        // -10 XP
        #majorBreach;                // -50 XP
        #taskIncomplete;             // -5 XP
    };

    public type UserReputation = {
        xp : XP;
        credits : Credits;
        warnings : WarningLevel;
        lastWarning : ?Timestamp;
    };

    public type ReputationUpdate = {
        #reward : { 
            xp : XP; 
            credits : Credits;
            rewardType : {
                #baseVerification;
                #complexityBonus;
                #accuracyBonus;
                #speedBonus;
                #seniorEscalation;
                #councilResolution;
                #trainingModule;
                #duplicateIdentification;
            };
        };
        #penalty : PenaltyType;
    };

    // ========== CONSTANTS ==========
    // XP Rewards (from documentation)
    let BASE_VERIFICATION_XP = 10;
    let COMPLEXITY_LOW_BONUS = 0;
    let COMPLEXITY_MED_BONUS = 5;
    let COMPLEXITY_HIGH_BONUS = 10;
    let ACCURACY_BONUS = 5;
    let SPEED_BONUS = 3;
    let SENIOR_ESCALATION_XP = 15;
    let COUNCIL_RESOLUTION_XP = 25;
    let TRAINING_MODULE_MIN_XP = 5;
    let TRAINING_MODULE_MAX_XP = 20;
    let DUPLICATE_ID_XP = 2;

    // XP Penalties (from documentation)
    let INCORRECT_VERIFICATION_PENALTY = 20;
    let MINOR_BREACH_PENALTY = 5;
    let REPEATED_MINOR_BREACH_PENALTY = 10;
    let MAJOR_BREACH_PENALTY = 50;
    let TASK_INCOMPLETE_PENALTY = 5;
    let THRESHOLD_PENALTY = 30;

    // Credit penalties (maintain existing ratios)
    let CREDIT_MULTIPLIER = 5;
    let THRESHOLD_CREDIT_PENALTY = THRESHOLD_PENALTY * CREDIT_MULTIPLIER;

    // Warning system
    let WARNING_DECAY_DAYS = 30; // Days after which warnings decay
    let WARNING_THRESHOLD = 3;   // Warning level that triggers threshold penalty

    // Rank thresholds (from documentation)
    let JUNIOR_MAX = 249;
    let ASSOCIATE_MAX = 749;
    let SENIOR_MAX = 1999;
    let EXPERT_MAX = 4999;

    // ========== STABLE STORAGE ==========
    stable var userReputationEntries : [(UserId, UserReputation)] = [];
    stable var version : Nat = 2; // Bumped for new implementation

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

    /// Gets user's current rank based on XP
    public query func getRank(user: UserId) : async Text {
        let rep = _getOrInitUser(user);
        _computeRank(rep.xp)
    };

    // ========== PRIVATE LOGIC ==========
    // Applies penalty based on type and updates warnings
    func _applyPenalty(current : UserReputation, penaltyType : PenaltyType, now : Timestamp) : UserReputation {
        let (xpDeduction, warningIncrement) = switch(penaltyType) {
            case (#incorrectVerification) { (INCORRECT_VERIFICATION_PENALTY, 1) };
            case (#minorBreach) { (MINOR_BREACH_PENALTY, 1) };
            case (#repeatedMinorBreach) { (REPEATED_MINOR_BREACH_PENALTY, 1) };
            case (#majorBreach) { (MAJOR_BREACH_PENALTY, 2) };
            case (#taskIncomplete) { (TASK_INCOMPLETE_PENALTY, 0) };
        };
        
        let creditDeduction = xpDeduction * CREDIT_MULTIPLIER;
        
        // Apply penalty
        let newXP = _safeSubtract(current.xp, xpDeduction);
        let newCredits = _safeSubtract(current.credits, creditDeduction);
        let newWarnings = current.warnings + warningIncrement;
        
        // Handle threshold penalty if warnings exceed threshold
        if (newWarnings >= WARNING_THRESHOLD) {
            return {
                xp = _safeSubtract(newXP, THRESHOLD_PENALTY);
                credits = _safeSubtract(newCredits, THRESHOLD_CREDIT_PENALTY);
                warnings = 0; // Reset warnings after threshold penalty
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

    // Computes rank based on XP
    func _computeRank(xp : XP) : Text {
        if (xp <= JUNIOR_MAX) {
            "Junior Aletheian"
        } else if (xp <= ASSOCIATE_MAX) {
            "Associate Aletheian"
        } else if (xp <= SENIOR_MAX) {
            "Senior Aletheian"
        } else if (xp <= EXPERT_MAX) {
            "Expert Aletheian"
        } else {
            "Master Aletheian / Elder"
        }
    };

    // Applies warning decay based on time
    func _applyWarningDecay(current : UserReputation, now : Timestamp) : UserReputation {
        switch(current.lastWarning) {
            case null { current };
            case (?lastWarning) {
                let secondsSinceWarning = now - lastWarning;
                let daysSinceWarning = Int.abs(secondsSinceWarning / (24 * 3600 * 1_000_000_000));
                
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

    // Authorization check (placeholder - implement proper auth in production)
    func _isAuthorized(caller : Principal) : Bool {
        // In production: verify caller is from Aletheia system
        // For now, allow only initializer (parent canister)
        caller == initializer
    };

    // ========== VERSIONING ==========
    public query func getVersion() : async Nat {
        version
    };
};