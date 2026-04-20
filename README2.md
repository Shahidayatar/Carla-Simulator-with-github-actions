# CARLA Simulator Podman Setup - For Christian's group

## Quick Start

Login to Hydra Server
### 1. Check Container Status
```bash
podman ps
```
This shows all running containers. If you see `carla-sim` listed, it's running.

### 2. Run the CARLA Container
```bash
podman run -d --name carla-sim --security-opt=label=disable --device nvidia.com/gpu=all -p 2000:2000 -p 2001:2001 -p 2002:2002 docker.io/carlasim/carla:0.9.14 /bin/bash -lc "./CarlaUE4.sh -RenderOffScreen -opengl -nosound -quality-level=Low"
```

**Flags explained:**
- `-d` — Run in detached mode (background)
- `--name carla-sim` — Container name
- `--security-opt=label=disable` — Disable SELinux constraints
- `--device nvidia.com/gpu=all` — Enable GPU access
- `-p 2000:2000 -p 2001:2001 -p 2002:2002` — Expose ports
- `RenderOffScreen` — Headless mode (no GUI)
- `-quality-level=Low` — Reduce resource usage

## Troubleshooting

### Error: "unmounting overlay: invalid argument"

If you get this error when starting the container:
```
Error: removing storage for container "carla-sim": unmounting 
"/home/carlactions/.local/share/containers/storage/overlay/..." invalid argument
```

**Fix it:**

1. **Remove stale container files:**
   ```bash
   rm -rf ~/.local/share/containers/storage/overlay-containers/*
   ```

2. **Clean up Podman storage (optional but recommended):**
   ```bash
   podman system prune -a --volumes
   ```

3. **Try running the container again:**
   ```bash
   podman run -d --name carla-sim --security-opt=label=disable --device nvidia.com/gpu=all -p 2000:2000 -p 2001:2001 -p 2002:2002 docker.io/carlasim/carla:0.9.14 /bin/bash -lc "./CarlaUE4.sh -RenderOffScreen -opengl -nosound -quality-level=Low"
   ```

### Check Container Logs
```bash
podman logs carla-sim
```

### Stop the Container
```bash
podman stop carla-sim
```

### Remove the Container
```bash
podman rm carla-sim
```

## Ports
- **2000** — CARLA server (default)
- **2001** — Traffic Manager
- **2002** — Additional connections

Connect to the simulator at `localhost:2000` or the remote host's IP.
