import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap"; // CORRECTED: Switched to TrieMap for standard state management.
import Array "mo:base/Array";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Nat "mo:base/Nat";

// The actor is anonymous, which is standard practice.
actor {
  // --- Type Definitions ---
  type UserId = Principal;

  // The variant type for different notification categories.
  type NotificationType = {
    #NewClaimAssignment;
    #ClaimVerified;
    #EscalationRequired;
    #PaymentReceived;
    #SystemAlert;
  };

  // The Notification object itself. `read` is now a mutable field.
  type Notification = {
    id: Nat;
    userId: UserId;
    type: NotificationType;
    message: Text;
    timestamp: Time.Time; // Using the Time alias for clarity.
    var read: Bool; // CORRECTED: Made mutable to allow in-place updates.
    link: ?Text;
  };

  // --- Canister State ---
  // CORRECTED: The state is now a TrieMap of Users to a mutable Array of Notifications.
  // This is far more efficient than using an immutable List.
  private var notifications: TrieMap.TrieMap<UserId, [var Notification]> = TrieMap.empty();
  private var nextId: Nat = 0;

  // --- Update Functions ---

  // Send a single notification.
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
      var read = false;
      link = link;
    };

    // Get the user's existing notification array, or create a new one.
    let userNotifs = switch (notifications.get(userId)) {
      case (?arr) { arr; };
      case (null) {
        let newArr : [var Notification] = [];
        notifications.put(userId, newArr);
        newArr;
      };
    };

    // Add the new notification to the front of the array.
    userNotifs := Array.append([notif], userNotifs);
    return id;
  };

  // Send the same notification to multiple users.
  public shared func sendBulkNotifications(
    userIds: [UserId],
    type: NotificationType,
    message: Text,
    link: ?Text
  ) : async () {
    for (userId in userIds.vals()) {
      // We don't need to wait for each notification to be sent.
      ignore sendNotification(userId, type, message, link);
    };
  };

  // Mark a specific notification as read.
  public shared func markAsRead(notificationId: Nat) : async Bool {
    let caller = msg.caller;
    switch (notifications.get(caller)) {
      case (?userNotifs) {
        // Loop through the user's notifications to find the right one.
        for (notif in userNotifs.vals()) {
          if (notif.id == notificationId) {
            notif.read := true; // Update the 'read' status in-place.
            return true;       // Return true as soon as we find it.
          };
        };
        return false; // Return false if no notification with that ID was found.
      };
      case (null) { return false; }; // User has no notifications.
    };
  };

  // Mark all of a user's notifications as read.
  public shared func markAllAsRead() : async () {
    let caller = msg.caller;
    switch (notifications.get(caller)) {
      case (?userNotifs) {
        // Loop through and update each notification.
        for (notif in userNotifs.vals()) {
          notif.read := true;
        };
      };
      case (null) { /* Do nothing if the user has no notifications. */ };
    };
  };

  // --- Query Functions ---

  // Get all notifications for the currently logged-in user.
  public query func getMyNotifications() : async [Notification] {
    switch (notifications.get(msg.caller)) {
      case (?userNotifs) { return Array.map(userNotifs, func(n){n}); }; // Return a stable copy
      case (null) { return []; };
    };
  };

  // Get only the unread notifications for the currently logged-in user.
  public query func getMyUnreadNotifications() : async [Notification] {
    switch (notifications.get(msg.caller)) {
      case (?userNotifs) {
        // Filter the array for notifications where 'read' is false.
        return Array.filter<Notification>(userNotifs, func(n) { not n.read });
      };
      case (null) { return []; };
    };
  };
}