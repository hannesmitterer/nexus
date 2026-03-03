# CI/CD Workflows Quick Reference

## Manual Workflow Triggers

Access: GitHub repository → Actions tab → Select workflow → "Run workflow"

### 1. Sync README_PARTNERS
**When to use:** Force sync partner information from common-core
```
Actions → Sync README_PARTNERS → Run workflow
```

### 2. Common Core Resources Update  
**When to use:** Force rebuild after common-core changes
```
Actions → Common Core Resources Update → Run workflow
Optional: Specify common-core ref/tag
```

### 3. Lint and Test
**When to use:** Run linting and tests manually
```
Actions → Lint and Test → Run workflow
```

### 4. Build and Deploy
**When to use:** Deploy to staging or production manually
```
Actions → Build and Deploy → Run workflow
Choose environment: staging or production
```

### 5. CodeQL Security Analysis
**When to use:** Run security analysis on-demand
```
Actions → CodeQL Security Analysis → Run workflow
```

### 6. Dependency Updates
**When to use:** Force dependency update check
```
Actions → Dependency Updates → Run workflow
```

### 7. Documentation
**When to use:** Validate and build documentation
```
Actions → Documentation → Run workflow
```

## Common Tasks

### Deploy to Production
1. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. Build and Deploy workflow triggers automatically
3. Check Actions tab for progress

### Update Dependencies
1. Wait for automated weekly PR (Sunday)
2. Review changes in the PR
3. Merge if tests pass

### Fix Security Issues
1. Check Security tab → Code scanning alerts
2. Review and fix reported issues
3. Push changes
4. Verify fix in next scan

### Sync with Common-Core
1. Common-core updates trigger automatically via repository_dispatch
2. Manual sync: Actions → Sync README_PARTNERS → Run workflow
3. Check workflow logs for results

## Workflow Status Indicators

✅ **Success** - All checks passed
⚠️ **Warning** - Non-critical issues found  
❌ **Failure** - Critical issues, needs attention
⏳ **In Progress** - Workflow running

## Quick Troubleshooting

### Workflow Failed
1. Click on failed workflow run
2. Expand failed step
3. Read error message
4. Fix issue and push

### Tests Failing
1. Run locally: `npm test`
2. Fix failing tests
3. Commit and push
4. Workflow re-runs automatically

### Deployment Failed
1. Check deployment logs
2. Verify environment configuration
3. Check secrets/variables
4. Re-run workflow

## File Locations

- **Workflows:** `.github/workflows/*.yml`
- **Config:** `.markdownlint.json`, `.github/markdown-link-check-config.json`
- **Docs:** `.github/WORKFLOWS.md`, `.github/INTEGRATION_SETUP.md`

## Need Help?

1. Check `.github/WORKFLOWS.md` for detailed documentation
2. Check `.github/INTEGRATION_SETUP.md` for setup instructions
3. Check `.github/IMPLEMENTATION_SUMMARY.md` for overview
4. Review workflow logs in Actions tab
5. Contact LexAmoris ecosystem team

---
*Quick Reference v1.0 - Last Updated: 2026-01-13*
