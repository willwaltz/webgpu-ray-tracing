#!/usr/bin/env bash
# Writes the WebGPU ray tracing changes in a Brave source tree (brave-browser's src) as patches:
#   patches/chromium.patch: Chromium's files, against the tree as Brave's sync leaves it
#     (Chromium's tagged sources with Brave's own patches, brave/patches, applied);
#   patches/dawn.patch: Dawn's, with paths from Dawn's own root (third_party/dawn).
#   scripts/export.sh <path to src>
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
src=$(realpath "${1:?usage: scripts/export.sh <path to the Chromium src directory>}")

chromium=(
  # The switch (--webgpu-ray-query-origins), and where it is passed on.
  gpu/config/gpu_switches.h
  gpu/config/gpu_switches.cc
  content/browser/gpu/gpu_process_host.cc
  content/browser/renderer_host/render_process_host_impl.cc
  # The GPU process exposes the feature with it.
  gpu/command_buffer/service/webgpu_decoder_impl.cc
  # Blink's API.
  third_party/blink/renderer/bindings/generated_in_modules.gni
  third_party/blink/renderer/bindings/idl_in_modules.gni
  third_party/blink/renderer/modules/webgpu/BUILD.gn
  third_party/blink/renderer/modules/webgpu/dawn_enum_conversions.cc
  third_party/blink/renderer/modules/webgpu/gpu_acceleration_structure.cc
  third_party/blink/renderer/modules/webgpu/gpu_acceleration_structure.h
  third_party/blink/renderer/modules/webgpu/gpu_acceleration_structure.idl
  third_party/blink/renderer/modules/webgpu/gpu_acceleration_structure_binding_layout.idl
  third_party/blink/renderer/modules/webgpu/gpu_acceleration_structure_build_descriptor.idl
  third_party/blink/renderer/modules/webgpu/gpu_acceleration_structure_descriptor.idl
  third_party/blink/renderer/modules/webgpu/gpu_adapter.cc
  third_party/blink/renderer/modules/webgpu/gpu_bind_group.cc
  third_party/blink/renderer/modules/webgpu/gpu_bind_group_entry.idl
  third_party/blink/renderer/modules/webgpu/gpu_bind_group_layout.cc
  third_party/blink/renderer/modules/webgpu/gpu_bind_group_layout_entry.idl
  third_party/blink/renderer/modules/webgpu/gpu_buffer_usage.idl
  third_party/blink/renderer/modules/webgpu/gpu_command_encoder.cc
  third_party/blink/renderer/modules/webgpu/gpu_command_encoder.h
  third_party/blink/renderer/modules/webgpu/gpu_command_encoder.idl
  third_party/blink/renderer/modules/webgpu/gpu_device.cc
  third_party/blink/renderer/modules/webgpu/gpu_device.h
  third_party/blink/renderer/modules/webgpu/gpu_device.idl
  third_party/blink/renderer/modules/webgpu/gpu_queue.cc
  third_party/blink/renderer/modules/webgpu/gpu_queue.h
  third_party/blink/renderer/modules/webgpu/gpu_queue.idl
  third_party/blink/renderer/modules/webgpu/gpu_resource_table.cc
  third_party/blink/renderer/modules/webgpu/gpu_supported_features.cc
  third_party/blink/renderer/modules/webgpu/gpu_supported_features.idl
  # Headless: WebGPU's Vulkan with GL interop, as on Wayland.
  ui/ozone/platform/headless/ozone_platform_headless.cc
)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
out="$root/patches/chromium.patch"
: >"$out"
for f in "${chromium[@]}"; do
  old="$tmp/old" label="a/$f"
  if git -C "$src" cat-file -e "HEAD:$f" 2>/dev/null; then
    git -C "$src" show "HEAD:$f" >"$old"
    bp="$src/brave/patches/$(tr / - <<<"$f").patch"
    [ -e "$bp" ] && patch -s --no-backup-if-mismatch "$old" <"$bp"
  else
    old=/dev/null label=/dev/null
  fi
  diff -u --label "$label" --label "b/$f" "$old" "$src/$f" >>"$out" || true
done

dawn="$src/third_party/dawn"
: >"$root/patches/dawn.patch"
git -C "$dawn" diff HEAD >>"$root/patches/dawn.patch"
git -C "$dawn" ls-files --others --exclude-standard | sort | while read -r f; do
  (cd "$dawn" && git diff --no-index -- /dev/null "$f") >>"$root/patches/dawn.patch" || true
done
echo "$(grep -c '^+++ ' "$out") files in chromium.patch, $(grep -c '^+++ ' "$root/patches/dawn.patch") in dawn.patch"
