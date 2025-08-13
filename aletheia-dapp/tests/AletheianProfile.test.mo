import A "canister:AletheianProfileCanister";
import Principal "mo:base/Principal";

actor {
    public func runTests() : async Text {
        let alice = Principal.fromText("2vxsx-fae");
        let bob = Principal.fromText("2chlq-3z7u7-7zamd");
        
        // Test registration
        let reg1 = await A.registerAletheian("Alice");
        let reg2 = await A.registerAletheian("Alice"); // Duplicate
        
        // Test profile retrieval
        let myProfile = await A.getMyProfile();
        let publicProfile = await A.getProfile(alice);
        
        // Test XP updates
        let xpResult = await A.updateXP(alice, 100);
        let xpNegative = await A.updateXP(alice, -200);
        
        // Test availability
        let availResult = await A.setAvailability(#busy);
        
        // Test badge assignment
        let badgeResult = await A.assignBadge(alice, #expert);
        
        // Format results
        var output = "";
        output #= "Registration: " # debug_show(reg1) # "\n";
        output #= "Duplicate Reg: " # debug_show(reg2) # "\n";
        output #= "XP Update: " # debug_show(xpResult) # "\n";
        output #= "Negative XP: " # debug_show(xpNegative) # "\n";
        output #= "Availability: " # debug_show(availResult) # "\n";
        output #= "Badge Assign: " # debug_show(badgeResult) # "\n";
        output
    };
};
