# Android Emulator with NVIDIA GPU + WebRTC

Android emulator in Docker with hardware GPU acceleration (NVIDIA) and WebRTC streaming to the browser.

## Prerequisites

- **Docker** 20.10+ with the NVIDIA Container Toolkit
- **NVIDIA driver**
- **KVM** enabled (`/dev/kvm` accessible — required for `-gpu host`)

```bash
# Install the toolkit, then verify GPU access from a container
sudo apt install nvidia-container-toolkit && sudo systemctl restart docker
docker run --rm --gpus all nvidia/cuda:11.0.3-base-ubuntu20.04 nvidia-smi
```

## Build

Nothing is published to a registry — you build both images yourself and pick your own tags. The examples use `android-emulator:headless` (base) and `android-emulator:webrtc` (WebRTC UI).

```bash
# 1. Base headless image (Android SDK + emulator + GPU)
docker build -t android-emulator:headless -f Dockerfile.emulator .

# 2. React WebRTC UI (must be built before the image below)
cd webrtc/emulator-demo && npm run build && cd ../..

# 3. WebRTC image (Envoy + nginx + UI) — pass the base tag via BASE_IMAGE
docker build \
  --build-arg BASE_IMAGE=android-emulator:headless \
  -t android-emulator:webrtc \
  -f Dockerfile.headless_webrtc_envoy .
```

## Run (local)

```bash
# IMAGE = the WebRTC image you built above
IMAGE=android-emulator:webrtc ./run-emulators-local.sh 4
```

Open each emulator in the browser — `?port=` is the Envoy port:

```
http://localhost:3000?port=8080
http://localhost:3001?port=8081
...
```

## Run on AWS (multiple GPUs)

```bash
# Optional: move Docker's data dir to NVMe if the root disk is small
sudo systemctl stop docker containerd
sudo mv /var/lib/docker /opt/dlami/nvme/docker && sudo ln -s /opt/dlami/nvme/docker /var/lib/docker
sudo mv /var/lib/containerd /opt/dlami/nvme/containerd && sudo ln -s /opt/dlami/nvme/containerd /var/lib/containerd
sudo systemctl start containerd docker

# Start an X server across all GPUs
sudo nvidia-xconfig --enable-all-gpus --allow-empty-initial-configuration -o /etc/X11/xorg.conf
sudo Xorg :99 & export DISPLAY=:99

# Run — the script spreads emulators across GPUs
IMAGE=android-emulator:webrtc ./run-emulators-aws.sh 16
```

To reach the UIs on a remote host, forward the ports over SSH (`~/.ssh/config`):

```
Host emu-aws
    HostName <AWS_IP>
    User ubuntu
    LocalForward 3000 localhost:3000
    LocalForward 8080 localhost:8080
    # ...one pair per emulator
```

## Install & launch an APK on all emulators

```bash
COUNT=16
for i in $(seq 1 $COUNT); do
  PORT=$((5552 + i*2))
  docker cp MyApp.apk android-emu-$i:/tmp/
  docker exec android-emu-$i adb -s emulator-$PORT install /tmp/MyApp.apk
  docker exec android-emu-$i adb -s emulator-$PORT shell am start -n com.example.app/.MainActivity
done
```

## Ports

Each emulator gets a unique set of ports:

| Emulator | ADB | gRPC | Envoy | Nginx (UI) |
|----------|-----|------|-------|------------|
| 1 | 5554 | 8554 | 8080 | 3000 |
| 2 | 5556 | 8555 | 8081 | 3001 |
| N | 5552+N*2 | 8553+N | 8079+N | 2999+N |

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `IMAGE` | — | WebRTC image tag to run (required by the run scripts) |
| `WINDOW` | `false` | `true` = GUI, `false` = headless |
| `DISPLAY` | `:0` | X11 display |
| `EMULATOR_PORT` | `5554` | ADB port |
| `GRPC_PORT` | `8554` | Emulator gRPC port |
| `ENVOY_PORT` | `8080` | Envoy proxy port |
| `NGINX_PORT` | `3000` | WebRTC UI port |

## Useful commands

```bash
# Stop and remove all emulators
docker rm -f $(docker ps -aq --filter "name=android-emu")

# Follow logs
docker logs -f android-emu-1

# Confirm the GPU is used (not SwiftShader)
docker logs android-emu-1 2>&1 | grep "Graphics Adapter"
# NVIDIA GeForce ... = GPU OK   |   SwiftShader ... = software rendering
```

## Notes

- GPU mode uses `-gpu host` / `hw.gpu.mode=host` and needs a running X server.
- Each emulator uses ~1 GB VRAM, 4 CPU cores, 12 GB RAM.
- Built on Ubuntu 20.04 (not tested on 22.04+); `LD_PRELOAD` applies an XInitThreads fix for a libxcb threading crash.

## License

[MIT](LICENSE) © x-kpanik
