import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Result "mo:base/Result";

actor GamifiedLearningCanister {
  type ModuleId = Text;
  type ExerciseId = Text;
  type UserId = Principal;
  
  type Question = {
    id: Text;
    text: Text;
    options: [Text];
    correctAnswer: Nat;
  };
  
  type Exercise = {
    id: ExerciseId;
    title: Text;
    content: Text;
    questions: [Question];
    points: Nat;
  };
  
  type Module = {
    id: ModuleId;
    title: Text;
    description: Text;
    exercises: [ExerciseId];
    requiredPoints: Nat;
  };
  
  type UserProgress = {
    completedExercises: [ExerciseId];
    earnedPoints: Nat;
  };
  
  let modules = HashMap.HashMap<ModuleId, Module>(0, Text.equal, Text.hash);
  let exercises = HashMap.HashMap<ExerciseId, Exercise>(0, Text.equal, Text.hash);
  let userProgress = HashMap.HashMap<UserId, UserProgress>(0, Principal.equal, Principal.hash);
  
  // Add a learning module
  public shared func addModule(module: Module) : async () {
    modules.put(module.id, module);
  };
  
  // Add an exercise
  public shared func addExercise(exercise: Exercise) : async () {
    exercises.put(exercise.id, exercise);
  };
  
  // Complete an exercise
  public shared ({ caller }) func completeExercise(
    exerciseId: ExerciseId, 
    answers: [Nat]
  ) : async Result.Result<Nat, Text> {
    switch (exercises.get(exerciseId)) {
      case (?exercise) {
        // Validate answers
        if (answers.size() != exercise.questions.size()) {
          return #err("Invalid number of answers");
        };
        
        // Calculate score
        var correctAnswers = 0;
        for (i in Iter.range(0, exercise.questions.size() - 1)) {
          if (answers[i] == exercise.questions[i].correctAnswer) {
            correctAnswers += 1;
          };
        };
        
        let pointsEarned = correctAnswers * exercise.points / exercise.questions.size();
        
        // Update user progress
        let progress = switch (userProgress.get(caller)) {
          case (?p) p;
          case null {
            { completedExercises = []; earnedPoints = 0 }
          };
        };
        
        let updatedProgress: UserProgress = {
          completedExercises = Array.append(progress.completedExercises, [exerciseId]);
          earnedPoints = progress.earnedPoints + pointsEarned;
        };
        
        userProgress.put(caller, updatedProgress);
        #ok(pointsEarned)
      };
      case null { #err("Exercise not found") };
    }
  };
  
  // Get user progress
  public shared query ({ caller }) func getProgress() : async UserProgress {
    switch (userProgress.get(caller)) {
      case (?progress) progress;
      case null { { completedExercises = []; earnedPoints = 0 } };
    }
  };
};