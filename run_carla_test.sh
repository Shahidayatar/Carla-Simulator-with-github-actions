#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   ./run_carla_test.sh [test_script]
# Example:
#   ./run_carla_test.sh test_carla.py

CARLA_CONTAINER="${CARLA_CONTAINER:-carla-sim}"
CARLA_IMAGE="${CARLA_IMAGE:-docker.io/carlasim/carla:0.9.14}"
CLIENT_IMAGE="${CLIENT_IMAGE:-docker.io/python:3.8-slim}"
CARLA_HOST="${CARLA_HOST:-127.0.0.1}"
CARLA_PORT="${CARLA_PORT:-2000}"
START_SIMULATOR="${START_SIMULATOR:-1}"

TEST_SCRIPT="${1:-test_carla.py}"
WORKDIR="$(pwd)"

log() {
  printf '[carla-runner] %s\n' "$*"
}

ensure_test_script_exists() {
  if [[ ! -f "$WORKDIR/$TEST_SCRIPT" ]]; then
    log "Test script not found: $WORKDIR/$TEST_SCRIPT"
    exit 1
  fi
}

start_simulator_if_needed() {
  if [[ "$START_SIMULATOR" != "1" ]]; then
    log "Skipping simulator startup (START_SIMULATOR=$START_SIMULATOR)."
    return
  fi

  if podman ps --format '{{.Names}}' | grep -Fxq "$CARLA_CONTAINER"; then
    log "Simulator container '$CARLA_CONTAINER' is already running."
    return
  fi

  if podman ps -a --format '{{.Names}}' | grep -Fxq "$CARLA_CONTAINER"; then
    log "Removing old container '$CARLA_CONTAINER'."
    podman rm -f "$CARLA_CONTAINER" >/dev/null
  fi

  log "Starting simulator container '$CARLA_CONTAINER' from $CARLA_IMAGE"
  podman run -d \
    --name "$CARLA_CONTAINER" \
    --replace \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    -p 2000:2000 -p 2001:2001 -p 2002:2002 \
    "$CARLA_IMAGE" \
    /bin/bash -lc "./CarlaUE4.sh -RenderOffScreen -opengl -nosound -quality-level=Low" >/dev/null
}

run_test_in_client_container() {
  log "Running $TEST_SCRIPT inside $CLIENT_IMAGE with carla==0.9.14"

  podman run --rm \
    --network host \
    -v "$WORKDIR:/work" \
    -w /work \
    "$CLIENT_IMAGE" \
    bash -lc "
      set -Eeuo pipefail
      python -m pip install --no-cache-dir -q carla==0.9.14

      python - <<'PY'
import sys
import time
import carla

host = '${CARLA_HOST}'
port = int('${CARLA_PORT}')
last_err = None

for attempt in range(1, 61):
    try:
        client = carla.Client(host, port)
        client.set_timeout(2.0)
        world = client.get_world()
        print(f'Ready: connected to {world.get_map().name} on {host}:{port}')
        sys.exit(0)
    except Exception as exc:
        last_err = exc
        print(f'Waiting for CARLA ({attempt}/60): {exc}')
        time.sleep(2)

print(f'ERROR: CARLA did not become ready in time: {last_err}')
sys.exit(1)
PY

      python '$TEST_SCRIPT'
    "
}

main() {
  ensure_test_script_exists
  start_simulator_if_needed
  run_test_in_client_container
  log "Done."
}

main
