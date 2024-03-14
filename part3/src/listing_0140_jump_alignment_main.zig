// How to run:
// as src/listing_0139_jump_alignment.asm -o zig-out/bin/listing_0139_jump_alignment.o
// libtool zig-out/bin/listing_0139_jump_alignment.o -o zig-out/bin/liblisting_0139_jump_alignment.a
// zig build-exe -llisting_0139_jump_alignment -L./zig-out/bin -femit-bin=zig-out/bin/listing_0140_jump_alingment_main src/listing_0140_jump_alignment_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0140_jump_alingment_main data_10000000_flex.json

const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");
const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
const RepetitionTester = repetition_tester.RepetitionTester;

const stdout = std.io.getStdOut().writer();

fn printName(fn_name: []const u8) void {
    stdout.print("\n--- {s} ---\n", .{fn_name}) catch unreachable;
}

const test_names = [_][]const u8{ //
    "NOPAligned64",
    "NOPAligned1",
    "NOPAligned15",
    "NOPAligned31",
    "NOPAligned63",
    "NOPAligned127",
};

extern fn NOPAligned64(size: usize, dest_buffer: [*]u8) void;
extern fn NOPAligned1(size: usize, dest_buffer: [*]u8) void;
extern fn NOPAligned15(size: usize, dest_buffer: [*]u8) void;
extern fn NOPAligned31(size: usize, dest_buffer: [*]u8) void;
extern fn NOPAligned63(size: usize, dest_buffer: [*]u8) void;
extern fn NOPAligned127(size: usize, dest_buffer: [*]u8) void;

const test_functions = [_]fn (usize, [*]u8) callconv(.C) void{ //
    NOPAligned64,
    NOPAligned1,
    NOPAligned15,
    NOPAligned31,
    NOPAligned63,
    NOPAligned127,
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
                test_function(buff.len, @ptrCast(buff.ptr));
                repetition_tester.endTime(tester);
                repetition_tester.countBytes(tester, buff.len);
            }
        }
        const test_function = test_functions[5];

        const tester: *RepetitionTester = &testers[5];
        repetition_tester.newTestWave(tester, buff.len, cpu_timer_freq, seconds_to_try);

        printName(test_names[5]);
        while (repetition_tester.isTesting(tester)) {
            repetition_tester.beginTime(tester);
            test_function(buff.len, @ptrCast(buff.ptr));
            repetition_tester.endTime(tester);
            repetition_tester.countBytes(tester, buff.len);
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
