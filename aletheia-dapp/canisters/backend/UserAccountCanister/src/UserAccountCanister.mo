import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Time "mo:base/Time";

actor UserAccountCanister {
  type UserId = Principal;
  type ClaimId = Text;
  
  type UserProfile = {
    username: ?Text;
    createdAt: Int;
    lastActive: Int;
    learningPoints: Nat;
    submittedClaims: [ClaimId];
  };
  
  let userProfiles = HashMap.HashMap<UserId, UserProfile>(0, Principal.equal, Principal.hash);
  let usernameToPrincipal = HashMap.HashMap<Text, UserId>(0, Text.equal, Text.hash);
  
  // Create a new user profile
  public shared ({ caller }) func createProfile(username: ?Text) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous users cannot create profiles");
    };
    
    switch (userProfiles.get(caller)) {
      case (?_) { #err("Profile already exists") };
      case null {
        let newProfile: UserProfile = {
          username = username;
          createdAt = Time.now();
          lastActive = Time.now();
          learningPoints = 0;
          submittedClaims = [];
        };
        
        userProfiles.put(caller, newProfile);
        
        switch (username) {
          case (?name) { usernameToPrincipal.put(name, caller) };
          case null {};
        };
        
        #ok(())
      }
    }
  };
  
  // Get user profile
  public shared query ({ caller }) func getProfile() : async Result.Result<UserProfile, Text> {
    switch (userProfiles.get(caller)) {
      case (?profile) { #ok(profile) };
      case null { #err("Profile not found") };
    }
  };
  
  // Add a submitted claim
  public shared ({ caller }) func addSubmittedClaim(claimId: ClaimId) : async Result.Result<(), Text> {
    switch (userProfiles.get(caller)) {
      case (?profile) {
        let updatedProfile: UserProfile = {
          profile with 
          submittedClaims = Array.append(profile.submittedClaims, [claimId]);
          lastActive = Time.now();
        };
        userProfiles.put(caller, updatedProfile);
        #ok(())
      };
      case null { #err("Profile not found") };
    }
  };
  
  // Add learning points
  public shared ({ caller }) func addLearningPoints(points: Nat) : async Result.Result<(), Text> {
    switch (userProfiles.get(caller)) {
      case (?profile) {
        let updatedProfile: UserProfile = {
          profile with 
          learningPoints = profile.learningPoints + points;
          lastActive = Time.now();
        };
        userProfiles.put(caller, updatedProfile);
        #ok(())
      };
      case null { #err("Profile not found") };
    }
  };
};