import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Nat "mo:base/Nat";
import _ "mo:base/Debug";

actor UserAccountCanister {
    // Configuration - stable vars must be declared first
    stable var controller : Principal = caller;
    stable var internetIdentityCanisterId : Principal = Principal.fromText("aaaaa-aa");
    stable var authorizedCanisters : [(Principal, Bool)] = [];
    stable var dataVersion : Nat = 1;
    
    // Non-stable storage (rebuilt during postupgrade)
    var authorizedCanistersMap = HashMap.fromIter<Principal, Bool>(authorizedCanisters.vals(), 0, Principal.equal, Principal.hash);
    
    // Types
    public type UserId = Principal;
    public type AnonymousId = Text;
    public type UserProfile = {
        id : UserId;
        anonymousId : AnonymousId;
        createdAt : Int;
        lastActive : Int;
        settings : UserSettings;
        deactivated : Bool;
    };

    // Added deactivated flag and explicit privacy controls

    public type PublicProfile = {
        createdAt : Int;
        lastActive : Int;
        status : { #active; #deactivated };
        privacyLevel : { #basic; #enhanced; #maximum };
    };

    public type UserSettings = {
        notifications : Bool;
        privacyLevel : { #basic; #enhanced; #maximum };
        language : { #en; #es; #fr; #de };
        theme : { #light; #dark; #default };
    };

    public type ActivityRecord = {
        claimId : Text;
        timestamp : Int;
        activityType : { #claimSubmitted; #factChecked; #learningCompleted };
    };

    // Stable storage backups
    private stable var _userProfilesBackup : [(UserId, UserProfile)] = [];
    private stable var _anonymousMappingsBackup : [(AnonymousId, UserId)] = [];
    private stable var _activityLogsBackup : [(UserId, [ActivityRecord])] = [];

    // Runtime storage
    var userProfiles = HashMap.HashMap<UserId, UserProfile>(0, Principal.equal, Principal.hash);
    var anonymousIdToUser = HashMap.HashMap<AnonymousId, UserId>(0, Text.equal, Text.hash);
    var userActivities = HashMap.HashMap<UserId, [ActivityRecord]>(0, Principal.equal, Principal.hash);

    // Canister references
    let notification = actor ("NotificationCanister") : actor {
        sendNotification : (userId : Principal, title : Text, message : Text, notificationType : Text) -> async Nat;
    };

    // Initialize from stable storage with versioning
    system func preupgrade() {
        // Bump version on schema changes
        dataVersion := 2;
        // Serialize current state to stable storage
        _userProfilesBackup := Iter.toArray(userProfiles.entries());
        _anonymousMappingsBackup := Iter.toArray(anonymousIdToUser.entries());
        _activityLogsBackup := Iter.toArray(userActivities.entries());
        authorizedCanisters := Iter.toArray(authorizedCanistersMap.entries());
    };

    /// Rebuilds HashMaps from stable arrays after upgrade and cleans up
    system func postupgrade() {
        // Rehydrate HashMaps from their stable backups
        userProfiles := HashMap.fromIter<UserId, UserProfile>(
            _userProfilesBackup.vals(), 0, Principal.equal, Principal.hash
        );
        anonymousIdToUser := HashMap.fromIter<AnonymousId, UserId>(
            _anonymousMappingsBackup.vals(), 0, Text.equal, Text.hash
        );
        userActivities := HashMap.fromIter<UserId, [ActivityRecord]>(
            _activityLogsBackup.vals(), 0, Principal.equal, Principal.hash
        );
        
        // Convert stable array to HashMap
        authorizedCanistersMap := HashMap.fromIter<Principal, Bool>(
            authorizedCanisters.vals(), 0, Principal.equal, Principal.hash
        );

        // Clear backups to prevent data duplication
        _userProfilesBackup := [];
        _anonymousMappingsBackup := [];
        _activityLogsBackup := [];
    };

    // Initialize with default settings
    func defaultSettings() : UserSettings {
        {
            notifications = true;
            privacyLevel = #enhanced;
            language = #en;
            theme = #default;
        }
    };

    // Generate random hexadecimal string for anonymous IDs (32 chars = 16 bytes)
    // Generates 32-character hex string from 16 random bytes
    func generateAnonymousId() : async AnonymousId {
        let random = await Random.blob();
        let bytes = Blob.toArray(random);
        // Take first 16 bytes and convert to hex
        let anonymousIdBytes = Array.tabulate<Nat8>(16, func(i : Nat) : Nat8 { 
            if (i < bytes.size()) bytes[i] else 0 : Nat8
        });
        toHex(anonymousIdBytes)
    };

    // Convert byte array to hexadecimal string
    func toHex(bytes : [Nat8]) : Text {
        let hexChars : [Text] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];
        Array.foldLeft<Nat8, Text>(bytes, "", func (acc : Text, byte : Nat8) : Text {
            acc # hexChars[Nat8.toNat(byte >> 4)] # hexChars[Nat8.toNat(byte & 0x0F)]
        })
    };

    // User registration
    public shared ({ caller }) func register() : async Result.Result<UserProfile, Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous principals cannot register");
        };

        switch (userProfiles.get(caller)) {
            case (?profile) {
                // Update last active time
                let updatedProfile = {
                    profile with lastActive = Time.now()
                };
                userProfiles.put(caller, updatedProfile);
                #ok(updatedProfile);
            };
            case null {
                // Create new profile
                let anonymousId = await generateAnonymousId();
                let newProfile : UserProfile = {
                    id = caller;
                    anonymousId;
                    createdAt = Time.now();
                    lastActive = Time.now();
                    settings = defaultSettings();
                };

                userProfiles.put(caller, newProfile);
                anonymousIdToUser.put(anonymousId, caller);
                userActivities.put(caller, []);
                
                // Send welcome notification
                ignore await notification.sendNotification(
                    caller,
                    "Welcome to Aletheia",
                    "Your account has been created successfully. Start by submitting your first claim!",
                    "welcome"
                );

                #ok(newProfile);
            };
        };
    };

    // Get current user profile
    public shared query ({ caller }) func getMyProfile() : async ?UserProfile {
        userProfiles.get(caller);
    };

    // Update user settings
    public shared ({ caller }) func updateSettings(newSettings : UserSettings) : async Result.Result<(), Text> {
        switch (userProfiles.get(caller)) {
            case (?profile) {
                let updatedProfile = {
                    profile with 
                    settings = newSettings;
                    lastActive = Time.now();
                };
                userProfiles.put(caller, updatedProfile);
                #ok();
            };
            case null {
                #err("User profile not found. Please register first.");
            };
        };
    };

    // Record user activity (called by other canisters)
    public shared ({ caller }) func recordActivity(userId : UserId, activity : Types.ActivityRecord) : async Result.Result<(), Text> {
        // Enforce allowlist: user or authorized canisters only
        if (caller != userId and Option.isNull(authorizedCanistersMap.get(caller))) {
            return #err("Unauthorized: Caller must be user or authorized canister");
        };
        switch (userProfiles.get(userId)) {
            case (?profile) {
                let currentActivities = Option.get(userActivities.get(userId), []);
                let newActivities = Array.append(currentActivities, [activity]);
                userActivities.put(userId, newActivities);
                #ok(());
            };
            case null {
                #err("User profile not found");
            };
        };
    };

    // Privacy-preserving activity retrieval
    public shared query ({ caller }) func getMyActivity() : async [ActivityRecord] {
        switch (userProfiles.get(caller), userActivities.get(caller)) {
            case (?profile, ?activities) {
                // Apply privacy settings
                switch (profile.settings.privacyLevel) {
                    case (#basic) activities;
                    case (#enhanced) {
                        Array.map<ActivityRecord, ActivityRecord>(
                            activities,
                            func(a) {
                                { a with claimId = "" } // Omit claim IDs
                            }
                        );
                    };
                    case (#maximum) {
                        [] // Return empty for maximum privacy
                    };
                };
            };
            case _ [];
        };
    };

    // Internet Identity integration
    public shared query func getInternetIdentityCanisterId() : async Principal {
        internetIdentityCanisterId
    };

    // Admin APIs
    public shared({ caller }) func authorizeCanister(canisterId : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized: Only controller can authorize canisters");
        };
        authorizedCanistersMap.put(canisterId, true);
        #ok(())
    };

    public shared ({ caller }) func revokeCanister(canisterId : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized: Only controller can revoke canisters");
        };
        authorizedCanisters.delete(canisterId);
        #ok(())
    };

    public shared ({ caller }) func setInternetIdentityCanisterId(newId : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized: Only controller can set Internet Identity canister");
        };
        internetIdentityCanisterId := newId;
        #ok(())
    };

    public shared ({ caller }) func setController(newController : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized: Only current controller can transfer control");
        };
        controller := newController;
        #ok(())
    };

    // Admin function for system maintenance
    public shared ({ caller }) func adminGetUserProfile(userId : UserId) : async Result.Result<?UserProfile, Text> {
        if (caller != controller) {
            return #err("Unauthorized: Only controller can access user profiles");
        };
        #ok(userProfiles.get(userId));
    };

    // Get anonymous ID for blockchain operations
    public shared({ caller }) func deactivateAccount() : async Result.Result<(), Text> {
        switch (userProfiles.get(caller)) {
            case (?profile) {
                let anonymizedProfile : UserProfile = {
                    profile with
                    anonymousId = "";
                    settings = {
                        profile.settings with
                        privacyLevel = #maximum;
                        notifications = false;
                    };
                    lastActive = Time.now();
                    deactivated = true;
                };
                userProfiles.put(caller, anonymizedProfile);
                #ok(());
            };
            case null {
                #err("User profile not found");
            };
        };
    };

    public shared({ caller }) func deactivateAccount() : async Result.Result<(), Text> {
        switch (userProfiles.get(caller)) {
            case (?profile) {
                // Anonymize profile but keep audit trail
                let anonymizedProfile : UserProfile = {
                    profile with
                    anonymousId = "";
                    settings = {
                        profile.settings with
                        privacyLevel = #maximum;
                        notifications = false;
                    };
                    lastActive = Time.now();
                    deactivated = true;
                };
                userProfiles.put(caller, anonymizedProfile);
                #ok(());
            };
            case null {
                #err("User profile not found");
            };
        };
    };

    public shared query func getPublicProfile(userId : UserId) : async ?PublicProfile {
        switch (userProfiles.get(userId)) {
            case (?profile) {
                ?{
                    createdAt = profile.createdAt;
                    lastActive = profile.lastActive;
                    status = if (profile.deactivated) #deactivated else #active;
                    privacyLevel = profile.settings.privacyLevel;
                }
            };
            case null null;
        }
    };

    public shared query ({ caller }) func getAnonymousId() : async ?AnonymousId {
        switch (userProfiles.get(caller)) {
            case (?profile) ?profile.anonymousId;
            case null null;
        };
    };
};
