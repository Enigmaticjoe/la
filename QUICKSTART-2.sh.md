# Quick Start Guide - 2.sh Installer

## TL;DR

```bash
# Download and run the installer
sudo ./2.sh

# After installation
# Access Portainer: http://localhost:9000
# Create admin account, then start deploying containers!
```

## What It Does

Installs Docker Engine + Portainer CE on Fedora 44 COSMIC with one command.

## Requirements

- Fedora 44 COSMIC (or Fedora 39+)
- sudo/root access
- Internet connection
- 10GB disk space
- 2GB RAM

## Common Issues

### "Unknown argument --add-repo"
✅ **Fixed!** This installer handles DNF5 syntax automatically.

### "Permission denied" when running docker
```bash
# Log out and back in, or run:
newgrp docker
```

### Ports already in use
```bash
# Check what's using ports 9000 or 9443:
sudo lsof -i :9000
sudo lsof -i :9443

# Kill the process or change Portainer ports in the script
```

### Installation fails
The script automatically rolls back changes. Check the error message and try again.

## Files

- `2.sh` - The installer
- `2.sh.README.md` - Full documentation
- `test-2.sh` - Test the installer
- `validate-installer.sh` - Verify installer logic
- `SECURITY-SUMMARY.md` - Security audit results

## Testing

```bash
# Validate the installer (doesn't install anything)
./validate-installer.sh

# Run tests
./test-2.sh
```

## After Installation

1. **Access Portainer**: http://YOUR-IP:9000
2. **Create admin account** (first time only)
3. **Add Docker endpoint** (local)
4. **Deploy stacks** from your repository

## Useful Commands

```bash
# Check Docker status
sudo systemctl status docker

# Check Portainer status
docker ps | grep portainer

# View Portainer logs
docker logs portainer

# Restart Portainer
docker restart portainer

# Stop and remove Portainer
docker stop portainer && docker rm portainer
```

## Get Help

- Issues: https://github.com/Enigmaticjoe/la/issues
- Full docs: Read `2.sh.README.md`
- Security: Read `SECURITY-SUMMARY.md`
