import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";

actor {
  private let apiKeys = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);
  private var currentKeyIndex = 0;
  
  public func init(keys: [(Text, Text)]) : async () {
    for ((service, key) in keys.vals()) {
      apiKeys.put(service, key);
    }
  };
  
  public func rotateKey(service: Text, newKey: Text) : async () {
    apiKeys.put(service, newKey);
  };
  
  public func getCurrentKey(service: Text) : async ?Text {
    apiKeys.get(service)
  };
  
  public func makeAICall(service: Text, payload: Text) : async Text {
    let key = switch (apiKeys.get(service)) {
      case (null) { throw Error.reject("Service not configured") };
      case (?k) { k };
    };
    
    // Implement HTTPS outcall with key rotation
    try {
      await callExternalAI(service, key, payload)
    } catch (e) {
      // Rotate key on failure
      let newKey = await refreshKey(service);
      await callExternalAI(service, newKey, payload)
    }
  };
  
  private func callExternalAI(service: Text, key: Text, payload: Text) : async Text {
    // HTTPS outcall implementation
    // ...
  };
  
  private func refreshKey(service: Text) : async Text {
    // Key rotation logic
    // ...
  };
};