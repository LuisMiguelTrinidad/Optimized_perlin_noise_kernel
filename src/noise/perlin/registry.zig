const std = @import("std");
const mode_meta = @import("mode_meta.zig");

const perlin_O0 = @import("00_ref.zig");
const perlin_O1 = @import("01_tiling.zig");
const perlin_O2 = @import("02_licm.zig");
const perlin_O3 = @import("03_simd.zig");
const perlin_O4 = @import("04_fpa.zig");

const mode_modules = .{
	.O0 = perlin_O0,
	.O1 = perlin_O1,
	.O2 = perlin_O2,
	.O3 = perlin_O3,
	.O4 = perlin_O4,
};

pub const OptMode = std.meta.FieldEnum(@TypeOf(mode_modules));
pub const SampleKind = mode_meta.SampleKind;

pub const ModeSpec = struct {
	module: type,
	sample_kind: SampleKind,
	required_alignment: u29,
};

pub const ScratchSpec = struct {
	gradient_cache_bytes: usize,
	gradient_cache_alignment: u29
};

fn mode_module(comptime mode: OptMode) type {
	return @field(mode_modules, @tagName(mode));
}

pub fn get_mode_spec(comptime mode: OptMode) ModeSpec {
	const mod = mode_module(mode);
	return .{
		.module = mod,
		.sample_kind = mod.sample_kind,
		.required_alignment = mod.RequiredAlignment,
	};
}

pub fn get_mode_scratch_spec(
	comptime mode: OptMode,
	comptime chunk_size: u64,
	comptime scale: u64,
) ScratchSpec {
	return switch (mode) {
		.O2 => .{
			.gradient_cache_bytes = perlin_O2.workspace_bytes(chunk_size, scale),
			.gradient_cache_alignment = perlin_O2.RequiredAlignment,
		},
		.O3 => .{
			.gradient_cache_bytes = perlin_O3.workspace_bytes(chunk_size, scale),
			.gradient_cache_alignment = perlin_O3.RequiredAlignment,
		},
		.O4 => .{
			.gradient_cache_bytes = perlin_O4.workspace_bytes(chunk_size, scale),
			.gradient_cache_alignment = perlin_O4.RequiredAlignment,
		},
		else => .{
			.gradient_cache_bytes = 0,
			.gradient_cache_alignment = 1
		},
	};
}

pub inline fn generate_chunk2d(
	comptime mode: OptMode,
	comptime chunk_size: u64,
	comptime scale: u64,
	seed: u64,
	cached_values: anytype,
	cached_smoothed_values: anytype,
	world_x: i64,
	world_y: i64,
	out_buffer: anytype,
) !void {

	switch (mode) {
		.O0 => {
			return perlin_O0.perlin_generate_chunk2d(
				seed,
				chunk_size,
				scale,
				cached_values,
				cached_smoothed_values,
				world_x,
				world_y,
				out_buffer,
			);
		},
		.O1 => {
			return perlin_O1.perlin_generate_chunk2d(
				seed,
				chunk_size,
				scale,
				cached_values,
				cached_smoothed_values,
				world_x,
				world_y,
				out_buffer,
			);
		},
		.O2 => {
			return perlin_O2.perlin_generate_chunk2d(
				seed,
				chunk_size,
				scale,
				cached_values,
				cached_smoothed_values,
				world_x,
				world_y,
				out_buffer,
			);
		},
		.O3 => {
			return perlin_O3.perlin_generate_chunk2d(
				seed,
				chunk_size,
				scale,
				cached_values,
				cached_smoothed_values,
				world_x,
				world_y,
				out_buffer,
			);
		},
		.O4 => {
			return perlin_O4.perlin_generate_chunk2d(
				seed,
				chunk_size,
				scale,
				cached_values,
				cached_smoothed_values,
				world_x,
				world_y,
				out_buffer,
			);
		},
	}
}

pub fn parse_mode(mode_arg: []const u8) ?OptMode {
	return std.meta.stringToEnum(OptMode, mode_arg);
}
