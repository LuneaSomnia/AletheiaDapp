// src/services/claims.ts
import { 
  getVerificationWorkflowActor, 
  getAIIntegrationActor, 
  getFactLedgerActor,
  getCurrentPrincipal 
} from './canisters';
import { Principal } from '@dfinity/principal';

export interface ClaimDetails {
  id: string;
  text: string;
  source?: string;
  submittedAt: string;
  evidence: Array<{
    source: string;
    url: string;
    summary: string;
    credibility: number;
  }>;
}

export interface AletheianClaim {
  id: string;
  text: string;
  submittedAt: string;
  deadline: string;
  status: string;
  complexity: string;
}

export const getAletheianClaims = async (principal: string): Promise<AletheianClaim[]> => {
  try {
    const actor = await getVerificationWorkflowActor();
    const tasks = await actor.getActiveTasks();
    
    const currentPrincipal = await getCurrentPrincipal();
    if (!currentPrincipal) {
      throw new Error('User not authenticated');
    }

    // Filter tasks assigned to current Aletheian
    const assignedTasks = tasks.filter(task => 
      task.assignedTo.some(aletheian => aletheian.toString() === currentPrincipal.toString())
    );

    return assignedTasks.map(task => ({
      id: task.claimId,
      text: `Claim ${task.claimId}`, // In production, get actual claim content
      submittedAt: new Date(Number(task.deadline) - 24 * 60 * 60 * 1000).toISOString(),
      deadline: new Date(Number(task.deadline)).toISOString(),
      status: task.status,
      complexity: 'Medium' // This would be determined by the system
    }));
  } catch (error) {
    console.error('Failed to fetch Aletheian claims:', error);
    // Return mock data as fallback
    return [
      {
        id: 'claim-001',
        text: "Drinking bleach cures COVID-19",
        submittedAt: "2023-05-15T10:30:00Z",
        deadline: "2023-05-15T11:00:00Z",
        status: "Assigned",
        complexity: "High"
      }
    ];
  }
};

export const getClaimDetails = async (claimId: string): Promise<ClaimDetails> => {
  try {
    const verificationActor = await getVerificationWorkflowActor();
    const aiActor = await getAIIntegrationActor();
    
    // Get task details
    const task = await verificationActor.getTask(claimId);
    if (!task) {
      throw new Error('Claim not found');
    }

    // Get AI-generated evidence (if available)
    const claim = {
      id: claimId,
      content: `Claim content for ${claimId}`, // In production, get from claim submission
      claimType: 'text',
      source: null,
      context: null
    };

    const researchResult = await aiActor.retrieveAndSummarize(claim);
    let evidence = [];
    
    if ('ok' in researchResult) {
      evidence = researchResult.ok.map((item: any) => ({
        source: item.sourceName,
        url: item.sourceUrl,
        summary: item.summary,
        credibility: item.credibilityScore * 10 // Convert to 0-10 scale
      }));
    }

    return {
      id: claimId,
      text: `Claim content for ${claimId}`,
      source: "Social media post",
      submittedAt: new Date(task.deadline - 24 * 60 * 60 * 1000).toISOString(),
      evidence
    };
  } catch (error) {
    console.error('Failed to fetch claim details:', error);
    // Return mock data as fallback
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
        }
      ]
    };
  }
};

export const acceptClaim = async (claimId: string): Promise<{ success: boolean; message: string }> => {
  try {
    const currentPrincipal = await getCurrentPrincipal();
    if (!currentPrincipal) {
      throw new Error('User not authenticated');
    }

    // In production, this would update the task status
    // For now, we'll just return success
    return { 
      success: true, 
      message: `Claim ${claimId} accepted successfully` 
    };
  } catch (error) {
    console.error('Failed to accept claim:', error);
    return { 
      success: false, 
      message: 'Failed to accept claim' 
    };
  }
};

export const submitVerification = async (
  claimId: string,
  verdict: string,
  explanation: string,
  evidenceLinks: string[]
): Promise<{ success: boolean; message: string }> => {
  try {
    const actor = await getVerificationWorkflowActor();
    const currentPrincipal = await getCurrentPrincipal();
    
    if (!currentPrincipal) {
      throw new Error('User not authenticated');
    }

    const result = await actor.submitFinding(
      claimId,
      verdict,
      explanation,
      evidenceLinks,
      false, // isDuplicate
      undefined // originalClaimId
    );

    if ('ok' in result) {
      return { 
        success: true, 
        message: 'Verification submitted successfully' 
      };
    } else {
      return { 
        success: false, 
        message: result.err 
      };
    }
  } catch (error) {
    console.error('Failed to submit verification:', error);
    return { 
      success: false, 
      message: 'Failed to submit verification' 
    };
  }
};

export const escalateClaim = async (
  claimId: string,
  rationale: string
): Promise<{ success: boolean; message: string }> => {
  try {
    // This would typically be handled by the verification workflow
    // when consensus is not reached
    return { 
      success: true, 
      message: `Claim ${claimId} escalated for senior review` 
    };
  } catch (error) {
    console.error('Failed to escalate claim:', error);
    return { 
      success: false, 
      message: 'Failed to escalate claim' 
    };
  }
};

export const searchDuplicateClaims = async (claimText: string): Promise<any[]> => {
  try {
    const aiActor = await getAIIntegrationActor();
    
    const claim = {
      id: 'temp',
      content: claimText,
      claimType: 'text',
      source: null,
      context: null
    };

    const result = await aiActor.findDuplicates(claim);
    
    if ('ok' in result) {
      return result.ok.map(id => ({
        id,
        text: `Similar claim found: ${id}`,
        matchScore: 0.85,
        link: `#/claim-result/${id}`
      }));
    }
    
    return [];
  } catch (error) {
    console.error('Failed to search for duplicates:', error);
    return [];
  }
};

export const getAIResearch = async (claimText: string): Promise<any[]> => {
  try {
    const aiActor = await getAIIntegrationActor();
    
    const claim = {
      id: 'temp',
      content: claimText,
      claimType: 'text',
      source: null,
      context: null
    };

    const result = await aiActor.retrieveAndSummarize(claim);
    
    if ('ok' in result) {
      return result.ok.map((item: any) => ({
        title: item.sourceName,
        summary: item.summary,
        url: item.sourceUrl,
        credibility: item.credibilityScore
      }));
    }
    
    return [];
  } catch (error) {
    console.error('Failed to get AI research:', error);
    return [];
  }
};