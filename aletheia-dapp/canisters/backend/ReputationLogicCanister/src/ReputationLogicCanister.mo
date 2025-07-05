import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import _ "mo:base/Array";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Text "mo:base/Text";
import _ "mo:base/Debug";
import _ "mo:base/Time";
import Option "mo:base/Option";
import Nat64 "mo:base/Nat64";

actor ReputationLogicCanister {
    type AletheianId = Principal;
    type Action = {
        #SuccessfulVerification;
        #ComplexityBonus: Nat; // 1=Low, 2=Medium, 3=High
        #AccuracyBonus;
        #SpeedBonus;
        #EscalationReview;
        #CouncilResolution;
        #TrainingComplete;
        #Mentoring;
        #DuplicateIdentification;
        #Penalty: Nat; // 1=Minor, 2=Major, 3=Severe
    };
    
    type Rank = {
        #Trainee;
        #Junior;
        #Associate;
        #Senior;
        #Expert;
        #Master;
    };
    
    // In-memory storage
    private var xpStore = HashMap.HashMap<AletheianId, Nat>(0, Principal.equal, Principal.hash);
    private var warnings = HashMap.HashMap<AletheianId, Nat>(0, Principal.equal, Principal.hash);
    private var performanceData = HashMap.HashMap<AletheianId, PerformanceMetrics>(0, Principal.equal, Principal.hash);
    
    type PerformanceMetrics = {
        accuracy: Float;
        avgVerificationTime: Nat;
        claimsVerified: Nat;
        escalationsResolved: Nat;
    };
    
    // Initialize with default values
    public shared func initializeAletheian(aletheianId: AletheianId) : async () {
        if (Option.isNull(xpStore.get(aletheianId))) {
            xpStore.put(aletheianId, 0);
            warnings.put(aletheianId, 0);
            performanceData.put(aletheianId, {
                accuracy = 0.0;
                avgVerificationTime = 0;
                claimsVerified = 0;
                escalationsResolved = 0;
            });
        };
    };
    
    // Update XP for an action
    public shared func updateXP(
        aletheianId: AletheianId,
        action: Action
    ) : async Result.Result<Nat, Text> {
        let xpDelta = calculateXP(action);
        let currentXP = Option.get(xpStore.get(aletheianId), 0);
        
        // Handle penalties
        switch (action) {
            case (#Penalty level) {
                let currentWarnings = Option.get(warnings.get(aletheianId), 0);
                warnings.put(aletheianId, currentWarnings + level);
            };
            case _ {};
        };
        
        let newXP = Nat64.fromIntWrap(currentXP + xpDelta);
        
        // Update performance metrics if applicable
        switch (action) {
                      case (#SuccessfulVerification) {
                await updatePerformance(aletheianId, #ClaimsVerified(1));
            };
            case (#EscalationReview) {
                await updatePerformance(aletheianId, #EscalationsResolved(1));
            };
            case _ {};
        };
        
        #ok(Nat64.toNat(newXP))
    };
    
    // Get current XP
    public query func getXP(aletheianId: AletheianId) : async ?Nat {
        xpStore.get(aletheianId)
    };
    
    // Get warnings
    public query func getWarnings(aletheianId: AletheianId) : async ?Nat {
        warnings.get(aletheianId)
    };
    
    // Get rank
    public query func getRank(aletheianId: AletheianId) : async ?Rank {
        switch (xpStore.get(aletheianId)) {
            case (?xp) ?(calculateRank(xp));
            case null null;
        }
    };
    
    // Get performance metrics
    public query func getPerformance(aletheianId: AletheianId) : async ?PerformanceMetrics {
        performanceData.get(aletheianId)
    };
    
    // Update performance metrics
    public shared func updatePerformance(
        aletheianId: AletheianId,
        update: {
            #Accuracy: Float;
            #VerificationTime: Nat;
            #ClaimsVerified: Nat;
            #EscalationsResolved: Nat;
        }
    ) : async () {
        switch (performanceData.get(aletheianId)) {
            case (?metrics) {
                let updated = switch (update) {
                    case (#Accuracy value) { 
                        { metrics with accuracy = value } 
                    };
                    case (#VerificationTime time) {
                        // Calculate new average
                        let newAvg = (metrics.avgVerificationTime * metrics.claimsVerified + time) / 
                                     (metrics.claimsVerified + 1);
                        { metrics with avgVerificationTime = newAvg }
                    };
                    case (#ClaimsVerified count) {
                        { metrics with claimsVerified = metrics.claimsVerified + count }
                    };
                    case (#EscalationsResolved count) {
                        { metrics with escalationsResolved = metrics.escalationsResolved + count }
                    };
                };
                performanceData.put(aletheianId, updated);
            };
            case null {};
        };
    };
    
    // Internal: Calculate XP for an action
    private func calculateXP(action: Action) : Int {
        switch (action) {
            case (#SuccessfulVerification) 10;
            case (#ComplexityBonus level) {
                switch (level) {
                    case 1 0;
                    case 2 5;
                    case 3 10;
                    case _ 0;
                }
            };
            case (#AccuracyBonus) 5;
            case (#SpeedBonus) 3;
            case (#EscalationReview) 15;
            case (#CouncilResolution) 25;
            case (#TrainingComplete) 15;
            case (#Mentoring) 10;
            case (#DuplicateIdentification) 2;
            case (#Penalty level) {
                switch (level) {
                    case 1 -5;
                    case 2 -20;
                    case 3 -50;
                    case _ 0;
                }
            };
        }
    };
    
    // Internal: Calculate rank from XP
    private func calculateRank(xp: Nat) : Rank {
        if (xp >= 10000) #Master
        else if (xp >= 5000) #Expert
        else if (xp >= 2000) #Senior
        else if (xp >= 750) #Associate
        else if (xp >= 250) #Junior
        else #Trainee
    };
};