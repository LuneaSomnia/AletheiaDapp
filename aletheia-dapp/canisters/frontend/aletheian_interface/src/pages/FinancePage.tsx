// src/pages/FinancePage.tsx
import React, { useEffect, useState } from 'react';
import FinanceDashboard from '../components/FinanceDashboard';
import { useAuth } from '../services/auth';
import { getAletheianEarnings, withdrawEarnings, getPaymentGoal, setPaymentGoal } from '../services/finance';
import GlassCard from '../components/GlassCard';

const FinancePage: React.FC = () => {
  const { user } = useAuth();
  const [earnings, setEarnings] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [paymentGoal, setPaymentGoalState] = useState<number>(50);
  const [goalInput, setGoalInput] = useState<string>('50');
  const [withdrawAmount, setWithdrawAmount] = useState<string>('');
  const [withdrawMsg, setWithdrawMsg] = useState<string>('');
  const [isWithdrawing, setIsWithdrawing] = useState(false);

  useEffect(() => {
    const fetchFinanceData = async () => {
      if (user) {
        setIsLoading(true);
        try {
          const [data, goalData] = await Promise.all([
            getAletheianEarnings(user.principal),
            getPaymentGoal()
          ]);
          setEarnings(data);
          setPaymentGoalState(goalData.goalICP);
          setGoalInput(goalData.goalICP.toString());
        } catch (error) {
          console.error('Failed to fetch earnings:', error);
        } finally {
          setIsLoading(false);
        }
      }
    };

    fetchFinanceData();
  }, [user]);

  if (!user) return null;

  // Mock breakdown if not present
  const breakdown = earnings?.breakdown || {
    xp: 3200,
    bonuses: 150,
    penalties: 50,
    net: (earnings?.total ?? 1250) + 150 - 50,
  };
  const available = earnings?.available ?? 800;
  const total = earnings?.total ?? 1250;
  const pending = earnings?.pending ?? 450;
  const progress = Math.min(100, Math.round((earnings?.earningsICP || 0) / paymentGoal * 100));

  const handleSetGoal = async () => {
    const val = parseFloat(goalInput);
    if (!isNaN(val) && val > 0) {
      try {
        const result = await setPaymentGoal(val);
        if (result.success) {
          setPaymentGoalState(val);
          setWithdrawMsg('Payment goal updated successfully!');
          setTimeout(() => setWithdrawMsg(''), 3000);
        }
      } catch (error) {
        console.error('Failed to set payment goal:', error);
        setWithdrawMsg('Failed to update payment goal.');
      }
    }
  };

  const handleWithdraw = async () => {
    const amt = parseFloat(withdrawAmount);
    if (!amt || amt <= 0) {
      setWithdrawMsg('Enter a valid amount.');
      return;
    }
    
    if (amt > (earnings?.earningsICP || 0)) {
      setWithdrawMsg('Amount exceeds available balance.');
      return;
    }
    
    setIsWithdrawing(true);
    setWithdrawMsg('');
    
    try {
      const result = await withdrawEarnings(amt);
      if (result.success) {
        setWithdrawMsg(`Withdrawal successful! Transaction ID: ${result.transactionId}`);
        setWithdrawAmount('');
        // Refresh earnings data
        const updatedEarnings = await getAletheianEarnings(user.principal);
        setEarnings(updatedEarnings);
      } else {
        setWithdrawMsg(result.message || 'Withdrawal failed.');
      }
    } catch (error) {
      console.error('Withdrawal failed:', error);
      setWithdrawMsg('Network error during withdrawal.');
    } finally {
      setIsWithdrawing(false);
    }
  };

  return (
    <div className="min-h-screen p-4 relative overflow-hidden">
      <div className="absolute inset-0 overflow-hidden pointer-events-none z-0">
        {[...Array(15)].map((_, i) => (
          <div
            key={i}
            className="absolute abstract-icon"
            style={{
              top: `${Math.random() * 100}%`,
              left: `${Math.random() * 100}%`,
              width: `${Math.random() * 100 + 50}px`,
              height: `${Math.random() * 100 + 50}px`,
              backgroundImage: `url(/assets/icons/${['torch', 'scales', 'magnifier', 'computer'][i % 4]}.svg)`,
              backgroundSize: 'contain',
              backgroundRepeat: 'no-repeat',
              filter: i % 2 === 0 ? 'invert(75%) sepia(40%) saturate(500%) hue-rotate(270deg) brightness(90%)' : 'invert(80%) sepia(80%) saturate(800%) hue-rotate(45deg) brightness(110%)',
              opacity: 0.12 + (i % 3) * 0.04,
              transform: `rotate(${Math.random() * 360}deg)`
            }}
          />
        ))}
      </div>
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold text-cream mb-8">Finance Dashboard</h1>
        {/* Finance Overview Section */}
        <GlassCard className="mb-8">
          <h2 className="text-xl font-bold text-gold mb-4">Overview</h2>
          {/* Payment Goal Setting */}
          <div className="mb-6 flex flex-col md:flex-row md:items-center gap-4">
            <div className="flex-1">
              <label className="text-cream font-semibold mr-2">Payment Goal:</label>
              <input
                type="number"
                min={1}
                className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream w-32 mr-2"
                value={goalInput}
                onChange={e => setGoalInput(e.target.value)}
              />
              <button
                className="luxury-btn px-4 py-2"
                onClick={handleSetGoal}
              >
                Set Goal
              </button>
              <span className="ml-4 text-gold font-bold">Current: {paymentGoal} ALTH</span>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
            <div className="bg-gold bg-opacity-10 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-gold">{total} ALTH</div>
              <div className="text-cream text-sm">Total Earnings</div>
            </div>
            <div className="bg-gold bg-opacity-10 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-gold">{available} ALTH</div>
              <div className="text-cream text-sm">Available Balance</div>
            </div>
            <div className="bg-gold bg-opacity-10 rounded-lg p-4 text-center">
              <div className="text-2xl font-bold text-gold">{pending} ALTH</div>
              <div className="text-cream text-sm">Pending Payouts</div>
            </div>
          </div>
          {/* Detailed Earnings Breakdown */}
          <div className="mb-6">
            <h3 className="text-gold font-semibold mb-2">Earnings Breakdown</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-red-900 bg-opacity-20 rounded-lg p-3 text-center">
                <div className="text-lg text-gold font-bold">{breakdown.xp}</div>
                <div className="text-cream text-xs">XP</div>
              </div>
              <div className="bg-red-900 bg-opacity-20 rounded-lg p-3 text-center">
                <div className="text-lg text-green-400 font-bold">+{breakdown.bonuses}</div>
                <div className="text-cream text-xs">Bonuses</div>
              </div>
              <div className="bg-red-900 bg-opacity-20 rounded-lg p-3 text-center">
                <div className="text-lg text-red-400 font-bold">-{breakdown.penalties}</div>
                <div className="text-cream text-xs">Penalties</div>
              </div>
              <div className="bg-red-900 bg-opacity-20 rounded-lg p-3 text-center">
                <div className="text-lg text-gold font-bold">{breakdown.net}</div>
                <div className="text-cream text-xs">Net Earnings</div>
              </div>
            </div>
          </div>
          {/* Payment Goal Progress */}
          <div className="mb-6">
            <div className="flex justify-between mb-1">
              <span className="text-cream font-semibold">Payment Goal</span>
              <span className="text-gold font-bold">{paymentGoal} ALTH</span>
            </div>
            <div className="w-full bg-red-900 bg-opacity-20 rounded-full h-4">
              <div
                className="bg-gold h-4 rounded-full"
                style={{ width: `${progress}%` }}
              ></div>
            </div>
            <div className="text-cream text-xs mt-1 text-right">
              {progress}% to goal
            </div>
          </div>
          {/* Withdrawal Option */}
          <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
            <div className="text-cream">You can withdraw your available balance at any time.</div>
            <div className="flex items-center gap-2">
              <input
                type="number"
                min={1}
                max={available}
                className="bg-red-900 bg-opacity-30 border border-gold rounded-lg p-2 text-cream w-28"
                placeholder="Amount"
                value={withdrawAmount}
                onChange={e => setWithdrawAmount(e.target.value)}
              />
              <button
                className="luxury-btn"
                onClick={handleWithdraw}
                disabled={isWithdrawing || !withdrawAmount || parseFloat(withdrawAmount) <= 0}
              >
                {isWithdrawing ? 'Processing...' : 'Withdraw Funds'}
              </button>
            </div>
          </div>
          {withdrawMsg && (
            <div className={`mt-2 text-sm font-semibold ${withdrawMsg.includes('submitted') ? 'text-green-400' : 'text-red-400'}`}>{withdrawMsg}</div>
          )}
        </GlassCard>
        {/* Existing Finance Dashboard */}
        {isLoading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gold mx-auto"></div>
            <p className="mt-4 text-cream">Loading financial data...</p>
          </div>
        ) : earnings ? (
          <FinanceDashboard earnings={earnings} />
        ) : (
          <GlassCard className="p-8">
            <p className="text-cream text-center">No financial data available</p>
          </GlassCard>
        )}
      </div>
    </div>
  );
};

export default FinancePage;