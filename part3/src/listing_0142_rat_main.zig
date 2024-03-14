// How to run:
// as src/listing_0141_rat.asm -o zig-out/bin/listing_0141_rat.o
// libtool zig-out/bin/listing_0141_rat.o -o zig-out/bin/liblisting_0141_rat.a
// zig build-exe -llisting_0141_rat -L./zig-out/bin -femit-bin=zig-out/bin/listing_0142_rat_main src/listing_0142_rat_main.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0142_rat_main

const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");
const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
const RepetitionTester = repetition_tester.RepetitionTester;

const stdout = std.io.getStdOut().writer();

fn printName(fn_name: []const u8) void {
    stdout.print("\n--- {s} ---\n", .{fn_name}) catch unreachable;
}

const test_names = [_][]const u8{ //
    "RATMovAddUnrolled",
    "RATMovAddUnrolled6",
    "RATHomework",
    "RATAdd",
    "RATMovAdd",
};

extern fn RATMovAddUnrolled() void;
extern fn RATMovAddUnrolled6() void;
extern fn RATAdd() void;
extern fn RATMovAdd() void;
extern fn RATHomework() void;

const test_functions = [_]fn () callconv(.C) void{ //
    RATMovAddUnrolled,
    RATMovAddUnrolled6,
    RATHomework,
    RATAdd,
    RATMovAdd,
};

fn readOverheadMain() void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();

    const iterations = 1000000000;

    const seconds_to_try = 10;

    var testers = [_]RepetitionTester{RepetitionTester{}} ** test_functions.len;

    while (true) {
        inline for (0..test_functions.len) |func_index| {
            const test_function = test_functions[func_index];

            const tester: *RepetitionTester = &testers[func_index];
            repetition_tester.newTestWave(tester, iterations, cpu_timer_freq, seconds_to_try);

            printName(test_names[func_index]);
            while (repetition_tester.isTesting(tester)) {
                repetition_tester.beginTime(tester);
                test_function();
                repetition_tester.endTime(tester);
                repetition_tester.countBytes(tester, iterations);
            }
        }
    }
}

pub fn main() void {
    readOverheadMain();
}

test {
    main();
}
