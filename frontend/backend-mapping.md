# Backend Canister to REST Endpoint Mapping

## auth (User Authentication)
- `authenticate` → POST /api/auth/login
- `logout` → POST /api/auth/logout  
- `refreshProfile` → GET /api/auth/me
- `updateProfile` → PUT /api/users/{id}

## claims (Claim Submission)
- `submitClaim` → POST /api/claims
- `getClaim` → GET /api/claims/{id}
- `listClaims` → GET /api/claims

## finance (Earnings & Payments)
- `getEarnings` → GET /api/finance
- `withdrawFunds` → POST /api/finance/withdrawals
- `getPaymentHistory` → GET /api/finance/history

## aletheian (Verification)
- `getVerificationQueue` → GET /api/aletheian/queue
- `submitVerification` → POST /api/aletheian/claims/{id}/verify
- `getProgress` → GET /api/aletheian/progress

## ledger (Fact Ledger)
- `getLedgerEntries` → GET /api/ledger
- `getLedgerEntry` → GET /api/ledger/{claimId}

## notifications
- `getNotifications` → GET /api/notifications
- `markRead` → POST /api/notifications/mark-read

TODO:
- Confirm exact parameter types for verification submission
- Validate pagination parameters for list endpoints
- Verify web3 auth flow details
