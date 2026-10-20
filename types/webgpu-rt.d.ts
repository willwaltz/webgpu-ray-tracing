// Types for the non-standard hardware ray tracing API these patches add to Chromium (the
// "chromium-experimental-ray-query" feature: Dawn's acceleration structures and WGSL's
// `enable chromium_experimental_ray_query;`). Mirrors the Blink IDL
// (third_party/blink/renderer/modules/webgpu/gpu_acceleration_structure*.idl).

export {};

declare global {
  type GPUAccelerationStructureType = 'bottom-level' | 'top-level';
  type GPUAccelerationStructureGeometryType = 'triangles' | 'aabbs';
  type GPUAccelerationStructureBuildMode = 'build' | 'update';

  interface GPUAccelerationStructure extends GPUObjectBase {
    readonly __brand: 'GPUAccelerationStructure';
    readonly type: GPUAccelerationStructureType;
    destroy(): undefined;
  }

  interface GPUAccelerationStructureGeometryLayout {
    type: GPUAccelerationStructureGeometryType;
    /** GPUAccelerationStructureGeometryFlag bits (OPAQUE 1, NO_DUPLICATE_ANY_HIT 2). */
    flags?: number;
    vertexFormat?: GPUVertexFormat;
    maxVertexCount?: number;
    indexFormat?: GPUIndexFormat;
    maxPrimitiveCount: number;
  }

  interface GPUAccelerationStructureDescriptor extends GPUObjectDescriptorBase {
    type: GPUAccelerationStructureType;
    /** GPUAccelerationStructureFlag bits (ALLOW_UPDATE 1, PREFER_FAST_TRACE 2, PREFER_FAST_BUILD 4,
     *  LOW_MEMORY 8); PREFER_FAST_TRACE if left out. */
    flags?: number;
    geometries?: GPUAccelerationStructureGeometryLayout[];
    maxInstanceCount?: number;
  }

  interface GPUAccelerationStructureGeometryData {
    vertexBuffer?: GPUBuffer;
    vertexOffset?: number;
    vertexStride?: number;
    vertexCount?: number;
    indexBuffer?: GPUBuffer;
    indexOffset?: number;
    aabbBuffer?: GPUBuffer;
    aabbOffset?: number;
    aabbStride?: number;
    primitiveCount: number;
  }

  interface GPUAccelerationStructureBuildDescriptor {
    destination: GPUAccelerationStructure;
    mode?: GPUAccelerationStructureBuildMode;
    geometries?: GPUAccelerationStructureGeometryData[];
    instanceCount?: number;
  }

  interface GPUAccelerationStructureBindingLayout {}

  interface GPUBindGroupLayoutEntry {
    accelerationStructure?: GPUAccelerationStructureBindingLayout;
  }

  interface GPUDevice {
    createAccelerationStructure(descriptor: GPUAccelerationStructureDescriptor): GPUAccelerationStructure;
  }

  interface GPUCommandEncoder {
    buildAccelerationStructure(descriptor: GPUAccelerationStructureBuildDescriptor): undefined;
  }

  interface GPUQueue {
    /** Writes 64-byte instance records into a top-level structure's instance table from
     *  `firstInstance` on. Each: a 3x4 transform (f32, row by row), then four u32s: the index of
     *  its bottom level in `blases`; 24 bits the shader reads as
     *  `RayIntersection.instance_custom_data`, with the visibility mask in the top 8 (a ray sees
     *  the instance where its `cull_mask` and this share a bit); and two words left 0. */
    writeAccelerationStructureInstances(
      destination: GPUAccelerationStructure,
      firstInstance: number,
      blases: GPUAccelerationStructure[],
      data: ArrayBufferView,
    ): undefined;
  }
}
