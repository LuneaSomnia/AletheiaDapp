const fs = require("fs");
const path = require("path");

console.log("🚀 Script started");

// Define your clean structure
const structure = [
  "aletheia-dapp/.dfx/",
  "aletheia-dapp/declarations/",
  "aletheia-dapp/node_modules/",
  "aletheia-dapp/canisters/backend/UserAccountCanister/src/UserAccountCanister.mo",
  "aletheia-dapp/canisters/backend/UserAccountCanister/UserAccountCanister.did",
  "aletheia-dapp/canisters/backend/AletheianProfileCanister/src/AletheianProfileCanister.mo",
  "aletheia-dapp/canisters/backend/AletheianProfileCanister/AletheianProfileCanister.did",
  "aletheia-dapp/canisters/backend/FactLedgerCanister/src/FactLedgerCanister.mo",
  "aletheia-dapp/canisters/backend/FactLedgerCanister/FactLedgerCanister.did",
  "aletheia-dapp/canisters/backend/ReputationLogicCanister/src/ReputationLogicCanister.mo",
  "aletheia-dapp/canisters/backend/ReputationLogicCanister/ReputationLogicCanister.did",
  "aletheia-dapp/canisters/backend/ClaimSubmissionCanister/src/ClaimSubmissionCanister.mo",
  "aletheia-dapp/canisters/backend/ClaimSubmissionCanister/ClaimSubmissionCanister.did",
  "aletheia-dapp/canisters/backend/AI_IntegrationCanister/src/AI_IntegrationCanister.mo",
  "aletheia-dapp/canisters/backend/AI_IntegrationCanister/AI_IntegrationCanister.did",
  "aletheia-dapp/canisters/backend/AletheianDispatchCanister/src/AletheianDispatchCanister.mo",
  "aletheia-dapp/canisters/backend/AletheianDispatchCanister/AletheianDispatchCanister.did",
  "aletheia-dapp/canisters/backend/VerificationWorkflowCanister/src/VerificationWorkflowCanister.mo",
  "aletheia-dapp/canisters/backend/VerificationWorkflowCanister/VerificationWorkflowCanister.did",
  "aletheia-dapp/canisters/backend/EscalationCanister/src/EscalationCanister.mo",
  "aletheia-dapp/canisters/backend/EscalationCanister/EscalationCanister.did",
  "aletheia-dapp/canisters/backend/FinanceCanister/src/FinanceCanister.mo",
  "aletheia-dapp/canisters/backend/FinanceCanister/FinanceCanister.did",
  "aletheia-dapp/canisters/backend/GamifiedLearningCanister/src/GamifiedLearningCanister.mo",
  "aletheia-dapp/canisters/backend/GamifiedLearningCanister/GamifiedLearningCanister.did",
  "aletheia-dapp/canisters/backend/NotificationCanister/src/NotificationCanister.mo",
  "aletheia-dapp/canisters/backend/NotificationCanister/NotificationCanister.did",
  "aletheia-dapp/canisters/frontend/user_interface/src/assets/icons/torch.svg",
  "aletheia-dapp/canisters/frontend/user_interface/src/assets/icons/scales.svg",
  "aletheia-dapp/canisters/frontend/user_interface/src/assets/icons/magnifier.svg",
  "aletheia-dapp/canisters/frontend/user_interface/src/assets/icons/computer.svg",
  "aletheia-dapp/canisters/frontend/user_interface/src/assets/textures/red-gold-bg.jpg",
  "aletheia-dapp/canisters/frontend/user_interface/src/assets/textures/glass-effect.png",
  "aletheia-dapp/canisters/frontend/user_interface/src/components/GlassCard.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/components/GoldButton.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/components/ClaimForm.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/components/ClaimStatus.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/components/CriticalThinkingExercise.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/components/QuestionMirror.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/components/FactCheckResult.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/components/ProfileSection.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/pages/LoginPage.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/pages/DashboardPage.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/pages/SubmitClaimPage.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/pages/ClaimResultPage.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/pages/LearningGymPage.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/pages/ProfilePage.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/services/auth.ts",
  "aletheia-dapp/canisters/frontend/user_interface/src/services/canisters.ts",
  "aletheia-dapp/canisters/frontend/user_interface/src/services/claims.ts",
  "aletheia-dapp/canisters/frontend/user_interface/src/services/learning.ts",
  "aletheia-dapp/canisters/frontend/user_interface/src/utils/helpers.ts",
  "aletheia-dapp/canisters/frontend/user_interface/src/App.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/index.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/routes.tsx",
  "aletheia-dapp/canisters/frontend/user_interface/src/user.css",
  "aletheia-dapp/canisters/frontend/user_interface/public/index.html",
  "aletheia-dapp/canisters/frontend/user_interface/public/favicon.ico",
  "aletheia-dapp/canisters/frontend/user_interface/package.json",
  "aletheia-dapp/canisters/frontend/user_interface/tsconfig.json",
  "aletheia-dapp/canisters/frontend/user_interface/webpack.config.js",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/assets/icons/",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/assets/textures/purple-gold-bg.jpg",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/assets/textures/glass-effect.png",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/components/GlassCard.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/components/PurpleButton.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/components/VerificationInterface.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/components/ClaimAssignment.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/components/EscalationReview.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/components/FinanceDashboard.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/components/ReputationBadge.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/components/EvidenceReview.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/pages/AletheianLogin.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/pages/AletheianDashboard.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/pages/ClaimVerificationPage.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/pages/EscalationPage.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/pages/FinancePage.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/pages/ProfilePage.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/services/auth.ts",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/services/canisters.ts",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/services/claims.ts",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/services/finance.ts",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/App.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/index.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/routes.tsx",
  "aletheia-dapp/canisters/frontend/aletheian_interface/src/aletheian.css",
  "aletheia-dapp/canisters/frontend/aletheian_interface/public/index.html",
  "aletheia-dapp/canisters/frontend/aletheian_interface/public/favicon.ico",
  "aletheia-dapp/canisters/frontend/aletheian_interface/package.json",
  "aletheia-dapp/canisters/frontend/aletheian_interface/tsconfig.json",
  "aletheia-dapp/canisters/frontend/aletheian_interface/webpack.config.js",
  "aletheia-dapp/scripts/deploy.sh",
  "aletheia-dapp/scripts/setup-env.sh",
  "aletheia-dapp/src/",
  "aletheia-dapp/dfx.json",
  "aletheia-dapp/package.json",
  "aletheia-dapp/tsconfig.json",
  "aletheia-dapp/webpack.config.js",
  "aletheia-dapp/README.md"
];

// Create folders and files recursively
structure.forEach(item => {
  const fullPath = path.resolve(item);
  const isFile = path.extname(fullPath) !== "";

  if (isFile) {
    fs.mkdirSync(path.dirname(fullPath), { recursive: true });
    fs.writeFileSync(fullPath, "");
    console.log("📄 Created file:", fullPath);
  } else {
    fs.mkdirSync(fullPath, { recursive: true });
    console.log("📁 Created folder:", fullPath);
  }
});

console.log("✅ Structure created successfully.");
