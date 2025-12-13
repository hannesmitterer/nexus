#!/bin/bash

# Quick Document Verification Script
# Provides fast SHA-256 verification for strategic documents

set -e

DOCS_DIR="./docs/strategic"
DOCUMENT="$DOCS_DIR/GPT-OSS-120B-Rapporto-di-Convergenza-Strategica-2026.md"
METADATA="$DOCS_DIR/metadata.json"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📜 Quick Document Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if files exist
if [ ! -f "$DOCUMENT" ]; then
    echo "❌ Error: Document not found at $DOCUMENT"
    exit 1
fi

if [ ! -f "$METADATA" ]; then
    echo "❌ Error: Metadata not found at $METADATA"
    exit 1
fi

# Extract expected hash from metadata
if command -v jq &> /dev/null; then
    EXPECTED_HASH=$(jq -r '.integrity.sha256' "$METADATA")
    DOC_TITLE=$(jq -r '.document.title' "$METADATA")
    DOC_VERSION=$(jq -r '.document.version' "$METADATA")
    IPFS_CID=$(jq -r '.ipfs.cid' "$METADATA")
else
    # Fallback without jq
    EXPECTED_HASH=$(grep -A 1 '"sha256"' "$METADATA" | tail -1 | sed 's/.*: "\(.*\)".*/\1/')
    DOC_TITLE="GPT-OSS 120B Rapporto di Convergenza Strategica (2026+)"
    DOC_VERSION="1.0.0"
    IPFS_CID="bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku"
fi

echo "Document: $DOC_TITLE"
echo "Version: $DOC_VERSION"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Calculate actual hash
echo "🔄 Calculating SHA-256 hash..."
ACTUAL_HASH=$(sha256sum "$DOCUMENT" | awk '{print $1}')

echo ""
echo "Expected Hash:"
echo "  $EXPECTED_HASH"
echo ""
echo "Calculated Hash:"
echo "  $ACTUAL_HASH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Compare hashes
if [ "$ACTUAL_HASH" = "$EXPECTED_HASH" ]; then
    echo "✅ VERIFICATION SUCCESSFUL"
    echo ""
    echo "   Document integrity confirmed!"
    echo "   The document matches the officially signed version."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 IPFS Archive:"
    echo "   CID: $IPFS_CID"
    echo "   Gateway: https://ipfs.io/ipfs/$IPFS_CID"
    echo ""
    exit 0
else
    echo "❌ VERIFICATION FAILED"
    echo ""
    echo "   WARNING: Document integrity compromised!"
    echo "   The hashes do not match."
    echo "   Please retrieve the official version from IPFS."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 Retrieve from IPFS:"
    echo "   https://ipfs.io/ipfs/$IPFS_CID"
    echo ""
    exit 1
fi
