# CARLA Test Run Instructions
# testing with Christain (delte later this comment)
## Manual Run (Direct Command)

1. Go to project folder on GPU server.

```bash
cd ~/shahid_carla
```

2. Run test in Python 3.8 container (CARLA client 0.9.14).

```bash
podman run --rm --network host -v "$PWD":/work -w /work docker.io/python:3.8-slim bash -lc '
python -m pip install --no-cache-dir carla==0.9.14 &&
python /work/test_carla.py
'
```

## Automatic Run (Recommended)

1. Make script executable (first time only).

```bash
chmod +x run_carla_test.sh
```

2. Run everything with one command.

```bash
./run_carla_test.sh test_carla.py
```

What the script does automatically:
- Starts CARLA simulator container if needed.
- Waits until CARLA is reachable on `127.0.0.1:2000`.
- Runs your Python test in a Python 3.8 container with `carla==0.9.14`.
- Returns pass/fail exit code for CI/CD.

## GitHub Actions Setup (Automatic CI)

## Self-hosted Runner Notes (Final Architecture)

### Why a Self-hosted Runner Was Used

- GitHub-hosted runner could not reach the GPU server over SSH (network timeout).
- The GPU server is reachable only from internal/VPN network.
- CARLA simulation requires direct GPU and local Podman access on that machine.
- Running Actions directly on the GPU server removes SSH/SCP network dependency.

### What Changed in CI

- Workflow execution changed from `ubuntu-latest` + SSH/SCP to `runs-on: self-hosted`.
- Test is executed directly by the runner on hydra:

```bash
./run_carla_test.sh test_carla.py
```

- No remote copy step is required in the final setup.

### Self-hosted Runner Setup Steps Used

1. On hydra, download and extract GitHub runner package.
2. Configure runner with repository URL and registration token.
3. Accept default labels (`self-hosted`, `Linux`, `X64`).
4. Start runner with `./run.sh` and verify `Listening for Jobs`.
5. Push workflow update from local repository.
6. Confirm Actions job is picked by the self-hosted runner and succeeds.

### Operational Recommendation

- Keep runner as a system service to survive terminal close/reboot.

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

- If a registration token is exposed in logs/chat, regenerate it in GitHub.

## Runner Daily Steps on Hydra

1. Go to runner folder.

```bash
cd /home/carlactions/shahid_carla/actions-runner
```

2. Confirm you are in the correct place.

```bash
pwd
ls -l
```

Expected files include: `run.sh`, `svc.sh`, `_work`, `_diag`.

3. Start runner in foreground (temporary/manual).

```bash
./run.sh
```

Keep terminal open. Stop with `Ctrl+C`.

4. After local push to `main`.

- GitHub Actions should auto-trigger.
- Runner on hydra picks the job from queue.
- Job runs `run_carla_test.sh` and reports pass/fail.