// src/services/escalation.ts
import { 
  getEscalationActor,
  getCurrentPrincipal 
} from './canisters';
import { Principal } from '@dfinity/principal';

export interface EscalatedClaim {
  claimId: string;
  initialFindings: Array<{
    aletheianId: Principal;
    verdict: string;
    explanation: string;
    evidence: string[];
  }>;
  seniorFindings: Array<{
    aletheianId: Principal;
    verdict: string;
    explanation: string;
    evidence: string[];
  }>;
  councilFindings: Array<{
    aletheianId: Principal;
    verdict: string;
    explanation: string;
    evidence: string[];
  }>;
  status: 'seniorReview' | 'councilReview' | { resolved: string };
  timestamp: number;
}

export const getEscalatedClaims = async (): Promise<EscalatedClaim[]> => {
  try {
    const actor = await getEscalationActor();
    const claims = await actor.getAllEscalatedClaims();
    
    return claims.map(([claimId, claim]) => ({
      claimId,
      initialFindings: claim.initialFindings.map((finding: any) => ({
        aletheianId: finding[0],
        verdict: finding[1].verdict,
        explanation: finding[1].explanation,
        evidence: finding[1].evidence
      })),
      seniorFindings: claim.seniorFindings.map((finding: any) => ({
        aletheianId: finding[0],
        verdict: finding[1].verdict,
        explanation: finding[1].explanation,
        evidence: finding[1].evidence
      })),
      councilFindings: claim.councilFindings.map((finding: any) => ({
        aletheianId: finding[0],
        verdict: finding[1].verdict,
        explanation: finding[1].explanation,
        evidence: finding[1].evidence
      })),
      status: claim.status,
      timestamp: Number(claim.timestamp)
    }));
  } catch (error) {
    console.error('Failed to fetch escalated claims:', error);
    return [];
  }
};

export const getEscalatedClaim = async (claimId: string): Promise<EscalatedClaim | null> => {
  try {
    const actor = await getEscalationActor();
    const claim = await actor.getEscalatedClaim(claimId);
    
    if (!claim) return null;
    
    return {
      claimId,
      initialFindings: claim.initialFindings.map((finding: any) => ({
        aletheianId: finding[0],
        verdict: finding[1].verdict,
        explanation: finding[1].explanation,
        evidence: finding[1].evidence
      })),
      seniorFindings: claim.seniorFindings.map((finding: any) => ({
        aletheianId: finding[0],
        verdict: finding[1].verdict,
        explanation: finding[1].explanation,
        evidence: finding[1].evidence
      })),
      councilFindings: claim.councilFindings.map((finding: any) => ({
        aletheianId: finding[0],
        verdict: finding[1].verdict,
        explanation: finding[1].explanation,
        evidence: finding[1].evidence
      })),
      status: claim.status,
      timestamp: Number(claim.timestamp)
    };
  } catch (error) {
    console.error('Failed to fetch escalated claim:', error);
    return null;
  }
};

export const submitSeniorFinding = async (
  claimId: string,
  verdict: string,
  explanation: string,
  evidence: string[]
): Promise<{ success: boolean; message: string }> => {
  try {
    const actor = await getEscalationActor();
    
    const finding = {
      verdict,
      explanation,
      evidence
    };
    
    const result = await actor.submitSeniorFinding(claimId, finding);
    
    if ('ok' in result) {
      return { 
        success: true, 
        message: 'Senior finding submitted successfully' 
      };
    } else {
      return { 
        success: false, 
        message: result.err 
      };
    }
  } catch (error) {
    console.error('Failed to submit senior finding:', error);
    return { 
      success: false, 
      message: 'Failed to submit finding' 
    };
  }
};

export const submitCouncilFinding = async (
  claimId: string,
  verdict: string,
  explanation: string,
  evidence: string[]
): Promise<{ success: boolean; message: string }> => {
  try {
    const actor = await getEscalationActor();
    
    const finding = {
      verdict,
      explanation,
      evidence
    };
    
    const result = await actor.submitCouncilFinding(claimId, finding);
    
    if ('ok' in result) {
      return { 
        success: true, 
        message: 'Council finding submitted successfully' 
      };
    } else {
      return { 
        success: false, 
        message: result.err 
      };
    }
  } catch (error) {
    console.error('Failed to submit council finding:', error);
    return { 
      success: false, 
      message: 'Failed to submit finding' 
    };
  }
};

export const checkEscalationEligibility = async (rank: string): Promise<boolean> => {
  // Check if user has sufficient rank for escalation review
  const seniorRanks = ['Senior', 'Expert', 'Master'];
  const councilRanks = ['Master'];
  
  return seniorRanks.includes(rank);
};

export const checkCouncilEligibility = async (rank: string): Promise<boolean> => {
  const councilRanks = ['Master'];
  return councilRanks.includes(rank);
};