const std = @import("std");

//###########################
//#        RAPIDHASH        #
//###########################
pub inline fn rapidhashnano_init_seed(seed: u64) u64 {
	const pro: u128 = std.math.mulWide(u64, seed ^ 0x4b33a62ed433d4a3, 0x8bb84b93962eacc9);
	return seed ^ @as(u64, @truncate(pro)) ^ @as(u64, @truncate(pro >> 64));
}

pub inline fn rapidhashnano_full(seed: u64, x: u64, y: u64) u64 {
	return rapidhashnano_no_init(rapidhashnano_init_seed(seed), x, y);
}

pub inline fn rapidhashnano_no_init(seed: u64, x: u64, y: u64) u64 {
 	var pro: u128 = std.math.mulWide(u64, x ^ 0x8bb84b93962eacc9, y ^ seed ^ 16);
	pro = std.math.mulWide(
		u64,
		@as(u64, @truncate(pro)) ^ 0xaaaaaaaaaaaaaaaa,
		@as(u64, @truncate(pro >> 64)) ^ 0x8bb84b93962eacc9 ^ 16
	);

	return @as(u64, @truncate(pro)) ^ @as(u64, @truncate(pro >> 64));
}
