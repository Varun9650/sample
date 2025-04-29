#!/bin/bash
# CONFIGURATION
REPO_URL="https://github.com/Varun9650/sample.git"  # ✅ Your updated GitHub repo
REPO_DIR="/root/sample/sample"                     # Local temp directory
DEPLOY_DIR="/var/www/html"                    # ✅ Destination on remote server (change if needed)
REMOTE_USER="root"                                   # ✅ Assuming you use root
REMOTE_HOST="157.66.191.31"                          # ✅ Your server IP
LAST_COMMIT_FILE=".last_deployed_commit"



# Ensure repo exists locally
if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR" || exit 1
# Pull the latest code
git pull origin main
# Get last deployed commit hash
if [ -f "$LAST_COMMIT_FILE" ]; then
    LAST_COMMIT=$(cat "$LAST_COMMIT_FILE")
else
    echo "No last commit file found, deploying all tracked files."
    LAST_COMMIT=$(git rev-list --max-parents=0 HEAD)
fi
# Get latest commit
LATEST_COMMIT=$(git rev-parse HEAD)
echo "Deploying changes from $LAST_COMMIT to $LATEST_COMMIT"
# Get changed files between commits
CHANGED_FILES=$(git diff --name-only "$LAST_COMMIT" "$LATEST_COMMIT")
if [ -z "$CHANGED_FILES" ]; then
    echo "No changes to deploy."
    exit 0
fi
# Create temporary folder to store changed files
TEMP_DEPLOY_DIR="/tmp/deploy-changes"
rm -rf "$TEMP_DEPLOY_DIR"
mkdir -p "$TEMP_DEPLOY_DIR"
# Copy changed files to temp folder
for file in $CHANGED_FILES; do
    if [ -f "$file" ]; then
        mkdir -p "$TEMP_DEPLOY_DIR/$(dirname "$file")"
        cp "$file" "$TEMP_DEPLOY_DIR/$file"
    fi
done
# Rsync changed files to remote server
#sshpass -p 'welcome2ris' rsync -avz -e "ssh -o StrictHostKeyChecking=no" "$TEMP_DEPLOY_DIR/" "$REMOTE_USER@$REMOTE_HOST:$DEPLOY_DIR"
sshpass -p 'welcome2ris' rsync -avz -e "ssh -o StrictHostKeyChecking=no" "$TEMP_DEPLOY_DIR/" "$REMOTE_USER@$REMOTE_HOST:$DEPLOY_DIR"

#sshpass -p 'welcome2ris' ssh -o StrictHostKeyChecking=no root@157.66.191.31

#rsync -avz -e ssh "$TEMP_DEPLOY_DIR/" "$REMOTE_USER@$REMOTE_HOST:$DEPLOY_DIR"
#scp -r "$TEMP_DEPLOY_DIR/" "$REMOTE_USER@$REMOTE_HOST:$DEPLOY_DIR"

# Save the new deployed commit hash
echo "$LATEST_COMMIT" > "$LAST_COMMIT_FILE"
echo ":white_tick: Deployment completed from $LAST_COMMIT to $LATEST_COMMIT."
