import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Nat64 "mo:base/Nat64";

actor ClaimSubmissionCanister {
    public type ClaimId = Nat64;
    public type ClaimContent = {
        #Text : Text;
        #Image : Blob;
        #Video : Blob;
        #Audio : Blob;
        #Link : Text;
        #Url : Text;
    };
    
    type Claim = {
        content : ClaimContent;
        creator : Principal;
        timestamp : Int;
        claimId : ClaimId;
    };

    // Stable storage for upgrades
    stable let stableStorage = do {
        var claims : HashMap.HashMap<ClaimId, Claim> = HashMap.HashMap(32, Nat64.equal, Hash.hash);
        var entries : [(ClaimId, Claim)] = [];
        
        public func preupgrade() {
            entries := HashMap.toArray(claims);
        };
        
        public func postupgrade() {
            claims := HashMap.fromIter<ClaimId, Claim>(
                entries.vals(), entries.size(), Nat64.equal, Hash.hash
            );
            entries := [];
        };
        
        object {
            public let claims = claims;
            public let preupgrade = preupgrade;
            public let postupgrade = postupgrade;
        }
    };

    let claims : HashMap.HashMap<ClaimId, Claim> = stableStorage.claims;

    // TODO: Implement integration with AletheianDispatchCanister
    private func aletheianDispatchCall(claimId : ClaimId) : async () {
        // Placeholder for future integration
    };

    // Submit a new claim with authentication
    public shared(msg) func submitClaim(content : ClaimContent) : async Result.Result<ClaimId, Text> {
        let claimId = Nat64.fromNat(Int.abs(Time.now()));
        let claim = {
            content = content;
            creator = msg.caller;
            timestamp = Time.now();
            claimId = claimId;
        };
        
        switch (claims.put(claimId, claim)) {
            case null {
                ignore aletheianDispatchCall(claimId); // Async fire-and-forget
                #ok(claimId);
            };
            case _ { #err("Claim ID collision occurred") };
        };
    };

    // Get single claim by ID
    public query func getClaim(claimId : ClaimId) : async ?Claim {
        claims.get(claimId)
    };

    // Get all claims for current user
    public shared query(msg) func getUserClaims() : async [Claim] {
        let userClaims = HashMap.filter<ClaimId, Claim>(
            claims,
            func(_, claim) { claim.creator == msg.caller }
        );
        HashMap.vals(userClaims)
    };
}
