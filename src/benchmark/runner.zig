const std = @import("std");
const config = @import("config.zig");
const report = @import("report.zig");
const cycle_counter = @import("../core/shared/cycle_counter.zig");
const registry = @import("../noise/perlin/registry.zig");

pub fn run_warmup(
	comptime mode: registry.OptMode,
	seed: u64,
	cached_values: anytype,
	cached_smoothed_values: anytype,
	chunk_buffer: anytype,
	warmup_chunk_count: u64,
) !void {
	const chunk_size_i64: i64 = @as(i64, @intCast(config.CHUNK_SIZE));

	for (0..warmup_chunk_count) |i| {
		const chunk_idx_i64: i64 = @as(i64, @intCast(i));
		const world_origin: i64 = chunk_idx_i64 * chunk_size_i64;
		try registry.generate_chunk2d(
			mode,
			config.CHUNK_SIZE,
			config.SCALE,
			seed,
			cached_values,
			cached_smoothed_values,
			world_origin,
			world_origin,
			chunk_buffer,
		);
	}
}

pub fn run_benchmark_pass(
	comptime mode: registry.OptMode,
	seed: u64,
	cached_values: anytype,
	cached_smoothed_values: anytype,
	chunk_buffer: anytype,
	benchmark_chunk_count: u64,
) !report.BenchmarkResult {
	const chunk_size_i64: i64 = @as(i64, @intCast(config.CHUNK_SIZE));

	var best_chunk_cycles: u64 = std.math.maxInt(u64);

	const start_cycles = cycle_counter.read();
	for (0..benchmark_chunk_count) |i| {
		const chunk_start_cycles = cycle_counter.read();
		const chunk_idx_i64: i64 = @as(i64, @intCast(i));
		const world_origin: i64 = chunk_idx_i64 * chunk_size_i64;

		try registry.generate_chunk2d(
			mode,
			config.CHUNK_SIZE,
			config.SCALE,
			seed,
			cached_values,
			cached_smoothed_values,
			world_origin,
			world_origin,
			chunk_buffer,
		);

		best_chunk_cycles = @min(cycle_counter.read() - chunk_start_cycles, best_chunk_cycles);
	}

	const end_cycles = cycle_counter.read();

	return report.BenchmarkResult{
		.total_cycles = end_cycles - start_cycles,
		.best_chunk_cycles = best_chunk_cycles,
	};
}