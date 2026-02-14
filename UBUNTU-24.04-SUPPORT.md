# Ubuntu 24.04 Support for ROCm Installation

## Summary

This document explains the changes made to support Ubuntu 24.04 (Noble Numbat) for ROCm installation in the Brain AI stack.

## Problem

The repository was configured to use ROCm 6.0 repository which is designed for Ubuntu 20.04:
```bash
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/6.0/ ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list
```

When running on Ubuntu 24.04, this caused dependency version conflicts because:
- Ubuntu 24.04 packages expect ROCm 6.2+ or newer versions
- The old repository configuration used deprecated `apt-key` method
- Package versions from ROCm 6.0 (for Ubuntu 20.04) conflicted with ROCm 7.1+ packages (for Ubuntu 24.04)

## Solution

Updated all ROCm repository configurations to use the modern approach:

### Ubuntu 24.04 (Noble):
```bash
sudo mkdir --parents --mode=0755 /etc/apt/keyrings
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest noble main" | \
    sudo tee /etc/apt/sources.list.d/rocm.list
```

### Ubuntu 22.04 (Jammy):
```bash
sudo mkdir --parents --mode=0755 /etc/apt/keyrings
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest jammy main" | \
    sudo tee /etc/apt/sources.list.d/rocm.list
```

## Key Changes

### 1. Modern GPG Key Management
- **Old**: `apt-key add` (deprecated)
- **New**: `/etc/apt/keyrings/rocm.gpg` with signed-by directive

### 2. Version-Specific Repository
- **Old**: Generic `/rocm/apt/6.0/` with `ubuntu` codename
- **New**: `/rocm/apt/latest/` with specific codename (`noble` or `jammy`)

### 3. ROCm Version Support
- **Ubuntu 24.04**: ROCm 6.2+ (latest from repository)
- **Ubuntu 22.04**: ROCm 6.1+ (latest from repository)
- **Older Systems**: ROCm 6.0 still available as fallback

### 4. PyTorch Wheels
Updated PyTorch installation instructions to match ROCm versions:
- Ubuntu 24.04: `https://download.pytorch.org/whl/rocm6.2`
- Ubuntu 22.04: `https://download.pytorch.org/whl/rocm6.1`
- Fallback: `https://download.pytorch.org/whl/rocm6.0`

## Files Updated

1. **BRAIN-AMD-SETUP.md**
   - Quick Start section
   - Detailed ROCm installation instructions
   - OS specification updated to include Ubuntu 24.04

2. **brain-requirements.txt**
   - ROCm installation instructions
   - PyTorch installation instructions
   - Version-specific guidance

3. **HUGGINGFACE-CLI-FIX-SUMMARY.md**
   - ROCm installation workflow
   - PyTorch installation instructions

## Verification

After applying these changes, users on Ubuntu 24.04 should be able to:

1. Successfully add the ROCm repository without deprecated warnings
2. Install ROCm packages without version conflicts
3. Use the latest ROCm features and bug fixes
4. Maintain compatibility with Ubuntu 22.04 installations

## Testing

To verify the fix works:

```bash
# On Ubuntu 24.04
sudo mkdir --parents --mode=0755 /etc/apt/keyrings
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest noble main" | \
    sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update
sudo apt install rocm-hip-sdk rocm-libs rocm-smi-lib

# Should complete without dependency conflicts
```

## Benefits

1. **Ubuntu 24.04 Support**: Full support for the latest LTS release
2. **Future-Proof**: Using 'latest' repository ensures automatic updates
3. **No Deprecation Warnings**: Modern GPG key management
4. **Better Security**: Signed packages with proper key validation
5. **Flexibility**: Easy to switch between Ubuntu versions

## References

- [AMD ROCm Official Documentation](https://rocm.docs.amd.com/)
- [ROCm Ubuntu Installation Guide](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/install-methods/package-manager/package-manager-ubuntu.html)
- [Ubuntu 24.04 ROCm Support Announcement](https://rocm.docs.amd.com/projects/install-on-linux/en/docs-6.2.4/install/native-install/ubuntu.html)
