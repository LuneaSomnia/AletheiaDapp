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
import Debug "mo:base/Debug";

actor class GamifiedLearningCanister(initialController : Principal) {
    type UserId = Principal;
    
    // Stable state storage
    stable var modules : [(ModuleId, Types.Module)] = [];
    stable var userProgress : [(Text, Types.UserProgress)] = [];
    stable var moduleOrder : [Types.ModuleId] = [];
    stable var authorizedCanisters : [(Principal, Bool)] = [];
    stable var controller : Principal = initialController;
    stable var dataVersion : Nat = 1;

    // Mutable state
    let moduleStore = HashMap.fromIter<Types.ModuleId, Types.Module>(
        modules.vals(), modules.size(), Text.equal, Text.hash);
    let progressStore = HashMap.fromIter<Text, Types.UserProgress>(
        userProgress.vals(), userProgress.size(), Text.equal, Text.hash);
    let authorizedCanisterStore = HashMap.fromIter<Principal, Bool>(
        authorizedCanisters.vals(), authorizedCanisters.size(), Principal.equal, Principal.hash);

    // Canister references
    let userAccount : actor {
        recordActivity : (Principal, Types.ActivityRecord) -> async Result.Result<(), Text>;
    } = actor("UserAccountCanister");
    
    let reputation : actor {
        awardXP : (Principal, Nat, Text) -> async Result.Result<(), Text>;
    } = actor("ReputationLogicCanister");
    
    let notification : actor {
        sendNotification : (Principal, Text, Text, Text) -> async Nat;
    } = actor("NotificationCanister");

    // Helper functions
    func generateProgressId(user : Principal, moduleId : Types.ModuleId) : Text {
        Principal.toText(user) # "-" # moduleId
    };

    func validateModuleInput(m : Types.ModuleInput) : Result.Result<(), Text> {
        if (m.title == "") { return #err("Title cannot be empty") };
        if (m.xpReward == 0) { return #err("XP reward must be positive") };
        if (m.lessons.size() == 0) { return #err("Module must have at least one lesson") };
        #ok(())
    };

    func keyEquals(key1 : Text, key2 : Text) : Bool { key1 == key2 };
    func keyHash(key : Text) : Hash.Hash { Text.hash(key) };

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
        aiFeedback : Text; // Added AI-generated feedback
    };

    public type Lesson = {
        id : LessonId;
        title : Text;
        content : Text;
        questions : [Question];
        rewardPoints : RewardPoints;
        difficulty : Text; // Added difficulty level
    };

    public type Module = {
        id : ModuleId;
        title : Text;
        description : Text;
        lessons : [Lesson];
        category : Text; // Added category for filtering
    };

    public type LessonProgress = {
        lessonId : LessonId;
        completed : Bool;
        score : Float;
        lastAttempted : Int;
        attempts : Nat; // Track number of attempts
    };

    public type UserProgress = {
        userId : UserId;
        completedModules : [ModuleId];
        lessonProgress : [LessonProgress];
        totalRewardPoints : RewardPoints;
        streak : Nat; // Daily streak counter
        lastActive : Int; // Last active timestamp
        achievements : [Text]; // Earned achievements
    };

    public type QuizResult = {
        score : Float;
        correctAnswers : Nat;
        totalQuestions : Nat;
        rewardPointsEarned : RewardPoints;
        feedback : [Text]; // AI-powered feedback
        nextRecommended : ?Lesson; // Recommended next lesson
    };

    // State
    stable var modules : [Module] = [];
    stable var userProgressEntries : [(UserId, UserProgress)] = [];
    
    var userProgress = HashMap.HashMap<UserId, UserProgress>(
        0,
        Principal.equal,
        Principal.hash
    );

    // AI feedback templates
    let aiFeedbackTemplates = [
        "Great job! You're mastering this concept.",
        "Nice work! Consider reviewing the explanation to reinforce your understanding.",
        "Good effort! Focus on the key concepts for improvement.",
        "You're making progress! Try practicing similar questions to strengthen your skills."
    ];

    // Achievement names
    let achievementNames = [
        "First Steps", "Quick Learner", "Perfect Score", "Critical Thinker",
        "Misinformation Buster", "Source Detective", "Daily Learner"
    ];

    // Canister references
    let userAccount = actor ("UserAccountCanister") : actor {
        recordActivity : (userId : Principal, activity : {
            claimId : Text;
            timestamp : Int;
            activityType : { #claimSubmitted; #factChecked; #learningCompleted };
        }) -> async ();
    };

    let notification = actor ("NotificationCanister") : actor {
        sendNotification : (userId : Principal, title : Text, message : Text, notifType : Text) -> async Nat;
    };

    // Initialize with comprehensive modules
    public func seedModules() : async () {
        modules := [
            {
                id = "digital-literacy-101";
                title = "Digital Literacy Fundamentals";
                description = "Learn essential digital skills for the modern world";
                category = "Foundations";
                lessons = [
                    {
                        id = "internet-basics";
                        title = "Internet Fundamentals";
                        content = "Understanding how the internet works, browsers, and websites...";
                        rewardPoints = 50;
                        difficulty = "Beginner";
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
                                aiFeedback = "Understanding URLs helps you navigate and evaluate online resources effectively.";
                            },
                            {
                                id = "q2";
                                questionText = "Which protocol is used for secure web browsing?";
                                options = ["HTTP", "FTP", "HTTPS", "SMTP"];
                                correctOption = "HTTPS";
                                explanation = "HTTPS (HyperText Transfer Protocol Secure) encrypts data between your browser and websites.";
                                aiFeedback = "Recognizing secure protocols is crucial for protecting your personal information online.";
                            }
                        ];
                    },
                    {
                        id = "online-safety";
                        title = "Online Safety Practices";
                        content = "Protecting yourself and your data online...";
                        rewardPoints = 75;
                        difficulty = "Intermediate";
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
                                aiFeedback = "Strong passwords are your first line of defense against unauthorized access.";
                            },
                            {
                                id = "q2";
                                questionText = "What should you do if you receive a suspicious email?";
                                options = [
                                    "Click links to verify",
                                    "Reply with personal information",
                                    "Delete without opening",
                                    "Forward to friends"
                                ];
                                correctOption = "Delete without opening";
                                explanation = "Suspicious emails may contain phishing attempts or malware.";
                                aiFeedback = "Critical evaluation of communications helps prevent security breaches.";
                            }
                        ];
                    }
                ];
            },
            {
                id = "critical-thinking";
                title = "Critical Thinking Skills";
                description = "Develop your ability to analyze information and ask the right questions";
                category = "Core Skills";
                lessons = [
                    {
                        id = "question-mirror";
                        title = "Asking the Right Questions";
                        content = "Learn how to formulate questions that uncover the truth...";
                        rewardPoints = 100;
                        difficulty = "Intermediate";
                        questions = [
                            {
                                id = "q1";
                                questionText = "What is the primary purpose of the 'Question Mirror' in Aletheia?";
                                options = [
                                    "To reflect the user's image",
                                    "To generate questions that help critically analyze a claim",
                                    "To provide answers to claims",
                                    "To mirror the claim to other users"
                                ];
                                correctOption = "To generate questions that help critically analyze a claim";
                                explanation = "The Question Mirror uses AI to generate insightful questions that help users critically evaluate claims.";
                                aiFeedback = "Asking the right questions is foundational to critical thinking and truth discovery.";
                            },
                            {
                                id = "q2";
                                questionText = "Which question would be MOST helpful when evaluating a health claim?";
                                options = [
                                    "How many people have shared this?",
                                    "What do my friends think about this?",
                                    "What scientific evidence supports this from reputable organizations?",
                                    "Does this align with my beliefs?"
                                ];
                                correctOption = "What scientific evidence supports this from reputable organizations?";
                                explanation = "Scientific evidence from reputable sources is crucial for evaluating health claims.";
                                aiFeedback = "Focusing on evidence helps separate facts from opinions.";
                            }
                        ];
                    },
                    {
                        id = "source-evaluation";
                        title = "Evaluating Sources with CRAAP";
                        content = "Learn the CRAAP model for source evaluation: Currency, Relevance, Authority, Accuracy, Purpose";
                        rewardPoints = 125;
                        difficulty = "Advanced";
                        questions = [
                            {
                                id = "q1";
                                questionText = "What does the 'A' in CRAAP stand for?";
                                options = [
                                    "Availability",
                                    "Authority",
                                    "Accuracy",
                                    "Appearance"
                                ];
                                correctOption = "Accuracy";
                                explanation = "Accuracy refers to the reliability and correctness of the information.";
                                aiFeedback = "Evaluating accuracy helps identify trustworthy information sources.";
                            },
                            {
                                id = "q2";
                                questionText = "Which factor is MOST important when evaluating a source's purpose?";
                                options = [
                                    "The design of the website",
                                    "The author's educational background",
                                    "The domain extension (.com, .org, etc.)",
                                    "Whether the intent is to inform, persuade, or sell"
                                ];
                                correctOption = "Whether the intent is to inform, persuade, or sell";
                                explanation = "Understanding purpose helps identify potential biases.";
                                aiFeedback = "Recognizing purpose enables you to interpret information in proper context.";
                            }
                        ];
                    }
                ];
            },
            {
                id = "misinformation-detection";
                title = "Identifying Misinformation";
                description = "Learn to spot and debunk common misinformation tactics";
                category = "Advanced Skills";
                lessons = [
                    {
                        id = "red-flags";
                        title = "Recognizing Misinformation Red Flags";
                        content = "Identify common signs of misinformation: emotional language, lack of sources, urgency...";
                        rewardPoints = 100;
                        difficulty = "Intermediate";
                        questions = [
                            {
                                id = "q1";
                                questionText = "Which is a common red flag for misinformation?";
                                options = [
                                    "Citations to scientific studies",
                                    "Neutral, factual language",
                                    "Emotional language and urgency",
                                    "Author credentials provided"
                                ];
                                correctOption = "Emotional language and urgency";
                                explanation = "Emotional appeals often distract from lack of evidence.";
                                aiFeedback = "Recognizing emotional manipulation helps identify potential misinformation.";
                            },
                            {
                                id = "q2";
                                questionText = "What should you suspect when a claim lacks verifiable sources?";
                                options = [
                                    "It's probably cutting-edge research",
                                    "It's likely to be accurate",
                                    "It may be misinformation",
                                    "The author is protecting sources"
                                ];
                                correctOption = "It may be misinformation";
                                explanation = "Verifiable sources are essential for credible claims.";
                                aiFeedback = "Source verification is crucial for information validation.";
                            }
                        ];
                    },
                    {
                        id = "deepfake-awareness";
                        title = "Deepfake Detection";
                        content = "Learn to identify AI-generated manipulated media";
                        rewardPoints = 150;
                        difficulty = "Advanced";
                        questions = [
                            {
                                id = "q1";
                                questionText = "Which technique helps detect deepfake videos?";
                                options = [
                                    "Checking for perfect lip-syncing",
                                    "Looking for unnatural blinking patterns",
                                    "Verifying the number of views",
                                    "Reading the comments section"
                                ];
                                correctOption = "Looking for unnatural blinking patterns";
                                explanation = "AI often struggles to replicate natural human blinking patterns.";
                                aiFeedback = "Attention to physiological details helps detect synthetic media.";
                            },
                            {
                                id = "q2";
                                questionText = "What's the MOST reliable way to verify a suspicious image?";
                                options = [
                                    "Asking friends on social media",
                                    "Using reverse image search tools",
                                    "Checking how many likes it has",
                                    "Looking at the image file size"
                                ];
                                correctOption = "Using reverse image search tools";
                                explanation = "Reverse image search can find original sources and context.";
                                aiFeedback = "Technical verification tools provide objective evidence for media analysis.";
                            }
                        ];
                    }
                ];
            }
        ];
    };

    // Public interface
    // User API implementations
    public shared query func listModules(onlyPublished : Bool) : async [Types.ModuleSummary] {
        Array.mapFilter<Types.ModuleId, Types.ModuleSummary>(
            moduleOrder,
            func(moduleId) {
                switch (moduleStore.get(moduleId)) {
                    case null { null };
                    case (?m) {
                        if (onlyPublished and not m.isPublished) {
                            null
                        } else {
                            ?{
                                id = m.id;
                                title = m.title;
                                description = m.description;
                                xpReward = m.xpReward;
                                lessonCount = m.lessons.size();
                                isPublished = m.isPublished;
                            }
                        }
                    };
                };
            }
        )
    };

    public shared query func getModule(moduleId : Types.ModuleId) : async ?Types.Module {
        moduleStore.get(moduleId)
    };

    public shared({ caller }) func enrollModule(moduleId : Types.ModuleId) : async Result.Result<Types.ProgressId, Text> {
        switch (moduleStore.get(moduleId)) {
            case null { #err("Module not found") };
            case (?module) {
                if (module.isPublished == false) {
                    return #err("Module is not published");
                };
                
                let progressId = generateProgressId(caller, moduleId);
                let now = Time.now();
                
                let progress : Types.UserProgress = {
                    progressId = progressId;
                    user = caller;
                    moduleId = moduleId;
                    lessonIndex = 0;
                    lessonStatuses = Array.init<Bool>(module.lessons.size(), false);
                    progressPercent = 0;
                    enrolledAt = now;
                    completedAt = null;
                    xpAwarded = false;
                };
                
                progressStore.put(progressId, progress);
                #ok(progressId)
            };
        };
    };

    public shared({ caller }) func recordLessonComplete(moduleId : Types.ModuleId, lessonIndex : Nat) : async Result.Result<(), Text> {
        let progressId = generateProgressId(caller, moduleId);
        
        switch (progressStore.get(progressId)) {
            case null { #err("Not enrolled in module") };
            case (?progress) {
                switch (moduleStore.get(moduleId)) {
                    case null { #err("Module not found") };
                    case (?module) {
                        if (lessonIndex >= module.lessons.size()) {
                            return #err("Invalid lesson index");
                        };
                        
                        let newStatuses = Array.tabulate<Bool>(
                            module.lessons.size(),
                            func(i) { 
                                if (i == lessonIndex) true 
                                else progress.lessonStatuses[i]
                            }
                        );
                        
                        let completed = Array.filter<Bool>(newStatuses, func(b) = b).size();
                        let newPercent = (completed * 100) / module.lessons.size();
                        
                        let updated = {
                            progress with
                            lessonIndex = lessonIndex;
                            lessonStatuses = newStatuses;
                            progressPercent = newPercent;
                        };
                        
                        progressStore.put(progressId, updated);
                        #ok(())
                    };
                };
            };
        };
    };
        // Return modules without answers
        Array.map<Module, Module>(
            modules,
            func(m) {
                {
                    id = m.id;
                    title = m.title;
                    description = m.description;
                    category = m.category;
                    lessons = Array.map<Lesson, Lesson>(
                        m.lessons,
                        func(lesson) {
                            {
                                id = lesson.id;
                                title = lesson.title;
                                content = lesson.content;
                                rewardPoints = lesson.rewardPoints;
                                difficulty = lesson.difficulty;
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
                    difficulty = lesson.difficulty;
                    questions = Array.map<Question, Question>(
                        lesson.questions,
                        func(q) {
                            {
                                id = q.id;
                                questionText = q.questionText;
                                options = q.options;
                                correctOption = "";
                                explanation = "";
                                aiFeedback = "";
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
                let feedbackBuffer = Buffer.Buffer<Text>(0);

                for (answer in answers.vals()) {
                    switch (Array.find(lesson.questions, func(q : Question) : Bool { q.id == answer.questionId })) {
                        case (null) {};
                        case (?question) {
                            if (question.correctOption == answer.selectedOption) {
                                correctAnswers += 1;
                                // Add AI feedback for correct answers
                                feedbackBuffer.add("✅ Correct! " # question.aiFeedback);
                            } else {
                                // More detailed feedback for incorrect answers
                                feedbackBuffer.add("❌ Incorrect. " # question.explanation # " " # question.aiFeedback);
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
                
                // Record learning activity
                await userAccount.recordActivity(userId, {
                    claimId = lessonId;
                    timestamp = Time.now();
                    activityType = #learningCompleted;
                });
                
                // Send notification for significant achievements
                if (score >= 90.0) {
                    ignore await notification.sendNotification(
                        userId,
                        "Excellent Performance",
                        "You scored " # Float.toText(score) # "% on " # lesson.title # "!",
                        "learning_achievement"
                    );
                };

                // Recommend next lesson
                let nextLesson = recommendNextLesson(userId, moduleId, lessonId);

                #ok({
                    score = score;
                    correctAnswers = correctAnswers;
                    totalQuestions = totalQuestions;
                    rewardPointsEarned = rewardPoints;
                    feedback = feedbackBuffer.toArray();
                    nextRecommended = nextLesson;
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
            case (?progress) { 
                // Update streak if needed
                updateStreak(userId, progress);
            };
        };
    };

    public shared (msg) func claimDailyReward() : async RewardPoints {
        let userId = msg.caller;
        let now = Time.now();
        let reward = 25; // Daily reward points
        
        switch (userProgress.get(userId)) {
            case (null) {
                let newProgress = createDefaultProgress(userId);
                userProgress.put(userId, newProgress);
                reward;
            };
            case (?progress) {
                let updatedProgress = updateStreak(userId, progress);
                updatedProgress.totalRewardPoints + reward;
            };
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
        var newProgressBuffer = Buffer.fromArray<LessonProgress>(currentProgress.lessonProgress);
        var found = false;
        
        // Update existing progress if found
        for (i in Iter.range(0, newProgressBuffer.size() - 1)) {
            let lp = newProgressBuffer.get(i);
            if (lp.lessonId == lessonId) {
                found := true;
                let updatedLp : LessonProgress = {
                    lessonId = lessonId;
                    completed = lp.completed or isCompleted;
                    score = Float.max(lp.score, score);
                    lastAttempted = now;
                    attempts = lp.attempts + 1;
                };
                newProgressBuffer.put(i, updatedLp);
            };
        };
        
        // Add new entry if not found
        if (not found) {
            newProgressBuffer.add({
                lessonId = lessonId;
                completed = isCompleted;
                score = score;
                lastAttempted = now;
                attempts = 1;
            });
        };

        // Update completed modules
        let completedModules = if (isModuleComplete(moduleId, newProgressBuffer.toArray())) {
            if (Array.find(currentProgress.completedModules, func(mid : ModuleId) : Bool { mid == moduleId }) == null) {
                let buffer = Buffer.fromArray<ModuleId>(currentProgress.completedModules);
                buffer.add(moduleId);
                buffer.toArray();
            } else {
                currentProgress.completedModules;
            };
        } else {
            currentProgress.completedModules;
        };

        // Update rewards
        let newRewards = currentProgress.totalRewardPoints + rewardPoints;

        // Update streak
        let updatedProgress = updateStreak(userId, {
            userId = userId;
            completedModules = completedModules;
            lessonProgress = newProgressBuffer.toArray();
            totalRewardPoints = newRewards;
            streak = currentProgress.streak;
            lastActive = currentProgress.lastActive;
            achievements = currentProgress.achievements;
        });

        // Check for achievements
        checkAchievements(userId, updatedProgress, score);

        userProgress.put(userId, updatedProgress);
    };

    func isModuleComplete(moduleId : ModuleId, progress : [LessonProgress]) : Bool {
        switch (Array.find(modules, func(m : Module) : Bool { m.id == moduleId })) {
            case (null) { false };
            case (?m) {
                for (lesson in m.lessons.vals()) {
                    switch (Array.find(progress, func(p : LessonProgress) : Bool { p.lessonId == lesson.id })) {
                        case (null) { return false };
                        case (?lp) {
                            if (not lp.completed) {
                                return false;
                            };
                        };
                    };
                };
                true;
            };
        };
    };

    func createDefaultProgress(userId : UserId) : UserProgress {
        {
            userId = userId;
            completedModules = [];
            lessonProgress = [];
            totalRewardPoints = 0;
            streak = 0;
            lastActive = Time.now();
            achievements = [];
        };
    };

    func updateStreak(userId : UserId, progress : UserProgress) : UserProgress {
        let now = Time.now();
        let oneDay = 86_400_000_000_000; // nanoseconds in a day
        let lastActive = progress.lastActive;
        
        // Reset streak if more than 2 days have passed
        if (now - lastActive > 2 * oneDay) {
            return {
                userId = progress.userId;
                completedModules = progress.completedModules;
                lessonProgress = progress.lessonProgress;
                totalRewardPoints = progress.totalRewardPoints;
                streak = 1;
                lastActive = now;
                achievements = progress.achievements;
            };
        } 
        // Increment streak if within 1 day
        else if (now - lastActive <= oneDay) {
            return {
                userId = progress.userId;
                completedModules = progress.completedModules;
                lessonProgress = progress.lessonProgress;
                totalRewardPoints = progress.totalRewardPoints;
                streak = progress.streak + 1;
                lastActive = now;
                achievements = progress.achievements;
            };
        }
        // Maintain streak if between 1-2 days
        else {
            return {
                userId = progress.userId;
                completedModules = progress.completedModules;
                lessonProgress = progress.lessonProgress;
                totalRewardPoints = progress.totalRewardPoints;
                streak = progress.streak;
                lastActive = now;
                achievements = progress.achievements;
            };
        };
    };

    func recommendNextLesson(userId : UserId, moduleId : ModuleId, currentLessonId : LessonId) : ?Lesson {
        switch (userProgress.get(userId)) {
            case (null) { null };
            case (?progress) {
                // 1. Check if there's another lesson in the same module
                switch (Array.find(modules, func(m : Module) : Bool { m.id == moduleId })) {
                    case (null) { null };
                    case (?e) {
                        var foundCurrent = false;
                        for (lesson in e.lessons.vals()) {
                            // If we passed the current lesson, return the next one
                            if (foundCurrent) {
                                // Check if user has already completed this lesson
                                switch (Array.find(progress.lessonProgress, func(p : LessonProgress) : Bool { p.lessonId == lesson.id })) {
                                    case (null) { return ?lesson; };
                                    case (?lp) {
                                        if (not lp.completed) {
                                            return ?lesson;
                                        };
                                    };
                                };
                            };
                            
                            if (lesson.id == currentLessonId) {
                                foundCurrent := true;
                            };
                        };
                        
                        // 2. If no next lesson in module, find next uncompleted module
                        for (m in modules.vals()) {
                            if (m.id != moduleId) {
                                // Check if user has completed this module
                                if (Array.find(progress.completedModules, func(id : ModuleId) : Bool { id == m.id }) == null) {
                                    return ?m.lessons[0]; // Return first lesson of next module
                                };
                            };
                        };
                        
                        null; // No recommendations found
                    };
                };
            };
        };
    };

    func checkAchievements(userId : UserId, progress : UserProgress, latestScore : Float) {
        let newAchievements = Buffer.Buffer<Text>(0);
        let currentAchievements = progress.achievements;
        
        // First Steps - Completed first lesson
        if (progress.lessonProgress.size() > 0 and not arrayContains<Text>(currentAchievements, "First Steps", Text.equal)) {
            newAchievements.add("First Steps");
        };
        
        // Quick Learner - Completed a lesson with 90%+ on first attempt
        for (lp in progress.lessonProgress.vals()) {
            if (lp.attempts == 1 and lp.score >= 90.0 and not arrayContains<Text>(currentAchievements, "Quick Learner", Text.equal)) {
                newAchievements.add("Quick Learner");
            };
        };
        
        // Perfect Score - Got 100% on any lesson
        if (latestScore == 100.0 and not arrayContains<Text>(currentAchievements, "Perfect Score", Text.equal)) {
            newAchievements.add("Perfect Score");
        };
        
        // Daily Learner - 7-day streak
        if (progress.streak >= 7 and not arrayContains<Text>(currentAchievements, "Daily Learner", Text.equal)) {
            newAchievements.add("Daily Learner");
        };
        
        // Critical Thinker - Completed all core skills modules
        var coreSkillsComplete = true;
        for (id in progress.completedModules.vals()) {
            let found = Array.find(modules, func(m : Module) : Bool { m.id == id });
            switch (found) {
                case (null) { coreSkillsComplete := false };
                case (?m) { if (m.category != "Core Skills") { coreSkillsComplete := false } };
            };
        };
        
        if (coreSkillsComplete and not arrayContains<Text>(currentAchievements, "Critical Thinker", Text.equal)) {
            newAchievements.add("Critical Thinker");
        };
        
        // Add new achievements to progress
        if (newAchievements.size() > 0) {
            let updatedAchievements = Buffer.fromArray<Text>(progress.achievements);
            for (ach in newAchievements.vals()) {
                updatedAchievements.add(ach);
            };
            
            let updatedProgress : UserProgress = {
                userId = progress.userId;
                completedModules = progress.completedModules;
                lessonProgress = progress.lessonProgress;
                totalRewardPoints = progress.totalRewardPoints;
                streak = progress.streak;
                lastActive = progress.lastActive;
                achievements = updatedAchievements.toArray();
            };
            
            userProgress.put(userId, updatedProgress);
        };
    };

    // Upgrade hooks
    public shared({ caller }) func completeModule(moduleId : Types.ModuleId) : async Result.Result<(), Text> {
        let progressId = generateProgressId(caller, moduleId);
        
        switch (progressStore.get(progressId)) {
            case null { #err("Not enrolled in module") };
            case (?progress) {
                if (progress.completedAt != null) {
                    return #ok(()); // Idempotent
                };
                
                switch (moduleStore.get(moduleId)) {
                    case null { #err("Module not found") };
                    case (?module) {
                        if (progress.progressPercent < 100) {
                            return #err("Module not complete");
                        };
                        
                        // Award XP
                        switch (await reputation.awardXP(caller, module.xpReward, "module_complete:" # moduleId)) {
                            case (#err(e)) return #err("XP award failed: " # e);
                            case (#ok) {};
                        };
                        
                        // Record activity
                        switch (await userAccount.recordActivity(caller, {
                            claimId = moduleId;
                            timestamp = Time.now();
                            activityType = #learningCompleted;
                        })) {
                            case (#err(e)) return #err("Activity logging failed: " # e);
                            case (#ok) {};
                        };
                        
                        // Update progress
                        let updated = { progress with 
                            completedAt = ?Time.now();
                            xpAwarded = true;
                        };
                        progressStore.put(progressId, updated);
                        
                        // Send notification
                        ignore await notification.sendNotification(
                            caller,
                            "Module Complete",
                            "You completed module: " # module.title,
                            "learning_complete"
                        );
                        
                        #ok(())
                    };
                };
            };
        };
    };

    // Admin query
    public shared({ caller }) func listUsersEnrolled(moduleId : Types.ModuleId) : async [Types.UserProgress] {
        if (caller != controller) {
            return [];
        };
        
        Iter.toArray(
            Iter.filter<Types.UserProgress>(
                progressStore.vals(),
                func(p) { p.moduleId == moduleId }
            )
        )
    };

    // System upgrade hooks
    system func preupgrade() {
        modules := Iter.toArray(moduleStore.entries());
        userProgress := Iter.toArray(progressStore.entries());
        authorizedCanisters := Iter.toArray(authorizedCanisterStore.entries());
    };

    system func postupgrade() {
        moduleStore := HashMap.fromIter<Types.ModuleId, Types.Module>(
            modules.vals(), modules.size(), Text.equal, Text.hash);
        progressStore := HashMap.fromIter<Text, Types.UserProgress>(
            userProgress.vals(), userProgress.size(), Text.equal, Text.hash);
        authorizedCanisterStore := HashMap.fromIter<Principal, Bool>(
            authorizedCanisters.vals(), authorizedCanisters.size(), Principal.equal, Principal.hash);
    };

    // Admin management functions
    public shared({ caller }) func setController(newController : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized");
        };
        controller := newController;
        #ok(())
    };

    public shared({ caller }) func authorizeCanister(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized");
        };
        authorizedCanisterStore.put(p, true);
        #ok(())
    };

    public shared({ caller }) func revokeCanister(p : Principal) : async Result.Result<(), Text> {
        if (caller != controller) {
            return #err("Unauthorized");
        };
        authorizedCanisterStore.delete(p);
        #ok(())
    };

    // Helper function to check if an array contains a value using a custom equality function
    func arrayContains<T>(arr : [T], value : T, eq : (T, T) -> Bool) : Bool {
        for (v in arr.vals()) {
            if (eq(v, value)) return true;
        };
        false
    }
};
