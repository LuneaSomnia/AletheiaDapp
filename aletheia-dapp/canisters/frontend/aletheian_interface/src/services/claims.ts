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