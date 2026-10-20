#!/usr/bin/env bash
# Runs Brave built with these patches, with the switches its ray tracing needs. Only the origins
# in RT_ORIGINS (comma-separated) are offered the feature.
#
#   BRAVE_SRC=<path to src> scripts/run-brave.sh [extra switches] [url]
#   RT_ORIGINS=http://localhost:5173,https://example.com BRAVE_SRC=<path to src> scripts/run-brave.sh
#
# BRAVE_BIN: the browser itself (default: $BRAVE_SRC/out/Static/brave).
# BRAVE_RT_PROFILE: its profile (default: ~/.config/brave-rt, apart from any other).
#
# The ray queries run on Dawn's Vulkan backend, so the GPU process must use Vulkan (Vulkan, ANGLE
# on Vulkan). The window runs through XWayland: that is how Chromium's WebGPU reached the GPU in
# testing on Linux. With more than one GPU, VK_LOADER_DEVICE_ID_FILTER (the PCI device ID, such
# as 0x2684 for an RTX 4090) keeps the Vulkan loader to one.
set -euo pipefail
bin="${BRAVE_BIN:-${BRAVE_SRC:?set BRAVE_SRC to the Chromium src directory, or BRAVE_BIN to the browser}/out/Static/brave}"
exec "$bin" \
  --user-data-dir="${BRAVE_RT_PROFILE:-$HOME/.config/brave-rt}" \
  --no-first-run --no-default-browser-check \
  --enable-features=Vulkan --use-angle=vulkan --ignore-gpu-blocklist --ozone-platform=x11 \
  --webgpu-ray-query-origins="${RT_ORIGINS:-http://localhost:5173}" \
  "$@"
