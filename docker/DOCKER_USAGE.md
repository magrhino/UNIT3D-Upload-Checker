# UNIT3D Upload Checker – Docker Usage

Focused reference for day-to-day Docker commands once the container has already been configured via `setup.sh`.

## Container Lifecycle

- Build image (after editing Dockerfile or requirements):
  ```bash
  docker-compose build
  ```
- Start services in background:
  ```bash
  docker-compose up -d
  ```
- Stop and remove containers:
  ```bash
  docker-compose down
  ```
- Rebuild and restart after config changes:
  ```bash
  docker-compose up -d --build
  ```
- Follow logs:
  ```bash
  docker-compose logs -f
  ```
- Restart only the checker service:
  ```bash
  docker-compose restart unit3d-checker
  ```

## One-Time Setup & Reconfiguration

Run whenever `.env` changes (new API keys, directories, etc.):

```bash
docker run --rm -it \
  -v ./config:/app/data:rw \
  --env-file .env \
  unit3d-checker:latest \
  /app/scripts/setup.sh
```

## Working Inside the Container

- Open interactive shell:
  ```bash
  docker exec -it unit3d-upload-checker bash
  ```
- Inspect health status:
  ```bash
  docker inspect unit3d-upload-checker | grep -A 10 Health
  ```

## Application Commands (run inside container)

- Full workflow:
  ```bash
  python3 check.py run-all -v
  ```
- Individual stages:
  ```bash
  python3 check.py scan -v
  python3 check.py tmdb -v
  python3 check.py search -v
  python3 check.py save
  python3 check.py txt
  python3 check.py csv
  python3 check.py gg
  python3 check.py ua
  ```
- Settings management:
  ```bash
  python3 check.py setting -t dir
  python3 check.py setting-add -t dir -s /data
  python3 check.py setting-rm -t dir
  python3 check.py clear-data
  ```

## Workflow Example

```bash
docker-compose up -d
docker exec -it unit3d-upload-checker bash
python3 check.py setting -t sites
python3 check.py run-all -v
ls -lh /app/outputs/
cat /app/outputs/fearnopeer_uploads.txt
```

Use this file as a quick command cheat sheet; configuration details live in `SETUP_GUIDE.md`.
