# Aletheia DApp Documentation

## Technical Stack
- Frontend: React + TypeScript
- Blockchain: Internet Computer (ICP)
- State Management: Redux
- Styling: Tailwind CSS with custom theme
- Authentication: Internet Identity

## Component API Reference

### EscalationReview.tsx
```tsx
interface Props {
  verdict: string
  rationale: string
  evidenceList: string[]
  onVerdictChange: (verdict: string) => void
  onRationaleChange: (rationale: string) => void
  onEvidenceUpdate: (evidence: string[]) => void
  onSubmit: () => void
}
```
- Handles dispute resolution workflow
- Supports multi-stage escalation process
- Manages evidence linking with blockchain hashes

### FinanceDashboard.tsx
```tsx
interface Props {
  earnings: {
    totalXP: number
    monthlyXP: number
    earningsICP: number
    earningsUSD: number
    paymentHistory: Array<{
      date: string
      amountICP: number
      amountUSD: number
    }>
  }
}
```
- Displays ICP/XPI earnings
- Payment goal tracking with progress visualization
- Withdrawal functionality integration

### ReputationBadge.tsx
```tsx
interface ReputationBadgeProps {
  xp: number
  rank: 'Trainee' | 'Junior' | 'Associate' | 'Senior' | 'Expert' | 'Master'
  badges: string[]
  warnings?: string[]
  penalties?: string[]
}
```
- Visualizes user reputation status
- Dynamic rank coloring system
- Displays earned badges and penalties

## Services Overview

### escalation.ts
```ts
interface EscalatedClaim {
  claimId: string
  initialFindings: Array<{
    aletheianId: Principal
    verdict: string
    explanation: string
    evidence: string[]
  }>
  status: 'seniorReview' | 'councilReview' | { resolved: string }
}

Key Functions:
- submitSeniorFinding(): Handle senior-level verdicts
- submitCouncilFinding(): Council-level resolution
- checkEscalationEligibility(): Rank-based access control
```

## Usage Examples

### Submitting a Claim (ClaimForm.tsx)
```tsx
<ClaimForm
  onSubmit={async (data) => {
    await canister.submitClaim({
      claim: data.claim,
      evidence: data.evidenceLinks,
      media: data.files
    })
  }}
/>
```

### Displaying Results (FactCheckResult.tsx)
```tsx
<FactCheckResult 
  result={{
    id: "claim-123",
    claim: "COVID-19 vaccine contains microchips",
    verdict: "FALSE",
    summary: "No evidence of microchip technology...",
    evidence: [{
      source: "WHO Report",
      url: "https://who.int/...",
      content: "Official denial of microchip claims..."
    }]
  }}
/>
```

## Verification Workflow (ClaimVerificationPage.tsx)
1. Claim prioritization queue
2. AI-powered duplicate detection
3. Evidence collection interface
4. Multi-tiered verification process
5. Final verdict submission
