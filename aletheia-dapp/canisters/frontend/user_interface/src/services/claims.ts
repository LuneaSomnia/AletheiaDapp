// src/services/claims.ts
import { getClaimSubmissionActor, getFactLedgerActor } from './canisters';

export const submitClaim = async (
  claim: string, 
  claimType: string, 
  source?: string, 
  context?: string
) => {
  const actor = await getClaimSubmissionActor();
  // In production: await actor.submitClaim({ claim, claimType, source, context });
  return {
    claimId: `claim-${Date.now()}`,
    questions: [
      "What scientific evidence supports this claim from reputable health organizations?",
      "Who is making this claim, and what are their qualifications or potential biases?"
    ]
  };
};

export const getClaimResult = async (claimId: string) => {
  const actor = await getFactLedgerActor();
  // In production: return await actor.getFact(claimId);
  return {
    id: claimId,
    claim: "Drinking bleach cures COVID-19",
    verdict: "FALSE",
    summary: "No scientific evidence supports this claim. Health authorities warn that drinking bleach is dangerous and can cause serious harm.",
    evidence: [
      {
        source: "WHO Official Statement",
        url: "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/advice-for-public/myth-busters",
        content: "WHO states that drinking bleach does not cure COVID-19 and is dangerous."
      },
      {
        source: "CDC Guidelines",
        url: "https://www.cdc.gov/coronavirus/2019-ncov/if-you-are-sick/steps-when-sick.html",
        content: "CDC does not recommend any unproven treatments for COVID-19."
      }
    ],
    aletheiansVerified: "3/3 Aletheians",
    submittedAt: "2023-05-15T10:30:00Z",
    verifiedAt: "2023-05-15T10:35:00Z"
  };
};