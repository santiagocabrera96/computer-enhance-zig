// How to run:
// as src/listing_0152_cache_test.asm -o zig-out/bin/listing_0152_cache_test.o
// libtool zig-out/bin/listing_0152_cache_test.o -o zig-out/bin/liblisting_0152_cache_test.a
// zig build-exe -llisting_0152_cache_test -L./zig-out/bin -femit-bin=zig-out/bin/listing_0153_cache_test_main src/listing_0153_cache_test_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0153_cache_test_main

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

    const bits_to_test = 30 - 10;

    const bytes_per_iteration = 96;

    var testers = [_]RepetitionTester{RepetitionTester{}} ** test_functions.len ** bits_to_test;

    const iterations = 1024 * 1024 * 1024;

    var buff = try allocator.alloc(u8, iterations);
    defer allocator.free(buff);

    for (0..buff.len) |idx| {
        buff[idx] = @truncate(idx);
    }

    const initial_size_to_test = 1024;

    inline for (0..test_functions.len) |func_index| {
        const test_function = test_functions[func_index];

        var size_to_test: u64 = initial_size_to_test;

        for (0..bits_to_test) |bit| {
            const inner_loop_iterations = size_to_test / bytes_per_iteration;
            const inner_loop_bytes_processed = inner_loop_iterations * bytes_per_iteration;
            const outer_loop_iterations = buff.len / inner_loop_bytes_processed;
            const bytes_processed = outer_loop_iterations * inner_loop_bytes_processed;

            const tester: *RepetitionTester = &testers[(func_index * bits_to_test) + bit];
            repetition_tester.newTestWave(tester, bytes_processed, cpu_timer_freq, seconds_to_try);

            printName(test_names[func_index], size_to_test);
            while (repetition_tester.isTesting(tester)) {
                repetition_tester.beginTime(tester);
                test_function(&buff[0], @intCast(inner_loop_iterations), @intCast(outer_loop_iterations));
                repetition_tester.endTime(tester);
                repetition_tester.countBytes(tester, bytes_processed);
            }

            size_to_test <<= 1;
        }
        stdout.print("Region size, gb/s \n", .{}) catch unreachable;
        inline for (0..bits_to_test) |bits| {
            const region_size = initial_size_to_test << bits;
            const tester = testers[(func_index * bits_to_test) + bits];

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
