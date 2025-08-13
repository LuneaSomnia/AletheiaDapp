import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Types "../common/Types";

    // Canister references
    let financeCanister = actor ("FinanceCanister") : actor {
        updateXP : (user : Principal, xp : Nat) -> async ();
    };

    let notification = actor ("NotificationCanister") : actor {
        sendNotification : (userId : Principal, title : Text, message : Text, notifType : Text) -> async Nat;
    };

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
    // XP Rewards (from Aletheia design doc)
    let BASE_VERIFICATION_XP : Nat = 10;
    let COMPLEXITY_LOW_BONUS : Nat = 0;
    let COMPLEXITY_MED_BONUS : Nat = 5;
    let COMPLEXITY_HIGH_BONUS : Nat = 10;
    let ACCURACY_BONUS : Nat = 5;
    let SPEED_BONUS : Nat = 3;
    let SENIOR_ESCALATION_XP : Nat = 15;
    let COUNCIL_RESOLUTION_XP : Nat = 25;
    
    // XP Penalties (from Aletheia design doc)
    let INCORRECT_VERIFICATION_PENALTY : Nat = 20;
    let MINOR_BREACH_PENALTY : Nat = 5;
    let REPEATED_MINOR_BREACH_PENALTY : Nat = 10;
    let MAJOR_BREACH_PENALTY : Nat = 50;

    // Rank thresholds (XP values)
    let JUNIOR_MAX : Nat = 249;
    let ASSOCIATE_MAX : Nat = 749;
    let SENIOR_MAX : Nat = 1999;
    let EXPERT_MAX : Nat = 4999;

    // System constants
    let INITIAL_DATA_VERSION : Nat = 1;
    let NANOS_PER_MONTH : Nat = 30 * 24 * 60 * 60 * 1_000_000_000; // ~30 days

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
    stable var userReputationEntries : [(UserId, Nat)] = [];
    stable var xpEventsEntries : [(UserId, [XPEvent])] = [];
    stable var awardedClaimsEntries : [Text] = [];
    stable var authorizedCallersEntries : [Principal] = [];
    stable var controller : Principal = initializer;
    stable var dataVersion : Nat = INITIAL_DATA_VERSION;

    // ========== STATE VARIABLES ==========
    let xpByAletheian = HashMap.HashMap<UserId, Nat>(
        0, Principal.equal, Principal.hash
    );
    
    let xpEventsByAletheian = HashMap.HashMap<UserId, [XPEvent]>(
        0, Principal.equal, Principal.hash
    );
    
    let awardedClaimsIndex = HashMap.HashMap<Text, Bool>(
        0, Text.equal, Text.hash
    );
    
    let authorizedCallers = HashMap.HashMap<Principal, Bool>(
        0, Principal.equal, Principal.hash
    );

    // ========== TYPE DEFINITIONS ==========
    public type XPEvent = {
        eventId : Text;
        target : Principal;
        source : Principal;
        claimId : ?Text;
        delta : Int;
        reason : Text;
        timestamp : Int;
    };

    public type ActorComplexity = {
        #low;
        #medium;
        #high;
    };

    // ========== SYSTEM FUNCTIONS ==========
    system func preupgrade() {
        userReputationEntries := Iter.toArray(xpByAletheian.entries());
        xpEventsEntries := Iter.toArray(xpEventsByAletheian.entries());
        awardedClaimsEntries := Iter.toArray(awardedClaimsIndex.keys());
        authorizedCallersEntries := Iter.toArray(authorizedCallers.keys());
    };

    system func postupgrade() {
        xpByAletheian := HashMap.fromIter<UserId, Nat>(
            userReputationEntries.vals(), 0, Principal.equal, Principal.hash
        );
        
        xpEventsByAletheian := HashMap.fromIter<UserId, [XPEvent]>(
            xpEventsEntries.vals(), 0, Principal.equal, Principal.hash
        );
        
        awardedClaimsIndex := HashMap.fromIter<Text, Bool>(
            awardedClaimsEntries.vals()
                |> Array.map(func(k : Text) : (Text, Bool) { (k, true) }), 
            0, Text.equal, Text.hash
        );
        
        authorizedCallers := HashMap.fromIter<Principal, Bool>(
            authorizedCallersEntries.vals()
                |> Array.map(func(p : Principal) : (Principal, Bool) { (p, true) }),
            0, Principal.equal, Principal.hash
        );
        
        // Future-proofing for data migrations
        if (dataVersion < INITIAL_DATA_VERSION) {
            // No migration needed for initial version
            dataVersion := INITIAL_DATA_VERSION;
        };
    };

    // ========== PUBLIC INTERFACE ==========
    ///////////////////////////////
    // Query APIs
    ///////////////////////////////
    
    public query func getXP(target : Principal) : async Nat {
        Option.get(xpByAletheian.get(target), 0)
    };
    
    public query func getRank(target : Principal) : async Text {
        let xp = Option.get(xpByAletheian.get(target), 0);
        _computeRank(xp)
    };
    
    public query func getXPHistory(target : Principal, limit : Nat, offset : Nat) : async [XPEvent] {
        let allEvents = Option.get(xpEventsByAletheian.get(target), []);
        let endIdx = Int.min(offset + limit, allEvents.size());
        Array.tabulate(endIdx - offset, func(i : Nat) : XPEvent {
            allEvents[offset + i]
        })
    };
    
    public query func getMonthlyXP(target : Principal, year : Nat, month : Nat) : async Nat {
        let now = Time.now();
        let monthStart = _getMonthStartNanos(year, month);
        let monthEnd = monthStart + NANOS_PER_MONTH;
        
        Option.get(xpEventsByAletheian.get(target), [])
        |> Array.filter(func(ev : XPEvent) : Bool {
            ev.timestamp >= monthStart and ev.timestamp < monthEnd
        })
        |> Array.map(func(ev : XPEvent) : Nat { Int.abs(ev.delta) })
        |> Array.foldLeft<Nat, Nat>(0, func(acc, x) { acc + x })
    };

    ///////////////////////////////
    // Update APIs
    ///////////////////////////////
    
    public shared({ caller }) func authorizeCaller(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Only controller can authorize callers");
        };
        authorizedCallers.put(p, true);
        #ok(())
    };
    
    public shared({ caller }) func revokeCaller(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Only controller can revoke callers");
        };
        authorizedCallers.delete(p);
        #ok(())
    };
    
    public shared({ caller }) func setController(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Only current controller can transfer control");
        };
        controller := p;
        #ok(())
    };
    
    public shared({ caller }) func awardXP(
        target : Principal,
        claimId : ?Text,
        params : {
            base : Nat;
            complexity : ActorComplexity;
            isSpeedBonus : Bool;
            isAccuracyBonus : Bool;
        },
        reason : Text
    ) : async Result.Result<Nat, Text> {
        if (not _isAuthorized(caller)) {
            return #err("Caller not authorized");
        };
        
        // Check for existing award for this claim
        switch(claimId) {
            case (?cid) {
                let awardKey = _getAwardKey(target, cid);
                if (Option.isSome(awardedClaimsIndex.get(awardKey))) {
                    return #err("already_awarded");
                };
            };
            case null {};
        };
        
        // Calculate XP delta
        let delta = _calculateXPDelta(params);
        let newXP = Option.get(xpByAletheian.get(target), 0) + delta;
        
        // Record the event
        let eventId = Int.toText(Time.now()) # "-" # Principal.toText(target);
        let event : XPEvent = {
            eventId;
            target;
            source = caller;
            claimId;
            delta;
            reason;
            timestamp = Time.now();
        };
        
        // Update state
        xpByAletheian.put(target, newXP);
        _appendXPEvent(target, event);
        
        // Mark claim as awarded if applicable
        switch(claimId) {
            case (?cid) {
                awardedClaimsIndex.put(_getAwardKey(target, cid), true);
            };
            case null {};
        };
        
        #ok(newXP)
    };
    
    public shared({ caller }) func penalize(
        target : Principal,
        delta : Nat,
        reason : Text,
        claimId : ?Text
    ) : async Result.Result<Nat, Text> {
        if (not _isAuthorized(caller)) {
            return #err("Caller not authorized");
        };
        
        let currentXP = Option.get(xpByAletheian.get(target), 0);
        let newXP = if (currentXP >= delta) { currentXP - delta } else { 0 };
        
        // Record the event
        let eventId = Int.toText(Time.now()) # "-" # Principal.toText(target);
        let event : XPEvent = {
            eventId;
            target;
            source = caller;
            claimId;
            delta = -Int.abs(delta);
            reason;
            timestamp = Time.now();
        };
        
        // Update state
        xpByAletheian.put(target, newXP);
        _appendXPEvent(target, event);
        
        #ok(newXP)
    };
    
    public func computeXPDelta(params : {
        base : Nat;
        complexity : ActorComplexity;
        isSpeedBonus : Bool;
        isAccuracyBonus : Bool;
    }) : async Int {
        _calculateXPDelta(params)
    };

    ///////////////////////////////
    // Legacy API (deprecated)
    ///////////////////////////////
    /// @deprecated - Use awardXP/penalize instead
    public shared({ caller }) func updateReputation(user : UserId, update : ReputationUpdate) : async () {
        // Existing implementation kept for backwards compatibility
        // ... (original code here) ...
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
    func _isAuthorized(caller : Principal) : Bool {
        caller == controller or Option.isSome(authorizedCallers.get(caller))
    };
    
    func _calculateXPDelta(params : {
        base : Nat;
        complexity : ActorComplexity;
        isSpeedBonus : Bool;
        isAccuracyBonus : Bool;
    }) : Int {
        var delta : Nat = params.base;
        
        // Complexity bonus
        delta += switch(params.complexity) {
            case (#low) COMPLEXITY_LOW_BONUS;
            case (#medium) COMPLEXITY_MED_BONUS;
            case (#high) COMPLEXITY_HIGH_BONUS;
        };
        
        // Speed bonus
        if (params.isSpeedBonus) {
            delta += SPEED_BONUS;
        };
        
        // Accuracy bonus
        if (params.isAccuracyBonus) {
            delta += ACCURACY_BONUS;
        };
        
        delta
    };
    
    func _computeRank(xp : Nat) : Text {
        if (xp <= JUNIOR_MAX) {
            "Junior"
        } else if (xp <= ASSOCIATE_MAX) {
            "Associate"
        } else if (xp <= SENIOR_MAX) {
            "Senior"
        } else if (xp <= EXPERT_MAX) {
            "Expert"
        } else {
            "Master/Elder"
        }
    };
    
    func _appendXPEvent(target : Principal, event : XPEvent) {
        let existing = Option.get(xpEventsByAletheian.get(target), []);
        xpEventsByAletheian.put(target, Array.append(existing, [event]));
    };
    
    func _getAwardKey(target : Principal, claimId : Text) : Text {
        Principal.toText(target) # "-" # claimId
    };
    
    func _getMonthStartNanos(year : Nat, month : Nat) : Int {
        // Simplified month calculation - would use proper date library in production
        let yearsSince1970 = year - 1970;
        let monthsSinceEpoch = yearsSince1970 * 12 + (month - 1);
        monthsSinceEpoch * NANOS_PER_MONTH
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
