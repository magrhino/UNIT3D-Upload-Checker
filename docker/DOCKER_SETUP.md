# UNIT3D Upload Checker - Docker Setup Guide

Run these commands from the `docker/` directory. From the repository root, add
`-f docker/docker-compose.yml` to compose commands.

## Quick Start

```bash
git clone https://github.com/magrhino/UNIT3D-Upload-Checker.git
cd UNIT3D-Upload-Checker/docker

cp .env.example .env
nano .env

docker compose build
docker compose --profile setup run --rm setup
docker compose up -d
docker exec -it unit3d-upload-checker bash
python3 check.py run-all -v
```

After setup, configuration persists in `./config/settings.json`. Re-run setup
whenever `.env` changes:

```bash
docker compose --profile setup run --rm setup
```

## Configuration

Set these values in `docker/.env`:

```bash
HOST_MEDIA_DIR=/path/to/your/media
CONTAINER_MEDIA_DIR=/data
MEDIA_DIR=/data

TMDB_API_KEY=your_tmdb_api_key_here
SITES_ENABLED=fnp,ras,hhd

FNP_API_KEY=your_fearnopeer_key
RAS_API_KEY=your_rastastugan_key
HHD_API_KEY=your_homiehelpdesk_key
BLU_API_KEY=your_blutopia_key
AITH_API_KEY=your_aither_key
RFX_API_KEY=your_reelflix_key
LST_API_KEY=your_lst_key
OE_API_KEY=your_onlyencodes_key
UPLOADCX_API_KEY=your_uploadcx_key

GG_PATH=/path/to/gg-bot-upload-assistant
UA_PATH=/path/to/upload-assistant
```

`HOST_MEDIA_DIR` is the host path. `CONTAINER_MEDIA_DIR` is where that one
host path is mounted in the container. `MEDIA_DIR` is what the checker saves in
settings, so it must use container paths.

The compose file works out of the box for one media root. If you have multiple
unrelated host roots, add each extra bind mount once in `docker-compose.yml`,
then set `MEDIA_DIR` to the matching comma-separated container paths, such as:

```yaml
volumes:
  - /mnt/movies:/media/movies:ro
  - /mnt/tv:/media/tv:ro
```

```bash
MEDIA_DIR=/media/movies,/media/tv
```

## How The Docker Workflow Works

- `docker-compose.yml` defines both services. `unit3d-checker` is the runtime
  container, and `setup` is a profiled one-shot service.
- `setup` runs `/app/scripts/setup.sh`, reads `.env`, validates keys and media
  paths, and writes `./config/settings.json`.
- `unit3d-checker` starts with a passive entrypoint. It reports current config
  status and opens a shell; it does not reapply `.env` changes.
- The runtime healthcheck is import-only and intentionally does not import
  `settings.py`, because settings initialization can write `settings.json`.
- `./config` maps to `/app/data`, and `./outputs` maps to `/app/outputs`.

The image runs as UID/GID `1000`. On Linux, if bind-mounted `config` or
`outputs` directories are not writable, create or chown them on the host:

```bash
mkdir -p config outputs data
sudo chown -R 1000:1000 config outputs
```

## Common Commands

```bash
docker compose build
docker compose --profile setup run --rm setup
docker compose up -d
docker compose logs -f
docker compose restart unit3d-checker
docker compose down
```

Inside the container:

```bash
python3 check.py run-all -v
python3 check.py scan -v
python3 check.py tmdb -v
python3 check.py search -v
python3 check.py save
python3 check.py txt
python3 check.py csv
python3 check.py gg
python3 check.py ua
```

## Troubleshooting

If setup fails:

1. Check `.env` syntax. Use `KEY=value` with no spaces around `=`.
2. Verify `HOST_MEDIA_DIR` exists on the host.
3. Verify `MEDIA_DIR` uses paths mounted inside the container.
4. Verify API keys on TMDB or tracker websites.
5. Re-run `docker compose --profile setup run --rm setup`.

If the runtime container says no configuration exists, run setup first:

```bash
docker compose --profile setup run --rm setup
```

If manual configuration is needed:

```bash
docker compose up -d
docker exec -it unit3d-upload-checker bash
python3 check.py setting-add -t tmdb -s YOUR_TMDB_KEY
python3 check.py setting-add -t dir -s /data
python3 check.py setting-add -t fnp -s YOUR_FNP_KEY
python3 check.py setting-add -t sites -s fnp
```

View current configuration:

```bash
docker exec -it unit3d-upload-checker bash
python3 check.py setting -t tmdb
python3 check.py setting -t dir
python3 check.py setting -t sites
cat /app/data/settings.json
```
