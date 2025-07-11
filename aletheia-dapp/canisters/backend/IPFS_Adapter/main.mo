import HTTP "mo:base/Http";
import Blob "mo:base/Blob";
import Text "mo:base/Text";

actor {
  let ipfsGateway = "https://ipfs.aletheia.xyz";
  
  public func upload(data: Blob) : async Text {
    let url = ipfsGateway # "/api/v0/add";
    let headers = [("Content-Type", "application/octet-stream")];
    let body = data;
    
    let response = await HTTP.request({
      method = "POST";
      url = url;
      headers = headers;
      body = body;
      transform = null;
    });
    
    if (response.status == 200) {
      parseCID(response.body)
    } else {
      throw Error.reject("IPFS upload failed: " # debug_show(response))
    }
  };
  
  private func parseCID(body: Blob) : Text {
    // Extract CID from JSON response
    // ...
  };
};