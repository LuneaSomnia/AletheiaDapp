import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Principal "mo:base/Principal";
import Nat16 "mo:base/Nat16";

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

actor {
  let ipfsGateway : Text = "https://ipfs.aletheia.xyz";
  
  // Public function to upload data to IPFS
  public shared func upload(data : Blob) : async Result.Result<Text, Text> {
    let url = ipfsGateway # "/api/v0/add";
    
    let requestHeaders = [
      ("Content-Type", "application/octet-stream"),
    ];
    
    let requestBody = Blob.toArray(data);
    
    try {
      let response = await ic.http_request({
        url = url;
        method = "POST";
        body = requestBody;
        headers = requestHeaders;
        transform = null;
        max_response_bytes = null;
      });
      if (response.status_code == 200) {
        // Parse CID from response
        let cid = parseCIDFromResponse(Blob.fromArray(response.body));
        switch (cid) {
          case (null) { #err("Failed to parse CID from response") };
          case (?c) { #ok(c) };
        };
      } else {
        #err("IPFS upload failed with status: " # Nat.toText(Nat16.toNat(response.status_code)))
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
    
    // HTTP outcalls are not available in query functions
    #err("HTTP outcalls are not available in query functions. Use an update call instead.")
  };
};