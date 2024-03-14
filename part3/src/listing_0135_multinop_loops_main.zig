// How to run:
// as src/listing_0134_multinop_loops.asm -o zig-out/bin/listing_0134_multinop_loops.out
// libtool zig-out/bin/listing_0134_multinop_loops.out -o zig-out/bin/liblisting_0134_multinop_loops.a
// zig build-exe -llisting_0134_multinop_loops -L./zig-out/bin -femit-bin=zig-out/bin/listing_0135_multinop_loops_main src/listing_0135_multinop_loops_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0135_multinop_loops_main data_10000000_flex.json

const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");
const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
const RepetitionTester = repetition_tester.RepetitionTester;

const stdout = std.io.getStdOut().writer();

fn printName(fn_name: []const u8) void {
    stdout.print("\n--- {s} ---\n", .{fn_name}) catch unreachable;
}

const test_names = [_][]const u8{ //
    "NOPAllBytesAsm",
    "NOP3AllBytesAsm",
    "NOP9AllBytesAsm",
    "NOP12AllBytesAsm",
};

extern fn NOPAllBytesAsm(size: usize) void;
extern fn NOP3AllBytesAsm(size: usize) void;
extern fn NOP9AllBytesAsm(size: usize) void;
extern fn NOP12AllBytesAsm(size: usize) void;

const test_functions = [_]fn (usize) callconv(.C) void{ //
    NOPAllBytesAsm,
    NOP3AllBytesAsm,
    NOP9AllBytesAsm,
    NOP12AllBytesAsm,
};

fn readOverheadMain(filename: []const u8, allocator: std.mem.Allocator) !void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();
    const stat = try std.fs.cwd().statFile(filename);
    const buff = try allocator.alloc(u8, stat.size);
    defer allocator.free(buff);

    const seconds_to_try = 10;

    var testers = [_]RepetitionTester{RepetitionTester{}} ** test_functions.len;

    while (true) {
        inline for (0..test_functions.len) |func_index| {
            const test_function = test_functions[func_index];

            const tester: *RepetitionTester = &testers[func_index];
            repetition_tester.newTestWave(tester, buff.len, cpu_timer_freq, seconds_to_try);
            printName(test_names[func_index]);
            while (repetition_tester.isTesting(tester)) {
                repetition_tester.beginTime(tester);
                test_function(buff.len);
                repetition_tester.endTime(tester);
                repetition_tester.countBytes(tester, buff.len);
            }
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
