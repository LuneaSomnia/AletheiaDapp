import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import _ "mo:base/Debug";

actor AletheianDispatchCanister {
  type ClaimId = Text;
  type AletheianId = Principal;
  type Claim = {
    id: ClaimId;
    content: Text;
    category: ?Text;
    complexity: Text; // "Low", "Medium", "High"
    submittedAt: Int;
  };

  type AletheianProfile = {
    id: AletheianId;
    expertise: [Text]; // Categories of expertise
    reputation: Nat; // XP
    status: Text; // "available", "busy", "offline"
    location: ?Text; // Optional for geo-assignment
    lastActive: Int;
  };

  // In-memory storage
  private var claimsQueue = List.nil<Claim>();
  private var aletheianProfiles = HashMap.HashMap<AletheianId, AletheianProfile>(0, Principal.equal, Principal.hash);
  private var assignments = HashMap.HashMap<ClaimId, [AletheianId]>(0, Text.equal, Text.hash);
  private var aletheianWorkload = HashMap.HashMap<AletheianId, Nat>(0, Principal.equal, Principal.hash);

  // Register an Aletheian profile
  public shared func registerAletheian(profile: AletheianProfile) : async Result.Result<(), Text> {
    aletheianProfiles.put(profile.id, profile);
    aletheianWorkload.put(profile.id, 0);
    #ok(())
  };

  // Update Aletheian status
  public shared func updateAletheianStatus(
    aletheianId: AletheianId, 
    status: Text
  ) : async Result.Result<(), Text> {
    switch (aletheianProfiles.get(aletheianId)) {
      case (?profile) {
        let updated = {
          profile with 
          status = status;
          lastActive = Time.now();
        };
        aletheianProfiles.put(aletheianId, updated);
        #ok(())
      };
      case null #err("Aletheian not found");
    }
  };

  // Add a claim to the queue
  public shared func addClaim(claim: Claim) : async Result.Result<(), Text> {
    claimsQueue := List.push(claim, claimsQueue);
    #ok(())
  };

  // Assign claims to Aletheians
  public shared func assignClaims() : async Result.Result<(), Text> {
    // 1. Filter by status
    let available = Buffer.Buffer<AletheianProfile>(0);
    for (profile in aletheianProfiles.vals()) {
      if (profile.status == "available") {
        available.add(profile);
      };
    };

    if (available.size() < 3) {
      return #err("Not enough available Aletheians");
    };

    // 2. Filter by expertise if claim has category
    let qualified = Buffer.Buffer<AletheianProfile>(0);
    for (claim in Iter.fromList(claimsQueue)) {
      switch (claim.category) {
        case (?category) {
          for (profile in available.vals()) {
            if (Array.find<Text>(profile.expertise, func(e) { e == category }) != null) {
              qualified.add(profile);
            };
          };
        };
        case null {
          for (profile in available.vals()) {
            qualified.add(profile);
          };
        };
      };
    };

      if (qualified.size() < 3) {
        return #err("Not enough qualified Aletheians");
      };
  
      // If you reach here, assignment logic would go here.
      // For now, just return ok(()) to satisfy the return type.
      return #ok(());
  }; 
  // Get workload of an Aletheian
  public shared func getWorkload(aletheianId: AletheianId) : async Result.Result<Nat, Text> {
    switch (aletheianWorkload.get(aletheianId)) {
      case (?workload) #ok(workload);
      case null #err("Aletheian not found");
    }
  }
}