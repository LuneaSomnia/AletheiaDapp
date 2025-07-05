import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Int "mo:base/Int";

actor AletheianProfileCanister {
  type AletheianId = Principal;
  type Badge = Text;
  type Rank = {
    #Trainee;
    #Junior;
    #Associate;
    #Senior;
    #Expert;
    #Master;
  };
  
  type Profile = {
    username: ?Text;
    createdAt: Int;
    lastActive: Int;
    xp: Nat;
    rank: Rank;
    badges: [Badge];
    warnings: Nat;
    performance: PerformanceMetrics;
  };
  
  type PerformanceMetrics = {
    accuracy: Float;
    avgVerificationTime: Nat;
    claimsVerified: Nat;
    escalationsResolved: Nat;
  };
  
  let profiles = HashMap.HashMap<AletheianId, Profile>(0, Principal.equal, Principal.hash);
  let usernameToPrincipal = HashMap.HashMap<Text, AletheianId>(0, Text.equal, Text.hash);
  
  // Create a new profile
  public shared ({ caller }) func createProfile(username: ?Text) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous users cannot create profiles");
    };
    
    switch (profiles.get(caller)) {
      case (?_) { #err("Profile already exists") };
      case null {
        let newProfile: Profile = {
          username = username;
          createdAt = Time.now();
          lastActive = Time.now();
          xp = 0;
          rank = #Trainee;
          badges = [];
          warnings = 0;
          performance = {
            accuracy = 0.0;
            avgVerificationTime = 0;
            claimsVerified = 0;
            escalationsResolved = 0;
          };
        };
        
        profiles.put(caller, newProfile);
        
        switch (username) {
          case (?name) { usernameToPrincipal.put(name, caller) };
          case null {};
        };
        
        #ok(())
      }
    }
  };
  
  // Get profile by principal
  public shared query ({ caller }) func getProfile() : async Result.Result<Profile, Text> {
    switch (profiles.get(caller)) {
      case (?profile) { #ok(profile) };
      case null { #err("Profile not found") };
    }
  };
  
  // Update profile
  public shared ({ caller }) func updateProfile(username: ?Text) : async Result.Result<(), Text> {
    switch (profiles.get(caller)) {
      case (?profile) {
        // Remove old username mapping
        switch (profile.username) {
          case (?oldName) { ignore usernameToPrincipal.remove(oldName) };
          case null {};
        };
        
        // Add new username mapping
        switch (username) {
          case (?newName) { usernameToPrincipal.put(newName, caller) };
          case null {};
        };
        
        let updatedProfile: Profile = {
          profile with 
          username = username;
          lastActive = Time.now();
        };
        
        profiles.put(caller, updatedProfile);
        #ok(())
      };
      case null { #err("Profile not found") };
    }
  };
  
  // Update XP and rank
  public shared ({ caller }) func updateXP(xpDelta: Int) : async Result.Result<(), Text> {
    switch (profiles.get(caller)) {
      case (?profile) {
       let newXP: Nat = Nat.fromInt(Int.abs(profile.xp + xpDelta));
        let newRank = calculateRank(newXP);
        
        let updatedProfile: Profile = {
          profile with 
          xp = newXP;
          rank = newRank;
          lastActive = Time.now();
        };
        
        profiles.put(caller, updatedProfile);
        #ok(())
      };
      case null { #err("Profile not found") };
    }
  };
  
  // Add a badge
  public shared ({ caller }) func addBadge(badge: Badge) : async Result.Result<(), Text> {
    switch (profiles.get(caller)) {
      case (?profile) {
        if (Array.find<Badge>(profile.badges, func(b) { b == badge }) != null) {
          return #err("Badge already exists");
        };
        
        let updatedBadges = Array.append(profile.badges, [badge]);
        let updatedProfile: Profile = {
          profile with 
          badges = updatedBadges;
          lastActive = Time.now();
        };
        
        profiles.put(caller, updatedProfile);
        #ok(())
      };
      case null { #err("Profile not found") };
    }
  };
  
  // Internal function to calculate rank based on XP
  func calculateRank(xp: Nat) : Rank {
    if (xp >= 10000) #Master
    else if (xp >= 5000) #Expert
    else if (xp >= 2000) #Senior
    else if (xp >= 1000) #Associate
    else if (xp >= 500) #Junior
    else #Trainee
  };
};
