// src/services/finance.ts
import { getFinanceActor } from './canisters';

export const getAletheianEarnings = async (principal: string) => {
  // Mock data - in production, call canister method
  return {
    totalXP: 1250,
    monthlyXP: 320,
    earningsICP: 42.75,
    earningsUSD: 1250.50,
    paymentHistory: [
      { date: "2023-04-30", amountICP: 15.25, amountUSD: 450.75 },
      { date: "2023-03-31", amountICP: 12.50, amountUSD: 375.25 },
      { date: "2023-02-28", amountICP: 15.00, amountUSD: 424.50 }
    ]
  };
};

export const withdrawEarnings = async (principal: string, amount: number) => {
  const actor = await getFinanceActor();
  // Call canister method
  return { success: true, transactionId: "tx-123456" };
};

// Store payment goals in-memory for mock/demo purposes
const paymentGoals: Record<string, number> = {};

// Set a payment goal for a user (mock implementation)
export const setPaymentGoal = async (principal: string, goalICP: number) => {
  paymentGoals[principal] = goalICP;
  // In production, call canister method
  return { success: true, goalICP };
};

// Get a payment goal for a user (mock implementation)
export const getPaymentGoal = async (principal: string) => {
  // In production, call canister method
  return { goalICP: paymentGoals[principal] ?? 0 };
};