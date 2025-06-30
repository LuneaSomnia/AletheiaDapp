// src/components/FinanceDashboard.tsx
import React from 'react';
import GlassCard from './GlassCard';

const FinanceDashboard: React.FC<{ earnings: any }> = ({ earnings }) => {
  return (
    <GlassCard className="p-8">
      <h2 className="text-2xl font-bold text-cream mb-6">Finance Dashboard</h2>
      
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
      
      <div>
        <h3 className="text-xl font-semibold text-cream mb-4">Withdraw Funds</h3>
        <div className="flex gap-4">
          <input
            type="number"
            placeholder="Amount in ICP"
            className="flex-1 bg-purple-900 bg-opacity-30 border border-gold rounded-lg p-3 text-cream"
          />
          <button className="bg-gradient-to-r from-purple-700 to-purple-900 text-cream py-3 px-6 rounded-lg font-bold hover:from-purple-800 hover:to-purple-950 transition-all">
            Withdraw
          </button>
        </div>
      </div>
    </GlassCard>
  );
};

export default FinanceDashboard;