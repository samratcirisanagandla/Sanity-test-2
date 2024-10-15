#!/bin/bash

SERVICE_CODE="mobius-utility-service"
K8_REPO_ACCESS_SECRET="$K8_REPO_ACCESS_SECRET"
REPO_URL="https://api.github.com/repos/gaiangroup/k8s-files-master/contents/helm/"
K8S_FILES_PATH="helm/$SERVICE_CODE/values.yaml"
BACKUP_FILE="values_backup.yaml"
RESULT_FILE="/tmp/revert_script_result.json"

# Function to exit with an error message
function exit_with_error() {
    echo "ERROR: $1"
    echo "{\"status\":\"failure\",\"message\":\"$1\"}" > $RESULT_FILE
    exit 1
}

# Ensure the K8_REPO_ACCESS_SECRET is set
if [ -z "$K8_REPO_ACCESS_SECRET" ]; then
    exit_with_error "K8_REPO_ACCESS_SECRET is not set."
fi

# Revert the code to the previous commit
echo "Reverting code to the previous commit..."
git fetch --all || exit_with_error "Failed to fetch changes."
git reset --hard HEAD~1 || exit_with_error "Failed to reset repository."
git push --force || exit_with_error "Failed to push the reverted commit."

# Check if the backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    exit_with_error "Backup file not found."
fi

# Restore values.yaml from backup
SHA=$(curl -s -H "Authorization: Bearer $K8_REPO_ACCESS_SECRET" \
              -H "Accept: application/vnd.github.v3+json" \
              "$REPO_URL/$K8S_FILES_PATH?ref=prod" | jq -r .sha)

if [ -z "$SHA" ]; then
    exit_with_error "Failed to fetch SHA."
fi

NEW_CONTENT=$(base64 -w 0 "$BACKUP_FILE")
if [ -z "$NEW_CONTENT" ]; then
    exit_with_error "Failed to encode the backup file."
fi

UPDATE_RESPONSE=$(curl -s -X PUT \
  -H "Authorization: Bearer $K8_REPO_ACCESS_SECRET" \
  -H "Content-Type: application/json" \
  "$REPO_URL/$K8S_FILES_PATH" \
  -d "{\"message\": \"Reverting values.yaml\", \"content\": \"$NEW_CONTENT\", \"sha\": \"$SHA\", \"branch\": \"prod\"}")

if echo "$UPDATE_RESPONSE" | grep -q '"commit"'; then
    echo "{\"status\":\"success\",\"message\":\"Successfully reverted values.yaml\"}" > $RESULT_FILE
else
    exit_with_error "Failed to update values.yaml."
fi
