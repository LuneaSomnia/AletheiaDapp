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
    // Types
    public type UserId = Principal;
    public type AnonymousId = Text;
    public type UserProfile = {
        id : UserId;
        anonymousId : AnonymousId;
        createdAt : Int;
        lastActive : Int;
        settings : UserSettings;
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

    // Stable storage
    stable var userProfilesEntries : [(UserId, UserProfile)] = [];
    stable var anonymousMappings : [(AnonymousId, UserId)] = [];
    stable var activityLogs : [(UserId, [ActivityRecord])] = [];

    // Runtime storage (var for upgrade handling)
    var userProfiles = HashMap.HashMap<UserId, UserProfile>(0, Principal.equal, Principal.hash);
    var anonymousIdToUser = HashMap.HashMap<AnonymousId, UserId>(0, Text.equal, Text.hash);
    var userActivities = HashMap.HashMap<UserId, [ActivityRecord]>(0, Principal.equal, Principal.hash);

    // Canister references
    let notification = actor ("NotificationCanister") : actor {
        sendNotification : (userId : Principal, title : Text, message : Text, notifType : Text) -> async Nat;
    };

    // Initialize from stable storage
    system func preupgrade() {
        userProfilesEntries := Iter.toArray(userProfiles.entries());
        anonymousMappings := Iter.toArray(anonymousIdToUser.entries());
        activityLogs := Iter.toArray(userActivities.entries());
    };

    system func postupgrade() {
        userProfiles := HashMap.fromIter<UserId, UserProfile>(
            userProfilesEntries.vals(), 0, Principal.equal, Principal.hash
        );
        anonymousIdToUser := HashMap.fromIter<AnonymousId, UserId>(
            anonymousMappings.vals(), 0, Text.equal, Text.hash
        );
        userActivities := HashMap.fromIter<UserId, [ActivityRecord]>(
            activityLogs.vals(), 0, Principal.equal, Principal.hash
        );
        userProfilesEntries := [];
        anonymousMappings := [];
        activityLogs := [];
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

    // Generate random hexadecimal string for anonymous IDs
    func generateAnonymousId() : async AnonymousId {
        let random = await Random.blob();
        let bytes = Blob.toArray(random);
        toHex(Array.tabulate<Nat8>(16, func(i : Nat) : Nat8 { 
            if (i < bytes.size()) bytes[i] else 0 : Nat8
        }));
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
    public shared func recordActivity(userId : UserId, activity : ActivityRecord) : async () {
        if (userProfiles.get(userId) != null) {
            let currentActivities = Option.get(userActivities.get(userId), []);
            let newActivities = Array.append(currentActivities, [activity]);
            userActivities.put(userId, newActivities);
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
    public shared func getInternetIdentityCanisterId() : async Principal {
        // TODO: Return the correct Internet Identity canister principal here
        Principal.fromText("aaaaa-aa")
    };

    // Admin function for system maintenance
    public shared ({ caller }) func adminGetUserProfile(userId : UserId) : async ?UserProfile {
        // In production, add controller check here
        userProfiles.get(userId);
    };

    // Get anonymous ID for blockchain operations
    public shared query ({ caller }) func getAnonymousId() : async ?AnonymousId {
        switch (userProfiles.get(caller)) {
            case (?profile) ?profile.anonymousId;
            case null null;
        };
    };
};