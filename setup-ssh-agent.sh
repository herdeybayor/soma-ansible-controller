#!/bin/bash
# SSH Agent Setup - Load Deployment Key from Vault
#
# This script decrypts the SSH private key from Ansible Vault and loads it
# into the SSH agent, allowing Ansible to authenticate without writing the
# key to disk.
#
# Usage:
#   source ./setup-ssh-agent.sh
#   ansible-playbook playbooks/pre_checks.yml --inventory inventory/staging
#

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  SSH Agent Setup - Vault Encrypted Key                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if SSH agent is running
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "🚀 Starting SSH agent..."
    eval "$(ssh-agent -s)"
    AGENT_STARTED=true
else
    echo "✅ SSH agent is already running"
    echo "   SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    AGENT_STARTED=false
fi

echo ""
echo "🔑 Loading deployment key from vault..."
echo "   You will be prompted for the vault password"
echo ""

# Extract vault encrypted key and pipe directly to ssh-add
# This decrypts the key in memory and loads it into the agent
# The key NEVER touches disk as plaintext
if ansible-vault view group_vars/all/vault.yml --ask-vault-pass | \
   grep -A 100 "vault_ssh_private_key:" | \
   sed '1d; /^[a-z]/d; s/^[[:space:]]*//' | \
   ssh-add - 2>/dev/null; then

    echo ""
    echo "✅ SSH Key Successfully Loaded into Agent"
    echo ""
    echo "Key Details:"
    ssh-add -l | grep -E "ED25519|RSA|ECDSA" || true
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Ready to run Ansible playbooks!                              ║"
    echo "║                                                                ║"
    echo "║  Run your playbook with:                                      ║"
    echo "║    ansible-playbook playbooks/pre_checks.yml \                ║"
    echo "║      --inventory inventory/staging                            ║"
    echo "║                                                                ║"
    echo "║  The deployment key is now in the SSH agent's memory.         ║"
    echo "║  It will be cleaned up when you close this session.           ║"
    echo "╚════════════════════════════════════════════════════════════════╝"

else
    echo "❌ Failed to load SSH key from vault"
    if [ "$AGENT_STARTED" = true ]; then
        echo ""
        echo "Cleaning up started agent..."
        kill $SSH_AGENT_PID
    fi
    exit 1
fi
