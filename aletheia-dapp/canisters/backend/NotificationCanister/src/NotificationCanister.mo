import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
// import Types "Types";
// import Utils "Utils";

// Minimal stubs for Types and Utils to allow compilation
actor class NotificationCanister(initialAdmins: [Principal]) = this {
    // Minimal type stubs
    type Notification = {
        id : Nat;
        userId : Principal;
        title : Text;
        body : Text;
        timestamp : Int;
        read : Bool;
        notificationType : Text;
    };
    type UserSettings = {
        inApp : Bool;
        push : Bool;
        email : Bool;
        pushTokens : [Text];
        disabledTypes : [Text];
    };
    type NotificationType = Text;
    type NotificationPreference = Text;

    // All stable and var declarations must come before any functions in Motoko
    stable var nextNotificationId: Nat = 0;
    stable var stableNotifications: [Notification] = [];
    stable var stableUserSettings: [(Principal, UserSettings)] = [];
    stable var stablePendingPush: [Notification] = [];
    stable var stableAllowedCanisters: [Principal] = [];

    var notifications = TrieMap.TrieMap<Nat, Notification>(Nat.equal, Hash.hash);
    var userSettings = TrieMap.TrieMap<Principal, UserSettings>(Principal.equal, Principal.hash);
    var pendingPush = Buffer.Buffer<Notification>(0);
    var allowedCanisters = Buffer.Buffer<Principal>(0);
    var admins = Buffer.Buffer<Principal>(0);

    // Initialize from stable state
    system func postupgrade() {
        // Convert stableNotifications to iterator of (Nat, Notification)
        let notifIter = stableNotifications.vals();
        let notifTuples = object {
            var i = 0;
            public func next() : ?(Nat, Notification) {
                switch (notifIter.next()) {
                    case null null;
                    case (?n) {
                        let idx = i;
                        i += 1;
                        ?(idx, n)
                    }
                }
            }
        };
        notifications := TrieMap.fromEntries<Nat, Notification>(notifTuples, Nat.equal, Hash.hash);

        // Convert stableUserSettings to iterator of (Principal, UserSettings)
        let userIter = stableUserSettings.vals();
        let userTuples = object {
            public func next() : ?(Principal, UserSettings) {
                userIter.next()
            }
        };
        userSettings := TrieMap.fromEntries<Principal, UserSettings>(userTuples, Principal.equal, Principal.hash);

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
        contains(admins, caller, Principal.equal)
    };

    private func isAllowedCanister(caller: Principal) : Bool {
        contains(allowedCanisters, caller, Principal.equal)
    };

    private func validateCaller(caller: Principal) : ?Text {
        if (Principal.isAnonymous(caller)) {
            return ?"Anonymous callers not allowed";
        };
        null
    };

    // ===== ADMIN MANAGEMENT =====
    public shared({ caller }) func addAdmin(newAdmin: Principal) : async () {
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };
        if (not contains(admins, newAdmin, Principal.equal)) {
            admins.add(newAdmin);
        };
    };

    public shared({ caller }) func removeAdmin(admin: Principal) : async () {
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };
        let size = admins.size();
        admins := bufferFilter<Principal>(admins, func(p) { p != admin });
        if (admins.size() == 0) {
            throw Error.reject("Cannot remove last admin");
        };
    };

    public query func getAdmins() : async [Principal] {
        admins.toArray()
    };

    // ===== CANISTER AUTHORIZATION =====
    public shared({ caller }) func addAllowedCanister(canisterId: Principal) : async () {
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };
        if (not contains(allowedCanisters, canisterId, Principal.equal)) {
            allowedCanisters.add(canisterId);
        };
    };

    public shared({ caller }) func removeAllowedCanister(canisterId: Principal) : async () {
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };
        allowedCanisters := bufferFilter<Principal>(allowedCanisters, func(p) { p != canisterId });
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
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
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
            inApp = optionOrDefault(inApp, settings.inApp);
            push = optionOrDefault(push, settings.push);
            email = optionOrDefault(email, settings.email);
            pushTokens = settings.pushTokens;
            disabledTypes = optionOrDefault(disabledTypes, settings.disabledTypes);
        };

        userSettings.put(caller, newSettings);
        newSettings
    };

    public shared({ caller }) func registerPushToken(token: Text) : async () {
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
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
        if (not containsArr(settings.pushTokens, token, Text.equal)) {
            let newTokens = Array.append(settings.pushTokens, [token]);
            userSettings.put(caller, {
                settings with pushTokens = newTokens;
            });
        };
    };

    public shared({ caller }) func unregisterPushToken(token: Text) : async () {
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
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
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
        let result = switch (userSettings.get(caller)) {
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
        };
        result
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
                if (containsArr<Text>(settings.disabledTypes, notifType, func(a : Text, b : Text) : Bool { a == b })) {
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
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
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
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
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
            case (null) 0;
            case (?t) t;
        };
        let maxResults = optionOrDefault(limit, 100);
        let filterUnread = optionOrDefault(unreadOnly, false);

        label notifLoop for (notification in notifications.vals()) {
            if (notification.userId == caller and
                notification.timestamp >= cutoff and
                (not filterUnread or not notification.read)) 
            {
                userNotifs.add(notification);
                if (userNotifs.size() >= maxResults) break notifLoop;
            };
        };

        // TODO: Implement sorting if needed. Motoko 0.9.8 may not have Array.sort. Return unsorted for now.
        userNotifs.toArray()
    };

    // ===== PUSH PROCESSING INTERFACE =====
    public shared({ caller }) func getPendingPushNotifications(
        maxResults: Nat
    ) : async [Notification] {
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
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
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
        if (not isAdmin(caller)) {
            throw Error.reject("Unauthorized: Admin access required");
        };

        // Remove delivered notifications from queue
        pendingPush := bufferFilter<Notification>(
            pendingPush,
            func(notif) { not containsArr(notificationIds, notif.id, Nat.equal) }
        );
    };

    // ===== MAINTENANCE =====
    public shared({ caller }) func cleanupOldNotifications(
        maxAgeSeconds: Nat
    ) : async () {
        switch (validateCaller(caller)) {
            case (?err) { throw Error.reject(err) };
            case null {};
        };
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

    // Utility functions must be at the end of the actor class in Motoko 0.9.8
    func contains<T>(buf : Buffer.Buffer<T>, value : T, eq : (T, T) -> Bool) : Bool {
        for (v in buf.vals()) {
            if (eq(v, value)) return true;
        };
        false
    };
    func containsArr<T>(arr : [T], value : T, eq : (T, T) -> Bool) : Bool {
        for (v in arr.vals()) {
            if (eq(v, value)) return true;
        };
        false
    };
    func optionOrDefault<T>(opt : ?T, def : T) : T {
        switch (opt) { case null def; case (?v) v };
    };
    func bufferFilter<T>(buf : Buffer.Buffer<T>, pred : (T) -> Bool) : Buffer.Buffer<T> {
        let out = Buffer.Buffer<T>(0);
        for (v in buf.vals()) {
            if (pred(v)) out.add(v);
        };
        out
    };
};