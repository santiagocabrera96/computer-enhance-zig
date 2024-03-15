// How to run:
// as src/listing_0146_byte_read.asm -o zig-out/bin/listing_0146_byte_read.o
// libtool zig-out/bin/listing_0146_byte_read.o -o zig-out/bin/liblisting_0146_byte_read.a
// zig build-exe -llisting_0146_byte_read -L./zig-out/bin -femit-bin=zig-out/bin/listing_0147_byte_read_main src/listing_0147_byte_read_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0147_byte_read_main

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
};

extern fn read_4X2(*u64, c_int) void;
extern fn read_8X2(*u64, c_int) void;

const test_functions = [_]fn (*u64, c_int) callconv(.C) void{ //
    read_4X2,
    read_8X2,
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
