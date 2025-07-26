# [cite_start]ALETHEIA DOCUMENTATION [cite: 1]

[cite_start]Aletheia is an ambitious and much-needed decentralized application (dApp) aimed at debunking misinformation, propaganda, and disinformation[cite: 2]. [cite_start]It also seeks to provide employment opportunities and a stable income for its fact-checkers (Aletheians)[cite: 3]. [cite_start]Aletheia is built upon three core elements: Artificial Intelligence (AI) , Blockchain Technology (ICP) , and The People (Users and Aletheians)[cite: 4]. [cite_start]Its primary purpose is to fact-check information, prove what's correct based on evidence, and improve digital/information literacy among users, nurturing their critical thinking[cite: 5]. [cite_start]This is achieved by cultivating the art of asking the "right questions," aided by AI that acts as a "question mirror." [cite: 6] [cite_start]Users will be educated on identifying information needs, locating credible information, evaluating it, and using it effectively[cite: 7].

[cite_start]Blockchain, specifically the Internet Computer (ICP) using Motoko , provides the decentralized foundation, ensuring censorship resistance and utilizing distributed ledgers to store verified facts and evidence cryptographically[cite: 8]. [cite_start]This creates a shared foundation for reasoning[cite: 9]. [cite_start]The "People" element includes users who submit claims and learn, and Aletheians (crowd-sourced fact-checkers operating like a hivemind) who verify information[cite: 10]. [cite_start]Aletheians are aided by AI to accelerate their work[cite: 11]. [cite_start]The frontend will have distinct interfaces for users and Aletheians[cite: 11].

## [cite_start]Enhanced Conceptual Design [cite: 12]

### [cite_start]User Flow (Claim Submission & Learning) [cite: 13]

#### [cite_start]Onboarding (First-Time User) [cite: 14]
- [cite_start]Visit Aletheia dApp (Web/Mobile)[cite: 15].
- [cite_start]Optional: Brief interactive tutorial on misinformation, critical thinking, and Aletheia's mission[cite: 16].
- [cite_start]Navigate to a login page offering distinct options: "Login as User" or "Login as Aletheian." [cite: 17]
- [cite_start]Create Account / Connect Wallet (e.g., Internet Identity on ICP)[cite: 18].
- [cite_start]Agree to Terms of Service & Privacy Policy[cite: 19].

#### [cite_start]Login & Dashboard [cite: 20]
- [cite_start]Authenticated user lands on their dashboard[cite: 21].
- [cite_start]The dashboard will feature[cite: 22]:
    - [cite_start]A **User Profile** section: Containing all necessary user data (linked to a unique identifier visible only to them and system admins for anonymity on the blockchain), settings (like notification preferences, privacy settings), and activity history (submitted claims, learning progress)[cite: 23].
    - [cite_start]Prominent "Submit a Claim" button[cite: 24].
    - [cite_start]Section for ongoing/past claim statuses[cite: 25].
    - [cite_start]Access to "Critical Thinking Gym" (gamified learning)[cite: 26].
    - [cite_start]Trending debunked topics (optional)[cite: 27].

#### [cite_start]Submit a Claim [cite: 28]
- [cite_start]User clicks "Submit a Claim." [cite: 29]
- [cite_start]System offers options for **claim type**: Text, Image (with a focus on deepfake detection tools), Video, Audio, Article Link, Fake News Site URL, or other relevant types[cite: 30].
- [cite_start]Form appears[cite: 31]:
    - [cite_start]**Claim Input:** Text field for the claim, or upload interface for image/video/audio[cite: 32].
    - [cite_start]**Source (Optional but encouraged):** URL, screenshot upload, text description of where they encountered the claim[cite: 33].
    - [cite_start]**Context (Optional):** Brief notes on why they are questioning it or its perceived impact[cite: 34].
    - [cite_start]**Tags/Categories (Optional, AI-suggested):** e.g., Politics, Health, Science, Social Media Hoax[cite: 35].
- [cite_start]User clicks "Submit." [cite: 36]

#### [cite_start]Initial AI Processing & "Question Mirror" [cite: 37]
- [cite_start]System receives the claim[cite: 38].
- [cite_start]**AI Module 1 (Claim Analysis & Question Generation):** A dedicated AI model analyzes the claim's content, keywords, and potential sentiment[cite: 39].
- [cite_start]It generates 2-3 "Right Questions" with explanations ("Why this question is important for this claim")[cite: 40].
    - [cite_start]**Example:** Claim: "Drinking bleach cures COVID-19." [cite: 41]
    - **Right Question 1:** "What scientific evidence supports this claim from reputable health organizations?" [cite_start](Why: Medical claims require scientific backing)[cite: 42].
    - **Right Question 2:** "Who is making this claim, and what are their qualifications or potential biases?" [cite_start](Why: Source credibility is key)[cite: 43, 44].
- [cite_start]**User Interface**[cite: 45]:
    - [cite_start]Displays a "Claim Submitted Successfully!" message[cite: 46].
    - [cite_start]Notification: "Your claim is now being processed by Aletheians. This should ideally take around **5 minutes**. We'll notify you if it might take a bit longer." [cite: 47]
    - [cite_start]Presents the "Question Mirror" showing the AI-generated questions and their importance[cite: 48]:
        - [cite_start]"To better understand claims like this, consider asking:" [cite: 49]
        - [cite_start][Question 1] + [Why] [cite: 50]
        - [cite_start][Question 2] + [Why] [cite: 51]
        - [cite_start][Question 3] + [Why] [cite: 52]
    - [cite_start]Option to "Learn more about asking good questions." [cite: 53]

#### [cite_start]Engaging/Gamified Learning (While Waiting) [cite: 54]
- [cite_start]**User Interface:** "While you wait, sharpen your critical thinking skills!" [cite: 55]
- [cite_start]**AI Module 2 (Interactive Learning):** Presents scenarios, mock articles, or social media posts related to the type of misinformation submitted[cite: 56].
- [cite_start]**Tasks:** Identify red flags (e.g., emotional language, lack of sources, poor grammar) , rate source trustworthiness, craft insightful questions about the presented mock information (AI-rated with feedback), mini-quizzes on digital literacy concepts[cite: 57].
- Points, badges, or progress bars incentivize engagement. [cite_start]Points earned can provide a discount/credit towards potential future platform usage fees or unlock premium learning content[cite: 58].

#### [cite_start]Notification of Completion [cite: 59]
- [cite_start]In-app notification and/or push notification: "Your claim regarding '[Claim Snippet]' has been verified!" [cite: 60]
- [cite_start]If the process exceeds the initial 5-minute estimate, an interim notification will inform the user: "Verification is underway and may take a few more minutes due to claim complexity. We'll notify you." [cite: 61]
- [cite_start]The user will also be informed that when an answer is available, they'd get notified (to avoid having to wait in the app)[cite: 62].

#### [cite_start]View Fact-Checked Result [cite: 63]
- [cite_start]User navigates to the completed claim[cite: 64].
- [cite_start]**Interface (Engaging & Digestible - "Tabloid Style" focused on truth, clarity, and attention-grabbing without being clickbait)**[cite: 65]:
    - [cite_start]**Headline:** Clear verdict (e.g., "FALSE: Drinking Bleach Does Not Cure COVID-19")[cite: 66].
    - [cite_start]**Summary:** Brief, easy-to-understand explanation (1-2 paragraphs)[cite: 67].
    - [cite_start]**Evidence Highlights:** Key pieces of counter-evidence presented visually (e.g., quotes from health authorities, links to studies)[cite: 68].
    - [cite_start]**Detailed Breakdown (Expandable)**[cite: 69]:
        - [cite_start]Original Claim[cite: 70].
        - [cite_start]**Verdict:** (Detailed classification from the standardized list, e.g., False, Truth, Half-Truth, Insufficient Evidence, Opinion, Propaganda, Misleading Context, Satire, Deepfake)[cite: 71].
        - [cite_start]Detailed Explanation from Aletheians & AI synthesis[cite: 72].
        - [cite_start]**Evidence:** Links to credible sources, embedded snippets of articles, scientific papers, official statements[cite: 73].
        - [cite_start]Direct links to the content on the ICP blockchain (including version history if the fact was updated)[cite: 74].
        - [cite_start]**Aletheian Consensus:** (e.g., "Verified by 3/3 Aletheians")[cite: 75].
        - [cite_start]Related "Right Questions" Revisited[cite: 76].
    - [cite_start]**Share Options.** Ability to share the verified fact (with a link back to Aletheia)[cite: 77].
    - **Feedback:** "Was this helpful?" [cite_start](Thumbs up/down, simple rating)[cite: 78].

#### [cite_start]Post-Verification Options [cite: 79]
- [cite_start]Return to dashboard, submit another claim, continue learning with critical thinking lessons, explore other verified facts, or exit[cite: 80].

### [cite_start]Aletheian Flow (Fact-Checking Process) [cite: 81]

#### [cite_start]Onboarding, Login & Dashboard (Aletheian) [cite: 82]
- [cite_start]**First-Time Aletheians:** A separate landing page for sign-up, involving testing (e.g., on applying the CRAAP model), vetting, and mandatory training modules on critical thinking, bias identification, Aletheia's guidelines, and platform use[cite: 83].
- [cite_start]The initial cohort might be formed from early testers who prove proficient[cite: 84].
- [cite_start]The onboarding and vetting will be done separately by admins who will then add the successful Aletheians to the system hence they can log in into the system once they have passed[cite: 85].
- [cite_start]Aletheian logs in via their dedicated portal/separate interface[cite: 86].
- [cite_start]**Dashboard**[cite: 87]:
    - [cite_start]**Aletheian Profile:** Rank (e.g., Junior, Senior, Expert), Reputation Points/Score (XP), location (optional, for geo-assignment), security/verification settings, performance analytics, and assigned tasks[cite: 88].
    - [cite_start]Available claims queue (prioritized by urgency, user type, or claim type)[cite: 89].
    - [cite_start]Ongoing tasks/claims they are working on[cite: 90].
    - [cite_start]Notifications (new assignments, escalations, system messages)[cite: 91].
    - [cite_start]Access to Finance section (earnings, payment goals)[cite: 92].
    - [cite_start]Access to Aletheian knowledge base/guidelines (including evidence standards like CRAAP)[cite: 93].

#### [cite_start]Claim Assignment [cite: 94]
- [cite_start]System analyzes new user claim: keywords, potential geographical relevance (if any), complexity[cite: 95].
- [cite_start]Assigns to 3 Aletheians: 1 (if possible) from geo-local (requires Aletheian profile data), 2 remote, based on online status, reputation score, **Expertise Badges** (e.g., "Health," "Deepfake Analysis," crucial for matching claims to suitable Aletheians, especially seniors), and workload balancing[cite: 96].
- **Aletheian Interface:** Receives a notification; [cite_start]“New claim ‘[Claim Snippet]’ assigned for verification[cite: 97].

#### [cite_start]Accept & Initial AI Check [cite: 98]
- [cite_start]Aletheian accepts task (Clicks “Accept Task”)[cite: 99].
- [cite_start]Prompts AI to check Aletheia's Ledger for existing verifications related to this claim[cite: 100].
- [cite_start]**AI Module 3 (Blockchain Search):** Scans the distributed ledger for identical or highly similar verified claims[cite: 101].
- [cite_start]AI provides results: exact match found: [Link to existing verified fact], similar claims found: [List of links], or no relevant verified facts found on the ledger[cite: 102].

#### [cite_start]Verification Process (If Not Already Verified) [cite: 103]
- [cite_start]**If Exact Match Found on Blockchain:** Aletheian reviews the existing verified fact and evidence, clicks “Confirm as Duplicate & Correct”[cite: 104].
    - [cite_start]System waits for all 3 Aletheians to confirm (If discrepancies, might trigger a mini-escalation or flag for review)[cite: 105].
    - [cite_start]Once a consensus is reached, system sends existing fact to user once all 3 Aletheians concur[cite: 106].
- [cite_start]**If No Match(or only similar claims)/New Verification**[cite: 107]:
    - [cite_start]Aletheian prompts AI for information retrieval: “Gather information and resources for this claim”[cite: 108].
    - [cite_start]**AI Module 4 (Information Retrieval & Summarization):** AI searches the internet (news, academic, videos, reports, fact-checking sites, etc.), retrieves relevant resources, provides links, source name & credibility scores (Aletheians are trained to assess this, using CRAAP, and can override/update AI's initial assessment), and 2 paragraph summaries of each of the content[cite: 109].
    - [cite_start]**Aletheian Analysis - Phase 1:** Reviews AI-provided sources, prioritizes credible ones[cite: 110].
        - [cite_start]If summaries from multiple credible sources align, Aletheian indicates this, provides their classification(True, False, Misleading, etc) and a brief rationale[cite: 111].
        - [cite_start]AI may then synthesize[cite: 112].
    - [cite_start]If summaries don’t align, or topic is nuanced: Aletheian proceeds to deeper analysis[cite: 113].

#### [cite_start]Deeper Analysis & Classification (If Needed) [cite: 114]
- [cite_start]Aletheian thoroughly reviews credible sources, cross-references information, seeks out primary sources[cite: 115].
- [cite_start]Aletheian identifies specific assertions within the claim and verifies each[cite: 116].
- [cite_start]For overall claim, Aletheian selects a classification from the **standardized granular list** (see "Claim Classifications" section below)[cite: 117].
- [cite_start]Writes concise explanation for their classification, provides evidence links for key pieces of evidence supporting their classification[cite: 118].
- [cite_start]Submits individual verification[cite: 119].

#### [cite_start]System Consensus Check [cite: 120]
- [cite_start]System waits for all 3 assigned Aletheians to submit their individual verifications and compares submissions (Classifications & core reasoning) from the 3 Aletheians[cite: 121].
- [cite_start]**If all 3 AGREE (and their reasoning is broadly similar)**[cite: 122]:
    - [cite_start]**AI Module 5 (Synthesis & Formatting):** AI takes the Aletheians’ classifications, explanations, and evidence[cite: 123].
    - [cite_start]Synthesizes a single, coherent, user-friendly response (following the “tabloid-style” brief, focusing on clarity and impact), and formats it with evidence links[cite: 124].
    - [cite_start]System shares the synthesized result with the user, stores the verified claim, evidence, and Aletheian consensus on ICP blockchain (with version history capabilities), then updates Aletheians' credit scores/XP positively[cite: 125].
    - [cite_start]Task closed[cite: 126].
- [cite_start]**If DISAGREE (or reasoning significantly differs):** Escalation triggered[cite: 127].

#### [cite_start]Escalation Review Process (Senior Aletheians) [cite: 128]
- [cite_start]The disputed claim and initial Aletheians' work (their classifications, reasoning, and evidence) is bundled & sent to 3 *different* Senior Aletheians with higher reputation scores and relevant **Expertise Badges**[cite: 129].
- [cite_start]Notification to new Aletheians: “ Escalated claim review: Initial verifiers disagreed.” [cite: 130]
- [cite_start]Senior Aletheians would review and independently determine the correct classification and reasoning and which of the initial Aletheians (if any) were correct and why, then they would submit their escalation review (Correct classification for the claim, with detailed reasoning and evidence)[cite: 131].

#### [cite_start]System Finalizes Escalated Claim [cite: 132]
- [cite_start]The system would collect reviews from the 3 senior Aletheians and a majority decision (2/3 or 3/3) among senior Aletheians determines outcome[cite: 133].
- [cite_start]**If senior Aletheians also don't reach consensus (e.g., 1-1-1 split)**[cite: 134]:
    - [cite_start]User is informed: "This claim is highly complex with differing expert interpretations. We are conducting a final review. You'll be notified of the outcome." [cite: 135]
    - [cite_start]The claim is then passed to a "**Council of Elders**" (top XP Aletheians with broad expertise badges) for a final binding decision[cite: 136].
    - [cite_start]The user is informed when this ultimate decision is available[cite: 137].
- [cite_start]**AI Module 6 (Synthesis):** AI synthesizes the final answer[cite: 138].
- [cite_start]The system then shares it with the user and stores the verified claim, evidence, reasoning, and escalation history on the blockchain[cite: 139].
- [cite_start]**Feedback to Original Aletheians:** XP updates; for those whose assessments were deemed correct by senior Aletheians, they’d get a positive credit score adjustment[cite: 140].
- [cite_start]Those whose assessments were deemed incorrect they’d[cite: 141]:
    - [cite_start]Receive a notification with the correct answer and the senior Aletheians’ reasoning (as a learning opportunity)[cite: 142].
    - [cite_start]Get their reputation score decreased[cite: 143].
    - [cite_start]Receive a warning[cite: 144].
    - [cite_start]Potential temporary suspension from certain claim types or pay reduction if repeated errors occur beyond a threshold[cite: 145].
- [cite_start]Update senior Aletheians’ credit scores positively[cite: 146]. [cite_start]Task closed[cite: 146].

#### [cite_start]Finance Management (Aletheian Portal) [cite: 147]
- [cite_start]Aletheians can view earnings (ICP tokens/stablecoin)[cite: 148].
- **Payment Model:** Derived from user subscriptions (Spotify-like revenue share). [cite_start]A percentage of platform revenue forms a pool[cite: 149].
- [cite_start]Payouts/earnings are directly proportional to validated contributions, quantified by **XP earned** (factoring in accuracy, speed with accuracy, complexity of claims, number of claims successfully verified (where their input was correct), bonus for correctly resolved escalated claims etc., as per the detailed Aletheian Reward System)[cite: 150].
- [cite_start]Aletheians can set personal income goals[cite: 151].
- [cite_start]Withdraw options[cite: 152].

### [cite_start]System Flow (Integrating User, Aletheian, AI & Blockchain) [cite: 153]

1.  [cite_start]**User Submits Claim (Frontend -> ClaimSubmissionCanister):** User inputs claim (text, image, video etc.), source, context via the user frontend[cite: 154].
2.  [cite_start]**Claim Processing & Initial AI Interaction (ClaimSubmissionCanister -> AI Service/AI_ModuleCanister):** ClaimSubmissionCanister stores raw claim temporarily, triggers AI (QuestionMirrorCanister) for "Right Questions," ClaimSubmissionCanister sends questions to user frontend[cite: 155].
3.  [cite_start]**User interacts with GamifiedLearningCanister**[cite: 156].
4.  [cite_start]**Aletheian Assignment (ClaimSubmissionCanister -> AletheianDispatchCanister):** AletheianDispatchCanister dispatches claim by querying AletheianProfileCanister (for availability, reputation, location, expertise badges)[cite: 157]. [cite_start]Selects 3 Aletheians and sends them notifications via a NotificationCanister[cite: 158]. [cite_start]Claim is assigned a unique ID[cite: 158].
5.  [cite_start]**Aletheian Fact-Checking (AletheianFrontend -> VerificationWorkflowCanister & AI):** [cite: 159]
    - [cite_start]Aletheians accept tasks via their frontend, interacting with the VerificationWorkflowCanister[cite: 160].
    - [cite_start]VerificationWorkflowCanister queries FactLedgerCanister for duplicates[cite: 161].
    - If new, VerificationWorkflowCanister calls AI for research. [cite_start]Aletheians submit findings[cite: 162].
    - [cite_start]Aletheians submit individual findings to VerificationWorkflowCanister[cite: 163].
6.  [cite_start]**Consensus & Escalation (VerificationWorkflowCanister, EscalationCanister):** [cite: 164]
    - VerificationWorkflowCanister compares Aletheians submissions. [cite_start]On agreement, AI synthesizes output, FactLedgerCanister stores result, user notified via NotificationCanister, AletheianProfileCanister & FinanceCanister updated with reputation changes and earnings respectively[cite: 165].
    - [cite_start]On disagreement, VerificationWorkflowCanister flags for escalation and passes all data to EscalationCanister which re-assigns to senior Aletheians (queries AletheianProfileCanister) manages review by senior Aletheians/Council of Elders[cite: 166].
    - [cite_start]EscalationCanister determines final outcome, updates FactLedgerCanister notifies user, and updates all relevant Aletheians’ profiles/finances[cite: 167].
7.  [cite_start]**Blockchain Storage (FactLedgerCanister):** Stores claim, final verdict/classification, detailed explanation, evidence links (or hashes to off-chain decentralized storage like IPFS/Arweave via ICP integration), timestamp of verification, verifying Aletheian IDs (anonymized proof), and **version history** if facts are updated due to new evidence[cite: 168].
8.  [cite_start]**User Receives Result (NotificationCanister -> User Frontend):** User receives a push notification, retrieves formatted result, ultimately sourced from FactLedgerCanister[cite: 169].

## [cite_start]Design Considerations (Frontend & Backend) [cite: 170]

### [cite_start]I. User Frontend [cite: 171]
- [cite_start]**UI/UX:** Simplicity (easy claim submission), clarity[cite: 172]. [cite_start]"Tabloid-Style" means engaging, digestible, visually appealing summaries with strong, clear headlines for verdicts and visual cues (icons for true/false/misleading), avoiding sensationalism[cite: 172].
- [cite_start]**Trust & transparency** (link to Aletheia’s methodology, clearly show evidence links/sources)[cite: 173]. [cite_start]Mobile-first (many will access this on the go)[cite: 173].
- [cite_start]**Key Sections:** Dashboard/homepage (with User Profile), Submit Claim Form (with claim type selection), Claim Status Tracker, Verified Fact Display Page, Critical Thinking Gym, Settings[cite: 174].

### II. [cite_start]Aletheian Frontend [cite: 175]
- [cite_start]**UI/UX:** Efficiency (streamlined workflow for quick processing of claims), information density (AI summaries, source lists, and claim details should be well organized), clear task management (easy to see pending, active, and completed tasks)[cite: 176].
- [cite_start]Robust tools for source flagging (CRAAP model assistance), classification, evidence linking[cite: 177]. [cite_start]Simple classification dropdowns[cite: 177].
- [cite_start]Rich text editor for explanations with evidence linking[cite: 178]. [cite_start]Financial overview (clear display of earnings, goals, payment history)[cite: 178].
- [cite_start]**Key Sections:** Dashboard (Claim Queue), Claim Verification Interface (with AI tools, source lists, submission forms), Escalation Review Interface, Profile (Reputation with XP, Stats, Rank, Badges/expertise) Finance Management, Aletheian Guidelines/Knowledge Base[cite: 179].

### III. [cite_start]Backend (ICP Canisters - Smart Contracts) [cite: 180]
- [cite_start]**Core Canisters:** UserAccountCanister, AletheianProfileCanister, ClaimSubmissionCanister, AletheianDispatchCanister, VerificationWorkflowCanister, EscalationCanister, FactLedgerCanister (with versioning), FinanceCanister[cite: 181].
- [cite_start]**Supporting Canisters:** AI_IntegrationCanister(s) (for Question Mirror, Research Aid, Synthesis), GamifiedLearningCanister, NotificationCanister, ReputationLogicCanister[cite: 182].

## [cite_start]Aletheia Canister Ecosystem & Development Order [cite: 183]
[cite_start]Here's a list of the necessary canisters for Aletheia, their functions, and a suggested order for development, keeping in mind dependencies and building core functionality first[cite: 184].

### [cite_start]Canister List & Functions [cite: 185]

[cite_start]**UserAccountCanister** [cite: 186]
- [cite_start]**Function:** Manages user profiles (unique anonymous identifiers, settings, links to learning progress, submitted claim history), authentication interactions (e.g., with Internet Identity)[cite: 187]. [cite_start]Handles user-specific preferences and data[cite: 188].

[cite_start]**AletheianProfileCanister** [cite: 189]
- [cite_start]**Function:** Manages Aletheian profiles: registration, XP scores, ranks, expertise badges, location (optional), availability status, performance statistics (accuracy, warnings), payment-related information links[cite: 190]. [cite_start]Central to Aletheian identity and progression[cite: 191].

[cite_start]**FactLedgerCanister** [cite: 192]
- [cite_start]**Function:** The immutable, distributed ledger for all verified facts[cite: 193]. [cite_start]Stores claims, final classifications, detailed explanations, evidence links/hashes, verification timestamps, IDs of verifying Aletheians (anonymized proof), and crucial **version history** for updates[cite: 194]. [cite_start]This is Aletheia's "source of truth." [cite: 195]

[cite_start]**ReputationLogicCanister** [cite: 196]
- [cite_start]**Function:** Encapsulates the complex rules for calculating and updating Aletheian XP, ranks, and issuing warnings based on the detailed reward/penalty system[cite: 197]. [cite_start]Called by workflow canisters after verification events[cite: 198].

[cite_start]**ClaimSubmissionCanister** [cite: 199]
- [cite_start]**Function:** Handles initial intake of user claims (text, image, video etc.)[cite: 200]. [cite_start]Stores raw claim temporarily, interacts with initial AI for "Question Mirror" generation, and passes claims to the dispatch system[cite: 201].

[cite_start]**AI_IntegrationCanister(s)** [cite: 202]
- [cite_start]**Function:** Acts as a gateway or proxy for various AI functionalities[cite: 203]. [cite_start]This might be one canister with multiple functions or several specialized canisters[cite: 204]. [cite_start]Handles[cite: 204]:
    - [cite_start]"Question Mirror" generation[cite: 205].
    - [cite_start]Information retrieval and summarization for Aletheians[cite: 206].
    - [cite_start]Synthesis of final user-facing reports[cite: 207].
    - [cite_start]Potentially, preliminary deepfake analysis or duplicate detection[cite: 208].
- [cite_start]Manages HTTPS outcalls to external AI services or interfaces with on-chain AI models[cite: 209].

[cite_start]**AletheianDispatchCanister** [cite: 210]
- [cite_start]**Function:** Contains the logic for assigning submitted claims to available and appropriate Aletheians based on criteria like online status, reputation score, expertise badges (from AletheianProfileCanister), workload, and geographical relevance (if applicable)[cite: 211].

[cite_start]**VerificationWorkflowCanister** [cite: 212]
- [cite_start]**Function:** Manages the core fact-checking process for the initial set of three Aletheians[cite: 213]. [cite_start]Facilitates their interaction with AI tools, collection of their individual findings, and initial consensus checking[cite: 214]. [cite_start]Communicates with FactLedgerCanister for duplicates and ReputationLogicCanister for XP updates[cite: 215].

[cite_start]**EscalationCanister** [cite: 216]
- [cite_start]**Function:** Manages the workflow for disputed claims that couldn't be resolved by the initial three Aletheians[cite: 217]. [cite_start]Assigns claims to Senior Aletheians or the Council of Elders, collects their reviews, determines final outcomes, and ensures proper recording and feedback[cite: 218].

[cite_start]**FinanceCanister** [cite: 219]
- [cite_start]**Function:** Manages the Aletheian payment system[cite: 220]. [cite_start]Calculates Aletheian earnings based on XP accumulated (data from AletheianProfileCanister or ReputationLogicCanister) and the total Aletheian Payment Pool (derived from user subscriptions)[cite: 220]. [cite_start]Handles transaction logic for payouts[cite: 221].

[cite_start]**GamifiedLearningCanister** [cite: 222]
- [cite_start]**Function:** Manages interactive learning modules for users[cite: 223]. [cite_start]Stores content, tracks user progress and points earned, and potentially interacts with an AI module for dynamic feedback on user-generated questions or task performance[cite: 223].

[cite_start]**NotificationCanister** [cite: 224]
- [cite_start]**Function:** Handles sending in-app and potentially push notifications to users (claim status updates, results) and Aletheians (new task assignments, escalation alerts, feedback)[cite: 225].

[cite_start]**Technology(tech stack):** ICP, Motoko (primary), Rust (optional; for performance-critical canisters if needed)[cite: 226].
[cite_start]**Frontend:** Modern JS framework(React, Vue) compiled to Wasm[cite: 227]. [cite_start]AI: emerging on-chain solutions[cite: 227].
[cite_start]**Evidence Storage:** Links to external sources, or IPFS/Arweave via ICP integration for decentralized storage of actual evidence files (screenshots, PDFs) with hashes stored on the FactLedgerCanister[cite: 228].

## [cite_start]Detailed Designs of Aletheia [cite: 229]

### [cite_start]1. Granular List of Claim Classifications [cite: 230]
[cite_start]This list aims to be comprehensive, allowing Aletheians to accurately categorize information: True, False, Misleading, Propaganda, Disinformation, Misinformation, Half-Truth, Opinion, Satire, Fabricated Content, Insufficient Evidence, etc. (Standardized list)[cite: 231].

#### [cite_start]A. Factual Accuracy Verdicts: [cite: 232]
1.  [cite_start]**True / Accurate:** All core assertions are factually correct and comprehensively supported by verifiable evidence[cite: 233].
2.  [cite_start]**Mostly True:** The central assertion is accurate, but minor details may be incorrect, lack full context, or are oversimplified[cite: 234]. [cite_start]Explanation should clarify these nuances[cite: 235].
3.  [cite_start]**Half Truth / Cherry-Picking:** Contains factually accurate elements but omits critical information or context, leading to a misleading overall impression[cite: 236].
4.  [cite_start]**Misleading Context:** Presents genuine information (e.g., a real photo or statistic) but applies it to an unrelated context to deceive[cite: 237].
5.  [cite_start]**False / Inaccurate:** Core assertions are factually incorrect and contradicted by verifiable evidence[cite: 238].
6.  [cite_start]**Mostly False:** The central assertion is false, though some peripheral details might be accurate[cite: 239]. [cite_start]Explanation should clarify[cite: 239].
7.  [cite_start]**Unsubstantiated / Unproven:** Insufficient reliable evidence currently exists to either confirm or definitively deny the claim[cite: 240]. [cite_start](Often for emerging topics or scientific claims not yet peer-reviewed)[cite: 241].
8.  [cite_start]**Outdated:** Information that was once accurate (or believed to be) but has been superseded by new findings, events, or clarifications[cite: 242].

#### [cite_start]B. Intent / Origin / Style Classifications (Can be combined with A): [cite: 243]
9.  [cite_start]**Misinformation:** False or inaccurate information spread, regardless of the intent to deceive[cite: 244].
10. [cite_start]**Disinformation:** False or inaccurate information that is deliberately created and spread with the intent to deceive or cause harm[cite: 245]. [cite_start](Intent can be hard to prove but can be inferred from context)[cite: 246].
11. [cite_start]**Satire / Parody:** Content created for humorous or critical commentary, not intended to be taken literally, but which could be mistaken for genuine fact[cite: 247]. [cite_start]The source usually indicates its satirical nature[cite: 248].
12. [cite_start]**Opinion / Commentary:** A statement expressing beliefs, judgments, or viewpoints rather than pure factual assertions[cite: 249]. [cite_start]Should be clearly distinguished from fact[cite: 250].
13. [cite_start]**Propaganda:** Information, often biased or misleading, systematically disseminated to promote a specific political cause, ideology, or point of view[cite: 251].
14. [cite_start]**Fabricated Content:** Content that is 100% false, designed to deceive and imitate legitimate news[cite: 252].
15. [cite_start]**Imposter Content:** Genuine sources are impersonated with false or fabricated information[cite: 253].
16. [cite_start]**Manipulated Content (Visual/Audio):** Genuine media (images, videos, audio) altered in a misleading way (e.g., photoshopping, selective editing, miscaptioning)[cite: 254].
17. [cite_start]**Deepfake (Visual/Audio):** AI-generated or significantly altered media where individuals are made to say or do things they never did[cite: 255].
18. [cite_start]**Conspiracy Theory:** An explanatory proposition accusing a secret group of a covert plan, often lacking evidence or based on misinterpretations of facts[cite: 256].

#### [cite_start]C. Other Useful Tags/Flags (Aletheians might add these): [cite: 257]
- [cite_start]Clickbait [cite: 258]
- [cite_start]Rumor [cite: 259]
- [cite_start]Hoax [cite: 260]
- [cite_start]Insufficient Evidence [cite: 261]
- [cite_start]User-Generated Content (needs extra scrutiny) [cite: 262]
- [cite_start]Sponsored Content [cite: 263]

### [cite_start]2. Aletheian Reward, Ranking, and Penalty System [cite: 264]
[cite_start]This system aims to incentivize accuracy, thoroughness, expertise development, and fair contribution[cite: 265].

#### [cite_start]A. Experience Points (XP) - The Core Metric: [cite: 266]

[cite_start]**Earning XP:** [cite: 267]
- [cite_start]**Successful Base Verification:** +10 XP (for each of the 3 initial Aletheians whose assessment aligns with the final consensus)[cite: 268].
- [cite_start]**Claim Complexity Bonus:** [cite: 269]
    - [cite_start]Low Complexity: +0 XP [cite: 270]
    - [cite_start]Medium Complexity: +5 XP [cite: 271]
    - [cite_start]High Complexity: +10 XP [cite: 272]
- [cite_start]**Accuracy Bonus** (for initial Aletheians if no escalation needed): +5 XP (if all 3 initial Aletheians agree and their verdict is final)[cite: 273].
- [cite_start]**Speed Bonus** (within top 25% percentile for similar complexity, with accuracy): +3 XP [cite: 274]
- [cite_start]**Successful Senior Escalation Review:** +15 XP (for each senior Aletheian whose assessment forms the final consensus)[cite: 275].
- [cite_start]**Council of Elders Resolution:** +25 XP (for each Council member involved in the final decision)[cite: 276].
- [cite_start]**Completing Training Modules:** +5-20 XP per module[cite: 277].
- [cite_start]**Mentoring New Aletheians (Future Feature):** +XP per successful mentee[cite: 278].
- [cite_start]**Identifying a Unique Duplicate** (previously unlinked): +2 XP [cite: 279]

[cite_start]**Losing XP (Penalties):** [cite: 280]
- [cite_start]**Incorrect Verification** (caught by escalation): -20 XP for the Aletheian(s) whose work was incorrect[cite: 281].
- [cite_start]**Minor Guideline Breach** (1st Warning): -5 XP[cite: 282].
- [cite_start]**Repeated Minor Guideline Breaches** (2nd Warning): -10 XP & temporary suspension from complex claims[cite: 283].
- [cite_start]**Major Guideline Breach / Negligence** (e.g., consistently poor work despite feedback): -50 XP & potential suspension from Aletheia[cite: 284]. [cite_start]This triggers a review by admins/Council of Elders[cite: 285].
- [cite_start]**Failing to complete an accepted task** without valid reason in a timely manner: -5 XP[cite: 286].

#### [cite_start]B. Rankings: [cite: 287]
Determined by cumulative XP. [cite_start]Ranks unlock access to more complex claims, senior review roles, and expertise badge applications[cite: 288].
- [cite_start]**Trainee Aletheian** (Upon completing initial vetting & base training) [cite: 289]
- [cite_start]**Junior Aletheian:** 0 - 249 XP [cite: 290]
- [cite_start]**Associate Aletheian:** 250 - 749 XP [cite: 291]
- [cite_start]**Senior Aletheian:** 750 - 1999 XP (Eligible for escalation reviews, can apply for expertise badges) [cite: 292]
- [cite_start]**Expert Aletheian:** 2000 - 4999 XP (Priority for complex claims in their badged areas, eligible for Council of Elders nomination) [cite: 293]
- [cite_start]**Master Aletheian / Elder:** 5000+ XP (Eligible for Council of Elders) [cite: 294]

#### [cite_start]C. Expertise Badges: [cite: 295]
[cite_start]Awarded to Senior Aletheians and above[cite: 296].
- [cite_start]**Requires:** [cite: 297]
    - [cite_start]Application[cite: 298].
    - [cite_start]Demonstrated high accuracy on a minimum number of claims (e.g., 50+) in a specific category (e.g., "Health & Medicine," "Climate Science," "Political Claims - Region X," "Deepfake Analysis")[cite: 299].
    - [cite_start]Potentially passing an additional specialized test for that category[cite: 300].
- [cite_start]Badges make Aletheians eligible for specific complex claims and targeted escalation reviews[cite: 301].

#### [cite_start]D. Payment Calculation (Spotify Model): [cite: 302]
- [cite_start]**Monthly Revenue Share Pool:** Aletheia dedicates X% of its monthly user subscription revenue to the "Aletheian Payment Pool." [cite: 303]
- [cite_start]**Monthly XP Accrual:** Each Aletheian has "Monthly XP Earned." [cite: 304]
- [cite_start]**Total Monthly XP:** Sum of all "Monthly XP Earned" by all active, eligible Aletheians[cite: 305].
- [cite_start]**Individual Aletheian's Share:** (Aletheian's Monthly XP Earned / Total Monthly XP by all Aletheians) * Aletheian Payment Pool [cite: 306]
- [cite_start]Payments made in ICP tokens or a designated stablecoin[cite: 307].

#### [cite_start]E. Warnings & Quality Control: [cite: 308]
- System tracks warnings. [cite_start]Accumulating too many warnings (e.g., 3 minor warnings in a 90-day period) could lead to temporary suspension, mandatory retraining, or removal from the platform[cite: 309].
- [cite_start]Random audits of verified claims by a quality assurance team or high-ranking Aletheians[cite: 310].

## [cite_start]Addressing Potential Gaps & Implementing Solutions [cite: 311]

[cite_start]**Aletheian Onboarding & Vetting:** [cite: 312]
- [cite_start]**Challenge:** Ensuring competent and ethical Aletheians[cite: 313].
- [cite_start]**Aletheia's Solution:** Dedicated Aletheian sign-up page with rigorous vetting, testing (including CRAAP model application), and mandatory training modules[cite: 314]. [cite_start]Initial Aletheians might be early proficient testers[cite: 315].

[cite_start]**Defining "Sufficient, Concrete Evidence":** [cite: 316]
- [cite_start]**Challenge:** Subjectivity in evidence standards[cite: 317].
- [cite_start]**Aletheia's Solution:** Aletheians trained on and utilize the **CRAAP model** (Currency, Relevance, Authority, Accuracy, Purpose)[cite: 318]. [cite_start]Clear guidelines in the Aletheian knowledge base[cite: 319].

[cite_start]**"Tabloid-Style" Output Nuance:** [cite: 320]
- [cite_start]**Challenge:** Balancing engagement with objectivity[cite: 321].
- [cite_start]**Aletheia's Solution:** Focus on truth, clarity, and **visual engagement** to draw attention correctly[cite: 322]. [cite_start]Strong, clear headlines for verdicts, but factual, unbiased content[cite: 323].

[cite_start]**AI "Right Questions" - Quality & Objectivity:** [cite: 324]
- [cite_start]**Challenge:** Ensuring AI generates truly insightful questions[cite: 325].
- [cite_start]**Aletheia's Solution:** Integration of a dedicated, well-trained AI model for this[cite: 326]. [cite_start]Continuous evaluation and refinement based on effectiveness, with Aletheian feedback[cite: 327].

[cite_start]**Complexity & Nuance of Claims:** [cite: 328]
- [cite_start]**Challenge:** Handling claims beyond simple true/false[cite: 329].
- [cite_start]**Aletheia's Solution:** Use of the **granular claim classification list**[cite: 330]. [cite_start]Aletheians trained to explain complexity[cite: 330]. [cite_start]"Unsubstantiated" category is key[cite: 331].

[cite_start]**Aletheian Bias & Geo-Location:** [cite: 332]
- [cite_start]**Challenge:** Mitigating individual biases[cite: 333].
- [cite_start]**Aletheia's Solution:** Geo-location for context balanced by remote Aletheians[cite: 334]. [cite_start]Emphasis on bias training[cite: 334]. [cite_start]Consensus model (3 initial, then 3 senior/Council) is primary mitigation[cite: 335].

[cite_start]**Scalability of Manual Review:** [cite: 336]
- [cite_start]**Challenge:** Immense volume of misinformation[cite: 337].
- [cite_start]**Aletheia's Solution:** AI pre-filtering for duplicates[cite: 338]. [cite_start]Prioritization of claims[cite: 338]. [cite_start]Users can link to existing verified facts[cite: 338]. [cite_start]Efficient Aletheian workflow aided by AI[cite: 339].

[cite_start]**Funding Aletheians & Platform Sustainability:** [cite: 340]
- [cite_start]**Challenge:** Ensuring sustainable payment for Aletheians[cite: 341].
- **Aletheia's Solution:** **User subscription model**. [cite_start]A percentage of revenue creates the Aletheian Payment Pool, distributed based on XP earned (quality and quantity of work)[cite: 342].

[cite_start]**Dispute Resolution for Senior Aletheians/Council:** [cite: 343]
- [cite_start]**Challenge:** Final tie-breaking[cite: 344].
- [cite_start]**Aletheia's Solution:** If senior Aletheians disagree, the claim goes to a "**Council of Elders**." [cite: 345] [cite_start]If even they cannot reach a definitive consensus on highly contentious topics, Aletheia will transparently publish the differing expert opinions and label the claim as such, noting the ongoing debate or lack of conclusive evidence[cite: 346].

[cite_start]**Speed vs. Thoroughness:** [cite: 347]
- [cite_start]**Challenge:** Balancing user desire for speed with need for accuracy[cite: 348].
- [cite_start]**Aletheia's Solution:** Users informed of ~5 min target, with updates if longer[cite: 349]. [cite_start]The Aletheian reward system primarily incentivizes **accuracy and thoroughness**, with efficiency as a secondary bonus if quality is maintained[cite: 350].

[cite_start]**Source Credibility Database/Assessment:** [cite: 351]
- [cite_start]**Challenge:** Maintaining an objective source credibility assessment[cite: 352].
- [cite_start]**Aletheia's Solution:** Primary responsibility falls on **Aletheians trained in source evaluation (e.g., CRAAP model)**[cite: 353]. [cite_start]The AI provides initial suggestions, but Aletheians validate[cite: 354]. [cite_start]Collective judgment and escalation help maintain standards[cite: 354].

[cite_start]**User Privacy for Submitted Claims:** [cite: 355]
- [cite_start]**Challenge:** Protecting user anonymity[cite: 356].
- [cite_start]**Aletheia's Solution:** Each user has a **unique identifier visible only to them and system admins**[cite: 357]. [cite_start]This identifier is used for recording claims on the blockchain, ensuring anonymity of the submitter in public records[cite: 358].

[cite_start]**Initial Aletheian Pool & Cold Start:** [cite: 359]
- [cite_start]**Challenge:** Bootstrapping the Aletheian network[cite: 360].
- [cite_start]**Aletheia's Solution:** **Early adopters and proficient testers** will form the initial cohort, potentially fast-tracked to senior roles based on demonstrated skill during the development and testing phases[cite: 361].