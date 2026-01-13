# Setting Up Inter-Repository Integration

This guide explains how to configure the LexAmoris common-core repository to trigger workflows in the nexus repository.

## Prerequisites

1. Admin access to both repositories (nexus and common-core)
2. GitHub Personal Access Token (PAT) with `repo` scope

## Step 1: Create GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name: "LexAmoris Repository Dispatch"
4. Select scopes:
   - ✓ `repo` (Full control of private repositories)
5. Click "Generate token"
6. **Copy the token** (you won't be able to see it again)

## Step 2: Add Token as Secret in Common-Core Repository

1. Go to the common-core repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `REPO_DISPATCH_TOKEN`
5. Value: Paste the token from Step 1
6. Click "Add secret"

## Step 3: Add Dispatch Triggers to Common-Core Workflows

### For README_PARTNERS.md Synchronization

Add this step to any workflow in the common-core repository that updates `README_PARTNERS.md`:

```yaml
name: Update README_PARTNERS

on:
  push:
    paths:
      - 'README_PARTNERS.md'
  workflow_dispatch:

jobs:
  sync-to-nexus:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout common-core
        uses: actions/checkout@v4
      
      # Your steps to update README_PARTNERS.md
      
      - name: Trigger nexus sync
        uses: peter-evans/repository-dispatch@v2
        with:
          token: ${{ secrets.REPO_DISPATCH_TOKEN }}
          repository: hannesmitterer/nexus
          event-type: readme-partners-updated
```

### For Common-Core Resource Updates

Add this step to any workflow that updates shared resources:

```yaml
name: Update Shared Resources

on:
  push:
    branches: [ main ]
    paths:
      - 'shared-config.json'
      - 'resources/**'
  workflow_dispatch:

jobs:
  update-ecosystem:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout common-core
        uses: actions/checkout@v4
      
      # Your steps to update shared resources
      
      - name: Trigger nexus rebuild
        uses: peter-evans/repository-dispatch@v2
        with:
          token: ${{ secrets.REPO_DISPATCH_TOKEN }}
          repository: hannesmitterer/nexus
          event-type: common-core-updated
          client-payload: |
            {
              "ref": "${{ github.ref }}",
              "sha": "${{ github.sha }}",
              "updated_files": ["shared-config.json"]
            }
```

## Step 4: Test the Integration

### Manual Test

1. In the nexus repository, go to Actions tab
2. Select "Sync README_PARTNERS" workflow
3. Click "Run workflow"
4. Check that it runs successfully

### Automated Test

1. In the common-core repository, update `README_PARTNERS.md`
2. Commit and push the change
3. Check that the workflow triggers in common-core
4. Verify that the nexus repository receives the dispatch event
5. Confirm that nexus's "Sync README_PARTNERS" workflow runs

## Step 5: Monitor Workflow Runs

### In Common-Core Repository

Check that the repository dispatch action completes successfully:
- Go to Actions tab
- Look for the workflow that triggers the dispatch
- Verify the "Trigger nexus" step shows success

### In Nexus Repository

Check that the triggered workflow runs:
- Go to Actions tab
- Look for workflow runs triggered by `repository_dispatch`
- Review logs for any errors

## Troubleshooting

### Issue: Workflow not triggering in nexus

**Possible causes:**
1. Token doesn't have correct permissions
   - Solution: Regenerate token with `repo` scope
2. Repository name is incorrect
   - Solution: Verify it's exactly `hannesmitterer/nexus`
3. Event type mismatch
   - Solution: Check event-type matches workflow trigger exactly

### Issue: Permission denied errors

**Possible causes:**
1. Token expired or revoked
   - Solution: Generate new token and update secret
2. Repository is private and token lacks access
   - Solution: Ensure token has access to private repos

### Issue: Workflow runs but fails

**Possible causes:**
1. Missing dependencies in nexus
   - Solution: Check workflow logs for specific errors
2. Common-core resources not accessible
   - Solution: Verify resource URLs and permissions

## Security Best Practices

1. **Use fine-grained tokens** when available for better security
2. **Rotate tokens periodically** (every 90 days recommended)
3. **Limit token scope** to only what's needed
4. **Use separate tokens** for different integrations
5. **Monitor token usage** in GitHub audit logs
6. **Revoke tokens** immediately if compromised

## Advanced Configuration

### Conditional Triggering

Only trigger nexus update for specific files:

```yaml
- name: Check changed files
  id: changes
  uses: dorny/paths-filter@v2
  with:
    filters: |
      critical:
        - 'shared-config.json'
        - 'resources/critical/**'

- name: Trigger nexus rebuild
  if: steps.changes.outputs.critical == 'true'
  uses: peter-evans/repository-dispatch@v2
  with:
    token: ${{ secrets.REPO_DISPATCH_TOKEN }}
    repository: hannesmitterer/nexus
    event-type: common-core-updated
```

### Multiple Target Repositories

Trigger updates in multiple repositories:

```yaml
- name: Trigger updates across ecosystem
  run: |
    repos=("hannesmitterer/nexus" "LexAmoris/another-repo")
    for repo in "${repos[@]}"; do
      curl -X POST \
        -H "Authorization: token ${{ secrets.REPO_DISPATCH_TOKEN }}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$repo/dispatches" \
        -d '{"event_type":"common-core-updated"}'
    done
```

## Verification Checklist

- [ ] PAT created with correct scopes
- [ ] Secret added to common-core repository
- [ ] Dispatch triggers added to common-core workflows
- [ ] Manual test successful
- [ ] Automated trigger test successful
- [ ] Error handling tested
- [ ] Documentation updated
- [ ] Team members notified of new integration

## Support

For issues with the integration:
1. Check workflow logs in both repositories
2. Review this documentation
3. Consult `.github/WORKFLOWS.md` in nexus repository
4. Contact the LexAmoris ecosystem team

---

*Document Version: 1.0*  
*Last Updated: 2026-01-13*  
*Maintained by: LexAmoris Ecosystem Team*
