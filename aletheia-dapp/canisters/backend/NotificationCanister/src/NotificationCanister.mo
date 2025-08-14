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
    // Notification types
    public type NotificationChannel = { #InApp; #Push; #Email; #Webhook };
    public type NotificationPriority = { #Low; #Normal; #High; #Urgent };
    public type NotificationStatus = { #Pending; #Sent; #Failed; #Acked };

    public type NotificationPayload = {
        id : Text;
        to : Principal;
        title : Text;
        body : Text;
        meta : [(Text, Text)]; // Key-value pairs for metadata
        channels : [NotificationChannel];
        priority : NotificationPriority;
        createdAt : Int;
    };

    public type NotificationRecord = {
        payload : NotificationPayload;
        status : NotificationStatus;
        attempts : Nat;
        lastAttemptAt : ?Int;
    };

    public type NotificationPreferences = {
        channels : [NotificationChannel];
        rateLimit : Nat; // Max notifications per hour
    };

    // Stable storage
    stable var controller : Principal = initialAdmins[0];
    stable var dataVersion : Nat = 1;
    stable var authorizedCanisters : [(Principal, Bool)] = [];
    stable var notificationQueue : [(Text, NotificationRecord)] = [];
    stable var notificationHistory : [(Principal, [Text])] = [];
    stable var pushTokens : [(Principal, [Text])] = [];
    stable var webhookEndpoints : [(Principal, [Text])] = [];
    stable var lastSentTimestamps : [(Principal, Int)] = [];
    stable var maxAttempts : Nat = 3;
    stable var offchainAdapterPrincipal : ?Principal = null;
    stable var recentHashes : [(Principal, [(Text, Int)])] = []; // For deduplication

    // Mutable state
    let notifications = TrieMap.TrieMap<Text, NotificationRecord>(Text.equal, Text.hash);
    let authorizedCanistersMap = TrieMap.TrieMap<Principal, Bool>(Principal.equal, Principal.hash);
    let userPushTokens = TrieMap.TrieMap<Principal, [Text]>(Principal.equal, Principal.hash);
    let userWebhooks = TrieMap.TrieMap<Principal, [Text]>(Principal.equal, Principal.hash);
    let userHistory = TrieMap.TrieMap<Principal, [Text]>(Principal.equal, Principal.hash);
    let rateLimits = TrieMap.TrieMap<Principal, Int>(Principal.equal, Principal.hash);
    let dedupHashes = TrieMap.TrieMap<Principal, TrieMap.TrieMap<Text, Int>>(Principal.equal, Principal.hash);

    var notifications = TrieMap.TrieMap<Nat, Notification>(Nat.equal, Hash.hash);
    var userSettings = TrieMap.TrieMap<Principal, UserSettings>(Principal.equal, Principal.hash);
    var pendingPush = Buffer.Buffer<Notification>(0);
    var allowedCanisters = Buffer.Buffer<Principal>(0);
    var admins = Buffer.Buffer<Principal>(0);

    // Initialize from stable state
    system func postupgrade() {
        authorizedCanistersMap := TrieMap.fromEntries<Principal, Bool>(
            authorizedCanisters.vals(), Principal.equal, Principal.hash
        );
        
        notifications := TrieMap.fromEntries<Text, NotificationRecord>(
            notificationQueue.vals(), Text.equal, Text.hash
        );
        
        userPushTokens := TrieMap.fromEntries<Principal, [Text]>(
            pushTokens.vals(), Principal.equal, Principal.hash
        );
        
        userWebhooks := TrieMap.fromEntries<Principal, [Text]>(
            webhookEndpoints.vals(), Principal.equal, Principal.hash
        );
        
        userHistory := TrieMap.fromEntries<Principal, [Text]>(
            notificationHistory.vals(), Principal.equal, Principal.hash
        );
        
        rateLimits := TrieMap.fromEntries<Principal, Int>(
            lastSentTimestamps.vals(), Principal.equal, Principal.hash
        );
        
        // Rebuild deduplication hashes
        for ((user, hashes) in recentHashes.vals()) {
            let userMap = TrieMap.TrieMap<Text, Int>(Text.equal, Text.hash);
            for ((hash, ts) in hashes.vals()) {
                userMap.put(hash, ts);
            };
            dedupHashes.put(user, userMap);
        };
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
    public shared({ caller }) func authorizeCanister(canisterId: Principal) : async Result.Result<(), Text> {
        assertController(caller);
        authorizedCanistersMap.put(canisterId, true);
        #ok(())
    };
    
    public shared({ caller }) func revokeCanister(canisterId: Principal) : async Result.Result<(), Text> {
        assertController(caller);
        authorizedCanistersMap.delete(canisterId);
        #ok(())
    };
    
    public shared({ caller }) func setOffchainAdapter(adapter: Principal) : async Result.Result<(), Text> {
        assertController(caller);
        offchainAdapterPrincipal := ?adapter;
        #ok(())
    };
    
    public shared({ caller }) func setMaxAttempts(n: Nat) : async Result.Result<(), Text> {
        assertController(caller);
        maxAttempts := n;
        #ok(())
    };
    
    func assertController(caller: Principal) {
        if (caller != controller) {
            throw Error.reject("Unauthorized: Controller only");
        };
    };
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
    public shared({ caller }) func enqueueNotification(
        payload : NotificationPayload
    ) : async Result.Result<Text, Text> {
        // Authorization check
        if (not isAuthorized(caller) and caller != payload.to) {
            return #err("Unauthorized");
        };
        
        // Rate limiting
        switch (checkRateLimit(payload.to)) {
            case (#err(msg)) return #err(msg);
            case _ {};
        };
        
        // Deduplication check
        switch (checkDuplicate(payload)) {
            case (#err(msg)) return #err(msg);
            case _ {};
        };
        
        // Get user preferences from UserAccountCanister
        let userPrefs = await getUserPreferences(payload.to);
        let allowedChannels = intersectChannels(payload.channels, userPrefs.channels);
        
        if (allowedChannels.size() == 0) {
            return #err("No allowed channels");
        };
        
        // Generate ID if missing
        let id = if (payload.id == "") {
            generateNotificationId(payload.to, payload.createdAt)
        } else {
            payload.id
        };
        
        // Create record
        let record : NotificationRecord = {
            payload = payload;
            status = #Pending;
            attempts = 0;
            lastAttemptAt = null;
        };
        
        // Store in queue
        notifications.put(id, record);
        
        // Update history
        addToUserHistory(payload.to, id);
        
        #ok(id)
    };
    
    func getUserPreferences(user : Principal) : async NotificationPreferences {
        // TODO: Implement actual call to UserAccountCanister
        { channels = [#InApp, #Push, #Email, #Webhook], rateLimit = 10 }
    };
    
    func generateNotificationId(user : Principal, createdAt : Int) : Text {
        let prefix = Principal.toText(user);
        let hash = SHA256.fromBlob(Text.encodeUtf8(prefix # Int.toText(createdAt)));
        CRC32.toText(CRC32.fromArray(hash))
    };
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

    // Rate limiting and deduplication
    func checkRateLimit(user : Principal) : Result.Result<(), Text> {
        let now = Time.now();
        let window = 3600_000_000_000; // 1 hour in nanoseconds
        switch (rateLimits.get(user)) {
            case (?lastTime) {
                if (now - lastTime < window) {
                    #err("Rate limit exceeded")
                } else {
                    rateLimits.put(user, now);
                    #ok(())
                }
            };
            case null {
                rateLimits.put(user, now);
                #ok(())
            };
        }
    };
    
    func checkDuplicate(payload : NotificationPayload) : Result.Result<(), Text> {
        let hash = generateContentHash(payload);
        let now = Time.now();
        let window = 300_000_000_000; // 5 minutes
        
        switch (dedupHashes.get(payload.to)) {
            case (?userHashes) {
                switch (userHashes.get(hash)) {
                    case (?timestamp) {
                        if (now - timestamp < window) {
                            #err("Duplicate notification")
                        } else {
                            userHashes.put(hash, now);
                            #ok(())
                        }
                    };
                    case null {
                        userHashes.put(hash, now);
                        #ok(())
                    };
                }
            };
            case null {
                let userHashes = TrieMap.TrieMap<Text, Int>(Text.equal, Text.hash);
                userHashes.put(hash, now);
                dedupHashes.put(payload.to, userHashes);
                #ok(())
            };
        }
    };
    
    func generateContentHash(payload : NotificationPayload) : Text {
        let content = payload.title # payload.body # debug_show(payload.meta);
        let hash = SHA256.fromBlob(Text.encodeUtf8(content));
        CRC32.toText(CRC32.fromArray(hash))
    };
    
    func intersectChannels(requested : [NotificationChannel], allowed : [NotificationChannel]) : [NotificationChannel] {
        Array.filter<NotificationChannel>(requested, func(c) {
            Array.find<NotificationChannel>(allowed, func(a) { a == c }) != null
        })
    };
    
    // Utility functions
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

