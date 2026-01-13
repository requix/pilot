# Installation Guide

## Prerequisites

### Required Software
- PILOT installed
- Kiro CLI installed
- jq (JSON processor)

### Platform Support
- macOS (darwin)
- Linux
- Windows (WSL)

## Installation Methods

### Method 1: AI-Guided Installation (Recommended)

The AI installer automatically handles compatibility checking, dependency resolution, and platform-specific adaptation.

```bash
# Install pack
~/.pilot/system/installation/ai-installer.sh install ~/.pilot/packs/pilot-pack-template

# Verify installation
~/.pilot/system/installation/ai-installer.sh verify ~/.pilot/packs/pilot-pack-template/pack.json
```

### Method 2: Manual Installation

For development or troubleshooting:

```bash
# 1. Copy pack to installation directory
cp -r src/packs/pilot-pack-template ~/.pilot/packs/

# 2. Create steering directory
mkdir -p ~/.kiro/steering/packs/pilot-pack-template

# 3. Copy steering files
cp ~/.pilot/packs/pilot-pack-template/src/steering/*.md \
   ~/.kiro/steering/packs/pilot-pack-template/

# 4. Install agent configuration
cp ~/.pilot/packs/pilot-pack-template/src/agents/template-agent.json \
   ~/.kiro/settings/agents/

# 5. Make scripts executable
chmod +x ~/.pilot/packs/pilot-pack-template/src/hooks/*.sh
chmod +x ~/.pilot/packs/pilot-pack-template/src/tools/*.sh

# 6. Verify installation
~/.pilot/packs/pilot-pack-template/tests/verify-pack.sh
```

## Post-Installation

### 1. Verify Kiro Integration

```bash
# Check steering files
ls -la ~/.kiro/steering/packs/pilot-pack-template/

# Check agent configuration
cat ~/.kiro/settings/agents/template-agent.json

# Test agent
kiro chat --agent template-agent
```

### 2. Test Hooks

```bash
# Hooks are automatically registered
# Test by using the agent and triggering hook events
```

### 3. Verify Health Checks

```bash
# Check pack health
~/.pilot/system/installation/ai-installer.sh health-check pilot-pack-template

# View health logs
tail -f ~/.pilot/logs/pack-health.log
```

## Configuration

### Environment Variables

No environment variables required for template pack.

For custom packs, document required variables:

```bash
export MY_PACK_API_KEY="your-api-key"
export MY_PACK_CONFIG_PATH="~/.config/my-pack"
```

### Pack-Specific Configuration

Edit pack configuration if needed:

```bash
# Pack configuration file
~/.pilot/packs/pilot-pack-template/config.json
```

## Troubleshooting

### Installation Fails

**Check Prerequisites:**
```bash
# Verify jq is installed
which jq || echo "jq not found"

# Check PILOT version
cat ~/.pilot/system/version.txt

# Check Kiro CLI version
kiro --version
```

**Check Permissions:**
```bash
# Ensure directories are writable
test -w ~/.pilot/packs || echo "~/.pilot/packs not writable"
test -w ~/.kiro/steering || echo "~/.kiro/steering not writable"
```

**Review Logs:**
```bash
# Installation logs
tail -50 ~/.pilot/logs/installation.log

# Error logs
tail -50 ~/.pilot/logs/errors.log
```

### Steering Files Not Loading

**Verify File Location:**
```bash
ls -la ~/.kiro/steering/packs/pilot-pack-template/
```

**Check File Permissions:**
```bash
chmod 644 ~/.kiro/steering/packs/pilot-pack-template/*.md
```

**Restart Kiro Session:**
```bash
# Exit and restart Kiro CLI
kiro chat --agent template-agent
```

### Hooks Not Executing

**Verify Hook Scripts:**
```bash
# Check executable permission
ls -la ~/.pilot/packs/pilot-pack-template/src/hooks/

# Make executable if needed
chmod +x ~/.pilot/packs/pilot-pack-template/src/hooks/*.sh
```

**Test Hook Manually:**
```bash
# Run hook script directly
~/.pilot/packs/pilot-pack-template/src/hooks/template-hook.sh "test input"
```

**Check Hook Logs:**
```bash
tail -50 ~/.pilot/logs/hooks/hook-execution.log
```

## Uninstallation

### Complete Removal

```bash
# Remove pack files
rm -rf ~/.pilot/packs/pilot-pack-template

# Remove steering files
rm -rf ~/.kiro/steering/packs/pilot-pack-template

# Remove agent configuration
rm -f ~/.kiro/settings/agents/template-agent.json

# Clean cache
rm -rf ~/.pilot/cache/pilot-pack-template
```

### Preserve Configuration

```bash
# Backup configuration before removal
cp -r ~/.pilot/packs/pilot-pack-template/config.json \
   ~/.pilot/backups/pilot-pack-template-config.json

# Then remove pack
rm -rf ~/.pilot/packs/pilot-pack-template
```

## Upgrade

### Upgrade Process

```bash
# 1. Backup current installation
cp -r ~/.pilot/packs/pilot-pack-template \
   ~/.pilot/backups/pilot-pack-template-$(date +%Y%m%d)

# 2. Install new version
~/.pilot/system/installation/ai-installer.sh install \
   ~/Downloads/pilot-pack-template-v2.0.0

# 3. Verify upgrade
~/.pilot/system/installation/ai-installer.sh verify \
   ~/.pilot/packs/pilot-pack-template/pack.json

# 4. Test functionality
kiro chat --agent template-agent
```

### Rollback

```bash
# Restore previous version
rm -rf ~/.pilot/packs/pilot-pack-template
cp -r ~/.pilot/backups/pilot-pack-template-20260111 \
   ~/.pilot/packs/pilot-pack-template
```

## Platform-Specific Notes

### macOS

```bash
# Install jq via Homebrew
brew install jq

# Ensure proper permissions
xattr -d com.apple.quarantine ~/.pilot/packs/pilot-pack-template/src/hooks/*.sh
```

### Linux

```bash
# Install jq via package manager
sudo apt-get install jq  # Debian/Ubuntu
sudo yum install jq      # RHEL/CentOS
```

### Windows (WSL)

```bash
# Install jq
sudo apt-get install jq

# Ensure line endings are correct
dos2unix ~/.pilot/packs/pilot-pack-template/src/hooks/*.sh
```

## Support

If you encounter issues:

1. Check troubleshooting section above
2. Review installation logs
3. Consult pack documentation
4. Open GitHub issue with logs

## Next Steps

After successful installation:

1. Read `README.md` for usage instructions
2. Review `VERIFY.md` for verification procedures
3. Explore steering files in `.kiro/steering/packs/pilot-pack-template/`
4. Try the template agent: `kiro chat --agent template-agent`
