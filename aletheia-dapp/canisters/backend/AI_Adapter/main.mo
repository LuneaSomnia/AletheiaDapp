import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Time "mo:base/Time";

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import CRC32 "mo:base/CRC32";
import SHA256 "mo:base/SHA256";

actor class AI_Adapter() = this {
    // Stable state
    stable var stableApiKeys : [(Text, Text)] = []; // (provider, encryptedKey)
    stable var stableRateLimits : [(Principal, Nat, Nat64)] = []; // (principal, callsPerMinute, lastReset)
    stable var stableMode : Types.DeploymentMode = #Direct;
    stable var stableStats : (Nat, Nat) = (0, 0); // (success, errors)
    stable var stableLastError : ?Text = null;

    // Runtime state
    let apiKeys = HashMap.fromIter<Text, Text>(
        stableApiKeys.vals(), 10, Text.equal, Text.hash);
    let rateLimits = HashMap.HashMap<Principal, (Nat, Nat64)>(
        10, Principal.equal, Principal.hash);
    var mode = stableMode;
    var stats = stableStats;
    var lastError = stableLastError;

    // Constants
    let MAX_RETRIES = 3;
    let BASE_RETRY_DELAY_MS = 1000;
    let RATE_LIMIT_RESET_INTERVAL_MS = 60_000_000_000; // 1 minute in nanoseconds

    // Management canister interface
    let ic : actor {
        http_request : {
            url : Text;
            method : Text;
            headers : [(Text, Text)];
            body : [Nat8];
            transform : ?{
                function : Principal;
                context : [Nat8];
            };
            max_response_bytes : ?Nat;
        } -> async {
            status_code : Nat16;
            headers : [(Text, Text)];
            body : [Nat8];
        };
    } = actor ("aaaaa-aa");

    // Transform function for HTTP requests
    public query func transform(raw : Types.TransformArgs) : async Types.CanisterHttpResponsePayload {
        let transformed : Types.CanisterHttpResponsePayload = {
            status = raw.response.status;
            headers = raw.response.headers;
            body = raw.response.body;
        };
        transformed;
    };

    // Utility functions
    func generateRequestId(claimId: Text) : Text {
        let now = Nat64.toNat(Int.abs(Time.now()));
        let hash = SHA256.fromBlob(Text.encodeUtf8(claimId # Nat.toText(now)));
        CRC32.toText(CRC32.fromArray(hash))
    };

    func checkRateLimit(caller: Principal) : Result.Result<(), Text> {
        switch (rateLimits.get(caller)) {
            case (?(limit, resetTime)) {
                if (Time.now() > resetTime) {
                    rateLimits.put(caller, (limit, Time.now() + RATE_LIMIT_RESET_INTERVAL_MS));
                    #ok();
                } else if (limit > 0) {
                    rateLimits.put(caller, (limit - 1, resetTime));
                    #ok();
                } else {
                    #err("Rate limit exceeded");
                }
            };
            case null { #ok() }; // No rate limit set
        }
    };

    func withRetry<T>(fn : () -> async T, retries: Nat) : async Result.Result<T, Text> {
        try {
            #ok(await fn());
        } catch (e) {
            if (retries > 0) {
                let delayMs = BASE_RETRY_DELAY_MS * (2 ** (MAX_RETRIES - retries));
                await Async.sleep(delayMs);
                await withRetry(fn, retries - 1);
            } else {
                #err(Error.message(e));
            }
        }
    };

    // Core API implementation
    public shared({ caller }) func sendForProcessing(req : Types.AIAdapterRequest) : async Types.AIAdapterResponse {
        switch (checkRateLimit(caller)) {
            case (#err(msg)) { return #Error("429", msg, true) };
            case _ {};
        };

        let requestId = generateRequestId(req.claimId);
        let startTime = Time.now();

        try {
            let result = await processRequest(req, requestId);
            stats := (stats.0 + 1, stats.1);
            result;
        } catch (e) {
            lastError := ?(Error.message(e));
            stats := (stats.0, stats.1 + 1);
            #Error("500", "Processing failed: " # Error.message(e), true);
        }
    };

    func processRequest(req: Types.AIAdapterRequest, requestId: Text) : async Types.AIAdapterResponse {
        switch (mode) {
            case (#Direct) {
                await handleDirectRequest(req, requestId)
            };
            case (#Bridge(bridgeCfg)) {
                await handleBridgeRequest(req, requestId, bridgeCfg)
            };
        }
    };

    func handleDirectRequest(req: Types.AIAdapterRequest, requestId: Text) : async Types.AIAdapterResponse {
        // Implementation for direct HTTP calls
        // ... (similar to existing code but with enhanced security)
    };

    func handleBridgeRequest(req: Types.AIAdapterRequest, requestId: Text, bridgeCfg: Types.BridgeConfig) : async Types.AIAdapterResponse {
        // Implementation for bridge mode with signed requests
        // ... (generates signed payload for off-chain processing)
    };

    // Other core functions (getEmbedding, fetchURL, etc) follow similar patterns

    // Admin API implementation
    public shared({ caller }) func setMode(newMode: Types.DeploymentMode) {
        assert _isAdmin(caller);
        mode := newMode;
    };

    public shared({ caller }) func setApiKey(provider: Text, encryptedKey: Text) {
        assert _isAdmin(caller);
        apiKeys.put(provider, encryptedKey);
    };

    public shared query func getConfiguredProviders() : async [Text] {
        Iter.toArray(apiKeys.keys());
    };

    public shared({ caller }) func setRateLimit(principal: Principal, limit: Nat) {
        assert _isAdmin(caller);
        rateLimits.put(principal, (limit, Time.now() + RATE_LIMIT_RESET_INTERVAL_MS));
    };

    // Monitoring API
    public shared query func getRequestStats() : async (Nat, Nat) { stats };
    public shared query func getLastError() : async ?Text { lastError };

    // Upgrade hooks
    system func preupgrade() {
        stableApiKeys := Iter.toArray(apiKeys.entries());
        stableRateLimits := Iter.toArray(rateLimits.entries());
        stableMode := mode;
        stableStats := stats;
        stableLastError := lastError;
    };

    system func postupgrade() {
        apiKeys := HashMap.fromIter<Text, Text>(stableApiKeys.vals(), 10, Text.equal, Text.hash);
        rateLimits := HashMap.fromIter<Principal, (Nat, Nat64)>(stableRateLimits.vals(), 10, Principal.equal, Principal.hash);
        mode := stableMode;
        stats := stableStats;
        lastError := stableLastError;
    };

    // Private helpers
    func _isAdmin(caller: Principal) : Bool {
        // Implement admin check based on your governance model
        true // Replace with actual auth check
    };
  
  type ServiceName = Text;
  
  // Service -> Current Key
  private let activeKeys = HashMap.HashMap<ServiceName, ApiKey>(0, Text.equal, Text.hash);
  
  // Service -> Backup Keys
  private let backupKeys = HashMap.HashMap<ServiceName, [Text]>(0, Text.equal, Text.hash);
  
  // Initialize with services and keys
  public func init(services : [(ServiceName, Text, [Text])]) : async () {
    for ((service, key, backups) in services.vals()) {
      activeKeys.put(service, {
        value = key;
        lastUsed = 0;
        usageCount = 0;
      });
      backupKeys.put(service, backups);
    };
  };
  
  // Rotate keys for a service
  public shared func rotateKey(service : ServiceName) : async () {
    switch (backupKeys.get(service)) {
      case (null) { throw Error.reject("No backup keys for service: " # service) };
      case (?backups) {
        if (backups.size() == 0) {
          throw Error.reject("No backup keys available for rotation");
        };
        
        // Get current key
        let currentKey = Option.get(activeKeys.get(service), 
          { value = ""; lastUsed = 0; usageCount = 0 });
        
        // Move first backup to active
        let newKey = backups[0];
        let updatedBackups : [Text] = Array.tabulate<Text>(backups.size() - 1, func i { backups[i + 1] }); // Explicit type annotation
        
        activeKeys.put(service, {
          value = newKey;
          lastUsed = 0;
          usageCount = 0;
        });
        
        // Add old key to end of backups
        backupKeys.put(service, Array.append(updatedBackups, [currentKey.value]));
      };
    };
  };
  
  // Make AI API call
  public shared func makeAICall(service : ServiceName, payload : Text) : async Text {
    let key = switch (activeKeys.get(service)) {
      case (null) { throw Error.reject("Service not configured: " # service) };
      case (?k) { k.value };
    };
    
    try {
      let response = await callExternalAPI(service, key, payload);
      
      // Update key usage
      switch (activeKeys.get(service)) {
        case (null) {};
        case (?k) {
          activeKeys.put(service, {
            value = k.value;
            lastUsed = Time.now();
            usageCount = k.usageCount + 1;
          });
        };
      };
      
      response;
    } catch (e) {
      // Rotate key and retry on failure
      await rotateKey(service);
      await makeAICall(service, payload);
    };
  };
  
  private func callExternalAPI(service : ServiceName, key : Text, payload : Text) : async Text {
    let url = switch (service) {
      case "openai" { "https://api.openai.com/v1/completions" };
      case "anthropic" { "https://api.anthropic.com/v1/complete" };
      case _ { throw Error.reject("Unsupported service: " # service) };
    };
    
    let requestHeaders = [
      ("Content-Type", "application/json"),
      ("Authorization", "Bearer " # key),
    ];
    
    let requestBody = switch (service) {
      case "openai" {
        "{ \"model\": \"text-davinci-003\", \"prompt\": \"" # payload # "\", \"max_tokens\": 150 }"
      };
      case "anthropic" {
        "{ \"prompt\": \"" # payload # "\", \"model\": \"claude-v1\", \"max_tokens_to_sample\": 150 }"
      };
      case _ { "" };
    };
    
    let response = await ic.http_request({
      url = url;
      method = "POST";
      body = Blob.toArray(Text.encodeUtf8(requestBody)); // Fix: ensure [Nat8] type
      headers = requestHeaders;
      transform = null;
      max_response_bytes = null;
    });
    
    if (response.status_code != 200) {
      return "API error: " # Nat.toText(Nat16.toNat(response.status_code));
    };
    switch (Text.decodeUtf8(Blob.fromArray(response.body))) {
      case (?text) text;
      case null "Invalid UTF-8 response";
    }
  }
}
