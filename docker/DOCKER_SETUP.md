# UNIT3D Upload Checker - Setup Guide

This guide explains how to configure and use the UNIT3D Upload Checker Docker container with the new simplified setup workflow.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Detailed Setup](#detailed-setup)
3. [Configuration Reference](#configuration-reference)
4. [Troubleshooting](#troubleshooting)

---

## Quick Start

### First-Time Setup


# 1. Obtain the Docker assets (pick one)
#    A) Download just the docker bundle into an empty folder (Recomnmended)
```
mkdir unit3d-upload-checker-docker && cd $_
wget https://raw.githubusercontent.com/magrhino/UNIT3D-Upload-Checker/main/docker/docker-compose.yml
wget https://raw.githubusercontent.com/magrhino/UNIT3D-Upload-Checker/main/docker/Dockerfile
wget https://raw.githubusercontent.com/magrhino/UNIT3D-Upload-Checker/main/docker/entrypoint.sh
wget -O .env.example https://raw.githubusercontent.com/magrhino/UNIT3D-Upload-Checker/main/docker/.env.example
wget https://raw.githubusercontent.com/magrhino/UNIT3D-Upload-Checker/main/docker/SETUP_GUIDE.md
mkdir -p scripts config outputs
wget -O scripts/setup.sh https://raw.githubusercontent.com/magrhino/UNIT3D-Upload-Checker/main/docker/scripts/setup.sh
```

#    B) Clone the repo, then work inside the docker/ directory
```
git clone https://github.com/magrhino/UNIT3D-Upload-Checker.git
cd UNIT3D-Upload-Checker/docker
```

# 2. Create and configure your .env file
```
cp .env.example .env
nano .env  # Add your API keys and settings
```
# 3. Build the Docker image
```
docker-compose build
```

# 4. Run the one-time setup command (must complete before the container starts)
```
docker run --rm -it \
  -v ./config:/app/data:rw \
  --env-file .env \
  unit3d-checker:latest \
  /app/scripts/setup.sh
```

# 5. Start the container
```
docker-compose up -d
```
# 6. Access the container shell
```
docker exec -it unit3d-upload-checker bash
```
# 7. Run the checker
```
python3 check.py run-all -v
```

### Subsequent Usage

After initial setup, your configuration persists in `./config/settings.json`:

```bash
# Start the container
docker-compose up -d

# Access the shell
docker exec -it unit3d-upload-checker bash

# Run the checker
python3 check.py run-all -v
```

---

## Detailed Setup

### Step 1: Configure Environment Variables

Create a `.env` file in the project root with your API keys and settings (or use .env.example):

```bash
# Required media paths
HOST_MEDIA_DIR=/path/to/your/media          # host path you want to scan
CONTAINER_MEDIA_DIR=/data                   # mount location inside the container

# TMDB
TMDB_API_KEY=your_tmdb_api_key_here

# Tracker API Keys (add the ones you use)
FNP_API_KEY=your_fearnopeer_key
RAS_API_KEY=your_rastastugan_key
HHD_API_KEY=your_homiehelpdesk_key
BLU_API_KEY=your_blutopia_key
AITH_API_KEY=your_aither_key
RFX_API_KEY=your_reelflix_key
LST_API_KEY=your_lst_key
OE_API_KEY=your_onlyencodes_key
UPLOADCX_API_KEY=your_uploadcx_key

# Enable sites (comma-separated list of tracker codes)
SITES_ENABLED=fnp,ras,hhd

# Optional paths for export commands
GG_PATH=/path/to/gg-bot-upload-assistant
UA_PATH=/path/to/upload-assistant
```

### Step 2: Build the Image

```bash
docker-compose build
```

This builds the image with:
- Alpine Linux 3.22 base
- Python 3.12
- All required dependencies
- Patched check.py for non-TTY environments
- Setup and entrypoint scripts

### Step 3: Run Setup Script

The setup script reads your `.env` file and configures `settings.json`:

```bash
docker run --rm -it \
  -v ./config:/app/data:rw \
  --env-file .env \
  unit3d-checker:latest \
  /app/scripts/setup.sh
```

**What this does:**
1. Creates default `settings.json` if missing
2. Configures TMDB API key
3. Adds the primary media directory (setup currently supports one path;
   add more later with `python3 check.py setting-add -t dir -s /other/path`)
4. Configures tracker API keys
5. Enables specified sites
6. Sets optional paths (gg-bot, upload-assistant)
7. Displays configuration summary

**Interactive prompts:**
- Press ENTER to continue with setup
- Configuration runs automatically from environment variables
- Shows success/failure for each step

### Step 4: Start the Container

```bash
docker-compose up -d
```

The container starts with a deliberately simple entrypoint that never mutates configuration. It:
- Warns if `/app/data/settings.json` is missing
- Displays the current TMDB key, directories, and enabled sites
- Lists the most common `check.py` commands
- Hands control to `bash` (or whatever command you override)

### Step 5: Use the Application

```bash
# Access the container
docker exec -it unit3d-upload-checker bash

# Run full workflow
python3 check.py run-all -v

# Or run individual steps
python3 check.py scan -v
python3 check.py tmdb -v
python3 check.py search -v
python3 check.py save
python3 check.py gg
# Add extra directories if needed (setup.sh only adds one):
python3 check.py setting-add -t dir -s /path/to/more/media
```

---

## Architecture Overview

The Docker workflow is intentionally split so configuration happens only when you request it.

- **Builder stage (Dockerfile)** installs requirements into `/tmp/deps`, then the runtime stage copies only those wheels plus the source tree. Build tools (git, compilers) never reach the final image.
- **Runtime stage** includes Python, `ffmpeg`, `mediainfo`, the app code, and a non-root `appuser`. It pre-creates `/app/data`, `/app/outputs`, and `/data` so volume mounts bind cleanly.
- **Setup script (`/app/scripts/setup.sh`)** is the only component that reads `.env` values and writes to `settings.json`. Run it via `docker run ... /app/scripts/setup.sh` any time you add trackers, change API keys, or adjust directories.
- **Entrypoint (`/usr/local/bin/entrypoint.sh`)** is intentionally passive: it prints status and exits to an interactive shell. Restarting the container will **not** reapply `.env` changes—you must re-run the setup script.
- **Volumes** keep `./config` (mapped to `/app/data`) and `./outputs` (mapped to `/app/outputs`) persistent so you can rebuild or replace the container without losing state.

---

## Configuration Reference

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TMDB_API_KEY` | Yes | TMDB API key for movie metadata |
| `HOST_MEDIA_DIR` | Yes | Host filesystem path that contains your media |
| `CONTAINER_MEDIA_DIR` | Yes | Container path that receives the media mount (default `/data`) |
| `MEDIA_DIR` | Yes | Path consumed by the setup script (keep equal to `CONTAINER_MEDIA_DIR`) |
| `SITES_ENABLED` | Recommended | Comma-separated tracker codes (e.g., "ras,hhd,fnp") |
| `FNP_API_KEY` | Optional | FearNoPeer API key |
| `RAS_API_KEY` | Optional | Rastastugan API key |
| `HHD_API_KEY` | Optional | HomieHelpDesk API key |
| `BLU_API_KEY` | Optional | Blutopia API key |
| `AITH_API_KEY` | Optional | Aither API key |
| `RFX_API_KEY` | Optional | ReelFlix API key |
| `LST_API_KEY` | Optional | LST API key |
| `OE_API_KEY` | Optional | OnlyEncodes API key |
| `UPLOADCX_API_KEY` | Optional | Upload.cx API key |
| `GG_PATH` | Optional | Path to gg-bot-upload-assistant |
| `UA_PATH` | Optional | Path to upload-assistant |

### Tracker Codes

| Code | Tracker Name |
|------|--------------|
| `fnp` | FearNoPeer |
| `ras` | Rastastugan |
| `hhd` | HomieHelpDesk |
| `blu` | Blutopia |
| `aith` | Aither |
| `rfx` | ReelFlix |
| `lst` | LST |
| `oe` | OnlyEncodes |
| `ulcx` | Upload.cx |

### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `./config` | `/app/data` | Configuration and database files |
| `./data` | `/data` | Media files to scan (read-only) |
| `./outputs` | `/app/outputs` | Generated output files |

---

## Troubleshooting

### Setup Script Fails

**Problem:** Setup script reports errors or fails to configure

**Solutions:**
1. Check your `.env` file syntax (no spaces around `=`)
2. Verify API keys are valid (test on tracker websites)
3. Ensure media directory exists and is mounted correctly
4. Re-run the setup script - it's safe to run multiple times

```bash
# Re-run setup
docker run --rm -it \
  -v ./config:/app/data:rw \
  --env-file .env \
  unit3d-checker:latest \
  /app/scripts/setup.sh
```

### Configuration Not Found

**Problem:** Container shows "No configuration found" warning

**Solution:** Run the setup script as shown in Step 3 above

### Invalid API Key Errors

**Problem:** Setup reports "Invalid API Key" for trackers

**Possible causes:**
1. API key is incorrect - verify on tracker website
2. API key has expired - generate a new one
3. Tracker API is temporarily down - try again later

### Media Directory Not Found

**Problem:** Setup fails to add media directory

**Solution:**
1. Verify the directory exists on your host system
2. Check docker-compose.yml volume mount is correct
3. Ensure `MEDIA_DIR` and `CONTAINER_MEDIA_DIR` match (default `/data`)
4. Confirm `HOST_MEDIA_DIR` points to an existing folder on the host

### Manual Configuration

If the setup script doesn't work, configure manually inside the container:

```bash
docker-compose up -d
docker exec -it unit3d-upload-checker bash

# Configure manually
python3 check.py setting-add -t tmdb -s YOUR_TMDB_KEY
python3 check.py setting-add -t dir -s /data
python3 check.py setting-add -t fnp -s YOUR_FNP_KEY
python3 check.py setting-add -t sites -s fnp
python3 check.py setting-add -t sites -s ras
python3 check.py setting-add -t sites -s hhd
```

### View Current Configuration

```bash
docker exec -it unit3d-upload-checker bash
python3 check.py setting -t tmdb    # View TMDB key
python3 check.py setting -t dir     # View directories
python3 check.py setting -t sites   # View enabled sites
cat /app/data/settings.json         # View raw JSON
```
---

## Advanced Usage

### Reconfigure Existing Setup

To change configuration after initial setup:

```bash
# Option 1: Update .env and re-run setup
nano .env  # Make changes
docker run --rm -it \
  -v ./config:/app/data:rw \
  --env-file .env \
  unit3d-checker:latest \
  /app/scripts/setup.sh

# Option 2: Manual changes inside container
docker exec -it unit3d-upload-checker bash
python3 check.py setting-add -t sites -s newtracker
python3 check.py setting-rm -t sites  # Remove a site
```

### Reset Configuration

```bash
# Remove settings.json and re-run setup
rm ./config/settings.json

docker run --rm -it \
  -v ./config:/app/data:rw \
  --env-file .env \
  unit3d-checker:latest \
  /app/scripts/setup.sh
```

### Backup Configuration

```bash
# Backup
cp ./config/settings.json ./config/settings.json.backup

# Restore
cp ./config/settings.json.backup ./config/settings.json
```

---

## Key Differences from Old Setup

| Aspect | Old Setup | New Setup |
|--------|-----------|-----------|
| **Configuration** | Automatic on container start | Explicit via setup script |
| **Entrypoint** | 336 lines, complex | ~90 lines, minimal |
| **First Boot** | Attempts auto-config (often fails) | Shows instructions if unconfigured |
| **Debugging** | Difficult (hidden in container logs) | Easy (run setup script interactively) |
| **Reconfiguration** | Requires container recreation | Re-run setup script anytime |
| **TTY Issues** | Frequent OSError failures | None (setup runs interactively) |
| **Startup Time** | Slow (runs config each boot) | Instant (config is one-time) |

---

## Getting Help

If you encounter issues not covered here:

1. Check container logs: `docker-compose logs -f`
2. Access container shell: `docker exec -it unit3d-upload-checker bash`
3. View settings: `cat /app/data/settings.json`
4. Re-run setup with verbose output: `/app/scripts/setup.sh`

---

## Summary

The new setup workflow provides:
- **Clean separation**: Setup is separate from runtime
- **Explicit control**: You choose when to configure
- **Easy debugging**: Interactive setup with clear output
- **No TTY issues**: Setup runs in proper terminal context
- **Fast startup**: Configuration happens once, not every boot
- **Simple entrypoint**: Minimal, focused on display and launch

Enjoy using UNIT3D Upload Checker!
