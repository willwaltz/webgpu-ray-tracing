# WebGPU hardware ray tracing for Chromium

Patches that add hardware ray tracing to WebGPU in Chromium-based browsers: acceleration
structures, and ray queries in WGSL, on Dawn's Vulkan backend (`VK_KHR_acceleration_structure`
and `VK_KHR_ray_query`). Made for [Globes](https://github.com/willwaltz/globes), and built and
used with Brave 1.97.59 (Chromium 155.0.8059.85) on Linux with an NVIDIA RTX 4090.

> [!WARNING]
> This is an experiment, not a browser for everyday use. It gives web pages raw GPU ray tracing
> and hasn't been hardened against hostile pages. The browser offers it only to the origins you
> list when you launch it: list only pages you trust, and keep it in a profile of its own.

## What it adds

**To JavaScript**, on a device created with the `chromium-experimental-ray-query` feature:

- `GPUAccelerationStructure`, made with `device.createAccelerationStructure()`
- `encoder.buildAccelerationStructure()`, for bottom levels (triangles or boxes) and top levels
  (instances)
- `queue.writeAccelerationStructureInstances()`
- acceleration structures in bind groups and their layouts
- `GPUBufferUsage.ACCELERATION_STRUCTURE_INPUT`

TypeScript declarations for all of it: [`types/webgpu-rt.d.ts`](types/webgpu-rt.d.ts).

**To WGSL:** `enable chromium_experimental_ray_query;`, the `acceleration_structure` and
`ray_query` types, and the ray query built-ins, compiled to SPIR-V ray queries.

For working code, see Globes' [`src/rt`](https://github.com/willwaltz/globes/tree/main/src/rt)
and [`rt_regions.wgsl`](https://github.com/willwaltz/globes/blob/main/src/sim/shaders/rt_regions.wgsl).

## What's in the patches

[`patches/dawn.patch`](patches/dawn.patch), 173 files, for `third_party/dawn` (Dawn is
Chromium's WebGPU, and Tint its shader compiler):

- the API in `dawn.json`: acceleration structures, their builds and instances, the binding type
  and the buffer usage;
- acceleration structures and their builds in the Vulkan backend (the other backends only gain
  unreachable stubs for the new binding type: the feature is Vulkan-only);
- the wire, between the renderer and the GPU process;
- Tint's WGSL extension, compiled to SPIR-V ray queries.

[`patches/chromium.patch`](patches/chromium.patch), 34 files:

- the switch `--webgpu-ray-query-origins`, passed on to the GPU and renderer processes;
- the GPU process exposes the feature only when the switch is there;
- Blink's API, as above;
- the adapter offers the feature only to the origins the switch lists;
- headless mode runs WebGPU on Vulkan too, so automated tests get the GPU's own adapter.

The Chromium patch is made against Brave's tree (Chromium's sources with Brave's own patches
applied). Brave patches five of the same files, on different lines. It hasn't been tried on
plain Chromium.

## Building Brave with it

1. Get Brave's source at tag `v1.97.59` and set up its build as Brave's own instructions describe
   (here: [brave-core](https://github.com/brave/brave-core) checked out into `src/brave`, then its
   `init`, which fetches Chromium into `src`).
2. Apply the patches: `scripts/apply.sh <path to src>`
3. Build as usual. Here it was a release build from `src/brave`:
   `pnpm run build Static --gn=symbol_level:0`, about 80 minutes.

Brave's sync puts Chromium's files back, which takes the patches out: run `scripts/apply.sh`
again after each sync. It says so if they're in already.

If the build's TypeScript step fails on type definitions from a `node_modules` folder above the
source tree (one in your home directory, say), also apply
[`patches/optional/ts-library-skip-outside-definitions.patch`](patches/optional/ts-library-skip-outside-definitions.patch)
(`patch -p1 -d <path to src>`).

## Running it

```sh
BRAVE_SRC=<path to src> scripts/run-brave.sh [url]
RT_ORIGINS=http://localhost:5173,https://example.com BRAVE_SRC=<path to src> scripts/run-brave.sh
```

- **Vulkan.** The ray queries run on Vulkan, so the GPU process must use it
  (`--enable-features=Vulkan --use-angle=vulkan`).
- **XWayland on Linux** (`--ozone-platform=x11`): that's how Chromium's WebGPU reached the GPU in
  testing. Under XWayland without Vulkan it fell back to SwiftShader.
- **Its own profile**: `~/.config/brave-rt`, or `BRAVE_RT_PROFILE`.
- **Origins**: only those in `RT_ORIGINS` see the feature (by default `http://localhost:5173`,
  Vite's dev server).
- **A development build.** It isn't one of Brave's official builds, so anything that relies on
  keys or settings Brave supplies only to those may not work.

To check a page has it:
`(await navigator.gpu.requestAdapter()).features.has('chromium-experimental-ray-query')`.

## Porting to another version

Dawn changes with every Chromium release, so the patches won't apply as they are to a newer Brave
or Chromium. Port them by hand, build, then `scripts/export.sh <path to src>` writes the new
patches from the tree.

From Chromium 151 to 155, Blink also needed two changes of its own: `DawnObject::SetLabelImpl`
now takes a `std::string_view`, and 155's new `GPUResourceTable`, which switches over the
binding resource union, had to refuse acceleration structures.

## Results in Globes

The globe's render passes on an RTX 4090 at 1528×761, the same frozen frame traced in hardware
and in software:

| Globe | Hardware | Software |
| --- | --- | --- |
| Clear Water | 1.41 ms | 1.76 ms |
| Koi | 2.09 ms | 2.91 ms |
| Kelp Forest | 2.05 ms | 2.37 ms |
| Anemone Reef | 2.28 ms | 2.49 ms |

The images agree but for a handful of pixels. Rebuilding the regions the hardware searches
costs about 0.28 ms a frame. While the water churns in a hard shake the hardware is the slower,
so Globes traces in software until it calms.

## License

The patches change Chromium and Dawn, which are under BSD-style licenses; the files they add
carry those projects' usual headers, so they could go upstream as they are. Everything here is
under the [BSD 3-Clause License](LICENSE), like them.
