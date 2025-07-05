import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import _ "mo:prim";
import Iter "mo:base/Iter";
import Int "mo:base/Int";


actor ClaimSubmissionCanister {
  type Event = {
    #ClaimSubmitted : Claim;
    #ClaimStatusUpdated : { id: ClaimId; oldStatus: {#Pending; #Processing; #Completed}; newStatus: {#Pending; #Processing; #Completed} };
  };
  
private let eventListeners = HashMap.HashMap<Principal, [shared Event -> ()]>(0, Principal.equal, Principal.hash);

public shared({ caller }) func addEventListener(listener: shared Event -> ()) : async () {
  let existing = switch (eventListeners.get(caller)) {
    case (?list) list;
    case null [];
  };
  eventListeners.put(caller, Array.append(existing, [listener]));
};

  public shared({ caller }) func removeEventListener(listener: shared Event -> ()) : async () {
    switch (eventListeners.get(caller)) {
      case (?existing) {
        let filtered = Array.filter(existing, func(l : shared Event -> ()) : Bool = l != listener);
        eventListeners.put(caller, filtered);
      };
      case null {};
    };
  };
  
private func emit(event: Event ) : async () {
  for (listeners in eventListeners.vals()) {
    for (handler in listeners.vals()) {
       handler(event); // Proper fire-and-forget
    };
  };
};
  type ClaimId = Text;
  type ClaimType = {
    #Text;
    #Image;
    #Video;
    #Audio;
    #Link;
    #Url;
  };
  
  type Claim = {
    id: ClaimId;
    userId: Principal;
    content: Text;
    claimType: ClaimType;
    source: ?Text;
    context: ?Text;
    submittedAt: Int;
    status: {
      #Pending;
      #Processing;
      #Completed;
    };
  };
  
  // Add retention limits
  let MAX_CLAIMS_PER_USER = 1000;
  let MAX_CLAIM_AGE = 30 * 24 * 60 * 60 * 1_000_000_000; // 30 days in nanoseconds
  
  let claims = HashMap.HashMap<ClaimId, Claim>(0, Text.equal, Text.hash);
  let userClaims = HashMap.HashMap<Principal, [ClaimId]>(0, Principal.equal, Principal.hash);
  
  // Submit a new claim
  public shared ({ caller }) func submitClaim(
    content: Text,
    claimType: ClaimType,
    source: ?Text,
    context: ?Text
  ) : async Result.Result<ClaimId, Text> {
    if (Principal.isAnonymous(caller)) {
      return #err("Anonymous users cannot submit claims");
    };
    
    // Validate content length
    if (Text.size(content) < 10) {
      return #err("Claim content too short - minimum 10 characters");
    };
    
    if (Text.size(content) > 5000) {
      return #err("Claim content too long - maximum 5000 characters");
    };
    
    // Validate URL format if present
    switch (claimType, source) {
      case ((#Link or #Url), ?url) {
        if (not Text.startsWith(url, #text("http://")) 
          and not Text.startsWith(url, #text("https://"))) {
          return #err("Invalid URL format - must start with http:// or https://");
        };
      };
      case _ {};
    };
    
let claimId = "claim_" # Int.toText(Int.abs(Time.now()));
let newClaim: Claim = {
  id = claimId;
  userId = caller;
  content;
  claimType;
  source;
  context;
  submittedAt = Int.abs(Time.now());
  status = #Pending;
};
    claims.put(claimId, newClaim);
    
    // Add to user's claims
    let currentClaims = switch (userClaims.get(caller)) {
      case (?ids) ids;
      case null [];
    };
    userClaims.put(caller, Array.append(currentClaims, [claimId]));
    
    // Emit event and notify system
    await emit(#ClaimSubmitted(newClaim));
    // let _ = await AletheianDispatchCanister.processClaim(newClaim); // Uncomment when interface is defined
    
    #ok(claimId)
  };
  
  // Get claim by ID
  public shared query func getClaim(claimId: ClaimId) : async ?Claim {
    claims.get(claimId)
  };
  
  // Get user's claims
  public shared query ({ caller }) func getUserClaims(skip: Nat, limit: Nat) : async [Claim] {
    switch (userClaims.get(caller)) {
      case (?claimIds) {
        let sliced = Iter.toArray(Array.slice(claimIds, skip, skip + limit));
        Array.mapFilter<ClaimId, Claim>(
          sliced,
          func(id) { claims.get(id) }
        )
      };
      case null [];
    }
  };
};
