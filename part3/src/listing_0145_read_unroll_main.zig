// How to run:
// as src/listing_0144_read_unroll.asm -o zig-out/bin/listing_0144_read_unroll.o
// libtool zig-out/bin/listing_0144_read_unroll.o -o zig-out/bin/liblisting_0144_read_unroll.a
// zig build-exe -llisting_0144_read_unroll -L./zig-out/bin -femit-bin=zig-out/bin/listing_0145_read_unroll_main src/listing_0145_read_unroll_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0145_read_unroll_main

const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");
const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
const RepetitionTester = repetition_tester.RepetitionTester;

const stdout = std.io.getStdOut().writer();

fn printName(fn_name: []const u8) void {
    stdout.print("\n--- {s} ---\n", .{fn_name}) catch unreachable;
}

const test_names = [_][]const u8{ //
    "read_4X2",
    "read_8X2",
    "readX1",
    "readX2",
    "readX3",
    "readX4",
    "readX5",
    "storeX1",
    "storeX2",
    "storeX3",
    "storeX4",
    "storeX5",
};

extern fn read_4X2(*u64, c_int) void;
extern fn read_8X2(*u64, c_int) void;
extern fn readX1(*u64, c_int) void;
extern fn readX2(*u64, c_int) void;
extern fn readX3(*u64, c_int) void;
extern fn readX4(*u64, c_int) void;
extern fn readX5(*u64, c_int) void;
extern fn storeX1(*u64, c_int) void;
extern fn storeX2(*u64, c_int) void;
extern fn storeX3(*u64, c_int) void;
extern fn storeX4(*u64, c_int) void;
extern fn storeX5(*u64, c_int) void;

const test_functions = [_]fn (*u64, c_int) callconv(.C) void{ //
    read_4X2,
    read_8X2,
    readX1,
    readX2,
    readX3,
    readX4,
    readX5,
    storeX1,
    storeX2,
    storeX3,
    storeX4,
    storeX5,
};

fn readOverheadMain(allocator: std.mem.Allocator) !void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();

    const iterations = 1000000000;

    const seconds_to_try = 10;

    var testers = [_]RepetitionTester{RepetitionTester{}} ** test_functions.len;

    var buff = try allocator.alloc(u64, 16);
    defer allocator.free(buff);

    while (true) {
        inline for (0..test_functions.len) |func_index| {
            const test_function = test_functions[func_index];

            const tester: *RepetitionTester = &testers[func_index];
            repetition_tester.newTestWave(tester, iterations, cpu_timer_freq, seconds_to_try);

            printName(test_names[func_index]);
            while (repetition_tester.isTesting(tester)) {
                repetition_tester.beginTime(tester);
                test_function(&buff[0], iterations);
                repetition_tester.endTime(tester);
                repetition_tester.countBytes(tester, iterations);
            }
        }
    }
}

pub fn main() !void {
    try readOverheadMain(std.heap.c_allocator);
}

test {
    try main();
}
