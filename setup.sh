#!/data/data/com.termux/files/usr/bin/env bash

echo "--- Starting Obsidian Sync Services ---"
echo "You will now be prompted for your SSH key passphrase to unlock it for this session."

# Step 1: Start and configure the ssh-agent via keychain.
# This is the command that will trigger the passphrase prompt.
eval $(keychain --eval --quiet id_ed25519)

# Step 2: Start the cron daemon if it's not already running.
pgrep -x crond > /dev/null || crond
echo "Cron daemon for scheduled sync is running."

# Step 3: Acquire a wakelock to keep Termux alive in the background.
termux-wake-lock
echo "Termux wakelock acquired."

echo "✅ All services are now active. Your vault will sync automatically in the background."
