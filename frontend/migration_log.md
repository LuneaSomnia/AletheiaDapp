# Mock Scaffold Migration Log

## Migration Date: 2025-08-18

### Affected UI Frontends:
1. aletheian_interface
2. user_interface

### Changes Applied:
- Created shared mock handlers in /shared-mocks
- Added user_interface mock scaffold
- Updated both UIs to use shared handlers
- Added UI-specific fixtures
- Configured cross-UI header-based routing
- Updated package.json scripts for mock mode
- Added environment configuration

### Known Issues:
- Web3 auth flow needs integration
- Ledger API mocks need blockchain hashes
- TODO: Confirm claim submission payload format with backend
- TODO: Verify x-ui header handling in production

### Backup Locations:
- Backups created in each UI's .migrated_backup_20250818 folder
