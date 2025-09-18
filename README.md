-----

# Automated Obsidian Sync on Android with Termux and Git

who is this for :
    You have obsidian and want a no-cost way to sync between your phone and computer
    Thanks to the GIT plugin by Vinzent , it works fine on the computer, but for phones they are not 
    usable so this approach solves it by using termux to run proper git on phones 
    and use it to sync notes on regular basis 

This repository provides a complete guide and a robust script for setting up a powerful, automated sync system for your Obsidian vault on Android. It uses Termux, Git, and Cron to create a free and reliable alternative to paid sync services.

This guide focuses on a conscious, manual-start approach: after a reboot, you run a single command to activate all background services.

### Key Features

  * **Reliable Background Syncing**: Runs on a schedule as long as Termux is active.
  * **Automatic Conflict Resolution**: Intelligently prioritizes remote changes in case of a direct conflict, ensuring the sync process never halts.
  * **Secure and Passwordless**: Uses SSH keys and `keychain` for secure authentication.
  * **Simple Manual Startup**: A single script starts all necessary services after a reboot.

-----

## Setup Guide

### Step 1: Initial Termux & Git Setup

First, prepare the Termux environment and install Git.

1.  **Install Termux**: Get the latest version from [F-Droid](https://f-droid.org/packages/com.termux/).
2.  **Update Packages & Install Git**:
    ```bash
    pkg update && pkg upgrade -y
    pkg install git -y
    ```
3.  **Grant Storage Access**:
    ```bash
    termux-setup-storage
    ```
    Accept the permission prompt that appears on your phone.
4.  **Configure Git Identity**:
    ```bash
    git config --global user.name "Your Name"
    git config --global user.email "youremail@example.com"
    ```

### Step 2: Secure SSH Authentication with Keychain

This process ensures your automated script can securely authenticate with your Git provider.

1.  **Generate a New SSH Key**:
    ```bash
    ssh-keygen -t ed25519 -C "youremail@example.com"
    ```
    Accept the defaults and set a strong passphrase when prompted.
2.  **Add Public Key to Your Git Provider**:
      * Copy the contents of your public key:
        ```bash
        cat ~/.ssh/id_ed25519.pub
        ```
      * Go to your GitHub/GitLab account **Settings \> SSH and GPG keys** and add the copied key.
3.  **Install and Configure `keychain`**: This tool manages your SSH agent across sessions.
    ```bash
    pkg install keychain
    ```

### Step 3: The Sync Script (`sync-vault.sh`)

This is the core script that performs the synchronization.

1.  **Place the Script**: Make sure the `sync-vault.sh` script from this repository is located in your Termux home directory (`~/`).
2.  **Configure the Script**: Open the script to edit the configuration variables at the top.
    ```bash
    nano ~/sync-vault.sh
    ```
      * Set `VAULT_PATH` to the correct path of your vault.
      * Set `BRANCH_NAME` to your repository's primary branch (usually `main` or `master`).
3.  **Make It Executable**:
    ```bash
    chmod +x ~/sync-vault.sh
    ```

### Step 4: Automation with Cron

This will run the sync script on a schedule.

1.  **Install the Cron Service**:
    ```bash
    pkg install cronie
    ```
2.  **Schedule the Sync**: Open your schedule file (`crontab`).
    ```bash
    crontab -e
    ```
    Add the following line to run the script silently every 20 minutes.
    ```crontab
    */20 * * * * ~/sync-vault.sh > /dev/null 2>&1
    ```

### Step 5: The Manual Startup Script (`start-sync.sh`)

This is the script you will run once after every reboot to activate all background services.

1.  **Create the Startup Script**:
    ```bash
    nano ~/start-sync.sh
    ```
2.  **Paste the Following Content**:
    ```sh
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
    ```
    Save and exit the editor.
3.  **Make the Startup Script Executable**:
    ```bash
    chmod +x ~/start-sync.sh
    ```

-----

## Final Workflow

Your setup is complete. Your workflow is now extremely simple:

**1. After Rebooting Your Phone:**

  * Open Termux.
  * Run the startup script: `./start-sync.sh`
  * Enter your SSH passphrase when prompted.

That's it. The sync services will now run in the background until your next reboot or you kill termux accidentaly .

**2. Keeping Termux Alive:**
For the background sync to work, remember to:

  * **Keep the Wakelock Notification**: Don't dismiss the persistent Termux notification.
  * **Disable Battery Optimization**: Ensure Termux is set to **Unrestricted** in your phone's app battery settings.

-----

## How the Sync Logic Works (Important\!)

philosophy: remote is always right 


The `sync-vault.sh` script uses a specific, robust Git workflow to prevent getting stuck on conflicts:

1.  **Commit Local Changes**: First, it saves any changes you've made on your device.

2.  **Fetch Remote Changes**: It downloads the latest history from the server.

3.  **Merge with "-X theirs" Strategy**: It then merges the remote changes. The crucial part is the `-X theirs` strategy. This means:

    > In the event of a direct conflict (i.e., the same lines in the same file were edited on both the remote and the local device), the script will **automatically keep the remote version ("theirs")** and discard the local change.

4.  **Push the Merged Result**: Finally, it uploads the clean, merged history back to the server.

This strategy makes the script extremely reliable for automation, but be aware of its behavior: if you edit the exact same sentence on two devices before a sync, the change from the last device to push (e.g., your computer) will win, and the conflicting change on your phone will be overwritten. For most single-user workflows, this is a safe and desirable way to maintain consistency.

Special mention and credits to work done by Vinzent on the obsidian gitplugin 
https://github.com/Vinzent03/obsidian-git#
    
