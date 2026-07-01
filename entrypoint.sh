#!/usr/bin/env bash

set -ex

readonly SDK_VERSION=${SDK_VERSION:-34}
readonly EMULATOR_ARCH=${EMULATOR_ARCH:-x86_64}
readonly EMULATOR_PORT=${EMULATOR_PORT:-5554}

# Start emulator in background (uses ENV variables: SDK_VERSION, EMULATOR_PORT, GRPC_PORT, WINDOW)
./run_emulator.sh &
EMULATOR_PID=$!

# Wait for emulator to boot
echo "Waiting for emulator to boot..."
DEVICE_SERIAL="emulator-${EMULATOR_PORT}"

for i in {1..180}; do
    BOOT_COMPLETED=$(adb -s ${DEVICE_SERIAL} shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
    if [[ "$BOOT_COMPLETED" == "1" ]]; then
        echo "Emulator booted successfully!"
        break
    fi
    echo "Waiting for boot... ($i/180)"
    sleep 1
done

# Add ADB key to emulator (skip "Allow USB debugging?" prompt)
if [[ -f /root/.android/adbkey.pub ]]; then
    echo "Adding ADB key to emulator..."
    adb -s ${DEVICE_SERIAL} root 2>/dev/null || true
    sleep 2
    adb -s ${DEVICE_SERIAL} shell "mkdir -p /data/misc/adb && cat >> /data/misc/adb/adb_keys" < /root/.android/adbkey.pub 2>/dev/null || true
    adb -s ${DEVICE_SERIAL} unroot 2>/dev/null || true
    echo "ADB key added."
fi

# Disable "Viewing full screen" dialog
adb -s ${DEVICE_SERIAL} shell settings put secure immersive_mode_confirmations confirmed 2>/dev/null || true

# Keep container running
wait $EMULATOR_PID
