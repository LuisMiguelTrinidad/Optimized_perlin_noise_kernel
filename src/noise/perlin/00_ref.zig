// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright (c) 2026 Luis Miguel Trinidad Salvador
const table = @import("../../core/f32/table.zig");

const hash = @import("../../core/shared/hash.zig");
const math = @import("../../core/shared/math.zig");

const mode_meta = @import("mode_meta.zig");

pub const RequiredAlignment: u29 = @alignOf(f32);
pub const sample_kind: mode_meta.SampleKind = .f32;

pub inline fn perlin_prepare_cached_values(
  values_buf: []f32,
  smoothed_buf: []f32,
  comptime chunk_size: u64,
  comptime scale: u64
) void {

  comptime {
    _ = chunk_size;
    if ((@popCount(scale) != 1)) {
      @compileError("O0 requires SCALE to be a power of two");
    }
  }
  _ = values_buf;
  _ = smoothed_buf;
}

pub fn perlin_generate_chunk2d(
  seed: u64,
  comptime chunk_size: u64,
  comptime scale: u64,
  cached_values: []const f32,
  cached_smoothed_values: []const f32,
  world_x: i64,
  world_y: i64,
  out_buffer: []f32,
) !void {
  _ = cached_values;
  _ = cached_smoothed_values;

  const cs_u: u64 = chunk_size;
  const cs_i: i64 = @as(i64, @intCast(chunk_size));

  const sc_i: i64 = @as(i64, @intCast(scale));
  const sc_l: u6  = @as(u6, @intCast(@ctz(scale))); 
  const sc_inv_f: f32 = 1.0 / @as(f32, @floatFromInt(sc_i));

  const arr_world_base_x_i: i64 = world_x;
  const arr_world_base_y_i: i64 = world_y;

  for (0..cs_u) |y| {
    const arr_local_y_i: i64 = cs_i - @as(i64, @intCast(y)) - 1;
    const arr_world_y_i: i64 = arr_world_base_y_i + arr_local_y_i;
        
    const noise_local_y_f: f32 = math.fast_fract(@as(f32, @floatFromInt(arr_world_y_i)) * sc_inv_f);

    const noise_grid_y0_i: i64 = arr_world_y_i >> sc_l;
    const noise_grid_y1_i: i64 = noise_grid_y0_i + 1;

    const row_off_u: u64 = y * cs_u;
    for (0..cs_u) |x| {
      const arr_world_x_i: i64 = arr_world_base_x_i + @as(i64, @intCast(x));
            
      const noise_local_x_f: f32 = math.fast_fract(@as(f32, @floatFromInt(arr_world_x_i)) * sc_inv_f);

      const noise_grid_x0_i: i64 = arr_world_x_i >> sc_l;
      const noise_grid_x1_i: i64 = noise_grid_x0_i + 1;

      const g00: [2]f32 = table.grad[hash.rapidhashnano_no_init(seed, @bitCast(noise_grid_x0_i), @bitCast(noise_grid_y0_i)) & table.grad_mask];
      const g10: [2]f32 = table.grad[hash.rapidhashnano_no_init(seed, @bitCast(noise_grid_x1_i), @bitCast(noise_grid_y0_i)) & table.grad_mask];
      const g01: [2]f32 = table.grad[hash.rapidhashnano_no_init(seed, @bitCast(noise_grid_x0_i), @bitCast(noise_grid_y1_i)) & table.grad_mask];
      const g11: [2]f32 = table.grad[hash.rapidhashnano_no_init(seed, @bitCast(noise_grid_x1_i), @bitCast(noise_grid_y1_i)) & table.grad_mask];

      const d00: f32 = math.dot_prod_2d(g00[0], g00[1], noise_local_x_f, noise_local_y_f);
      const d10: f32 = math.dot_prod_2d(g10[0], g10[1], noise_local_x_f - 1.0, noise_local_y_f);
      const d01: f32 = math.dot_prod_2d(g01[0], g01[1], noise_local_x_f, noise_local_y_f - 1.0);
      const d11: f32 = math.dot_prod_2d(g11[0], g11[1], noise_local_x_f - 1.0, noise_local_y_f - 1.0);

      const x_smooth = math.smooth_step(noise_local_x_f);
      const y_smooth = math.smooth_step(noise_local_y_f);

      const value = math.lerp(
        math.lerp(d00, d10, x_smooth),
        math.lerp(d01, d11, x_smooth),
				y_smooth
      );

      out_buffer[row_off_u + x] = value;
    }
  }
}