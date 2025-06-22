#!/bin/bash
set -e

# Install Windmill CLI
WMILL_VERSION="v1.123.0"
curl -L "https://github.com/windmill-labs/windmill/releases/download/${WMILL_VERSION}/wmill-linux-amd64" -o /usr/local/bin/wmill
chmod +x /usr/local/bin/wmill

# Setup credentials
mkdir -p ~/.windmill
echo "{\"token\": \"${WINDMILL_TOKEN}\"}" > ~/.windmill/credentials.json

# Detect workspaces
WORKSPACES=()
if [ -f windmill/workspaces.json ]; then
  WORKSPACES=($(jq -r '.workspaces[]' windmill/workspaces.json))
else
  WORKSPACES=($(ls windmill | grep -v wmill.yaml))
fi

for WS in "${WORKSPACES[@]}"; do
  echo "Syncing workspace: $WS"
  cd windmill/$WS

  # Pull from Windmill
  wmill sync pull --workspace "$WS" || { echo "Pull failed for $WS"; exit 1; }

  # Check for changes
  if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "🔁 Sync from Windmill [$WS] at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  fi

  # Push to Windmill
  wmill sync push --workspace "$WS" || { echo "Push failed for $WS"; exit 1; }

  cd ../..
done
