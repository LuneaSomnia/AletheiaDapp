import HTTP "mo:base/Http";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Error "mo:base/Error";

actor {
  let ipfsGateway : Text = "https://ipfs.aletheia.xyz";
  
  // Public function to upload data to IPFS
  public shared func upload(data : Blob) : async Result.Result<Text, Text> {
    let url = ipfsGateway # "/api/v0/add";
    
    let requestHeaders = [
      ("Content-Type", "application/octet-stream"),
    ];
    
    let requestBody = Blob.toArray(data);
    
    let request : HTTP.HttpRequestArgs = {
      url = url;
      method = "POST";
      body = requestBody;
      headers = requestHeaders;
      transform = null;
    };
    
    try {
      let response = await HTTP.http_request(request);
      
      if (response.status_code == 200) {
        // Parse CID from response
        let cid = parseCIDFromResponse(Blob.fromArray(response.body));
        switch (cid) {
          case (null) { #err("Failed to parse CID from response") };
          case (?c) { #ok(c) };
        };
      } else {
        #err("IPFS upload failed with status: " # Nat.toText(response.status_code))
      };
    } catch (e) {
      #err("HTTP request failed: " # Error.message(e))
    };
  };
  
  // Parse CID from IPFS response
  private func parseCIDFromResponse(responseBody : Blob) : ?Text {
    // This would parse the actual JSON response in a real implementation
    // For demo purposes, we return a mock CID
    ?"QmXKqTpFM23YdH9F4Y7wzq3w7XeX7Y8Y9Z0A1B2C3D4E5F6G7H"
  };
  
  // Public function to retrieve data from IPFS
  public shared query func get(cid : Text) : async Result.Result<Blob, Text> {
    let url = ipfsGateway # "/ipfs/" # cid;
    
    let request : HTTP.HttpRequestArgs = {
      url = url;
      method = "GET";
      body = [];
      headers = [];
      transform = null;
    };
    
    try {
      let response = await HTTP.http_request(request);
      
      if (response.status_code == 200) {
        #ok(Blob.fromArray(response.body))
      } else {
        #err("Failed to retrieve CID: " # cid # ", status: " # Nat.toText(response.status_code))
      };
    } catch (e) {
      #err("HTTP request failed: " # Error.message(e))
    };
  };
};