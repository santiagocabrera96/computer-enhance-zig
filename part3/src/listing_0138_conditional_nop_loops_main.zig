// How to run:
// as src/listing_0136_conditional_nop_loops.asm -o zig-out/bin/listing_0136_conditional_nop_loops.o
// libtool zig-out/bin/listing_0136_conditional_nop_loops.o -o zig-out/bin/liblisting_0136_conditional_nop_loops.a
// zig build-exe -llisting_0136_conditional_nop_loops -L./zig-out/bin -femit-bin=zig-out/bin/listing_0138_conditional_nop_loops src/listing_0138_conditional_nop_loops_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0138_conditional_nop_loops data_10000000_flex.json

const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");
const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
const RepetitionTester = repetition_tester.RepetitionTester;

const stdout = std.io.getStdOut().writer();

fn printName(fn_name: []const u8) void {
    stdout.print("\n--- {s} ---\n", .{fn_name}) catch unreachable;
}

const BranchPattern = enum { //
    never_taken,
    always_taken,
    every2,
    every3,
    every4,
    random_bcrypt,
};

fn fillWithBranchPattern(pattern: BranchPattern, buffer: []u8) void {
    for (0..buffer.len) |idx| {
        const value: u8 = switch (pattern) {
            .never_taken => 0,
            .always_taken => 1,
            .every2 => if (idx % 2 == 0) 1 else 0,
            .every3 => if (idx % 3 == 0) 1 else 0,
            .every4 => if (idx % 4 == 0) 1 else 0,
            .random_bcrypt => if (std.crypto.random.boolean()) 1 else 0,
        };
        buffer[idx] = value;
    }
}

const test_names = [_][]const u8{ //
    "conditionalNOP",
};

extern fn conditionalNOP(size: usize, dest_buffer: [*]u8) void;

const test_functions = [_]fn (usize, [*]u8) callconv(.C) void{ //
    conditionalNOP,
};

fn readOverheadMain(filename: []const u8, allocator: std.mem.Allocator) !void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();
    const stat = try std.fs.cwd().statFile(filename);
    const buff = try allocator.alloc(u8, stat.size);
    defer allocator.free(buff);

    const seconds_to_try = 10;

    var testers = [_]RepetitionTester{RepetitionTester{}} ** std.enums.values(BranchPattern).len;

    while (true) {
        inline for (comptime std.enums.values(BranchPattern)) |pattern| {
            fillWithBranchPattern(pattern, buff);
            inline for (0..test_functions.len) |func_index| {
                const test_function = test_functions[func_index];

                const tester: *RepetitionTester = &testers[@intFromEnum(pattern)];
                repetition_tester.newTestWave(tester, buff.len, cpu_timer_freq, seconds_to_try);
                const name = switch (pattern) {
                    .never_taken => "Never taken",
                    .always_taken => "Always taken",
                    .every2 => "Every 2",
                    .every3 => "Every 3",
                    .every4 => "Every 4",
                    .random_bcrypt => "Bcrypt",
                };

                printName(name);
                while (repetition_tester.isTesting(tester)) {
                    repetition_tester.beginTime(tester);
                    test_function(buff.len, @ptrCast(buff.ptr));
                    repetition_tester.endTime(tester);
                    repetition_tester.countBytes(tester, buff.len);
                }
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
