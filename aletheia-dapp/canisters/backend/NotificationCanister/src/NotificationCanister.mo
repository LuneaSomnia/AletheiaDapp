import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Text "mo:base/Text";
import List "mo:base/List";
import Time "mo:base/Time";
import Debug "mo:base/Debug";

actor NotificationCanister {
    type UserId = Principal;
    type NotificationType = {
        #NewClaimAssignment;
        #ClaimVerified;
        #EscalationRequired;
        #PaymentReceived;
        #SystemAlert;
    };
    
    type Notification = {
        id: Nat;
        userId: UserId;
        type: NotificationType;
        message: Text;
        timestamp: Int;
        read: Bool;
        link: ?Text;
    };
    
    // In-memory storage
    private var notifications = HashMap.HashMap<Principal, List.List<Notification>>(0, Principal.equal, Principal.hash);
    private var nextId: Nat = 0;
    
    // Send a notification
    public shared func sendNotification(
        userId: UserId,
        type: NotificationType,
        message: Text,
        link: ?Text
    ) : async Nat {
        let id = nextId;
        nextId += 1;
        
        let notif: Notification = {
            id = id;
            userId = userId;
            type = type;
            message = message;
            timestamp = Time.now();
            read = false;
            link = link;
        };
        
        let userNotifs = switch (notifications.get(userId)) {
            case (?list) list;
            case null { List.nil<Notification>() };
        };
        
        let newNotifs = List.push(notif, userNotifs);
        notifications.put(userId, newNotifs);
        
        id
    };
    
    // Send bulk notifications
    public shared func sendBulkNotifications(
        userIds: [UserId],
        type: NotificationType,
        message: Text,
        link: ?Text
    ) : async () {
        for (userId in userIds.vals()) {
            ignore await sendNotification(userId, type, message, link);
        };
    };
    
    // Get notifications for a user
    public query func getNotifications(userId: UserId) : async [Notification] {
        switch (notifications.get(userId)) {
            case (?list) List.toArray(list);
            case null [];
        }
    };
    
    // Get unread notifications
    public query func getUnreadNotifications(userId: UserId) : async [Notification] {
        switch (notifications.get(userId)) {
            case (?list) List.toArray(
                List.filter(list, func(n: Notification): Bool { not n.read })
            );
            case null [];
        }
    };
    
    // Mark notification as read
    public shared func markAsRead(userId: UserId, notificationId: Nat) : async Bool {
        switch (notifications.get(userId)) {
            case (?list) {
                let (newList, found) = List.mapFilter<Notification, Notification>(list, func(n) {
                    if (n.id == notificationId) {
                        ?{ n with read = true };
                    } else {
                        ?n;
                    }
                });
                
                notifications.put(userId, newList);
                found
            };
            case null false;
        }
    };
    
    // Mark all as read
    public shared func markAllAsRead(userId: UserId) : async () {
        switch (notifications.get(userId)) {
            case (?list) {
                let newList = List.map(list, func(n: Notification): Notification {
                    { n with read = true }
                });
                notifications.put(userId, newList);
            };
            case null {};
        }
    };
};