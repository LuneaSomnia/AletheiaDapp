import React from 'react';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const PrivacyPolicyPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 p-4">
      <div className="max-w-4xl mx-auto">
        <GlassCard className="p-8">
          <h1 className="text-3xl font-bold text-gold mb-8 text-center">Privacy Policy</h1>
          
          <div className="space-y-6 text-cream">
            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">1. Information We Collect</h2>
              <p className="mb-4">We collect information you provide directly to us, such as when you create an account, submit claims, or contact us for support.</p>
              <ul className="list-disc list-inside space-y-2 ml-4">
                <li>Account information (username, email, profile data)</li>
                <li>Claim submissions and related content</li>
                <li>Learning progress and achievements</li>
                <li>Communication with our support team</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">2. How We Use Your Information</h2>
              <p className="mb-4">We use the information we collect to:</p>
              <ul className="list-disc list-inside space-y-2 ml-4">
                <li>Provide and maintain our services</li>
                <li>Process and verify claim submissions</li>
                <li>Track learning progress and award achievements</li>
                <li>Send notifications and updates</li>
                <li>Improve our platform and user experience</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">3. Data Security</h2>
              <p>We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">4. Data Sharing</h2>
              <p className="mb-4">We do not sell, trade, or otherwise transfer your personal information to third parties except:</p>
              <ul className="list-disc list-inside space-y-2 ml-4">
                <li>With your explicit consent</li>
                <li>To comply with legal obligations</li>
                <li>To protect our rights and safety</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">5. Your Rights</h2>
              <p className="mb-4">You have the right to:</p>
              <ul className="list-disc list-inside space-y-2 ml-4">
                <li>Access your personal information</li>
                <li>Correct inaccurate data</li>
                <li>Request deletion of your data</li>
                <li>Opt out of certain communications</li>
                <li>Export your data</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">6. Contact Us</h2>
              <p>If you have questions about this Privacy Policy, please contact us at privacy@aletheia.com</p>
            </section>
          </div>

          <div className="mt-8 text-center">
            <GoldButton onClick={() => window.history.back()}>
              Back to Previous Page
            </GoldButton>
          </div>
        </GlassCard>
      </div>
    </div>
  );
};

export default PrivacyPolicyPage; 