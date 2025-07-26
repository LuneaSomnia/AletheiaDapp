# ALETHEIA DOCUMENTATION

Aletheia is an ambitious and much-needed decentralized application (dApp) aimed at debunking misinformation, propaganda, and disinformation. It also seeks to provide employment opportunities and a stable income for its fact-checkers (Aletheians).

Aletheia is built upon three core elements: **Artificial Intelligence (AI)**, **Blockchain Technology (ICP)**, and **The People** (Users and Aletheians). Its primary purpose is to fact-check information, prove what's correct based on evidence, and improve digital/information literacy among users, nurturing their critical thinking. This is achieved by cultivating the art of asking the "right questions," aided by AI that acts as a "question mirror."

-----

## Table of Contents

  - [Enhanced Conceptual Design]
      - [User Flow (Claim Submission & Learning)]
      - [Aletheian Flow (Fact-Checking Process)]
      - [System Flow (Integrating User, Aletheian, AI & Blockchain)]
  - [Design Considerations (Frontend & Backend)]
      - [User Frontend]
      - [Aletheian Frontend]
      - [Backend (ICP Canisters)]
  - [Aletheia Canister Ecosystem & Development Order]
      - [Canister List & Functions]
  - [Detailed Designs of Aletheia]
      - [Granular List of Claim Classifications]
      - [Aletheian Reward, Ranking, and Penalty System]
  - [Addressing Potential Gaps & Implementing Solutions]

-----

## Enhanced Conceptual Design

### User Flow (Claim Submission & Learning)

#### Onboarding (First-Time User)

  - **Visit Aletheia dApp** (Web/Mobile).
  - **Optional Tutorial**: Brief interactive tutorial on misinformation, critical thinking, and Aletheia's mission.
  - **Login**: Navigate to a login page offering distinct options: "Login as User" or "Login as Aletheian."
  - **Create Account / Connect Wallet**: (e.g., Internet Identity on ICP).
  - **Agree to Terms**: Accept the Terms of Service & Privacy Policy.

#### Login & Dashboard

  - The authenticated user lands on their dashboard, which features:
      - A **User Profile** section: Contains all necessary user data (linked to a unique identifier visible only to them and system admins), settings, and activity history.
      - Prominent **"Submit a Claim"** button.
      - Section for ongoing/past claim statuses.
      - Access to **"Critical Thinking Gym"** (gamified learning).
      - Trending debunked topics (optional).

#### Submit a Claim

1.  User clicks **"Submit a Claim"**.
2.  System offers options for **claim type**: Text, Image, Video, Audio, Article Link, etc.
3.  A form appears for:
      - **Claim Input**: Text field or upload interface.
      - **Source (Optional but encouraged)**: URL, screenshot, etc.
      - **Context (Optional)**: Notes on why they are questioning it.
      - **Tags/Categories (Optional, AI-suggested)**: e.g., Politics, Health, Science.
4.  User clicks **"Submit"**.

#### Initial AI Processing & "Question Mirror"

  - The system receives the claim.
  - **AI Module 1 (Claim Analysis & Question Generation)** analyzes the claim's content and generates 2-3 "Right Questions" with explanations.
  - **User Interface**:
      - Displays a "Claim Submitted Successfully\!" message.
      - Notification: "Your claim is now being processed by Aletheians. This should ideally take around **5 minutes**."
      - Presents the **"Question Mirror"** showing the AI-generated questions.

#### Engaging/Gamified Learning (While Waiting)

  - **User Interface**: "While you wait, sharpen your critical thinking skills\!"
  - **AI Module 2 (Interactive Learning)** presents scenarios and tasks related to the submitted misinformation type.
  - Points, badges, or progress bars incentivize engagement.

#### Notification of Completion

  - An in-app or push notification is sent: "Your claim regarding '[Claim Snippet]' has been verified\!"
  - Users are notified of any delays and informed that they will receive a notification when the answer is ready.

#### View Fact-Checked Result

  - The user navigates to the completed claim.
  - The interface provides an engaging and digestible "Tabloid Style" result:
      - **Headline**: Clear verdict (e.g., "FALSE: Drinking Bleach Does Not Cure COVID-19").
      - **Summary**: A brief, easy-to-understand explanation.
      - **Evidence Highlights**: Key pieces of counter-evidence presented visually.
      - **Detailed Breakdown (Expandable)**: Includes the original claim, a detailed verdict from a standardized list, the Aletheians' explanation, links to evidence on the ICP blockchain, and Aletheian consensus.
      - **Share Options** and a **Feedback** mechanism.

### Aletheian Flow (Fact-Checking Process)

#### Onboarding, Login & Dashboard (Aletheian)

  - **First-Time Aletheians** undergo a separate sign-up process involving testing, vetting, and mandatory training.
  - **Dashboard**:
      - **Aletheian Profile**: Shows Rank, Reputation Score (XP), performance analytics, and assigned tasks.
      - **Claim Queue**: An available queue of claims to be verified.
      - **Finance Section**: Displays earnings and payment goals.
      - **Knowledge Base**: Access to Aletheian guidelines.

#### Verification Process

1.  **Claim Assignment**: The system assigns a new claim to 3 Aletheians based on availability, reputation, and expertise.
2.  **Accept & Initial AI Check**: An Aletheian accepts the task, and an AI module scans the ledger for existing verifications.
3.  **Verification**:
      - If a match is found, the Aletheian confirms it.
      - If no match is found, a new verification process begins. An AI module retrieves and summarizes information from the internet. The Aletheian analyzes these sources, provides a classification (True, False, etc.), and submits their findings.
4.  **System Consensus Check**: The system compares the submissions from the 3 Aletheians.
      - If they **AGREE**, an AI module synthesizes a user-friendly response, which is stored on the blockchain.
      - If they **DISAGREE**, the claim is escalated.

#### Escalation Review Process

  - The disputed claim is sent to 3 different **Senior Aletheians**.
  - A majority decision among the senior Aletheians determines the outcome.
  - If there is still no consensus, the claim is passed to a **"Council of Elders"** for a final binding decision.
  - Feedback is provided to the original Aletheians, and their reputation scores are adjusted accordingly.

### System Flow (Integrating User, Aletheian, AI & Blockchain)

1.  **User Submits Claim**: The claim is sent to the `ClaimSubmissionCanister`.
2.  **AI Processing**: The `ClaimSubmissionCanister` triggers the AI module for "Right Questions".
3.  **Aletheian Assignment**: The `AletheianDispatchCanister` assigns the claim to 3 Aletheians.
4.  **Fact-Checking**: Aletheians interact with the `VerificationWorkflowCanister` to process the claim.
5.  **Consensus & Escalation**: The `VerificationWorkflowCanister` checks for consensus or passes the claim to the `EscalationCanister`.
6.  **Blockchain Storage**: The final result is stored in the `FactLedgerCanister`.
7.  **User Receives Result**: The user is notified and can view the result.

-----

## Design Considerations (Frontend & Backend)

### I. User Frontend

  - **UI/UX**: Focus on simplicity, clarity, and trust. A mobile-first design with engaging, "Tabloid-Style" summaries.
  - **Key Sections**: Dashboard, Submit Claim Form, Claim Status Tracker, Verified Fact Display Page, Critical Thinking Gym, Settings.

### II. Aletheian Frontend

  - **UI/UX**: Prioritize efficiency and information density with robust tools for fact-checking.
  - **Key Sections**: Dashboard (Claim Queue), Claim Verification Interface, Escalation Review Interface, Profile, Finance Management, Guidelines.

### III. Backend (ICP Canisters - Smart Contracts)

  - **Core Canisters**: `UserAccountCanister`, `AletheianProfileCanister`, `ClaimSubmissionCanister`, `VerificationWorkflowCanister`, `FactLedgerCanister`, `FinanceCanister`.
  - **Supporting Canisters**: `AI_IntegrationCanister`, `GamifiedLearningCanister`, `NotificationCanister`, `ReputationLogicCanister`.

-----

## Aletheia Canister Ecosystem & Development Order

### Canister List & Functions

  - **`UserAccountCanister`**: Manages user profiles and authentication.
  - **`AletheianProfileCanister`**: Manages Aletheian profiles, reputation, and status.
  - **`FactLedgerCanister`**: The immutable ledger for all verified facts.
  - **`ReputationLogicCanister`**: Calculates and updates Aletheian XP and ranks.
  - **`ClaimSubmissionCanister`**: Handles the initial intake of user claims.
  - **`AI_IntegrationCanister(s)`**: Acts as a gateway for various AI functionalities.
  - **`AletheianDispatchCanister`**: Assigns claims to appropriate Aletheians.
  - **`VerificationWorkflowCanister`**: Manages the core fact-checking process.
  - **`EscalationCanister`**: Manages the workflow for disputed claims.
  - **`FinanceCanister`**: Manages the Aletheian payment system.
  - **`GamifiedLearningCanister`**: Manages interactive learning modules for users.
  - **`NotificationCanister`**: Handles sending notifications to users and Aletheians.

#### Technology Stack

  - **Backend**: ICP, Motoko (primary), Rust (optional).
  - **Frontend**: Modern JS framework (React, Vue) compiled to Wasm.
  - **AI**: Emerging on-chain solutions.
  - **Evidence Storage**: IPFS/Arweave via ICP integration.

-----

## Detailed Designs of Aletheia

### 1\. Granular List of Claim Classifications

A comprehensive list to allow Aletheians to accurately categorize information.

#### A. Factual Accuracy Verdicts:

  - **True / Accurate**
  - **Mostly True**
  - **Half Truth / Cherry-Picking**
  - **Misleading Context**
  - **False / Inaccurate**
  - **Mostly False**
  - **Unsubstantiated / Unproven**
  - **Outdated**

#### B. Intent / Origin / Style Classifications:

  - **Misinformation**
  - **Disinformation**
  - **Satire / Parody**
  - **Opinion / Commentary**
  - **Propaganda**
  - **Fabricated Content**
  - **Imposter Content**
  - **Manipulated Content (Visual/Audio)**
  - **Deepfake (Visual/Audio)**
  - **Conspiracy Theory**

### 2\. Aletheian Reward, Ranking, and Penalty System

This system incentivizes accuracy, thoroughness, and expertise.

#### A. Experience Points (XP) - The Core Metric:

  - **Earning XP**: Based on successful verifications, complexity, accuracy, speed, and participating in escalation reviews.
  - **Losing XP (Penalties)**: For incorrect verifications, guideline breaches, or negligence.

#### B. Rankings:

Determined by cumulative XP, unlocking access to more complex claims and senior roles.

  - **Trainee Aletheian**
  - **Junior Aletheian**
  - **Associate Aletheian**
  - **Senior Aletheian**
  - **Expert Aletheian**
  - **Master Aletheian / Elder**

#### C. Expertise Badges:

Awarded to Senior Aletheians and above, requiring demonstrated high accuracy in specific categories.

#### D. Payment Calculation (Spotify Model):

  - A percentage of monthly user subscription revenue forms the "Aletheian Payment Pool."
  - An Aletheian's share is proportional to their monthly XP earned.

-----

## Addressing Potential Gaps & Implementing Solutions

  - **Aletheian Onboarding**: Rigorous vetting, testing, and mandatory training.
  - **Evidence Standards**: Aletheians are trained on the **CRAAP model** (Currency, Relevance, Authority, Accuracy, Purpose).
  - **Output Nuance**: Focus on truth and clarity with engaging visuals, avoiding sensationalism.
  - **AI Quality**: Continuous evaluation and refinement of AI models based on effectiveness and feedback.
  - **Claim Complexity**: A granular classification list and training for Aletheians to explain nuances.
  - **Aletheian Bias**: A consensus model with geo-location and remote Aletheians to mitigate bias.
  - **Scalability**: AI pre-filtering for duplicates and an efficient workflow.
  - **Funding**: A user subscription model to ensure sustainable payment for Aletheians.
  - **Dispute Resolution**: A multi-tiered escalation process involving Senior Aletheians and a "Council of Elders."
  - **User Privacy**: Anonymized user identifiers on the blockchain.
