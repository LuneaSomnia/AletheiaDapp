// src/services/finance.ts
import { 
  getFinanceActor, 
  getAletheianProfileActor,
  getCurrentPrincipal 
} from './canisters';
import type { EarningsData } from './canisters';

export const getAletheianEarnings = async (principal: string): Promise<EarningsData> => {
  try {
    const financeActor = await getFinanceActor();
    const profileActor = await getAletheianProfileActor();
    const currentPrincipal = await getCurrentPrincipal();
    
    if (!currentPrincipal) {
      throw new Error('User not authenticated');
    }

    // Get earnings data from finance canister
    const [userEarnings, monthlyXP, totalMonthlyXP] = await Promise.all([
      financeActor.getUserEarnings(currentPrincipal),
      financeActor.getMonthlyXP(currentPrincipal),
      financeActor.getTotalMonthlyXP()
    ]);

    // Get profile data for total XP
    const profile = await profileActor.getProfile(currentPrincipal);
    const totalXP = profile?.xp || 0;

    // Convert earnings from e8s to ICP (1 ICP = 100,000,000 e8s)
    const earningsICP = Number(userEarnings) / 100_000_000;
    
    // Mock USD conversion rate (in production, get from exchange API)
    const icpToUsd = 12.50;
    const earningsUSD = earningsICP * icpToUsd;

    // Generate mock payment history (in production, get from finance canister)
    const paymentHistory = [
      { 
        date: "2023-04-30", 
        amountICP: earningsICP * 0.3, 
        amountUSD: earningsUSD * 0.3 
      },
      { 
        date: "2023-03-31", 
        amountICP: earningsICP * 0.25, 
        amountUSD: earningsUSD * 0.25 
      },
      { 
        date: "2023-02-28", 
        amountICP: earningsICP * 0.2, 
        amountUSD: earningsUSD * 0.2 
      }
    ];

    return {
      totalXP,
      monthlyXP: Number(monthlyXP),
      earningsICP,
      earningsUSD,
      paymentHistory
    };
  } catch (error) {
    console.error('Failed to fetch earnings:', error);
    // Return mock data as fallback
    return {
      totalXP: 1250,
      monthlyXP: 320,
      earningsICP: 42.75,
      earningsUSD: 534.38,
      paymentHistory: [
        { date: "2023-04-30", amountICP: 15.25, amountUSD: 190.63 },
        { date: "2023-03-31", amountICP: 12.50, amountUSD: 156.25 },
        { date: "2023-02-28", amountICP: 15.00, amountUSD: 187.50 }
      ]
    };
  }
};

export const withdrawEarnings = async (amount: number): Promise<{ success: boolean; transactionId?: string; message?: string }> => {
  try {
    const financeActor = await getFinanceActor();
    
    // Convert ICP to e8s for the canister call
    const amountE8s = Math.floor(amount * 100_000_000);
    
    const result = await financeActor.withdraw(amountE8s);
    
    if ('ok' in result) {
      return { 
        success: true, 
        transactionId: result.ok.toString(),
        message: `Successfully withdrew ${amount} ICP`
      };
    } else {
      let errorMessage = 'Withdrawal failed';
      
      if ('InsufficientFunds' in result.err) {
        const balance = Number(result.err.InsufficientFunds.balance.e8s) / 100_000_000;
        errorMessage = `Insufficient funds. Available balance: ${balance} ICP`;
      } else if ('BadFee' in result.err) {
        const expectedFee = Number(result.err.BadFee.expected_fee.e8s) / 100_000_000;
        errorMessage = `Amount too small. Minimum withdrawal after fees: ${expectedFee} ICP`;
      } else if ('Other' in result.err) {
        errorMessage = result.err.Other.error_message;
      }
      
      return { 
        success: false, 
        message: errorMessage 
      };
    }
  } catch (error) {
    console.error('Withdrawal failed:', error);
    return { 
      success: false, 
      message: 'Network error during withdrawal' 
    };
  }
};

export const getPaymentGoal = async (): Promise<{ goalICP: number }> => {
  try {
    // In production, this would be stored in user preferences
    const stored = localStorage.getItem('aletheian_payment_goal');
    const goalICP = stored ? parseFloat(stored) : 50.0;
    return { goalICP };
  } catch (error) {
    console.error('Failed to get payment goal:', error);
    return { goalICP: 50.0 };
  }
};

export const setPaymentGoal = async (goalICP: number): Promise<{ success: boolean; goalICP: number }> => {
  try {
    // In production, this would be stored in a user preferences canister
    localStorage.setItem('aletheian_payment_goal', goalICP.toString());
    return { success: true, goalICP };
  } catch (error) {
    console.error('Failed to set payment goal:', error);
    return { success: false, goalICP: 0 };
  }
};

export const getRevenuePoolInfo = async (): Promise<{ totalPool: number; distributionDate: string }> => {
  try {
    const financeActor = await getFinanceActor();
    const totalPool = await financeActor.getRevenuePool();
    
    // Convert from e8s to ICP
    const totalPoolICP = Number(totalPool) / 100_000_000;
    
    // Calculate next distribution date (monthly)
    const now = new Date();
    const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    const distributionDate = nextMonth.toISOString().split('T')[0];
    
    return {
      totalPool: totalPoolICP,
      distributionDate
    };
  } catch (error) {
    console.error('Failed to get revenue pool info:', error);
    return {
      totalPool: 10000,
      distributionDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    };
  }
};