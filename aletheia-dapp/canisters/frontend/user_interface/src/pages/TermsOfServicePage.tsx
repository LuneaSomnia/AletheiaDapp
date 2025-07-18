import React from 'react';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const TermsOfServicePage: React.FC = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 p-4">
      <div className="max-w-4xl mx-auto">
        <GlassCard className="p-8">
          <h1 className="text-3xl font-bold text-gold mb-8 text-center">Terms of Service</h1>
          
          <div className="space-y-6 text-cream">
            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">1. Acceptance of Terms</h2>
              <p>By accessing and using Aletheia DApp, you accept and agree to be bound by the terms and provision of this agreement.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">2. Description of Service</h2>
              <p className="mb-4">Aletheia DApp is a decentralized fact-checking platform that allows users to:</p>
              <ul className="list-disc list-inside space-y-2 ml-4">
                <li>Submit claims for verification</li>
                <li>Access verified information and evidence</li>
                <li>Participate in learning exercises</li>
                <li>Earn achievements and badges</li>
                <li>Contribute to the community</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">3. User Responsibilities</h2>
              <p className="mb-4">As a user, you agree to:</p>
              <ul className="list-disc list-inside space-y-2 ml-4">
                <li>Provide accurate and truthful information</li>
                <li>Respect intellectual property rights</li>
                <li>Not submit malicious or harmful content</li>
                <li>Maintain the security of your account</li>
                <li>Comply with all applicable laws</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">4. Content Guidelines</h2>
              <p className="mb-4">When submitting claims, you must:</p>
              <ul className="list-disc list-inside space-y-2 ml-4">
                <li>Ensure content is factual and verifiable</li>
                <li>Provide appropriate context and sources</li>
                <li>Not submit copyrighted material without permission</li>
                <li>Not submit content that promotes harm or violence</li>
                <li>Respect community guidelines</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">5. Intellectual Property</h2>
              <p>The platform and its content are protected by intellectual property laws. Users retain rights to their submitted content while granting us license to use it for verification purposes.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">6. Disclaimers</h2>
              <p className="mb-4">We provide verification services but cannot guarantee:</p>
              <ul className="list-disc list-inside space-y-2 ml-4">
                <li>100% accuracy of all verifications</li>
                <li>Continuous availability of the service</li>
                <li>Compatibility with all devices or browsers</li>
                <li>Freedom from errors or bugs</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">7. Limitation of Liability</h2>
              <p>We shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the service.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">8. Termination</h2>
              <p>We may terminate or suspend your account at any time for violations of these terms or for any other reason at our discretion.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">9. Changes to Terms</h2>
              <p>We reserve the right to modify these terms at any time. Continued use of the service constitutes acceptance of updated terms.</p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gold mb-4">10. Contact Information</h2>
              <p>For questions about these Terms of Service, please contact us at legal@aletheia.com</p>
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

export default TermsOfServicePage; 