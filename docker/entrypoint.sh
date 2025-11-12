#!/bin/bash
set -e

# UNIT3D Upload Checker - Container Entrypoint
# This minimal entrypoint launches the container and displays status
# Configuration happens via separate setup script

echo "=================================================="
echo "   UNIT3D Upload Checker"
echo "=================================================="

# Create necessary directories
mkdir -p /app/data /app/outputs

# ================================================
# CHECK CONFIGURATION STATUS
# ================================================

if [ ! -f "/app/data/settings.json" ] || [ ! -s "/app/data/settings.json" ]; then
    echo ""
    echo "⚠ WARNING: No configuration found!"
    echo ""
    echo "This appears to be your first time running the container."
    echo "Please run the setup command to configure:"
    echo ""
    echo "  docker run --rm -it \\"
    echo "    -v ./config:/app/data:rw \\"
    echo "    --env-file .env \\"
    echo "    unit3d-checker:latest \\"
    echo "    /app/scripts/setup.sh"
    echo ""
    echo "Or configure manually:"
    echo "  python3 check.py setting-add -t tmdb -s YOUR_KEY"
    echo "  python3 check.py setting-add -t dir -s /data"
    echo "  python3 check.py setting-add -t sites -s ras,hhd,fnp"
    echo ""
fi

# ================================================
# DISPLAY CONFIGURATION STATUS
# ================================================

if [ -f "/app/data/settings.json" ]; then
    echo ""
    echo "Current Configuration:"
    echo "---------------------"
    python3 << 'PYEOF' 2>/dev/null || echo "Unable to read settings"
import json
try:
    with open('/app/data/settings.json') as f:
        s = json.load(f)

    # TMDB Status
    tmdb_status = '✓ Configured' if s.get('tmdb_key') else '✗ Missing'
    print(f'TMDB Key:       {tmdb_status}')

    # Directories
    dirs = s.get('directories', [])
    print(f'Directories:    {len(dirs)} configured')

    # Enabled Sites
    enabled = s.get('enabled_sites', [])
    if enabled:
        print(f'Enabled Sites:  {", ".join(enabled)}')
    else:
        print('Enabled Sites:  None')

except Exception:
    pass
PYEOF
    echo ""
fi

# ================================================
# DISPLAY AVAILABLE COMMANDS
# ================================================

echo "Available Commands:"
echo "-------------------"
echo "  python3 check.py run-all -v      # Run full workflow"
echo "  python3 check.py scan -v         # Scan directories"
echo "  python3 check.py tmdb -v         # Match with TMDB"
echo "  python3 check.py search -v       # Search trackers"
echo "  python3 check.py setting -t dir  # View settings"
echo ""
echo "=================================================="

# Execute the provided command or default to bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    exec "$@"
fi
