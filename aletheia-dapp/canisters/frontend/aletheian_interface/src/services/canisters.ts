// src/services/canisters.ts
import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory as verificationWorkflowFactory } from '../../../declarations/VerificationWorkflowCanister';
import { idlFactory as aletheianProfileFactory } from '../../../declarations/AletheianProfileCanister';
import { idlFactory as factLedgerFactory } from '../../../declarations/FactLedgerCanister';
import { idlFactory as financeFactory } from '../../../declarations/FinanceCanister';

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

export const getVerificationWorkflowActor = async () => {
  return createActor(
    process.env.VERIFICATION_WORKFLOW_CANISTER_ID!,
    verificationWorkflowFactory
  );
};

export const getAletheianProfileActor = async () => {
  return createActor(
    process.env.ALETHEIAN_PROFILE_CANISTER_ID!,
    aletheianProfileFactory
  );
};

export const getFactLedgerActor = async () => {
  return createActor(
    process.env.FACT_LEDGER_CANISTER_ID!,
    factLedgerFactory
  );
};

export const getFinanceActor = async () => {
  return createActor(
    process.env.FINANCE_CANISTER_ID!,
    financeFactory
  );
};