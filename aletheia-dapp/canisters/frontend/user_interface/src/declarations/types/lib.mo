module {
    public type ModuleId = Text;
    public type ExerciseId = Text;
    public type UserId = Principal;

    public type Question = {
        id: Text;
        text: Text;
        options: [Text];
        correctAnswerIndex: Nat;
    };

    public type Exercise = {
        id: ExerciseId;
        title: Text;
        content: Text;
        questions: [Question];
        pointsPerCorrectAnswer: Nat;
    };

    public type LearningModule = {
        id: ModuleId;
        title: Text;
        description: Text;
        exerciseIds: [ExerciseId];
    };

    public type UserProgress = {
        completedExercises: [ExerciseId];
        earnedPoints: Nat;
    };

    public type CompleteExerciseResult = {
        #Ok : Nat;
        #Err : Text;
    };
};