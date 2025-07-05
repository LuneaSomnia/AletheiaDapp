import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Result "mo:base/Result";

// This import is correct, it allows us to use shared types.
import Types "src/declarations/types";

// The actor name is conventionally removed to make it an anonymous actor,
// which is standard practice.
actor {
  // --- Type Definitions ---
  // These types are specific to this canister's internal logic.
  type ModuleId = Text;
  type ExerciseId = Text;
  type UserId = Principal; // This is an alias for Principal

  type Question = {
    id: Text;
    text: Text;
    options: [Text];
    correctAnswerIndex: Nat;
  };

  type Exercise = {
    id: ExerciseId;
    title: Text;
    content: Text; // e.g., A mock article or scenario
    questions: [Question];
    pointsPerCorrectAnswer: Nat;
  };

  type LearningModule = {
    id: ModuleId;
    title: Text;
    description: Text;
    exerciseIds: [ExerciseId];
  };

  type UserProgress = {
    var completedExercises: [ExerciseId];
    var earnedPoints: Nat;
  };

  // --- Canister State ---
  // CORRECTED: The variable name `moduleData` was a typo. It has been renamed to `modules`
  // to match its usage in the `addModule` and `getAllModules` functions.
  private var modules: TrieMap.TrieMap<ModuleId, LearningModule> = TrieMap.empty();
  private var exercises: TrieMap.TrieMap<ExerciseId, Exercise> = TrieMap.empty();
  private var userProgress: TrieMap.TrieMap<UserId, UserProgress> = TrieMap.empty();
  private let admin: Principal = msg.caller; // The deployer is the admin

  // --- Admin Functions ---
  // These functions allow the admin to add new learning content.
  public shared func addModule(module: LearningModule) : async () {
    // TODO: Add authorization: if (msg.caller != admin) { throw Error.reject("Unauthorized"); };
    modules.put(module.id, module);
  };

  public shared func addExercise(exercise: Exercise) : async () {
    // TODO: Add authorization
    exercises.put(exercise.id, exercise);
  };

  // --- User-Facing Functions ---

  // Called by a user to submit their answers for a specific exercise.
  public shared func completeExercise(
    exerciseId: ExerciseId,
    answers: [Nat] // An array of indices corresponding to the user's chosen options
  ) : async Result.Result<Nat, Text> {

    let caller = msg.caller;

    // Step 1: Get the exercise from the map.
    switch (exercises.get(exerciseId)) {
      case (null) {
        return Result.Err("Exercise not found.");
      };
      case (?exercise) {
        // Step 2: Validate the input.
        if (answers.size() != exercise.questions.size()) {
          return Result.Err("Invalid number of answers submitted.");
        };

        // Step 3: Calculate the score.
        var correctAnswersCount: Nat = 0;
        for (i in 0 ..< answers.size()) {
          if (answers[i] == exercise.questions[i].correctAnswerIndex) {
            correctAnswersCount += 1;
          };
        };

        let pointsEarned: Nat = correctAnswersCount * exercise.pointsPerCorrectAnswer;

        // Step 4: Update the user's progress.
        // Get the user's existing progress, or create a new one if it's their first time.
        let progress = switch (userProgress.get(caller)) {
          case (?p) { p; }; // User has existing progress
          case (null) {
            // Create a new progress record for the user
            let newProgress: UserProgress = { var completedExercises = []; var earnedPoints = 0; };
            userProgress.put(caller, newProgress);
            newProgress;
          };
        };

        // Add the completed exercise and update points.
        // This prevents users from re-taking an exercise for more points.
        // The Array.contains function needs a proper equality check for Text.
        if (not Array.contains<ExerciseId>(progress.completedExercises, exerciseId, Text.equal)) {
            progress.completedExercises := Array.append(progress.completedExercises, [exerciseId]);
            progress.earnedPoints += pointsEarned;
        };

        return Result.Ok(pointsEarned);
      };
    };
  };

  // A query function for the user to see their own progress.
  public query func getMyProgress() : async ?UserProgress {
    return userProgress.get(msg.caller);
  };

  // A query function to get all available learning modules for the frontend to display.
  public query func getAllModules() : async [LearningModule] {
    return TrieMap.values(modules);
  };
}