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
			@compileError("O1 requires SCALE to be a power of two");
    }
  }

  for (0..scale) |i| {
    const if32: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(scale));
    values_buf[i] = if32;
    smoothed_buf[i] = math.smooth_step(if32);
  }
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
  const cs_u: u64 = chunk_size;
  const sc_u: u64 = scale;
  const sc_m: u64 = sc_u - 1;
  const sc_l: u6  = @as(u6, @intCast(@ctz(sc_u))); 
  
  const arr_world_base_x_i: i64 = world_x;
  const arr_world_base_y_i: i64 = world_y;

  const noise_grid_base_x_i: i64 = arr_world_base_x_i >> sc_l;
  const noise_grid_base_y_i: i64 = arr_world_base_y_i >> sc_l;
  
  const gps: usize = @as(usize, @intCast(@max(@as(u64, @intCast(cs_u >> sc_l)), @as(u64, 1)) + @as(u64, 1)));

  const arr_world_off_x_u: u64 = @as(u64, @bitCast(arr_world_base_x_i ))&sc_m;
  const arr_world_off_y_u: u64 = @as(u64, @bitCast(arr_world_base_y_i ))&sc_m;

  const min_dim: u64 = @min(cs_u, sc_u);

  for (0..(gps-1)) |gy| {
		const noise_local_tile_y_u: u64 = (gps - 1) - gy - 1;
		const arr_world_tile_y_u: u64 = noise_local_tile_y_u * sc_u;

		for (0..(gps-1)) |gx| {
			const arr_world_tile_x_u: u64 = gx * sc_u;

      const noise_grid_x0_i: i64 = noise_grid_base_x_i + @as(i64, @intCast(gx));
      const noise_grid_y0_i: i64 = noise_grid_base_y_i + @as(i64, @intCast(gy));
      const noise_grid_x1_i: i64 = noise_grid_x0_i + 1;
      const noise_grid_y1_i: i64 = noise_grid_y0_i + 1;

      const g00: [2]f32 = table.grad[hash.rapidhashnano_no_init(seed,@bitCast(noise_grid_x0_i), @bitCast(noise_grid_y0_i)) & table.grad_mask];
      const g10: [2]f32 = table.grad[hash.rapidhashnano_no_init(seed,@bitCast(noise_grid_x1_i), @bitCast(noise_grid_y0_i)) & table.grad_mask];
      const g01: [2]f32 = table.grad[hash.rapidhashnano_no_init(seed,@bitCast(noise_grid_x0_i), @bitCast(noise_grid_y1_i)) & table.grad_mask];
      const g11: [2]f32 = table.grad[hash.rapidhashnano_no_init(seed,@bitCast(noise_grid_x1_i), @bitCast(noise_grid_y1_i)) & table.grad_mask];

			for (0..min_dim) |ly| {
        const noise_local_y_u: u64 = min_dim - ly - 1;
        const noise_local_y_idx_u: u64 = (noise_local_y_u - arr_world_off_y_u) & sc_m;
        const noise_local_y_f: f32 = cached_values[noise_local_y_idx_u];

        const matrix_offset: u64 = arr_world_tile_x_u + (arr_world_tile_y_u + ly) * cs_u;

				for (0..min_dim) |lx| {
          const noise_local_x_idx_u: u64 = (lx + arr_world_off_x_u) & sc_m;
          const noise_local_x_f: f32 = cached_values[noise_local_x_idx_u];

          const d00: f32 = math.dot_prod_2d(g00[0], g00[1], noise_local_x_f, noise_local_y_f);
          const d10: f32 = math.dot_prod_2d(g10[0], g10[1], noise_local_x_f - 1.0, noise_local_y_f);
          const d01: f32 = math.dot_prod_2d(g01[0], g01[1], noise_local_x_f, noise_local_y_f - 1.0);
          const d11: f32 = math.dot_prod_2d(g11[0], g11[1], noise_local_x_f - 1.0, noise_local_y_f - 1.0);

          const sx = cached_smoothed_values[noise_local_x_idx_u];
          const sy = cached_smoothed_values[noise_local_y_idx_u];

					out_buffer[matrix_offset + lx] = math.lerp(
						math.lerp(d00, d10, sx),
						math.lerp(d01, d11, sx),
						sy
					);
				}
			}
    }
  }
}