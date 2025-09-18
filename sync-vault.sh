#!/data/data/com.termux/files/usr/bin/env bash

# --- CONFIGURATION ---
# Set the full path to your Obsidian vault here
VAULT_PATH="~/storage/documents/obsidian/THEMIND"
# Set your primary branch name here (usually "main" or "master")
BRANCH_NAME="main"
# --- END CONFIGURATION ---

# Exit immediately if a command exits with a non-zero status.
set -e

# Source the keychain to connect to the ssh-agent
source $HOME/.keychain/$HOSTNAME-sh

# Expand the tilde (~) to the full home directory path
EVAL_VAULT_PATH=$(eval echo "$VAULT_PATH")

echo "--- Starting vault sync @ $(date) ---"

# Navigate to the vault directory
cd "$EVAL_VAULT_PATH"

# Step 1: Commit any local changes first to ensure a clean state.
echo "Checking for local changes to commit..."
if ! git diff-index --quiet HEAD --; then
    echo "Local changes detected. Committing..."
    git add .
    git commit -m "Auto-sync local changes @ $(date)"
fi

# Step 2: Fetch the latest history from the remote repository.
# This downloads changes but does NOT try to integrate them yet.
echo "Fetching latest changes from remote..."
git fetch origin

# Step 3: Merge the remote changes into your local branch.
# The "-X theirs" option is the key: it automatically resolves any
# content conflicts by choosing the remote's version.
echo "Merging remote changes (prioritizing remote in case of conflict)..."
git merge -X theirs "origin/${BRANCH_NAME}"

# Step 4: Finally, push the newly combined history back to the remote.
echo "Pushing changes to remote..."
git push origin "${BRANCH_NAME}"

echo "--- Sync finished ---"
