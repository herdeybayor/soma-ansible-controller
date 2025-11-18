# Pre-Checks Playbook Documentation

## Overview

`playbooks/pre_checks.yml` is a **validation playbook** that runs **before the main deployment**. It verifies that all prerequisites are met and the target servers are ready for the full deployment.

## What It Checks

### 1. **Connectivity Checks**
- ✅ Ping connectivity to target host
- ✅ Internet connectivity (can reach external URLs)
- ✅ DNS resolution working

### 2. **User & Permissions**
- ✅ Deploy user exists (creates if missing)
- ✅ Deploy user has sudo access (sets up NOPASSWD)
- ✅ SSH directory exists and has correct permissions
- ✅ Known hosts configured for GitHub

### 3. **Git Access**
- ✅ Can access GitHub repositories anonymously
- ✅ SSH configured for git operations

### 4. **System Requirements**
- ✅ APT package manager available
- ✅ Available disk space
- ✅ Available memory
- ✅ Nginx can be installed
- ✅ Certbot can be installed

### 5. **AWS Credentials**
- ✅ AWS CLI installed
- ✅ AWS credentials are valid
- ✅ Can authenticate to AWS

### 6. **Directory Structure**
- ✅ Application directories exist or can be created
- ✅ Correct ownership and permissions

### 7. **Port Availability**
- ✅ Port 80 (HTTP) availability
- ✅ Port 443 (HTTPS) availability

## How to Run

### Run Against Staging Environment

```bash
cd ansible-controller

ansible-playbook playbooks/pre_checks.yml \
  --inventory inventory/staging \
  --ask-vault-pass
```

### Run Against Production Environment

```bash
ansible-playbook playbooks/pre_checks.yml \
  --inventory inventory/production \
  --ask-vault-pass
```

### Run Against Specific Host

```bash
ansible-playbook playbooks/pre_checks.yml \
  --inventory inventory/staging \
  --extra-vars "target_group=staging_backend" \
  --ask-vault-pass
```

### Run Specific Checks Only

```bash
# Only connectivity checks
ansible-playbook playbooks/pre_checks.yml \
  --inventory inventory/staging \
  --ask-vault-pass \
  --tags connectivity

# Only user/permission checks
ansible-playbook playbooks/pre_checks.yml \
  --inventory inventory/staging \
  --ask-vault-pass \
  --tags users

# Only AWS checks
ansible-playbook playbooks/pre_checks.yml \
  --inventory inventory/staging \
  --ask-vault-pass \
  --tags aws
```

## Available Tags

You can filter checks by using tags:

| Tag | Description |
|-----|-------------|
| `connectivity` | Network and DNS tests |
| `users` | Deploy user setup and permissions |
| `git` | Git repository access |
| `packages` | Package manager and installable packages |
| `disk` | Disk space checks |
| `memory` | Available memory checks |
| `aws` | AWS credentials and CLI tests |
| `directories` | Application directory structure |
| `ports` | Port availability checks |
| `dns` | DNS resolution tests |
| `nginx` | Nginx readiness |
| `certbot` | Certbot readiness |
| `ssh` | SSH configuration |
| `sudo` | Sudo access checks |

## Example Output

```
PLAY [Pre-Deployment Validation Checks] ****

TASK [PreChecks | Display validation information] ***
╔════════════════════════════════════════════════════════════════╗
║  Pre-Deployment Validation Checks                              ║
║  Target Host: staging-backend-1                                ║
║  Environment: staging                                          ║
║  OS: Debian                                                    ║
║  Python: 3.9.2                                                ║
╚════════════════════════════════════════════════════════════════╝

TASK [PreChecks | Test connectivity to target host] ***
ok: [staging-backend-1] => {
    "ping": "pong"
}

TASK [PreChecks | Display ping result] ***
ok: [staging-backend-1] => {
    "msg": "✅ Host is reachable (pong)"
}

...

TASK [PreChecks | Display validation summary] ***
╔════════════════════════════════════════════════════════════════╗
║  ✅ Pre-Deployment Validation Complete                          ║
║                                                                ║
║  staging-backend-1                                             ║
║  Environment: staging                                          ║
║                                                                ║
║  Checks Passed:                                               ║
║  ✅ Connectivity                                               ║
║  ✅ User permissions                                           ║
║  ✅ Git access                                                 ║
║  ✅ Package management                                         ║
║  ✅ System resources                                           ║
║  ✅ AWS credentials                                            ║
║  ✅ Required directories                                       ║
║                                                                ║
║  This system is ready for deployment!                         ║
╚════════════════════════════════════════════════════════════════╝

PLAY RECAP ****
staging-backend-1 : ok=25 changed=1 unreachable=0 failed=0
```

## Troubleshooting Pre-Checks Failures

### If Connectivity Fails

```bash
# Check network connectivity
ping -c 1 <target-host>

# Check SSH access
ssh -i ~/.ssh/deploy_key deploy@<target-host> "echo OK"

# Check if Ansible can reach host
ansible all -i inventory/staging -m ping --ask-vault-pass
```

### If Git Access Fails

```bash
# SSH to the target and test git access
ssh deploy@<target-host>
ssh -T git@github.com
git ls-remote https://github.com/hngprojects/stock-keeping-app-BE.git HEAD
```

### If AWS Credentials Fail

```bash
# Check AWS credentials in vault
ansible-vault view group_vars/all/vault.yml

# Test AWS credentials manually
export AWS_ACCESS_KEY_ID="<key>"
export AWS_SECRET_ACCESS_KEY="<secret>"
aws sts get-caller-identity
```

### If Disk Space Is Low

The system needs at least 5GB free for:
- Application code (~500MB)
- Node modules / Maven cache (~2GB)
- Build artifacts (~1GB)
- Logs and data (~2GB)

Solution: Clean up or add more disk space

```bash
# On target server
df -h
du -sh /opt/*  # Check what's using space
```

## What Pre-Checks Does NOT Do

- ❌ Does not perform the actual deployment
- ❌ Does not install packages
- ❌ Does not clone repositories
- ❌ Does not configure services
- ❌ Does not start applications

These are all done by `playbooks/deploy.yml` after pre-checks pass.

## Best Practices

1. **Always run pre-checks first**
   ```bash
   # Step 1: Pre-checks
   ansible-playbook playbooks/pre_checks.yml \
     --inventory inventory/staging \
     --ask-vault-pass

   # Step 2: Only run deployment if pre-checks pass
   ansible-playbook playbooks/deploy.yml \
     --inventory inventory/staging \
     --ask-vault-pass
   ```

2. **Run pre-checks on all environments before major deployments**
   ```bash
   # Staging
   ansible-playbook playbooks/pre_checks.yml \
     --inventory inventory/staging

   # Production
   ansible-playbook playbooks/pre_checks.yml \
     --inventory inventory/production
   ```

3. **Use tags to focus on specific issues**
   ```bash
   # If deployment failed due to AWS issues
   ansible-playbook playbooks/pre_checks.yml \
     --inventory inventory/production \
     --tags aws
   ```

4. **Document any pre-check failures**
   Save output for troubleshooting:
   ```bash
   ansible-playbook playbooks/pre_checks.yml \
     --inventory inventory/staging \
     --ask-vault-pass \
     -v | tee pre_checks_$(date +%Y%m%d_%H%M%S).log
   ```

## Integration with Main Deployment

The pre-checks playbook is **independent** but should always run before `deploy.yml`:

```bash
#!/bin/bash
# deploy.sh - Safe deployment script

ENVIRONMENT=$1
INVENTORY="inventory/${ENVIRONMENT}"

echo "🔍 Running pre-checks..."
ansible-playbook playbooks/pre_checks.yml \
  --inventory ${INVENTORY} \
  --ask-vault-pass

if [ $? -eq 0 ]; then
  echo "✅ Pre-checks passed!"
  echo "🚀 Starting deployment..."
  ansible-playbook playbooks/deploy.yml \
    --inventory ${INVENTORY} \
    --ask-vault-pass
else
  echo "❌ Pre-checks failed! Fix issues before deploying."
  exit 1
fi
```

Run it:
```bash
chmod +x deploy.sh
./deploy.sh staging
```

## Performance Notes

- Pre-checks typically take **2-5 minutes** per target
- Can be run in parallel against multiple targets
- Uses Ansible's optimized gathering (gather_facts: true)
- Includes timeout configurations for reliability

## Security Considerations

Pre-checks validate but do NOT:
- Store any sensitive data
- Modify production configuration
- Deploy any code
- Create any services

It's a **safe, read-mostly operation** that can be run frequently without side effects.
