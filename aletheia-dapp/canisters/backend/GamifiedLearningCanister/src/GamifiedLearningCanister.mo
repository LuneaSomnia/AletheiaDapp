import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Float "mo:base/Float";

actor class GamifiedLearningCanister() {
    type UserId = Principal;
    type ModuleId = Text;
    type LessonId = Text;
    type QuestionId = Text;
    type RewardPoints = Nat;

    public type Answer = {
        questionId : QuestionId;
        selectedOption : Text;
    };

    public type Question = {
        id : QuestionId;
        questionText : Text;
        options : [Text];
        correctOption : Text;
        explanation : Text;
    };

    public type Lesson = {
        id : LessonId;
        title : Text;
        content : Text;
        questions : [Question];
        rewardPoints : RewardPoints;
    };

    public type Module = {
        id : ModuleId;
        title : Text;
        description : Text;
        lessons : [Lesson];
    };

    public type LessonProgress = {
        lessonId : LessonId;
        completed : Bool;
        score : Float;
        lastAttempted : Int;
    };

    public type UserProgress = {
        userId : UserId;
        completedModules : [ModuleId];
        lessonProgress : [LessonProgress];
        totalRewardPoints : RewardPoints;
    };

    public type QuizResult = {
        score : Float;
        correctAnswers : Nat;
        totalQuestions : Nat;
        rewardPointsEarned : RewardPoints;
    };

    // State
    stable var modules : [Module] = [];
    stable var userProgressEntries : [(UserId, UserProgress)] = [];
    
    var userProgress = HashMap.HashMap<UserId, UserProgress>(
        0,
        Principal.equal,
        Principal.hash
    );

    // Initialize with sample modules
    public func seedModules() : async () {
        modules := [
            {
                id = "digital-literacy-101";
                title = "Digital Literacy Fundamentals";
                description = "Learn essential digital skills for the modern world";
                lessons = [
                    {
                        id = "internet-basics";
                        title = "Internet Fundamentals";
                        content = "Understanding how the internet works, browsers, and websites...";
                        rewardPoints = 50;
                        questions = [
                            {
                                id = "q1";
                                questionText = "What does URL stand for?";
                                options = [
                                    "Uniform Resource Locator",
                                    "Universal Reference Link",
                                    "Unified Resource Library",
                                    "Uniform Retrieval Location"
                                ];
                                correctOption = "Uniform Resource Locator";
                                explanation = "A URL (Uniform Resource Locator) is the address of a resource on the internet.";
                            },
                            {
                                id = "q2";
                                questionText = "Which protocol is used for secure web browsing?";
                                options = ["HTTP", "FTP", "HTTPS", "SMTP"];
                                correctOption = "HTTPS";
                                explanation = "HTTPS (HyperText Transfer Protocol Secure) encrypts data between your browser and websites.";
                            }
                        ];
                    },
                    {
                        id = "online-safety";
                        title = "Online Safety Practices";
                        content = "Protecting yourself and your data online...";
                        rewardPoints = 75;
                        questions = [
                            {
                                id = "q1";
                                questionText = "What's the strongest type of password?";
                                options = [
                                    "Short dictionary words",
                                    "Long phrases with mixed characters",
                                    "Your pet's name",
                                    "12345678"
                                ];
                                correctOption = "Long phrases with mixed characters";
                                explanation = "Long passphrases with upper/lower case letters, numbers and symbols are most secure.";
                            }
                        ];
                    }
                ];
            },
            {
                id = "web3-fundamentals";
                title = "Web3 Essentials";
                description = "Understanding blockchain, crypto, and decentralized systems";
                lessons = [
                    {
                        id = "blockchain-basics";
                        title = "Blockchain Technology";
                        content = "How blockchains work and their key features...";
                        rewardPoints = 100;
                        questions = [];
                    }
                ];
            }
        ];
    };

    // Public interface
    public shared query func getAvailableModules() : async [Module] {
        // Return modules without answers
        Array.map<Module, Module>(
            modules,
            func(m) {
                {
                    id = m.id;
                    title = m.title;
                    description = m.description;
                    lessons = Array.map<Lesson, Lesson>(
                        m.lessons,
                        func(lesson) {
                            {
                                id = lesson.id;
                                title = lesson.title;
                                content = lesson.content;
                                rewardPoints = lesson.rewardPoints;
                                questions = [];
                            };
                        }
                    );
                };
            }
        );
    };

    public shared query func getLessonContent(moduleId : ModuleId, lessonId : LessonId) : async Result.Result<Lesson, Text> {
        switch (findLesson(moduleId, lessonId)) {
            case (null) { #err("Lesson not found") };
            case (?lesson) {
                // Return lesson without correct answers
                let sanitizedLesson : Lesson = {
                    id = lesson.id;
                    title = lesson.title;
                    content = lesson.content;
                    rewardPoints = lesson.rewardPoints;
                    questions = Array.map<Question, Question>(
                        lesson.questions,
                        func(q) {
                            {
                                id = q.id;
                                questionText = q.questionText;
                                options = q.options;
                                correctOption = "";
                                explanation = "";
                            };
                        }
                    );
                };
                #ok(sanitizedLesson);
            };
        };
    };

    public shared (msg) func submitLessonAnswers(
        moduleId : ModuleId,
        lessonId : LessonId,
        answers : [Answer]
    ) : async Result.Result<QuizResult, Text> {
        let userId = msg.caller;
        switch (findLesson(moduleId, lessonId)) {
            case (null) { #err("Lesson not found") };
            case (?lesson) {
                // Calculate score
                let totalQuestions = lesson.questions.size();
                var correctAnswers = 0;

                for (answer in answers.vals()) {
                    switch (Array.find(lesson.questions, func(q : Question) : Bool { q.id == answer.questionId })) {
                        case (null) {};
                        case (?question) {
                            if (question.correctOption == answer.selectedOption) {
                                correctAnswers += 1;
                            };
                        };
                    };
                };

                let score = if (totalQuestions > 0) {
                    (Float.fromInt(correctAnswers) / Float.fromInt(totalQuestions)) * 100.0;
                } else {
                    100.0; // Lessons without questions are auto-completed
                };

                // Update progress
                let rewardPoints = if (score >= 80.0) { lesson.rewardPoints } else { 0 };
                updateUserProgress(userId, moduleId, lessonId, score, rewardPoints);

                #ok({
                    score = score;
                    correctAnswers = correctAnswers;
                    totalQuestions = totalQuestions;
                    rewardPointsEarned = rewardPoints;
                });
            };
        };
    };

    public shared query (msg) func getUserProgress() : async UserProgress {
        let userId = msg.caller;
        switch (userProgress.get(userId)) {
            case (null) {
                createDefaultProgress(userId);
            };
            case (?progress) { progress };
        };
    };

    // Internal helper functions
    func findLesson(moduleId : ModuleId, lessonId : LessonId) : ?Lesson {
    let m = Array.find(
        modules,
        func(m : Module) : Bool { m.id == moduleId }
    );

    switch (m) {
        case (null) { null };
        case (?m) {
            Array.find(
                m.lessons,
                func(lesson : Lesson) : Bool { lesson.id == lessonId }
            );
        };
    };
};

    func updateUserProgress(
        userId : UserId,
        moduleId : ModuleId,
        lessonId : LessonId,
        score : Float,
        rewardPoints : RewardPoints
    ) {
        let currentProgress = switch (userProgress.get(userId)) {
            case (null) { createDefaultProgress(userId) };
            case (?progress) { progress };
        };

        let isCompleted = score >= 80.0;
        let now = Time.now();

        // Update lesson progress
        var newProgress = Buffer.fromArray<LessonProgress>(currentProgress.lessonProgress);
        switch (Array.find(newProgress.toArray(), func(lp : LessonProgress) : Bool { lp.lessonId == lessonId })) {
            case (null) {
                newProgress.add({
                    lessonId = lessonId;
                    completed = isCompleted;
                    score = score;
                    lastAttempted = now;
                });
            };
            case (?lp) {
                newProgress := Buffer.map<UserProgress.LessonProgress, LessonProgress>(
                    newProgress,
                    func(lp) {
                        if (lp.lessonId == lessonId) {
                            {
                                lessonId = lessonId;
                                completed = lp.completed or isCompleted;
                                score = Float.max(lp.score, score);
                                lastAttempted = now;
                            };
                        } else {
                            lp;
                        };
                    }
                );
            };
        };

        // Update completed modules
        let completedModules = if (isModuleComplete(moduleId, newProgress.toArray())) {
            if (Array.find(currentProgress.completedModules, func(mid : ModuleId) : Bool { mid == moduleId }) == null) {
                Buffer.fromArray<ModuleId>(currentProgress.completedModules).add(moduleId).toArray();
            } else {
                currentProgress.completedModules;
            };
        } else {
            currentProgress.completedModules;
        };

        // Update rewards
        let newRewards = currentProgress.totalRewardPoints + rewardPoints;

        let updatedProgress : UserProgress = {
            userId = userId;
            completedModules = completedModules;
            lessonProgress = newProgress.toArray();
            totalRewardPoints = newRewards;
        };

        userProgress.put(userId, updatedProgress);
    };

    func isModuleComplete(moduleId : ModuleId, progress : [LessonProgress]) : Bool {
    switch (Array.find(modules, func(m : Module) : Bool { m.id == moduleId })) {
        case (null) { false };
        case (?m) {
            Array.all(
                m.lessons,
                func(lesson : Lesson) : Bool {
                    switch (Array.find(progress, func(p : LessonProgress) : Bool { p.lessonId == lesson.id })) {
                        case (null) { false };
                        case (?lp) { lp.completed };
                    };
                }
            );
        };
    };
};

    func createDefaultProgress(userId : UserId) : UserProgress {
        {
            userId = userId;
            completedModules = [];
            lessonProgress = [];
            totalRewardPoints = 0;
        };
    };

    // Upgrade hooks
    system func preupgrade() {
        userProgressEntries := Iter.toArray(userProgress.entries());
    };

    system func postupgrade() {
        userProgress := HashMap.fromIter<UserId, UserProgress>(
            userProgressEntries.vals(),
            userProgressEntries.size(),
            Principal.equal,
            Principal.hash
        );
        userProgressEntries := [];
    };
};