#!/bin/bash

# CONFIGURATION
REPO_URL="https://github.com/Varun9650/sample.git"
REPO_DIR="/z/Work (Y)/RealITSolutions/sample"  # ⚠️ Update this if needed
DEPLOY_DIR="/var/www/html"
REMOTE_USER="root"
REMOTE_HOST="157.66.191.31"
LAST_COMMIT_FILE=".last_deployed_commit"

# Function to install rsync if not installed
install_rsync_if_missing() {
    if ! command -v rsync &> /dev/null; then
        echo "⚠️  'rsync' not found. Installing..."
        if command -v pacman &> /dev/null; then
            pacman -Sy --noconfirm rsync
            echo "✅ 'rsync' installed successfully."
        else
            echo "❌ 'pacman' not found. Please install rsync manually."
            exit 1
        fi
    else
        echo "✅ 'rsync' is already installed."
    fi
}

# Check and install rsync if missing
install_rsync_if_missing

# Ensure repo exists locally
if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR" || exit 1

# Pull latest changes
git pull origin main

# Determine commit range
if [ -f "$LAST_COMMIT_FILE" ]; then
    LAST_COMMIT=$(cat "$LAST_COMMIT_FILE")
else
    echo "No last commit file found, deploying all tracked files."
    LAST_COMMIT=$(git rev-list --max-parents=0 HEAD)
fi

LATEST_COMMIT=$(git rev-parse HEAD)
echo "Deploying changes from $LAST_COMMIT to $LATEST_COMMIT"

# List changed files
CHANGED_FILES=$(git diff --name-only "$LAST_COMMIT" "$LATEST_COMMIT")
if [ -z "$CHANGED_FILES" ]; then
    echo "No changes to deploy."
    exit 0
fi

# Temp folder to stage changes
TEMP_DEPLOY_DIR="/tmp/deploy-changes"
rm -rf "$TEMP_DEPLOY_DIR"
mkdir -p "$TEMP_DEPLOY_DIR"

# Copy changed files while preserving structure
for file in $CHANGED_FILES; do
    if [ -f "$file" ]; then
        mkdir -p "$TEMP_DEPLOY_DIR/$(dirname "$file")"
        cp "$file" "$TEMP_DEPLOY_DIR/$file"
    fi
done

# Deploy to remote server (overwrite files in place)
rsync -avz -e ssh "$TEMP_DEPLOY_DIR/" "$REMOTE_USER@$REMOTE_HOST:$DEPLOY_DIR"

# Save last deployed commit
echo "$LATEST_COMMIT" > "$LAST_COMMIT_FILE"

echo "✅ Deployment completed from $LAST_COMMIT to $LATEST_COMMIT."

