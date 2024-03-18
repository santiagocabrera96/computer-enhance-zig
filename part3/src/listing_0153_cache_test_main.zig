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

fn printName(fn_name: []const u8, mask: u64) void {
    stdout.print("\n--- {s} - 0x{x} - {d} ---\n", .{ fn_name, mask, mask }) catch unreachable;
}

const test_names = [_][]const u8{ //
    "readMasked",
};

extern fn readMasked(*u8, usize, c_long) void;

const test_functions = [_]fn (*u8, usize, c_long) callconv(.C) void{ //
    readMasked,
};

fn readOverheadMain(allocator: std.mem.Allocator) !void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();

    const seconds_to_try = 10;

    const bits_to_test = 31 - 8;

    var testers = [_]RepetitionTester{RepetitionTester{}} ** test_functions.len ** bits_to_test;

    const gigabyte = 1024 * 1024 * 1024;
    const iterations = gigabyte;

    var buff = try allocator.alloc(u8, iterations);
    defer allocator.free(buff);

    for (0..buff.len) |idx| {
        buff[idx] = @truncate(idx);
    }

    while (true) {
        // var mask: u64 = 0xff;
        var mask: u64 = 0x3fffffff;

        for (0..bits_to_test) |bit| {
            inline for (0..test_functions.len) |func_index| {
                const test_function = test_functions[func_index];

                const tester: *RepetitionTester = &testers[(func_index * bits_to_test) + bit];
                repetition_tester.newTestWave(tester, iterations, cpu_timer_freq, seconds_to_try);

                printName(test_names[func_index], mask);
                while (repetition_tester.isTesting(tester)) {
                    repetition_tester.beginTime(tester);
                    test_function(&buff[0], buff.len, @intCast(mask));
                    repetition_tester.endTime(tester);
                    repetition_tester.countBytes(tester, iterations);
                }
            }
            mask <<|= 1;
            mask += 1;
        }
    }
}

pub fn main() !void {
    try readOverheadMain(std.heap.c_allocator);
}

test {
    try main();
}
