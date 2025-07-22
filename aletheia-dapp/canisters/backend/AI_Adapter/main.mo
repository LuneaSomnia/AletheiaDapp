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

actor {
  // Define the management canister interface for http_request
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

  type ApiKey = {
    value : Text;
    lastUsed : Int;
    usageCount : Nat;
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