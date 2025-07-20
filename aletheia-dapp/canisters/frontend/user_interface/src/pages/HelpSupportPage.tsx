import React, { useState } from 'react';
import GlassCard from '../components/GlassCard';
import GoldButton from '../components/GoldButton';

const HelpSupportPage: React.FC = () => {
  const [activeSection, setActiveSection] = useState('faq');

  const faqs = [
    {
      question: "How do I submit a claim for verification?",
      answer: "Navigate to the 'Submit Claim' page, choose your claim type (text, image, video, or link), fill in the required information, and click submit. Our AI and human experts will review your claim."
    },
    {
      question: "How long does claim verification take?",
      answer: "Simple claims are typically verified within 24-48 hours. Complex claims may take 3-5 business days. You'll receive notifications as your claim progresses."
    },
    {
      question: "What types of claims can I submit?",
      answer: "You can submit text claims, images, videos, audio files, article links, and social media posts. We support most common file formats and URLs."
    },
    {
      question: "How does the Learning Gym work?",
      answer: "The Learning Gym offers interactive exercises, scenarios, and quizzes to improve your critical thinking skills. Complete exercises to earn points, badges, and track your progress."
    },
    {
      question: "Can I appeal a claim result?",
      answer: "Yes, if you disagree with a verification result, you can submit an appeal with additional evidence. Our escalation system will review your case."
    }
  ];

  const contactInfo = {
    email: "support@aletheia.com",
    discord: "https://discord.gg/aletheia",
    twitter: "@AletheiaDApp",
    github: "https://github.com/aletheia-dapp"
  };

  const sections = [
    { id: 'faq', label: 'FAQ', icon: '❓' },
    { id: 'contact', label: 'Contact', icon: '📧' },
    { id: 'resources', label: 'Resources', icon: '📚' }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-900 via-red-800 to-red-900 p-4">
      <div className="max-w-4xl mx-auto">
        <GlassCard className="p-8">
          <h1 className="text-3xl font-bold text-gold mb-8 text-center">Help & Support</h1>

          {/* Navigation */}
          <div className="flex justify-center mb-8">
            <div className="flex gap-2">
              {sections.map((section) => (
                <button
                  key={section.id}
                  onClick={() => setActiveSection(section.id)}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg transition-colors ${
                    activeSection === section.id
                      ? 'bg-gold text-red-900 font-semibold'
                      : 'bg-red-900 bg-opacity-30 text-cream hover:bg-opacity-50'
                  }`}
                >
                  <span>{section.icon}</span>
                  <span>{section.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* FAQ Section */}
          {activeSection === 'faq' && (
            <div className="space-y-4">
              {faqs.map((faq, index) => (
                <div key={index} className="p-4 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30">
                  <h3 className="font-bold text-gold mb-2">{faq.question}</h3>
                  <p className="text-cream">{faq.answer}</p>
                </div>
              ))}
            </div>
          )}

          {/* Contact Section */}
          {activeSection === 'contact' && (
            <div className="space-y-6">
              <div className="grid md:grid-cols-2 gap-4">
                <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30">
                  <h3 className="font-bold text-gold mb-2">Email Support</h3>
                  <p className="text-cream mb-2">{contactInfo.email}</p>
                  <p className="text-sm text-cream opacity-75">Response within 24 hours</p>
                </div>
                <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30">
                  <h3 className="font-bold text-gold mb-2">Discord Community</h3>
                  <p className="text-cream mb-2">Join our community</p>
                  <a href={contactInfo.discord} target="_blank" rel="noopener noreferrer" className="text-gold hover:underline">Discord Server</a>
                </div>
                <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30">
                  <h3 className="font-bold text-gold mb-2">Twitter</h3>
                  <p className="text-cream mb-2">Follow for updates</p>
                  <a href={`https://twitter.com/${contactInfo.twitter.replace('@', '')}`} target="_blank" rel="noopener noreferrer" className="text-gold hover:underline">{contactInfo.twitter}</a>
                </div>
                <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30">
                  <h3 className="font-bold text-gold mb-2">GitHub</h3>
                  <p className="text-cream mb-2">Open source contributions</p>
                  <a href={contactInfo.github} target="_blank" rel="noopener noreferrer" className="text-gold hover:underline">Repository</a>
                </div>
              </div>
            </div>
          )}

          {/* Resources Section */}
          {activeSection === 'resources' && (
            <div className="space-y-6">
              <div className="grid md:grid-cols-2 gap-4">
                <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30">
                  <h3 className="font-bold text-gold mb-2">User Guide</h3>
                  <p className="text-cream mb-2">Complete guide to using Aletheia</p>
                  <GoldButton className="w-full" onClick={() => {}}>Read Guide</GoldButton>
                </div>
                <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30">
                  <h3 className="font-bold text-gold mb-2">API Documentation</h3>
                  <p className="text-cream mb-2">Developer resources</p>
                  <GoldButton className="w-full" onClick={() => {}}>View Docs</GoldButton>
                </div>
                <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30">
                  <h3 className="font-bold text-gold mb-2">Privacy Policy</h3>
                  <p className="text-cream mb-2">How we protect your data</p>
                  <GoldButton className="w-full" onClick={() => {}}>Read Policy</GoldButton>
                </div>
                <div className="p-4 bg-red-900 bg-opacity-20 rounded-lg border border-gold border-opacity-30">
                  <h3 className="font-bold text-gold mb-2">Terms of Service</h3>
                  <p className="text-cream mb-2">Platform terms and conditions</p>
                  <GoldButton className="w-full" onClick={() => {}}>Read Terms</GoldButton>
                </div>
              </div>
            </div>
          )}

          <div className="mt-8 text-center">
            <GoldButton onClick={() => window.history.back()}>
              Back to Dashboard
            </GoldButton>
          </div>
        </GlassCard>
      </div>
    </div>
  );
};

export default HelpSupportPage; 