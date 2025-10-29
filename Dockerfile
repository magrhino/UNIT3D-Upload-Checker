# syntax=docker/dockerfile:1
FROM python:3.11-slim AS base

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Install system dependencies required by pymediainfo
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libmediainfo0v5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Ensure expected folders exist for runtime state
RUN mkdir -p data outputs

ENTRYPOINT ["python", "check.py"]
CMD ["--help"]
