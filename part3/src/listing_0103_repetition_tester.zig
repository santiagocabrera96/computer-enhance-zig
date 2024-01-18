const std = @import("std");
const timer = @import("./listing_0074_platform_metrics.zig");

const stdout = std.io.getStdOut().writer();

const TestMode = enum { uninitialized, testing, completed, test_error };
const RepetitionTestResults = struct { test_count: u64 = 0, total_time: u64, max_time: u64, min_time: u64 };

pub const RepetitionTester = struct {
    target_processed_byte_count: u64 = undefined,
    cpu_timer_freq: u64 = undefined,
    try_for_time: u64 = undefined,
    tests_started_at: u64 = undefined,

    mode: TestMode = .uninitialized,
    print_new_minimums: bool = undefined,
    open_block_count: u32 = 0,
    close_block_count: u32 = 0,
    time_accumulated_on_this_test: u64 = 0,
    bytes_accumulated_on_this_tests: u64 = 0,

    results: RepetitionTestResults = undefined,
};

pub fn beginTime(tester: *RepetitionTester) void {
    tester.open_block_count += 1;
    tester.time_accumulated_on_this_test -%= timer.readCPUTimer();
}

pub fn endTime(tester: *RepetitionTester) void {
    tester.close_block_count += 1;
    tester.time_accumulated_on_this_test +%= timer.readCPUTimer();
}

pub fn testerError(tester: *RepetitionTester, message: []const u8) void {
    tester.mode = .test_error;
    std.log.err("{s}", .{message});
}

fn secondsFromCPUTime(cpu_time: f64, cpu_timer_freq: u64) f64 {
    const result = if (cpu_timer_freq > 0) (cpu_time / @as(f64, @floatFromInt(cpu_timer_freq))) else 0;
    return result;
}

fn printTime(label: []const u8, cpu_time: f64, cpu_timer_freq: u64, byte_count: u64) void {
    stdout.print("{s}: {d:.0}", .{ label, cpu_time }) catch unreachable;
    if (cpu_timer_freq > 0) {
        const seconds = secondsFromCPUTime(cpu_time, cpu_timer_freq);
        stdout.print("  ({d:.6}ms)", .{1000 * seconds}) catch unreachable;

        if (byte_count > 0) {
            const gigabyte = (1024 * 1024 * 1024);
            const best_bandwidth = @as(f64, @floatFromInt(byte_count)) / (gigabyte * seconds);
            stdout.print(" {d:.6}gb/s", .{best_bandwidth}) catch unreachable;
        }
    }
}

fn printResults(results: RepetitionTestResults, cpu_timer_freq: u64, byte_count: u64) void {
    printTime("Min", @floatFromInt(results.min_time), cpu_timer_freq, byte_count);
    stdout.print("\n", .{}) catch unreachable;
    printTime("Max", @floatFromInt(results.max_time), cpu_timer_freq, byte_count);
    stdout.print("\n", .{}) catch unreachable;

    if (results.test_count > 0) {
        printTime("Avg", @as(f64, @floatFromInt(results.total_time)) / @as(f64, @floatFromInt(results.test_count)), cpu_timer_freq, byte_count);
        stdout.print("\n", .{}) catch unreachable;
    }
}

pub fn countBytes(tester: *RepetitionTester, byte_count: u64) void {
    tester.bytes_accumulated_on_this_tests += byte_count;
}

pub fn isTesting(tester: *RepetitionTester) bool {
    if (tester.mode == .testing) {
        const current_time = timer.readCPUTimer();

        if (tester.open_block_count > 0) { // Note: Don't count tests that had no timing blocks - assume the took some other path
            if (tester.open_block_count != tester.close_block_count) {
                testerError(tester, "Unbalanced BeginTime/EndTime");
            }
            if (tester.bytes_accumulated_on_this_tests != tester.target_processed_byte_count) {
                testerError(tester, "Processed byte count mismatch");
            }

            if (tester.mode == .testing) {
                const results = &tester.results;
                const elapsed_time = tester.time_accumulated_on_this_test;

                results.test_count += 1;
                results.total_time += elapsed_time;

                if (results.max_time < elapsed_time) {
                    results.max_time = elapsed_time;
                }
                if (results.min_time > elapsed_time) {
                    results.min_time = elapsed_time;
                    // Note: Whenever we get a new minimum time, reset the clock to the full trial time
                    tester.tests_started_at = current_time;
                    if (tester.print_new_minimums) {
                        printTime("Min", @as(f64, @floatFromInt(results.min_time)), tester.cpu_timer_freq, tester.bytes_accumulated_on_this_tests);
                        stdout.print("               \r", .{}) catch unreachable;
                    }
                }

                tester.open_block_count = 0;
                tester.close_block_count = 0;
                tester.bytes_accumulated_on_this_tests = 0;
                tester.time_accumulated_on_this_test = 0;
            }

            if (current_time - tester.tests_started_at > tester.try_for_time) {
                tester.mode = .completed;
                stdout.print("                                                          \r", .{}) catch unreachable;
                printResults(tester.results, tester.cpu_timer_freq, tester.target_processed_byte_count);
            }
        }
    }

    const result = tester.mode == .testing;
    return result;
}

pub fn newTestWave(tester: *RepetitionTester, target_processed_byte_count: u64, cpu_timer_freq: u64, seconds_to_try: u32) void {
    if (tester.mode == .uninitialized) {
        tester.mode = .testing;
        tester.target_processed_byte_count = target_processed_byte_count;
        tester.cpu_timer_freq = cpu_timer_freq;
        tester.print_new_minimums = true;
        tester.results.min_time = std.math.maxInt(u64);
    } else if (tester.mode == .completed) {
        tester.mode = .testing;

        if (tester.target_processed_byte_count != target_processed_byte_count) {
            testerError(tester, "TargetProcessedByteCount changed");
        }
        if (tester.cpu_timer_freq != cpu_timer_freq) {
            testerError(tester, "CPU frequency changed");
        }
    }

    tester.try_for_time = seconds_to_try * cpu_timer_freq;
    tester.tests_started_at = timer.readCPUTimer();
}
