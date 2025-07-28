// src/services/canisters.ts
import { Actor, HttpAgent } from '@dfinity/agent';
import { AuthClient } from '@dfinity/auth-client';
import { Principal } from '@dfinity/principal';

// Import IDL factories (assuming dfx generate has been run)
// These imports will be available after running `dfx generate`
import { idlFactory as verificationWorkflowFactory, canisterId as verificationWorkflowCanisterId } from '../../../../declarations/VerificationWorkflowCanister';
import { idlFactory as aletheianProfileFactory, canisterId as aletheianProfileCanisterId } from '../../../../declarations/AletheianProfileCanister';
import { idlFactory as factLedgerFactory, canisterId as factLedgerCanisterId } from '../../../../declarations/FactLedgerCanister';
import { idlFactory as financeFactory, canisterId as financeCanisterId } from '../../../../declarations/FinanceCanister';
import { idlFactory as escalationFactory, canisterId as escalationCanisterId } from '../../../../declarations/EscalationCanister';
import { idlFactory as aiIntegrationFactory, canisterId as aiIntegrationCanisterId } from '../../../../declarations/AI_IntegrationCanister';
import { idlFactory as aletheianDispatchFactory, canisterId as aletheianDispatchCanisterId } from '../../../../declarations/AletheianDispatchCanister';
import { idlFactory as notificationFactory, canisterId as notificationCanisterId } from '../../../../declarations/NotificationCanister';
import { idlFactory as reputationLogicFactory, canisterId as reputationLogicCanisterId } from '../../../../declarations/ReputationLogicCanister';

// Type definitions based on the Motoko canisters
export interface AletheianProfile {
  id: Principal;
  rank: 'Trainee' | 'Junior' | 'Associate' | 'Senior' | 'Expert' | 'Master';
  xp: number;
  expertiseBadges: string[];
  location?: string;
  status: 'Active' | 'Suspended' | 'Retired';
  warnings: number;
  accuracy: number;
  claimsVerified: number;
  completedTraining: string[];
  createdAt: number;
  lastActive: number;
}

export interface ClaimAssignment {
  claimId: string;
  assignedTo: Principal[];
  deadline: number;
  status: 'Pending' | 'InProgress' | 'Completed' | 'Escalated';
  verifications: Array<{
    aletheianId: Principal;
    verdict: string;
    explanation: string;
    submittedAt: number;
  }>;
}

export interface EarningsData {
  totalXP: number;
  monthlyXP: number;
  earningsICP: number;
  earningsUSD: number;
  paymentHistory: Array<{
    date: string;
    amountICP: number;
    amountUSD: number;
  }>;
}

export interface NotificationData {
  id: number;
  userId: Principal;
  title: string;
  message: string;
  timestamp: number;
  read: boolean;
  notificationType: string;
}

// Environment configuration
const isLocal = process.env.DFX_NETWORK !== 'ic';
const host = isLocal ? 'http://localhost:8000' : 'https://icp-api.io';

// Create HTTP agent with authentication
let agent: HttpAgent | null = null;
let authClient: AuthClient | null = null;

export const initializeAgent = async (): Promise<HttpAgent> => {
  if (!agent) {
    // Initialize auth client
    authClient = await AuthClient.create();
    
    // Get identity from auth client
    const identity = authClient.getIdentity();
    
    // Create agent with identity
    agent = new HttpAgent({
      identity,
      host,
    });

    // Fetch root key for local development
    if (isLocal) {
      try {
        await agent.fetchRootKey();
      } catch (err) {
        console.warn("Unable to fetch root key. Check local replica is running");
        console.error(err);
      }
    }
  }
  return agent;
};

// Generic actor creator with authentication
const createActor = async <T>(canisterId: string, idlFactory: any): Promise<T> => {
  const currentAgent = await initializeAgent();
  return Actor.createActor<T>(idlFactory, {
    agent: currentAgent,
    canisterId,
  });
};

// ========== VERIFICATION WORKFLOW CANISTER ==========
export interface VerificationWorkflowService {
  createTask: (claimId: string, aletheians: Principal[]) => Promise<{ ok: null } | { err: string }>;
  submitFinding: (
    claimId: string,
    verdict: string,
    explanation: string,
    evidence: string[],
    isDuplicate: boolean,
    originalClaimId?: string
  ) => Promise<{ ok: null } | { err: string }>;
  getTask: (claimId: string) => Promise<ClaimAssignment | null>;
  getActiveTasks: () => Promise<ClaimAssignment[]>;
}

export const getVerificationWorkflowActor = async (): Promise<VerificationWorkflowService> => {
  return createActor<VerificationWorkflowService>(
    verificationWorkflowCanisterId,
    verificationWorkflowFactory
  );
};

// ========== ALETHEIAN PROFILE CANISTER ==========
export interface AletheianProfileService {
  getProfile: (aletheian: Principal) => Promise<AletheianProfile | null>;
  updateProfile: (location?: string) => Promise<{ ok: null } | { err: string }>;
  updateAletheianXp: (
    aletheian: Principal,
    xpChange: number,
    accuracyImpact?: number
  ) => Promise<{ ok: null } | { err: string }>;
  applyForBadge: (badge: string, evidence: string[]) => Promise<{ ok: string } | { err: string }>;
  heartbeat: () => Promise<void>;
  getAllAletheians: () => Promise<AletheianProfile[]>;
  getAletheiansByRank: (minRank: string) => Promise<AletheianProfile[]>;
}

export const getAletheianProfileActor = async (): Promise<AletheianProfileService> => {
  return createActor<AletheianProfileService>(
    aletheianProfileCanisterId,
    aletheianProfileFactory
  );
};

// ========== FACT LEDGER CANISTER ==========
export interface FactLedgerService {
  getFact: (id: number) => Promise<any | null>;
  getAllFacts: () => Promise<any[]>;
  getFactsByStatus: (status: string) => Promise<any[]>;
  getFactsByClassification: (classification: string) => Promise<any[]>;
}

export const getFactLedgerActor = async (): Promise<FactLedgerService> => {
  return createActor<FactLedgerService>(
    factLedgerCanisterId,
    factLedgerFactory
  );
};

// ========== FINANCE CANISTER ==========
export interface FinanceService {
  getUserEarnings: (user: Principal) => Promise<number>;
  getMonthlyXP: (user: Principal) => Promise<number>;
  withdraw: (amount: number) => Promise<{ ok: number } | { err: any }>;
  getRevenuePool: () => Promise<number>;
  getTotalMonthlyXP: () => Promise<number>;
}

export const getFinanceActor = async (): Promise<FinanceService> => {
  return createActor<FinanceService>(
    financeCanisterId,
    financeFactory
  );
};

// ========== ESCALATION CANISTER ==========
export interface EscalationService {
  escalateClaim: (
    claimId: string,
    initialFindings: Array<[Principal, any]>
  ) => Promise<{ ok: null } | { err: string }>;
  submitSeniorFinding: (
    claimId: string,
    finding: any
  ) => Promise<{ ok: null } | { err: string }>;
  submitCouncilFinding: (
    claimId: string,
    finding: any
  ) => Promise<{ ok: null } | { err: string }>;
  getEscalatedClaim: (claimId: string) => Promise<any | null>;
  getAllEscalatedClaims: () => Promise<Array<[string, any]>>;
}

export const getEscalationActor = async (): Promise<EscalationService> => {
  return createActor<EscalationService>(
    escalationCanisterId,
    escalationFactory
  );
};

// ========== AI INTEGRATION CANISTER ==========
export interface AIIntegrationService {
  generateQuestions: (claim: any) => Promise<{ ok: any } | { err: string }>;
  findDuplicates: (claim: any) => Promise<{ ok: string[] } | { err: string }>;
  retrieveAndSummarize: (claim: any) => Promise<{ ok: any[] } | { err: string }>;
  synthesizeReport: (claim: any, findings: any[]) => Promise<{ ok: any } | { err: string }>;
  analyzeMedia: (claim: any) => Promise<{ ok: any } | { err: string }>;
}

export const getAIIntegrationActor = async (): Promise<AIIntegrationService> => {
  return createActor<AIIntegrationService>(
    aiIntegrationCanisterId,
    aiIntegrationFactory
  );
};

// ========== ALETHEIAN DISPATCH CANISTER ==========
export interface AletheianDispatchService {
  assignClaim: (claim: any) => Promise<{ ok: Principal[] } | { err: string }>;
  completeAssignment: (claimId: string) => Promise<boolean>;
  updateProfile: (online: boolean, expertise: string[], location?: string) => Promise<boolean>;
  registerProfile: (expertise: string[], location?: string) => Promise<boolean>;
}

export const getAletheianDispatchActor = async (): Promise<AletheianDispatchService> => {
  return createActor<AletheianDispatchService>(
    aletheianDispatchCanisterId,
    aletheianDispatchFactory
  );
};

// ========== NOTIFICATION CANISTER ==========
export interface NotificationService {
  sendNotification: (
    userId: Principal,
    title: string,
    message: string,
    notifType: string
  ) => Promise<number>;
  getNotifications: (
    since?: number,
    limit?: number,
    unreadOnly?: boolean
  ) => Promise<NotificationData[]>;
  markAsRead: (notificationId: number) => Promise<void>;
  markAllAsRead: () => Promise<void>;
  updateSettings: (
    inApp?: boolean,
    push?: boolean,
    email?: boolean,
    disabledTypes?: string[]
  ) => Promise<any>;
}

export const getNotificationActor = async (): Promise<NotificationService> => {
  return createActor<NotificationService>(
    notificationCanisterId,
    notificationFactory
  );
};

// ========== REPUTATION LOGIC CANISTER ==========
export interface ReputationLogicService {
  updateReputation: (user: Principal, update: any) => Promise<void>;
  getReputation: (user: Principal) => Promise<any>;
  getRank: (user: Principal) => Promise<string>;
}

export const getReputationLogicActor = async (): Promise<ReputationLogicService> => {
  return createActor<ReputationLogicService>(
    reputationLogicCanisterId,
    reputationLogicFactory
  );
};

// ========== UTILITY FUNCTIONS ==========
export const getCurrentPrincipal = async (): Promise<Principal | null> => {
  if (!authClient) {
    authClient = await AuthClient.create();
  }
  
  if (await authClient.isAuthenticated()) {
    return authClient.getIdentity().getPrincipal();
  }
  
  return null;
};

export const isAuthenticated = async (): Promise<boolean> => {
  if (!authClient) {
    authClient = await AuthClient.create();
  }
  return authClient.isAuthenticated();
};

// Initialize all actors at once
export const initAllActors = async () => {
  try {
    const [
      verificationWorkflow,
      aletheianProfile,
      factLedger,
      finance,
      escalation,
      aiIntegration,
      aletheianDispatch,
      notification,
      reputationLogic
    ] = await Promise.all([
      getVerificationWorkflowActor(),
      getAletheianProfileActor(),
      getFactLedgerActor(),
      getFinanceActor(),
      getEscalationActor(),
      getAIIntegrationActor(),
      getAletheianDispatchActor(),
      getNotificationActor(),
      getReputationLogicActor()
    ]);

    return {
      verificationWorkflow,
      aletheianProfile,
      factLedger,
      finance,
      escalation,
      aiIntegration,
      aletheianDispatch,
      notification,
      reputationLogic
    };
  } catch (error) {
    console.error('Failed to initialize actors:', error);
    throw error;
  }
};