import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Http "mo:base/Http";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Option "mo:base/Option";

actor {
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
        let updatedBackups = Array.tabulate(backups.size() - 1, func i { backups[i + 1] });
        
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
    
    let request : HTTP.HttpRequestArgs = {
      url = url;
      method = "POST";
      body = Blob.toArray(Text.encodeUtf8(requestBody));
      headers = requestHeaders;
      transform = null;
    };
    
    let response = await HTTP.http_request(request);
    
    if (response.status_code != 200) {
      throw Error.reject("API error: " # Nat.toText(response.status_code));
    };
    
    Text.decodeUtf8(Blob.fromArray(response.body)) 
      |? "Invalid UTF-8 response";
  };
};