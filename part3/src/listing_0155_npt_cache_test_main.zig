// How to run:
// as src/listing_0154_npt_cache_test.asm -o zig-out/bin/listing_0154_npt_cache_test.o
// libtool zig-out/bin/listing_0154_npt_cache_test.o -o zig-out/bin/liblisting_0154_npt_cache_test.a
// zig build-exe -llisting_0154_npt_cache_test -L./zig-out/bin -femit-bin=zig-out/bin/listing_0155_npt_cache_test_main src/listing_0155_npt_cache_test_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0155_npt_cache_test_main

const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");
const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
const RepetitionTester = repetition_tester.RepetitionTester;

const stdout = std.io.getStdOut().writer();

fn printName(fn_name: []const u8, size_to_test: u64) void {
    stdout.print("\n--- {s} - {d} ---\n", .{ fn_name, size_to_test }) catch unreachable;
}

const test_names = [_][]const u8{ //
    "readMasked",
};

extern fn readMasked(*u8, c_long, c_long) void;

const test_functions = [_]fn (*u8, c_long, c_long) callconv(.C) void{ //
    readMasked,
};

fn readOverheadMain(allocator: std.mem.Allocator) !void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();

    const seconds_to_try = 10;

    const bytes_per_iteration = 96;

    var sizes_to_test: [64]u64 = [_]u64{0} ** 64;

    var testers = [_]RepetitionTester{RepetitionTester{}} ** test_functions.len ** sizes_to_test.len;

    const iterations = 1024 * 1024 * 1024;

    var buff = try allocator.alloc(u8, iterations);
    defer allocator.free(buff);

    for (0..buff.len) |idx| {
        buff[idx] = @truncate(idx);
    }

    // Note: Take results from previous listing to measure with more granularity the intervals size that had the changes
    for (0..32) |idx| {
        const point_1 = 131072;
        const point_2 = 262144;

        const diff: u64 = (point_2 - point_1) / 32;

        sizes_to_test[idx] = (diff * idx) + point_1;
    }

    for (0..32) |idx| {
        const point_3 = 8388608;
        const point_4 = 16777216;

        const diff: u64 = (point_4 - point_3) / 32;

        sizes_to_test[32 + idx] = (diff * idx) + point_3;
    }

    inline for (0..test_functions.len) |func_index| {
        const test_function = test_functions[func_index];

        for (0..sizes_to_test.len) |idx| {
            const size_to_test = sizes_to_test[idx];
            const inner_loop_iterations = size_to_test / bytes_per_iteration;
            const inner_loop_bytes_processed = inner_loop_iterations * bytes_per_iteration;
            const outer_loop_iterations = buff.len / inner_loop_bytes_processed;
            const bytes_processed = outer_loop_iterations * inner_loop_bytes_processed;

            const tester: *RepetitionTester = &testers[(func_index * sizes_to_test.len) + idx];
            repetition_tester.newTestWave(tester, bytes_processed, cpu_timer_freq, seconds_to_try);

            printName(test_names[func_index], size_to_test);
            while (repetition_tester.isTesting(tester)) {
                repetition_tester.beginTime(tester);
                test_function(&buff[0], @intCast(inner_loop_iterations), @intCast(outer_loop_iterations));
                repetition_tester.endTime(tester);
                repetition_tester.countBytes(tester, bytes_processed);
            }
        }
        stdout.print("Region size, gb/s \n", .{}) catch unreachable;
        inline for (0..sizes_to_test.len) |idx| {
            const region_size = sizes_to_test[idx];
            const tester = testers[(func_index * sizes_to_test.len) + idx];

            const value = tester.results.min;
            const seconds = repetition_tester.secondsFromCPUTime(@floatFromInt(value.E[@intFromEnum(repetition_tester.RepetitionValueType.cpu_timer)]), tester.cpu_timer_freq);
            const gigabyte = (1024 * 1024 * 1024);
            const bandwidth: f64 = @as(f64, @floatFromInt(value.E[@intFromEnum(repetition_tester.RepetitionValueType.byte_count)])) / (gigabyte * seconds);

            stdout.print("{d}, {d} \n", .{ region_size, bandwidth }) catch unreachable;
        }
    }
}

pub fn main() !void {
    try readOverheadMain(std.heap.c_allocator);
}

test {
    try main();
}
