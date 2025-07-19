// src/services/claims.ts
import { getVerificationWorkflowActor } from './canisters';

export const getAletheianClaims = async (principal: string) => {
  const actor = await getVerificationWorkflowActor();
  // Mock data - in production, call canister method
  return [
    {
      id: 'claim-001',
      text: "Drinking bleach cures COVID-19",
      submittedAt: "2023-05-15T10:30:00Z",
      deadline: "2023-05-15T11:00:00Z",
      status: "Assigned",
      complexity: "High"
    },
    {
      id: 'claim-002',
      text: "New study shows chocolate prevents aging",
      submittedAt: "2023-05-15T10:45:00Z",
      deadline: "2023-05-15T11:15:00Z",
      status: "In Progress",
      complexity: "Medium"
    },
    {
      id: 'claim-003',
      text: "Government announces universal basic income",
      submittedAt: "2023-05-15T11:00:00Z",
      deadline: "2023-05-15T11:30:00Z",
      status: "Pending",
      complexity: "Low"
    }
  ];
};

export const getClaimDetails = async (claimId: string) => {
  // Mock data
  return {
    id: claimId,
    text: "Drinking bleach cures COVID-19",
    source: "Social media post",
    submittedAt: "2023-05-15T10:30:00Z",
    evidence: [
      {
        source: "WHO Official Statement",
        url: "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/advice-for-public/myth-busters",
        summary: "WHO states that drinking bleach does not cure COVID-19 and is dangerous.",
        credibility: 9.8
      },
      {
        source: "CDC Guidelines",
        url: "https://www.cdc.gov/coronavirus/2019-ncov/if-you-are-sick/steps-when-sick.html",
        summary: "CDC does not recommend any unproven treatments for COVID-19.",
        credibility: 9.5
      }
    ]
  };
};

// Assign a claim to a user (mock implementation)
export const assignClaimToUser = async (claimId: string, principal: string) => {
  // In production, call canister method
  return { success: true, message: `Claim ${claimId} assigned to user ${principal}` };
};

// Accept a claim (mock implementation)
export const acceptClaim = async (claimId: string, principal: string) => {
  // In production, call canister method
  return { success: true, message: `User ${principal} accepted claim ${claimId}` };
};

// Submit verification for a claim (mock implementation)
export const verifyClaim = async (claimId: string, principal: string, verdict: string, explanation: string, evidenceLinks: string[]) => {
  // In production, call canister method
  return { success: true, message: `Verification submitted for claim ${claimId}` };
};

// Escalate a claim for further review (mock implementation)
export const escalateClaim = async (claimId: string, principal: string, rationale: string) => {
  // In production, call canister method
  return { success: true, message: `Claim ${claimId} escalated by user ${principal}` };
};

// AI integration: Blockchain duplicate search (mock implementation)
export const aiBlockchainDuplicateSearch = async (claimText: string) => {
  // In production, call AI service
  return [
    {
      id: 'blockchain-001',
      text: 'Similar claim found on blockchain: "Drinking bleach cures COVID-19"',
      matchScore: 0.97,
      link: 'https://blockchain.example/claim/001'
    }
  ];
};

// AI integration: Information retrieval (mock implementation)
export const aiInformationRetrieval = async (claimText: string) => {
  // In production, call AI service
  return [
    {
      title: 'WHO Myth Busters',
      summary: 'WHO states that drinking bleach does not cure COVID-19 and is dangerous.',
      url: 'https://www.who.int/emergencies/diseases/novel-coronavirus-2019/advice-for-public/myth-busters'
    },
    {
      title: 'CDC COVID-19 Guidelines',
      summary: 'CDC does not recommend any unproven treatments for COVID-19.',
      url: 'https://www.cdc.gov/coronavirus/2019-ncov/if-you-are-sick/steps-when-sick.html'
    }
  ];
};