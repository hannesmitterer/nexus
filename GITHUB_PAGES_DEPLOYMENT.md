# GitHub Pages Deployment Guide

This repository is configured to automatically deploy to GitHub Pages.

## Setup Instructions

### 1. Enable GitHub Pages in Repository Settings

1. Go to your repository on GitHub
2. Click on **Settings** → **Pages**
3. Under **Source**, select **GitHub Actions**

### 2. Automatic Deployment

The deployment happens automatically:
- **On every push to `main` branch**: The site will be automatically rebuilt and deployed
- **Manual deployment**: You can trigger a manual deployment from the Actions tab

### 3. Accessing Your Site

Once deployed, your site will be available at:
```
https://hannesmitterer.github.io/nexus/
```

## Available Pages

The repository includes several HTML pages:

- **index.html** - Main Nexus Kosymbiosis Live interface
- **lexamoris.html** - Lex Amoris resonance tracking interface
- **QuantumInterface.html** - Quantum interface dashboard
- **apollo-nexus.html** - Apollo Nexus interface
- **dashboard/** - Additional dashboard components

## Deployment Workflow

The deployment is handled by `.github/workflows/deploy-pages.yml` which:
1. Checks out the repository
2. Configures GitHub Pages
3. Uploads all files as a Pages artifact
4. Deploys to GitHub Pages

## Local Testing

To test the site locally before deployment:

```bash
# Using Python's built-in HTTP server
python3 -m http.server 8080

# Then visit http://localhost:8080 in your browser
```

## Troubleshooting

- **404 Error**: Make sure GitHub Pages is enabled in repository settings with "GitHub Actions" as the source
- **Deployment Failed**: Check the Actions tab for error logs
- **Changes Not Showing**: GitHub Pages may take a few minutes to update after deployment

## Notes

- All files in the repository root are deployed to GitHub Pages
- The workflow requires the `pages: write` and `id-token: write` permissions
- The deployment uses the latest GitHub Actions for Pages deployment
