#!/bin/bash
# AWS launch script for multiple emulators with Xorg
# Usage: ./run-emulators-aws.sh [count]

COUNT="${1:-8}"
# The WebRTC image you built yourself (see README "Build from Source"), e.g.:
#   IMAGE=android-emulator:webrtc ./run-emulators-aws.sh 16
IMAGE="${IMAGE:?Set IMAGE to the WebRTC image you built — see README 'Build from Source'}"

echo "Starting $COUNT emulators"

for i in $(seq 1 $COUNT); do
  GPU_ID=$(( (i - 1) % 8 ))
  
  docker rm -f android-emu-$i 2>/dev/null || true
  
  echo "Emulator $i: GPU=$GPU_ID, DISPLAY=:99.$GPU_ID"
  
  EMULATOR_PORT=$((5552 + i*2))
  
  docker run -d --gpus all --device /dev/kvm --network host \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=:99.$GPU_ID \
    -e WINDOW=false \
    -e GRPC_PORT=$((8553 + i)) \
    -e ENVOY_PORT=$((8079 + i)) \
    -e ENVOY_ADMIN_PORT=$((8000 + i)) \
    -e EMULATOR_PORT=$EMULATOR_PORT \
    -e NGINX_PORT=$((2999 + i)) \
    -e ANDROID_SERIAL=emulator-$EMULATOR_PORT \
    --cpus 4 --memory 12g \
    --restart=unless-stopped \
    --name android-emu-$i \
    $IMAGE
  
  sleep 10
done

echo "WebRTC UI:"
for i in $(seq 1 $COUNT); do
  echo "  Emulator $i: http://localhost:$((2999 + i))?port=$((8079 + i))"
done

