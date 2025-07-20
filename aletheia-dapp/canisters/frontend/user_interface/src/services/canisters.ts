// src/services/canisters.ts
import { Actor, HttpAgent } from '@dfinity/agent';

// TODO: Run `dfx generate` and ensure the following modules exist
// import { idlFactory as userAccountFactory } from 'declarations/UserAccountCanister';
// import { idlFactory as claimSubmissionFactory } from 'declarations/ClaimSubmissionCanister';
// import { idlFactory as factLedgerFactory } from 'declarations/FactLedgerCanister';
// import { idlFactory as learningFactory } from 'declarations/GamifiedLearningCanister';

// Temporary stubs for compilation
const userAccountFactory = {};
const claimSubmissionFactory = {};
const factLedgerFactory = {};
const learningFactory = {};

// Temporary stubs for type imports
type UserAccountService = any;
type ClaimSubmissionService = any;
type FactLedgerService = any;
type LearningService = any;

// Environment variables setup (add to your .env file)
const CANISTER_IDS = {
  USER_ACCOUNT: process.env.USER_ACCOUNT_CANISTER_ID || 'rrkah-fqaaa-aaaaa-aaaaq-cai',
  CLAIM_SUBMISSION: process.env.CLAIM_SUBMISSION_CANISTER_ID || 'ryjl3-tyaaa-aaaaa-aaaba-cai',
  FACT_LEDGER: process.env.FACT_LEDGER_CANISTER_ID || 'r7inp-6aaaa-aaaaa-aaabq-cai',
  LEARNING: process.env.LEARNING_CANISTER_ID || 'rno2w-sqaaa-aaaaa-aaacq-cai'
};

// Create a reusable agent instance
const createAgent = () => {
  const isLocal = process.env.DFX_NETWORK !== 'ic';
  return new HttpAgent({ 
    host: isLocal ? 'http://localhost:8000' : 'https://icp-api.io'
  });
};

// Initialize agent once (singleton pattern)
const agent = createAgent();

// Fetch root key for local development
if (process.env.NODE_ENV !== 'production') {
  agent.fetchRootKey().catch(err => {
    console.warn("Unable to fetch root key. Check local replica is running");
    console.error(err);
  });
}

// Generic actor creator
export const createActor = <T>(canisterId: string, idlFactory: any): T => {
  return Actor.createActor<T>(idlFactory, { agent, canisterId });
};

// Typed actor getters
export const getUserAccountActor = () => {
  return createActor<UserAccountService>(
    CANISTER_IDS.USER_ACCOUNT,
    userAccountFactory
  );
};

export const getClaimSubmissionActor = () => {
  return createActor<ClaimSubmissionService>(
    CANISTER_IDS.CLAIM_SUBMISSION,
    claimSubmissionFactory
  );
};

export const getFactLedgerActor = () => {
  return createActor<FactLedgerService>(
    CANISTER_IDS.FACT_LEDGER,
    factLedgerFactory
  );
};

export const getLearningActor = () => {
  return createActor<LearningService>(
    CANISTER_IDS.LEARNING,
    learningFactory
  );
};

// Optional: Initialize all actors at once
export const initCanisters = () => ({
  userAccount: getUserAccountActor(),
  claimSubmission: getClaimSubmissionActor(),
  factLedger: getFactLedgerActor(),
  learning: getLearningActor()
});