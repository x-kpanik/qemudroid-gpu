#!/bin/bash
set -euo pipefail

# Docker ENV params
SDK_VERSION="${SDK_VERSION:-34}"
AVD_NAME="emulator_${SDK_VERSION}"
EMULATOR_PORT="${EMULATOR_PORT:-5554}"
GRPC_PORT="${GRPC_PORT:-8554}"           # gRPC/WebRTC ports
ENABLE_GRPC="${ENABLE_GRPC:-true}"       # true = enable gRPC, false = без gRPC
WINDOW="${WINDOW:-true}"                 # true = GUI, false = headless

# Base emulator args
EMULATOR_ARGS=(
  -avd "${AVD_NAME}"
  -port "${EMULATOR_PORT}"
  -no-snapshot
  -no-boot-anim
  -partition-size 2048
)

# GPU mode (host by default)
GPU_MODE="${GPU_MODE:-host}"

# GUI/headless mode
if [ "${WINDOW}" = "true" ]; then
  # GUI
  EMULATOR_ARGS+=(
    -gpu "${GPU_MODE}"
  )
else
  # Headless
  EMULATOR_ARGS+=(
    -no-window
    -gpu "${GPU_MODE}"
    -no-audio
  )
fi

# Enable gRPC-server(for WebRTC)
if [ "${ENABLE_GRPC}" = "true" ]; then
  EMULATOR_ARGS+=(
    -grpc ${GRPC_PORT}
  )
fi

cd /opt/android-sdk/emulator

echo "Запускаю emulator с аргументами: ${EMULATOR_ARGS[*]}"
# "no" answers the usage statistics prompt automatically
echo "no" | ./emulator "${EMULATOR_ARGS[@]}"
