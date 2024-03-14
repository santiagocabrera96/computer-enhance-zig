// How to run:
// as src/listing_0132_nop_loop.asm -o zig-out/bin/listing_0132_nop_loop.out
// libtool zig-out/bin/listing_0132_nop_loop.out -o zig-out/bin/liblisting_0132_nop_loop.a
// zig build-exe -llisting_0132_nop_loop -L./zig-out/bin -femit-bin=zig-out/bin/listing_0133_front_end_test_main src/listing_0133_front_end_test_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0133_front_end_test_main data_10000000_flex.json

const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");
const read_fns = @import("./listing_0131_front_end_test.zig");
const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
const RepetitionTester = read_fns.RepetitionTester;
const ReadParameters = read_fns.ReadParameters;

const stdout = std.io.getStdOut().writer();

const test_functions = [_]fn (*RepetitionTester, *ReadParameters) anyerror!void{ //
    read_fns.writeToAllBytes,
    read_fns.writeToAllBytesAsm,
    read_fns.NOPToAllBytesAsm,
    read_fns.CMPToAllBytesAsm,
    read_fns.DECToAllBytesAsm,
};

fn readOverheadMain(filename: []const u8, allocator: std.mem.Allocator) !void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();
    const stat = try std.fs.cwd().statFile(filename);
    const buff = try allocator.alloc(u8, stat.size);
    defer allocator.free(buff);

    const seconds_to_try = 10;

    var params = ReadParameters{ .dest = buff, .filename = filename, .allocator = allocator, .allocation_type = .none };

    if (params.dest.len == 0) {
        std.log.err("Test data size must be non-zero", .{});
        return;
    }

    var testers = [_]RepetitionTester{RepetitionTester{}} ** test_functions.len;

    while (true) {
        inline for (0..test_functions.len) |func_index| {
            const test_function = test_functions[func_index];

            const tester: *RepetitionTester = &testers[func_index];
            repetition_tester.newTestWave(tester, params.dest.len, cpu_timer_freq, seconds_to_try);
            try test_function(tester, &params);
        }
    }
}

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.log.err("Usage: {s} [existing filename]\n", .{std.os.argv[0]});
        return;
    }

    const filename = std.mem.sliceTo(std.os.argv[1], 0);

    try readOverheadMain(filename, std.heap.c_allocator);
}

test {
    const filename = "data_10000000_flex.json";
    try readOverheadMain(filename, std.testing.allocator);
}
