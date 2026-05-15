#!/usr/bin/env zsh
# =============================================================
# LegitApp Release Script
# Usage: ./release.sh <version> <dmg_path>
# Example: ./release.sh 1.0.1 ~/Desktop/LegitApp.dmg
# =============================================================
set -euo pipefail

# Find sign_update path dynamically
SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -name sign_update -path "*/Sparkle/bin/sign_update" | head -n 1)

if [[ -z "$SIGN_UPDATE" ]]; then
  echo "❌ Could not find sign_update utility in DerivedData."
  exit 1
fi

APPCAST="docs/appcast.xml"
REPO="sondecode/legitapp"

# --- Validate args ---
if [[ $# -lt 2 ]]; then
  echo "❌ Usage: ./release.sh <version> <path_to_dmg>"
  echo "   Example: ./release.sh 1.0.1 ~/Desktop/LegitApp.dmg"
  exit 1
fi

VERSION="$1"
DMG_PATH="${2:A}"  # resolve absolute path

if [[ ! -f "$DMG_PATH" ]]; then
  echo "❌ DMG not found: $DMG_PATH"
  exit 1
fi

echo "🚀 Releasing LegitApp v${VERSION}"
echo "   DMG: $DMG_PATH"
echo ""

# --- Step 1: Sign DMG ---
echo "🔏 Signing DMG..."
SIGN_OUTPUT=$("$SIGN_UPDATE" "$DMG_PATH")
echo "$SIGN_OUTPUT"

# Extract edSignature from output (handles both JSON and key=value formats)
if echo "$SIGN_OUTPUT" | grep -q '"edSignature":'; then
  ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep -o '"edSignature": "[^"]*"' | cut -d'"' -f4)
else
  ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
fi

if [[ -z "$ED_SIGNATURE" ]]; then
  echo "❌ Could not extract edSignature from sign_update output"
  exit 1
fi
echo "✅ edSignature: $ED_SIGNATURE"
echo ""

# --- Step 2: Get DMG file size ---
DMG_SIZE=$(stat -f%z "$DMG_PATH")
echo "📦 DMG size: $DMG_SIZE bytes"

# --- Step 3: Get current date in RFC 2822 format ---
PUB_DATE=$(date -R)

# --- Step 4: Build number (integer for sparkle:version) ---
BUILD_NUMBER=$(echo "$VERSION" | tr -d '.' | sed 's/^0*//')

# --- Step 5: Update appcast.xml ---
echo ""
echo "📝 Updating $APPCAST..."

# Generate new item XML
NEW_ITEM=$(cat <<EOF
    <item>
      <title>${VERSION}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:version>${BUILD_NUMBER}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>
        https://github.com/${REPO}/releases/tag/v${VERSION}
      </sparkle:releaseNotesLink>
      <description><![CDATA[
        <h2>LegitApp ${VERSION}</h2>
        <p>Xem chi tiết tại: https://github.com/${REPO}/releases/tag/v${VERSION}</p>
      ]]></description>
      <enclosure
        url="https://github.com/${REPO}/releases/download/v${VERSION}/LegitApp.dmg"
        length="${DMG_SIZE}"
        type="application/octet-stream"
        sparkle:edSignature="${ED_SIGNATURE}" />
    </item>
EOF
)

# Insert new item after opening <channel> section header comments (before existing first <item>)
python3 - "$APPCAST" "$NEW_ITEM" <<'PYEOF'
import sys, re

appcast_path = sys.argv[1]
new_item = sys.argv[2]

with open(appcast_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Insert new item before the first existing <item>
updated = re.sub(r'(\s*<item>)', '\n' + new_item + r'\1', content, count=1)

with open(appcast_path, 'w', encoding='utf-8') as f:
    f.write(updated)

print("appcast.xml updated.")
PYEOF

echo "✅ $APPCAST updated"
echo ""

# --- Step 6: Commit & push ---
echo "📤 Committing and pushing..."
git add "$APPCAST"
git commit -m "chore: release v${VERSION}"
git tag "v${VERSION}"
git push origin main
git push origin "v${VERSION}"
echo "✅ Pushed to GitHub"
echo ""

# --- Step 7: Upload DMG to GitHub Release ---
echo "🎁 Creating GitHub Release..."
if command -v gh &>/dev/null; then
  gh release create "v${VERSION}" "$DMG_PATH" \
    --repo "$REPO" \
    --title "LegitApp v${VERSION}" \
    --notes "Xem thay đổi tại: https://github.com/${REPO}/releases/tag/v${VERSION}"
  echo "✅ GitHub Release created: https://github.com/${REPO}/releases/tag/v${VERSION}"
else
  echo "⚠️  GitHub CLI (gh) chưa được cài. Tải thủ công:"
  echo "   1. Vào https://github.com/${REPO}/releases/new"
  echo "   2. Tag: v${VERSION}"
  echo "   3. Upload file: $DMG_PATH"
fi

echo ""
echo "🎉 Release v${VERSION} hoàn tất!"
echo "   App sẽ nhận cập nhật tự động qua Sparkle trong vài phút."
