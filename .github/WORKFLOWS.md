# CI/CD Workflows Documentation

This document describes the GitHub Actions workflows configured for the nexus repository, aligned with the LexAmoris ecosystem standards.

## Overview

The nexus repository uses automated CI/CD pipelines to ensure code quality, security, and seamless integration with the broader LexAmoris ecosystem.

## Workflows

### 1. Sync README_PARTNERS (`.github/workflows/sync-readme-partners.yml`)

**Purpose:** Synchronizes partner information from the common-core repository to maintain consistency across the ecosystem.

**Triggers:**
- Manual dispatch (`workflow_dispatch`)
- Daily schedule at 00:00 UTC
- Repository dispatch event `readme-partners-updated` from common-core repo

**Actions:**
- Fetches the latest `README_PARTNERS.md` from the common-core repository
- Compares with the local version
- Commits and pushes changes if different

**Usage:**
To manually trigger: Go to Actions → Sync README_PARTNERS → Run workflow

### 2. Common Core Resources Update (`.github/workflows/common-core-trigger.yml`)

**Purpose:** Automatically rebuilds and deploys nexus when the common-core resources repository is updated.

**Triggers:**
- Repository dispatch event `common-core-updated` from common-core repo
- Manual dispatch with optional common-core ref/tag input

**Actions:**
- Fetches latest common-core resources
- Installs dependencies
- Builds the project
- Runs tests
- Deploys updates

**Usage:**
To manually trigger: Go to Actions → Common Core Resources Update → Run workflow

### 3. Lint and Test (`.github/workflows/lint-and-test.yml`)

**Purpose:** Ensures code quality and correctness through linting and testing.

**Triggers:**
- Push to main, develop, or copilot/** branches
- Pull requests to main or develop branches
- Manual dispatch

**Jobs:**

#### Lint
- JavaScript/TypeScript linting (if lint script exists)
- Markdown checking with markdownlint
- Solidity contract linting (if contracts exist)
- Shell script checking with shellcheck

#### Test
- Unit tests execution
- Smart contract tests (if Hardhat configured)
- Coverage report generation
- Upload to Codecov (if coverage available)

#### Security Scan
- npm audit for dependency vulnerabilities
- Trivy vulnerability scanner
- Upload results to GitHub Security tab

**Usage:**
Runs automatically on push/PR. To run manually: Go to Actions → Lint and Test → Run workflow

### 4. Build and Deploy (`.github/workflows/build-and-deploy.yml`)

**Purpose:** Builds the project and deploys to staging or production environments.

**Triggers:**
- Push to main branch
- Version tags (v*)
- Manual dispatch with environment selection

**Jobs:**

#### Build
- Installs dependencies
- Builds dashboard (if exists)
- Builds main project
- Creates deployment archive
- Uploads build artifacts

#### Deploy to Staging
- Runs on main branch pushes or manual staging selection
- Downloads build artifacts
- Deploys to staging environment
- Verifies deployment

#### Deploy to Production
- Runs on version tags or manual production selection
- Downloads build artifacts
- Deploys to production environment
- Creates GitHub release (for tags)
- Verifies deployment

**Usage:**
- Automatic deployment on push to main (staging)
- Tag a version for production: `git tag v1.0.0 && git push origin v1.0.0`
- Manual: Go to Actions → Build and Deploy → Run workflow → Select environment

### 5. CodeQL Security Analysis (`.github/workflows/codeql-analysis.yml`)

**Purpose:** Performs advanced security analysis using GitHub's CodeQL engine.

**Triggers:**
- Push to main or develop branches
- Pull requests to main or develop branches
- Weekly schedule (Monday 00:00 UTC)
- Manual dispatch

**Actions:**
- Initializes CodeQL with security-extended queries
- Automatically builds the codebase
- Performs security and quality analysis
- Uploads results to GitHub Security tab

**Usage:**
Runs automatically. View results in: Security → Code scanning alerts

### 6. Dependency Updates (`.github/workflows/dependency-updates.yml`)

**Purpose:** Keeps dependencies up-to-date and applies security patches.

**Triggers:**
- Weekly schedule (Sunday 00:00 UTC)
- Manual dispatch

**Jobs:**

#### Update Dependencies
- Updates npm packages respecting semver
- Applies security patches via npm audit fix
- Creates a pull request with changes

#### Check Outdated
- Lists outdated packages
- Runs security audit

**Usage:**
Runs automatically weekly. Check for automated PRs labeled `dependencies` and `automated`.

### 7. Documentation (`.github/workflows/documentation.yml`)

**Purpose:** Validates and builds documentation.

**Triggers:**
- Push to main affecting docs/** or *.md files
- Pull requests affecting documentation
- Manual dispatch

**Jobs:**

#### Validate Docs
- Checks markdown links
- Validates documentation structure
- Checks for broken references

#### Build Docs
- Generates documentation site
- Creates index page
- Uploads documentation artifacts

**Usage:**
Runs automatically on documentation changes. View artifacts in Actions run details.

## Configuration Files

### `.markdownlint.json`

Configures markdown linting rules to ensure consistent documentation formatting:
- Line length: 120 characters
- HTML allowed
- Ordered list style
- First line heading rule disabled

### `.github/markdown-link-check-config.json`

Configures link checking behavior:
- Ignores localhost links
- Retries on 429 errors
- 20-second timeout
- Accepts 200 and 206 status codes

## Integration with LexAmoris Ecosystem

### Common-Core Repository

The nexus repository integrates with the common-core repository through:

1. **Resource Synchronization:** Shared configurations and resources are fetched automatically
2. **Partner Information:** README_PARTNERS.md is synced daily
3. **Build Triggers:** Updates in common-core trigger rebuilds in nexus

### Setting Up Repository Dispatch

For the common-core repository to trigger workflows in nexus:

1. In common-core, add a workflow step:
```yaml
- name: Trigger nexus update
  uses: peter-evans/repository-dispatch@v2
  with:
    token: ${{ secrets.REPO_DISPATCH_TOKEN }}
    repository: hannesmitterer/nexus
    event-type: common-core-updated
```

2. For README_PARTNERS sync:
```yaml
- name: Trigger README_PARTNERS sync
  uses: peter-evans/repository-dispatch@v2
  with:
    token: ${{ secrets.REPO_DISPATCH_TOKEN }}
    repository: hannesmitterer/nexus
    event-type: readme-partners-updated
```

## Best Practices

1. **Always run tests locally before pushing:** Use `npm test` and `npm run lint`
2. **Keep dependencies updated:** Review and merge automated dependency update PRs
3. **Address security alerts promptly:** Check Security tab regularly
4. **Use semantic versioning for releases:** Follow v{major}.{minor}.{patch} format
5. **Document changes:** Update relevant .md files with code changes
6. **Review workflow runs:** Check Actions tab for failures and warnings

## Troubleshooting

### Workflow Failures

1. **Check workflow logs:** Go to Actions → Select failed run → View logs
2. **Common issues:**
   - Missing secrets: Add required secrets in repository settings
   - Permission errors: Ensure GITHUB_TOKEN has necessary permissions
   - Build failures: Check dependency versions and build scripts

### Security Alerts

1. **CodeQL alerts:** Review in Security → Code scanning alerts
2. **Dependency vulnerabilities:** Review in Security → Dependabot alerts
3. **Trivy findings:** Check workflow run artifacts

### Manual Intervention

Some workflows support manual triggering:
1. Go to Actions tab
2. Select the workflow
3. Click "Run workflow"
4. Fill in any required inputs
5. Click "Run workflow" button

## Continuous Improvement

The workflows are designed to evolve with the project. Contributions to improve CI/CD processes are welcome:

1. Test workflow changes in a fork first
2. Document any new workflows or changes
3. Ensure backward compatibility
4. Update this documentation

---

*Document Version: 1.0*  
*Last Updated: 2026-01-13*  
*Maintained by: LexAmoris Ecosystem Team*
