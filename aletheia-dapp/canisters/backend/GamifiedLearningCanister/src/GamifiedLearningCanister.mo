import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Array "mo:base/Array";
import AI_Integration "canister:AI_Integration";
import UserAccount "canister:UserAccount";

actor {
  type ModuleId = Nat;
  type UserId = Principal;
  
  type LearningModule = {
    id : ModuleId;
    title : Text;
    content : Text;
    difficulty : Nat; // 1-5 scale
    topic : Text;
    questions : [Question];
  };
  
  type Question = {
    text : Text;
    options : [Text];
    correctIndex : Nat;
    explanation : Text;
  };
  
  type UserProgress = {
    completedModules : [ModuleId];
    currentModule : ?ModuleId;
    totalXP : Nat;
    subscriptionCredit : Float; // Percentage discount
  };
  
  private var nextModuleId : ModuleId = 1;
  private let modules = HashMap.HashMap<ModuleId, LearningModule>(0, Nat.equal, Hash.hash);
  private let userProgress = HashMap.HashMap<UserId, UserProgress>(0, Principal.equal, Principal.hash);
  
  // Create a new learning module
  public shared ({ caller }) func createModule(title : Text, content : Text, difficulty : Nat, topic : Text) : async ModuleId {
    let moduleId = nextModuleId;
    nextModuleId += 1;
    
    let newModule : LearningModule = {
      id = moduleId;
      title = title;
      content = content;
      difficulty = difficulty;
      topic = topic;
      questions = generateQuestions(content);
    };
    
    modules.put(moduleId, newModule);
    moduleId;
  };
  
  // Generate questions for a module (simplified)
  private func generateQuestions(content : Text) : [Question] {
    // In production, this would use AI to generate questions
    [{
      text = "What is the main topic of this module?";
      options = ["Critical Thinking", "Fact Checking", "Media Literacy", "All of the above"];
      correctIndex = 3;
      explanation = "The module covers all these aspects of information verification.";
    }];
  };
  
  // Generate personalized module using AI
  public shared ({ caller }) func generatePersonalizedModule(topic : Text) : async Result.Result<LearningModule, Text> {
    try {
      let userData = switch (userProgress.get(caller)) {
        case (null) { "new user" };
        case (?progress) { "experienced user with " # Nat.toText(progress.totalXP) # " XP" };
      };
      
      let prompt = "Create a critical thinking learning module about " # topic 
        # " for " # userData # ". Include 3 multiple-choice questions.";
      
      let aiResponse = await AI_Integration.generateContent(prompt);
      
      let newModuleId = nextModuleId;
      nextModuleId += 1;
      
      let newModule : LearningModule = {
        id = newModuleId;
        title = "AI-Generated: " # topic;
        content = aiResponse;
        difficulty = 3; // Default difficulty
        topic = topic;
        questions = parseAIQuestions(aiResponse);
      };
      
      modules.put(newModuleId, newModule);
      
      // Assign to user
      assignModuleToUser(caller, newModuleId);
      
      #ok(newModule);
    } catch (e) {
      #err("Failed to generate module: " # Error.message(e));
    };
  };
  
  // Simplified parser for demo
  private func parseAIQuestions(content : Text) : [Question] {
    // In production, this would parse structured AI response
    [{
      text = "What did you learn from this module?";
      options = ["Critical evaluation", "Source checking", "Bias detection", "All of the above"];
      correctIndex = 3;
      explanation = "This module covered all these essential skills.";
    }];
  };
  
  private func assignModuleToUser(user : UserId, moduleId : ModuleId) {
    let progress = switch (userProgress.get(user)) {
      case (null) { { completedModules = []; currentModule = ?moduleId; totalXP = 0; subscriptionCredit = 0.0 } };
      case (?p) { { p with currentModule = ?moduleId } };
    };
    userProgress.put(user, progress);
  };
  
  // Complete a module and award XP
  public shared ({ caller }) func completeModule(moduleId : ModuleId, score : Float) : async Result.Result<Nat, Text> {
    switch (modules.get(moduleId)) {
      case (null) { #err("Module not found") };
      case (?learningmodule) {
        let xpEarned = calculateXP(learningmodule.difficulty, score);
        let progress = switch (userProgress.get(caller)) {
          case (null) { 
            let newProgress : UserProgress = {
              completedModules = [moduleId];
              currentModule = null;
              totalXP = xpEarned;
              subscriptionCredit = Float.fromInt(xpEarned) / 1000.0;
            };
            newProgress
          };
          case (?p) {
            let newCompleted = Array.append(p.completedModules, [moduleId]);
            let newXP = p.totalXP + xpEarned;
            let newCredit = p.subscriptionCredit + (Float.fromInt(xpEarned) / 1000.0);
            { 
              completedModules = newCompleted; 
              currentModule = null;
              totalXP = newXP;
              subscriptionCredit = newCredit;
            }
          };
        };
        
        userProgress.put(caller, progress);
        
        // Apply subscription credit to user account
        await UserAccount.applySubscriptionCredit(caller, progress.subscriptionCredit);
        
        #ok(progress.totalXP);
      };
    };
  };
  
  private func calculateXP(difficulty : Nat, score : Float) : Nat {
    let baseXP = difficulty * 20;
    Float.toInt(Float.fromInt(baseXP) * score)
  };
};