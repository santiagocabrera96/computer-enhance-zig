// How to run:
// as src/listing_0150_read_widths.asm -o zig-out/bin/listing_0150_read_widths.o
// libtool zig-out/bin/listing_0150_read_widths.o -o zig-out/bin/liblisting_0150_read_widths.a
// zig build-exe -llisting_0150_read_widths -L./zig-out/bin -femit-bin=zig-out/bin/listing_0151_read_widths_main src/listing_0151_read_widths_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0151_read_widths_main

const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");
const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
const RepetitionTester = repetition_tester.RepetitionTester;

const stdout = std.io.getStdOut().writer();

fn printName(fn_name: []const u8) void {
    stdout.print("\n--- {s} ---\n", .{fn_name}) catch unreachable;
}

const test_names = [_][]const u8{ //
    "read_4x3",
    "read_8x3",
    "read_16x3",
    "read_32x3",
};

extern fn read_4x3(*u64, c_int) void;
extern fn read_8x3(*u64, c_int) void;
extern fn read_16x3(*u64, c_int) void;
extern fn read_32x3(*u64, c_int) void;

const test_functions = [_]fn (*u64, c_int) callconv(.C) void{ //
    read_4x3,
    read_8x3,
    read_16x3,
    read_32x3,
};

fn readOverheadMain(allocator: std.mem.Allocator) !void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();

    const iterations = 1000000000;

    const seconds_to_try = 10;

    var testers = [_]RepetitionTester{RepetitionTester{}} ** test_functions.len;

    var buff = try allocator.alloc(u64, 16);
    buff[0] = 0x0123456789abcdef;
    buff[1] = 0xfedcba9876543210;
    buff[2] = 0x1111111111111110;
    buff[3] = 0x2222222222222220;
    buff[4] = 0x3333333333333330;
    buff[5] = 0x4444444444444440;
    buff[6] = 0x0123456789abcdef;
    buff[7] = 0xfedcba9876543210;
    buff[8] = 0x1111111111111110;
    buff[9] = 0x2222222222222220;
    buff[10] = 0x3333333333333330;
    buff[11] = 0x4444444444444440;
    defer allocator.free(buff);

    read_32x3(&buff[0], iterations);

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
