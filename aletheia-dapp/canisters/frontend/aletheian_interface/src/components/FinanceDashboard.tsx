// src/components/FinanceDashboard.tsx
import React, { useState } from 'react';
import GlassCard from './GlassCard';

const FinanceDashboard: React.FC<{ earnings: any }> = ({ earnings }) => {
  // Payment goal state
  const [goal, setGoal] = useState<number>(earnings.paymentGoal || 10);
  const [goalInput, setGoalInput] = useState<string>(goal.toString());
  const progress = Math.min(100, (earnings.earningsICP / goal) * 100);

  // Withdrawal state
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [withdrawing, setWithdrawing] = useState(false);
  const [withdrawMsg, setWithdrawMsg] = useState<string | null>(null);

  // Earnings breakdown (placeholder if not provided)
  const earningsBreakdown = earnings.breakdown || [
    { label: 'Fact Checking', value: earnings.earningsICP * 0.6 },
    { label: 'Escalations', value: earnings.earningsICP * 0.2 },
    { label: 'Learning', value: earnings.earningsICP * 0.2 },
  ];

  const handleSetGoal = () => {
    const val = parseFloat(goalInput);
    if (!isNaN(val) && val > 0) setGoal(val);
  };

  const handleWithdraw = () => {
    setWithdrawing(true);
    setWithdrawMsg(null);
    // Simulate async withdrawal
    setTimeout(() => {
      setWithdrawing(false);
      setWithdrawMsg(`Withdrawal of ${withdrawAmount} ICP successful!`);
      setWithdrawAmount('');
    }, 1200);
  };

  return (
    <GlassCard className="p-8">
      <h2 className="text-2xl font-bold text-cream mb-6">Finance Dashboard</h2>

      {/* Payment Goal Setting */}
      <div className="mb-8">
        <h3 className="text-xl font-semibold text-cream mb-2">Set Your Payment Goal</h3>
        <div className="flex gap-2 items-center mb-2">
          <input
            type="number"
            min="1"
            value={goalInput}
            onChange={e => setGoalInput(e.target.value)}
            className="w-32 bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream"
          />
          <span className="text-cream">ICP</span>
          <button
            className="bg-gold text-purple-900 font-bold px-4 py-2 rounded hover:bg-yellow-300 transition-all"
            onClick={handleSetGoal}
            type="button"
          >
            Set Goal
          </button>
        </div>
        <div className="w-full bg-purple-900 bg-opacity-30 border border-gold rounded-lg h-6 relative mb-1">
          <div
            className="bg-gold h-6 rounded-lg transition-all"
            style={{ width: `${progress}%` }}
          />
          <span className="absolute left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2 text-purple-900 font-bold">
            {progress.toFixed(0)}% of {goal} ICP goal
          </span>
        </div>
      </div>

      {/* Earnings Overview */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-6 text-center">
          <p className="text-3xl font-bold text-gold">{earnings.totalXP} XP</p>
          <p className="text-cream">Total Reputation</p>
        </div>
        <div className="bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-6 text-center">
          <p className="text-3xl font-bold text-gold">{earnings.earningsICP} ICP</p>
          <p className="text-cream">≈ ${earnings.earningsUSD}</p>
        </div>
        <div className="bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-6 text-center">
          <p className="text-3xl font-bold text-gold">{earnings.monthlyXP} XP</p>
          <p className="text-cream">This Month</p>
        </div>
      </div>

      {/* Earnings Breakdown */}
      <div className="mb-8">
        <h3 className="text-xl font-semibold text-cream mb-4">Earnings Breakdown</h3>
        <div className="flex flex-col md:flex-row gap-4">
          {earningsBreakdown.map((b: any, idx: number) => (
            <div key={idx} className="flex-1 bg-purple-900 bg-opacity-20 border border-gold rounded-lg p-4 text-center">
              <p className="text-lg text-gold font-bold">{b.label}</p>
              <p className="text-cream">{b.value.toFixed(2)} ICP</p>
            </div>
          ))}
        </div>
      </div>

      {/* Payment History */}
      <div className="mb-8">
        <h3 className="text-xl font-semibold text-cream mb-4">Payment History</h3>
        <div className="bg-purple-900 bg-opacity-20 rounded-lg overflow-hidden">
          <table className="w-full">
            <thead className="bg-purple-900 bg-opacity-30">
              <tr>
                <th className="py-3 px-4 text-left text-cream">Date</th>
                <th className="py-3 px-4 text-left text-cream">ICP Amount</th>
                <th className="py-3 px-4 text-left text-cream">USD Value</th>
              </tr>
            </thead>
            <tbody>
              {earnings.paymentHistory.map((payment: any, index: number) => (
                <tr key={index} className="border-b border-purple-800">
                  <td className="py-3 px-4 text-cream">{payment.date}</td>
                  <td className="py-3 px-4 text-gold">{payment.amountICP} ICP</td>
                  <td className="py-3 px-4 text-cream">${payment.amountUSD}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Withdraw Funds */}
      <div>
        <h3 className="text-xl font-semibold text-cream mb-4">Withdraw Funds</h3>
        <div className="flex gap-4 mb-2">
          <input
            type="number"
            placeholder="Amount in ICP"
            className="flex-1 bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
            value={withdrawAmount}
            onChange={e => setWithdrawAmount(e.target.value)}
            disabled={withdrawing}
          />
          <button
            className="bg-gradient-to-r from-purple-700 to-purple-900 text-cream py-3 px-6 rounded-lg font-bold hover:from-purple-800 hover:to-purple-950 transition-all disabled:opacity-50"
            onClick={handleWithdraw}
            disabled={withdrawing || !withdrawAmount || parseFloat(withdrawAmount) <= 0}
            type="button"
          >
            {withdrawing ? 'Processing...' : 'Withdraw'}
          </button>
        </div>
        {withdrawMsg && <div className="text-gold font-semibold mt-1">{withdrawMsg}</div>}
      </div>
    </GlassCard>
  );
};

export default FinanceDashboard;