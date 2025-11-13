# =============================================================================
# UNIT3D Upload Checker - Dockerfile
# =============================================================================
# This Dockerfile creates a containerized environment for the UNIT3D Upload
# Checker application using a TRUE multi-stage build for optimal size and
# security.
#
# Repository: https://github.com/magrhino/UNIT3D-Upload-Checker
#
# Build Arguments:
#   - REPO_URL: Git repository URL (default: official repo)
#   - REPO_BRANCH: Branch to clone (default: main)
#   - PYTHON_VERSION: Python version to use (default: 3.11)
#
# Volume Mounts:
#   - /data: Mount your media directory here
#   - /app/data: Configuration and database files (settings.json, etc.)
#   - /app/outputs: Generated output files (txt, csv, gg commands)
#
# Environment Variables:
#   - TMDB_API_KEY: TMDB API key for movie metadata
#   - MEDIA_DIR: Path to media directory inside container
#   - SITES_ENABLED: Comma-separated list of tracker nicknames
#   - *_API_KEY: API keys for various trackers (FNP, RAS, HHD, etc.)
#
# Build:
#   docker build -t unit3d-checker .
#
# Run:
#   docker-compose up -d
#   docker exec -it unit3d-upload-checker bash
# =============================================================================

# Build arguments for flexibility
ARG PYTHON_VERSION=3.11
ARG REPO_URL=https://github.com/magrhino/UNIT3D-Upload-Checker.git
ARG REPO_BRANCH=main

# =============================================================================
# STAGE 1: Builder
# =============================================================================
# This stage contains build-time dependencies (git) and performs the repository
# cloning and dependency installation. These tools will NOT be in the final image.
# =============================================================================
FROM python:${PYTHON_VERSION}-slim as builder

# Build arguments need to be redeclared in each stage
ARG REPO_URL
ARG REPO_BRANCH

# Set environment variables for build stage
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install ONLY build-time dependencies
# git: Required to clone the repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create temporary build directory
WORKDIR /tmp/build

# Clone the repository
# Using --depth 1 for faster clone and smaller download
RUN git clone --depth 1 --branch ${REPO_BRANCH} ${REPO_URL} . && \
    echo "✓ Repository cloned from ${REPO_URL} (branch: ${REPO_BRANCH})"

# Install Python dependencies to a target directory
# This allows us to copy just the installed packages to the runtime stage
RUN pip install --no-cache-dir --target=/tmp/deps -r requirements.txt && \
    echo "✓ Python dependencies installed to /tmp/deps"

# =============================================================================
# STAGE 2: Runtime
# =============================================================================
# This stage contains ONLY runtime dependencies and the application code.
# Build tools (git) are NOT included, reducing image size and attack surface.
# =============================================================================
FROM python:${PYTHON_VERSION}-slim as runtime

# Metadata labels
LABEL maintainer="UNIT3D Upload Checker"
LABEL description="Automated tracker upload checker for UNIT3D-based private trackers"
LABEL version="2.0"
LABEL org.opencontainers.image.source="https://github.com/magrhino/UNIT3D-Upload-Checker"

# Set environment variables for runtime
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/usr/local/lib/python-packages \
    DEBIAN_FRONTEND=noninteractive

# Install ONLY runtime dependencies
# ffmpeg: Media file processing (required by application)
# mediainfo: Extract media file metadata (required by application)
# NOTE: git and jq are NOT installed - they were only needed at build time
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    mediainfo \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && echo "✓ Runtime dependencies installed"

# Create application directory
WORKDIR /app

# Copy Python dependencies from builder stage
# This is the key to multi-stage builds: copy installed packages, not the build tools
COPY --from=builder /tmp/deps /usr/local/lib/python-packages

# Copy application code from builder stage
# We copy the entire cloned repository
COPY --from=builder /tmp/build /app

# PATCH: Fix terminal size detection for non-interactive environments
# The upstream check.py crashes when os.get_terminal_size() is called without a TTY
# This happens during Docker entrypoint execution, CI/CD pipelines, cron jobs, etc.
COPY scripts/patch_check.py /tmp/patch_check.py
RUN python3 /tmp/patch_check.py && rm /tmp/patch_check.py

# Create necessary runtime directories
RUN mkdir -p /app/data /app/outputs /data && \
    echo "✓ Application directories created"

# Make check.py executable
RUN chmod +x check.py && \
    echo "✓ check.py is executable"

# Create a non-root user for security
# Using UID/GID 1000 for compatibility with most host systems
RUN groupadd -r -g 1000 appuser && \
    useradd -r -u 1000 -g appuser -d /app -s /bin/bash appuser && \
    chown -R appuser:appuser /app && \
    echo "✓ Non-root user created (UID/GID 1000)"

# Create scripts directory and copy setup script
RUN mkdir -p /app/scripts && \
    echo "✓ Scripts directory created"
COPY --chown=appuser:appuser scripts/setup.sh /app/scripts/setup.sh
RUN chmod +x /app/scripts/setup.sh && \
    echo "✓ setup.sh is executable"

# Copy and setup entrypoint script
COPY --chown=appuser:appuser entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER appuser

# Expose volumes
# - /data: Media files to scan (should be mounted read-only)
# - /app/data: Configuration and database files
# - /app/outputs: Generated output files
VOLUME ["/data", "/app/data", "/app/outputs"]

# Set working directory
WORKDIR /app

# Improved health check
# Tests that Python can actually import the required modules, not just that files exist
# This catches missing dependencies, import errors, and actual application issues
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python3 -c "import sys; sys.path.insert(0, '/usr/local/lib/python-packages'); import check; import settings; exit(0)" || exit 1

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

# =============================================================================
# Build Optimization Notes
# =============================================================================
#
# This Dockerfile uses a TRUE multi-stage build pattern:
#
# BUILDER STAGE:
# - Contains: git, build tools, source code
# - Purpose: Clone repo, install dependencies
# - Size: ~300MB (not in final image)
#
# RUNTIME STAGE:
# - Contains: Only runtime deps (ffmpeg, mediainfo), app code, Python packages
# - Purpose: Run the application
# - Size: ~150-200MB (100-150MB smaller than before)
#
# Key Differences from Previous "Fake" Multi-Stage Build:
# 1. Runtime stage starts fresh from base Python image
# 2. Uses COPY --from=builder to get only what's needed
# 3. git and build tools are NOT in the final image
# 4. Each stage has a clear, single purpose
#
# Benefits:
# - 100-150MB smaller final image
# - Reduced attack surface (no git, no build tools)
# - Faster container startup
# - Better security (fewer packages to patch)
#
# =============================================================================

# =============================================================================
# Usage Instructions
# =============================================================================
#
# Building the image:
#   docker build -t unit3d-checker .
#
# Using custom repository:
#   docker build -t unit3d-checker \
#     --build-arg REPO_URL=https://github.com/yourfork/UNIT3D-Upload-Checker.git \
#     --build-arg REPO_BRANCH=develop .
#
# Running with docker-compose:
#   1. Configure .env file with API keys and settings
#   2. Run: docker-compose up -d
#   3. Access shell: docker exec -it unit3d-upload-checker bash
#
# Running standalone:
#   docker run -it --rm \
#     -v ./data:/data:ro \
#     -v ./config:/app/data:rw \
#     -v ./outputs:/app/outputs:rw \
#     -e TMDB_API_KEY=your_key \
#     -e MEDIA_DIR=/data \
#     unit3d-checker
#
# Common commands inside container:
#   python3 check.py run-all -v          # Run complete workflow
#   python3 check.py scan -v             # Scan directories only
#   python3 check.py tmdb -v             # Search TMDB
#   python3 check.py search -v           # Search trackers
#   python3 check.py setting -t dir      # View directory settings
#   python3 check.py setting-add -t dir -s /path  # Add directory
#
# =============================================================================
