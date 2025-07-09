import Principal "mo:base/Principal";
import List "mo:base/List";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Result "mo:base/Result";
import _ "mo:base/Option";

actor NotificationCanister {
    public type NotificationId = Nat;
    
    public type Notification = {
        id: NotificationId;
        userId: Principal;
        message: Text;
        notificationType: Text;
        isRead: Bool;
        timestamp: Int;
    };
    
    public type NotificationRequest = {
        userId: Principal;
        message: Text;
        notificationType: Text;
    };
    
    public type NotificationResponse = {
        id: NotificationId;
        message: Text;
        notificationType: Text;
        isRead: Bool;
        timestamp: Int;
    };
    
    var notifications: List.List<Notification> = List.nil();
    var nextId: NotificationId = 0;
    
    // Send notification to a user
    public shared ({ caller }) func sendNotification(req: NotificationRequest) : async Result.Result<(), Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous callers cannot send notifications");
        };
        
        let newNotification: Notification = {
            id = nextId;
            userId = req.userId;
            message = req.message;
            notificationType = req.notificationType;
            isRead = false;
            timestamp = Time.now();
        };
        
        notifications := List.push(newNotification, notifications);
        nextId += 1;
        Debug.print("Notification sent to user: " # Principal.toText(req.userId));
        #ok(())
    };
    
    // Mark notification as read
    public shared ({ caller }) func markAsRead(id: NotificationId) : async Result.Result<(), Text> {
        let result = List.find(notifications, func (n: Notification) : Bool { n.id == id });
        
        switch (result) {
            case (null) { return #err("Notification not found"); };
            case (?notification) {
                if (notification.userId != caller) {
                    return #err("Unauthorized: You can only mark your own notifications as read");
                };
                
                let updatedNotifications = List.map(notifications, func (n: Notification) : Notification {
                    if (n.id == id) {
                        { n with isRead = true }
                    } else {
                        n
                    }
                });
                
                notifications := updatedNotifications;
                #ok(())
            };
        }
    };
    
    // Get unread notifications for current user
    public shared query ({ caller }) func getUnreadNotifications() : async [NotificationResponse] {
        let userNotifications = List.filter(notifications, func (n: Notification) : Bool {
            n.userId == caller and not n.isRead
        });
        
        List.toArray(
            List.map(userNotifications, func (n: Notification) : NotificationResponse {
                {
                    id = n.id;
                    message = n.message;
                    notificationType = n.notificationType;
                    isRead = n.isRead;
                    timestamp = n.timestamp;
                }
            })
        )
    };
    
    // Get all notifications for current user
    public shared query ({ caller }) func getAllNotifications() : async [NotificationResponse] {
        let userNotifications = List.filter(notifications, func (n: Notification) : Bool {
            n.userId == caller
        });
        
        List.toArray(
            List.map(userNotifications, func (n: Notification) : NotificationResponse {
                {
                    id = n.id;
                    message = n.message;
                    notificationType = n.notificationType;
                    isRead = n.isRead;
                    timestamp = n.timestamp;
                }
            })
        )
    };
    
    // System method to clear expired notifications (original logic preserved)
    public func clearExpiredNotifications(threshold: Int) : async () {
        notifications := List.filter(notifications, func (n: Notification) : Bool {
            n.timestamp > threshold
        });
    };
    
    // Additional methods from original implementation
    public shared ({ caller }) func deleteNotification(id: NotificationId) : async Result.Result<(), Text> {
        let result = List.find(notifications, func (n: Notification) : Bool { n.id == id });
        
        switch (result) {
            case (null) { return #err("Notification not found"); };
            case (?notification) {
                if (notification.userId != caller) {
                    return #err("Unauthorized: You can only delete your own notifications");
                };
                
                notifications := List.filter(notifications, func (n: Notification) : Bool { n.id != id });
                #ok(())
            };
        }
    };
    
    public shared query func getNotificationCount(userId: Principal) : async Nat {
        let userNotifications = List.filter(notifications, func (n: Notification) : Bool {
            n.userId == userId
        });
        List.size(userNotifications)
    };
};