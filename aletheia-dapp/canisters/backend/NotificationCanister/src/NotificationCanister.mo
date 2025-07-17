import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Types "Types";
import Utils "Utils";

actor class NotificationCanister(initialAdmins: [Principal]) = this {
    type Notification = Types.Notification;
    type UserSettings = Types.UserSettings;
    type NotificationType = Types.NotificationType;
    type NotificationPreference = Types.NotificationPreference;
    
    // Stable state for upgrades
    private stable var nextNotificationId: Nat = 0;
    private stable var stableNotifications: [Notification] = [];
    private stable var stableUserSettings: [(Principal, UserSettings)] = [];
    private stable var stablePendingPush: [Notification] = [];
    private stable var stableAllowedCanisters: [Principal] = [];

    // Runtime state
    private var notifications = TrieMap.TrieMap<Nat, Notification>(Nat.equal, Hash.hash);
    private var userSettings = TrieMap.TrieMap<Principal, UserSettings>(Principal.equal, Principal.hash);
    private var pendingPush = Buffer.Buffer<Notification>(0);
    private var allowedCanisters = Buffer.Buffer<Principal>(0);
    private var admins = Buffer.Buffer<Principal>(0);

    // Initialize from stable state
    system func postupgrade() {
        notifications := TrieMap.fromIter<Nat, Notification>(
            stableNotifications.vals(), stableNotifications.size(), Nat.equal, Hash.hash
        );
        
        userSettings := TrieMap.fromIter<Principal, UserSettings>(
            stableUserSettings.vals(), stableUserSettings.size(), Principal.equal, Principal.hash
        );
        
        pendingPush := Buffer.fromArray<Notification>(stablePendingPush);
        allowedCanisters := Buffer.fromArray<Principal>(stableAllowedCanisters);
        admins := Buffer.fromArray<Principal>(initialAdmins);
    };

    system func preupgrade() {
        stableNotifications := Iter.toArray(notifications.vals());
        stableUserSettings := Iter.toArray(userSettings.entries());
        stablePendingPush := pendingPush.toArray();
        stableAllowedCanisters := allowedCanisters.toArray();
    };

    // Authorization helpers
    private func isAdmin(caller: Principal) : Bool {
        Utils.contains(admins, caller, Principal.equal)
    };

    private func isAllowedCanister(caller: Principal) : Bool {
        Utils.contains(allowedCanisters, caller, Principal.equal)
    };

    private func validateCaller(caller: Principal) {
        if (Principal.isAnonymous(caller)) {
            throw Error.reject("Anonymous callers not allowed");
        }
    };

    // ===== ADMIN MANAGEMENT =====
    public shared({ caller }) func addAdmin(newAdmin: Principal) : async () {
        validateCaller(caller);
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };
        if (not Utils.contains(admins, newAdmin, Principal.equal)) {
            admins.add(newAdmin);
        };
    };

    public shared({ caller }) func removeAdmin(admin: Principal) : async () {
        validateCaller(caller);
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };
        let size = admins.size();
        admins := Buffer.filter<Principal>(admins, func(p) { p != admin });
        if (admins.size() == 0) {
            throw Error.reject("Cannot remove last admin");
        };
    };

    public query func getAdmins() : async [Principal] {
        admins.toArray()
    };

    // ===== CANISTER AUTHORIZATION =====
    public shared({ caller }) func addAllowedCanister(canisterId: Principal) : async () {
        validateCaller(caller);
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };
        if (not Utils.contains(allowedCanisters, canisterId, Principal.equal)) {
            allowedCanisters.add(canisterId);
        };
    };

    public shared({ caller }) func removeAllowedCanister(canisterId: Principal) : async () {
        validateCaller(caller);
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };
        allowedCanisters := Buffer.filter<Principal>(allowedCanisters, func(p) { p != canisterId });
    };

    public query func getAllowedCanisters() : async [Principal] {
        allowedCanisters.toArray()
    };

    // ===== USER SETTINGS MANAGEMENT =====
    public shared({ caller }) func updateSettings(
        inApp: ?Bool,
        push: ?Bool,
        email: ?Bool,
        disabledTypes: ?[NotificationType]
    ) : async UserSettings {
        validateCaller(caller);
        let settings : UserSettings = switch (userSettings.get(caller)) {
            case (null) {
                {
                    inApp = true;
                    push = false;
                    email = false;
                    pushTokens = [];
                    disabledTypes = [];
                }
            };
            case (?s) { s };
        };

        let newSettings : UserSettings = {
            inApp = Utils.optionOrDefault(inApp, settings.inApp);
            push = Utils.optionOrDefault(push, settings.push);
            email = Utils.optionOrDefault(email, settings.email);
            pushTokens = settings.pushTokens;
            disabledTypes = Utils.optionOrDefault(disabledTypes, settings.disabledTypes);
        };

        userSettings.put(caller, newSettings);
        newSettings
    };

    public shared({ caller }) func registerPushToken(token: Text) : async () {
        validateCaller(caller);
        let settings = switch (userSettings.get(caller)) {
            case (null) {
                let defaultSettings : UserSettings = {
                    inApp = true;
                    push = true;
                    email = false;
                    pushTokens = [];
                    disabledTypes = [];
                };
                userSettings.put(caller, defaultSettings);
                defaultSettings
            };
            case (?s) { s };
        };

        // Add token if not already present
        if (not Utils.contains(settings.pushTokens, token, Text.equal)) {
            let newTokens = Array.append(settings.pushTokens, [token]);
            userSettings.put(caller, {
                settings with pushTokens = newTokens;
            });
        };
    };

    public shared({ caller }) func unregisterPushToken(token: Text) : async () {
        validateCaller(caller);
        switch (userSettings.get(caller)) {
            case (null) {};
            case (?settings) {
                let newTokens = Array.filter<Text>(settings.pushTokens, func(t) { t != token });
                userSettings.put(caller, {
                    settings with pushTokens = newTokens;
                });
            };
        };
    };

    public query({ caller }) func getSettings() : async UserSettings {
        switch (userSettings.get(caller)) {
            case (null) {
                {
                    inApp = true;
                    push = false;
                    email = false;
                    pushTokens = [];
                    disabledTypes = [];
                }
            };
            case (?settings) { settings };
        }
    };

    // ===== NOTIFICATION CORE =====
    public shared({ caller }) func sendNotification(
        userId: Principal,
        title: Text,
        body: Text,
        notifType: NotificationType
    ) : async Nat {
        // Authorization check
        if (not isAllowedCanister(caller) and not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Only allowed canisters can send notifications");
        };

        // Check if user has disabled this notification type
        switch (userSettings.get(userId)) {
            case (?settings) {
                if (Utils.contains(settings.disabledTypes, notifType, func(a, b) { a == b })) {
                    throw Error.reject("Notification type disabled by user");
                };
            };
            case (_) {};
        };

        let id = nextNotificationId;
        nextNotificationId += 1;

        let now = Time.now();
        let notification : Notification = {
            id = id;
            userId = userId;
            title = title;
            body = body;
            timestamp = now;
            read = false;
            notificationType = notifType;
        };

        // Store notification
        notifications.put(id, notification);

        // Queue for push delivery if enabled
        switch (userSettings.get(userId)) {
            case (null) {};
            case (?settings) {
                if (settings.push and settings.pushTokens.size() > 0) {
                    pendingPush.add(notification);
                };
            };
        };

        id
    };

    public shared({ caller }) func markAsRead(notificationId: Nat) : async () {
        validateCaller(caller);
        switch (notifications.get(notificationId)) {
            case (null) {
                throw Error.reject("Notification not found");
            };
            case (?notification) {
                if (notification.userId != caller) {
                    throw Error.reject("Unauthorized: Cannot modify others' notifications");
                };
                notifications.put(notificationId, {
                    notification with read = true;
                });
            };
        };
    };

    public shared({ caller }) func markAllAsRead() : async () {
        validateCaller(caller);
        for ((id, notification) in notifications.entries()) {
            if (notification.userId == caller and not notification.read) {
                notifications.put(id, {
                    notification with read = true;
                });
            };
        };
    };

    // ===== NOTIFICATION RETRIEVAL =====
    public query({ caller }) func getNotifications(
        since: ?Time.Time,
        limit: ?Nat,
        unreadOnly: ?Bool
    ) : async [Notification] {
        var userNotifs = Buffer.Buffer<Notification>(0);
        let now = Time.now();
        let cutoff = switch (since) {
            case (null) { 0 };
            case (?t) { t };
        };
        let maxResults = Utils.optionOrDefault(limit, 100);
        let filterUnread = Utils.optionOrDefault(unreadOnly, false);

        for (notification in notifications.vals()) {
            if (notification.userId == caller and
                notification.timestamp >= cutoff and
                (not filterUnread or not notification.read)) 
            {
                userNotifs.add(notification);
                if (userNotifs.size() >= maxResults) break
            };
        };

        // Sort by timestamp descending (newest first)
        let sorted = Array.sort(
            userNotifs.toArray(), 
            func(a: Notification, b: Notification): Order.Order {
                if (a.timestamp > b.timestamp) { #less }
                else if (a.timestamp < b.timestamp) { #greater }
                else { #equal }
            }
        );
        sorted
    };
};
};

    // ===== PUSH PROCESSING INTERFACE =====
    public shared({ caller }) func getPendingPushNotifications(
        maxResults: Nat
    ) : async [Notification] {
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };

        let result = Buffer.Buffer<Notification>(maxResults);
        var count = 0;

        while (count < maxResults and pendingPush.size() > 0) {
            result.add(pendingPush.remove(0));
            count += 1;
        };

        result.toArray()
    };

    public shared({ caller }) func confirmPushDelivery(
        notificationIds: [Nat]
    ) : async () {
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };

        // Remove delivered notifications from queue
        pendingPush := Buffer.filter<Notification>(
            pendingPush,
            func(notif) { not Utils.contains(notificationIds, notif.id, Nat.equal) }
        );
    };

    // ===== MAINTENANCE =====
    public shared({ caller }) func cleanupOldNotifications(
        maxAgeSeconds: Nat
    ) : async () {
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };

        let now = Time.now();
        let cutoff = now - (maxAgeSeconds * 1_000_000_000); // Convert to nanoseconds

        let toDelete = Buffer.Buffer<Nat>(0);
        for ((id, notification) in notifications.entries()) {
            if (notification.timestamp < cutoff) {
                toDelete.add(id);
            };
        };

        for (id in toDelete.vals()) {
            ignore notifications.remove(id);
        };
    };
};