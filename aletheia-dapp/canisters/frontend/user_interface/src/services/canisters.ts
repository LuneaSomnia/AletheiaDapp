// src/services/canisters.ts
import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory as userAccountFactory } from '../../../declarations/UserAccountCanister';
import { idlFactory as claimSubmissionFactory } from '../../../declarations/ClaimSubmissionCanister';
import { idlFactory as factLedgerFactory } from '../../../declarations/FactLedgerCanister';
import { idlFactory as learningFactory } from '../../../declarations/GamifiedLearningCanister';

export const createActor = async (canisterId: string, idlFactory: any) => {
  const agent = new HttpAgent({ 
    host: process.env.DFX_NETWORK === 'ic' 
      ? 'https://icp-api.io' 
      : 'http://localhost:8000'
  });
  
  if (process.env.NODE_ENV !== 'production') {
    await agent.fetchRootKey();
  }

  return Actor.createActor(idlFactory, {
    agent,
    canisterId
  });
};

export const getUserAccountActor = async () => {
  return createActor(
    process.env.USER_ACCOUNT_CANISTER_ID!,
    userAccountFactory
  );
};

export const getClaimSubmissionActor = async () => {
  return createActor(
    process.env.CLAIM_SUBMISSION_CANISTER_ID!,
    claimSubmissionFactory
  );
};

export const getFactLedgerActor = async () => {
  return createActor(
    process.env.FACT_LEDGER_CANISTER_ID!,
    factLedgerFactory
  );
};

export const getLearningActor = async () => {
  return createActor(
    process.env.LEARNING_CANISTER_ID!,
    learningFactory
  );
};