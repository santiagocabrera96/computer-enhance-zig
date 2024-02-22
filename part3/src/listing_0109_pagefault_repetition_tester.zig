const std = @import("std");
const timer = @import("./listing_0108_platform_metrics.zig");

const stdout = std.io.getStdOut().writer();

const TestMode = enum { uninitialized, testing, completed, test_error };

const RepetitionValueType = enum { test_count, cpu_timer, mem_page_faults, byte_count };
const repetition_value_type_count = @typeInfo(RepetitionValueType).Enum.fields.len;

const RepetitionValue = struct {
    E: [repetition_value_type_count]u64 = [_]u64{0} ** repetition_value_type_count,
};

const RepetitionTestResults = struct {
    total: RepetitionValue = RepetitionValue{},
    min: RepetitionValue = RepetitionValue{},
    max: RepetitionValue = RepetitionValue{},
};

pub const RepetitionTester = struct {
    target_processed_byte_count: u64 = undefined,
    cpu_timer_freq: u64 = undefined,
    try_for_time: u64 = undefined,
    tests_started_at: u64 = undefined,

    mode: TestMode = .uninitialized,
    print_new_minimums: bool = true,
    open_block_count: u32 = 0,
    close_block_count: u32 = 0,

    accumulated_on_this_test: RepetitionValue = RepetitionValue{},

    results: RepetitionTestResults = RepetitionTestResults{},
};

fn secondsFromCPUTime(cpu_time: f64, cpu_timer_freq: u64) f64 {
    const result = if (cpu_timer_freq > 0) (cpu_time / @as(f64, @floatFromInt(cpu_timer_freq))) else 0;
    return result;
}

fn printValue(label: []const u8, value: RepetitionValue, cpu_timer_freq: u64) void {
    const test_count = value.E[@intFromEnum(RepetitionValueType.test_count)];
    const divisor: f64 = if (test_count > 0) @floatFromInt(test_count) else 1;

    var E: [repetition_value_type_count]f64 = undefined;
    for (E, 0..) |_, idx| {
        E[idx] = @as(f64, @floatFromInt(value.E[idx])) / divisor;
    }

    stdout.print("{s}: {d:.0}", .{ label, E[@intFromEnum(RepetitionValueType.cpu_timer)] }) catch unreachable;
    if (cpu_timer_freq > 0) {
        const seconds = secondsFromCPUTime(E[@intFromEnum(RepetitionValueType.cpu_timer)], cpu_timer_freq);
        stdout.print("  ({d:.6}ms)", .{1000 * seconds}) catch unreachable;

        if (E[@intFromEnum(RepetitionValueType.byte_count)] > 0) {
            const gigabyte = (1024 * 1024 * 1024);
            const best_bandwidth = E[@intFromEnum(RepetitionValueType.byte_count)] / (gigabyte * seconds);
            stdout.print(" {d:.6}gb/s", .{best_bandwidth}) catch unreachable;
        }
    }

    if (E[@intFromEnum(RepetitionValueType.mem_page_faults)] > 0) {
        stdout.print(" PF: {d:.4} ({d:.4}k/fault)", .{ E[@intFromEnum(RepetitionValueType.mem_page_faults)], E[@intFromEnum(RepetitionValueType.byte_count)] / (E[@intFromEnum(RepetitionValueType.mem_page_faults)] * 1024) }) catch unreachable;
    }
}

fn printResults(results: RepetitionTestResults, cpu_timer_freq: u64) void {
    printValue("Min", results.min, cpu_timer_freq);
    stdout.print("\n", .{}) catch unreachable;
    printValue("Max", results.max, cpu_timer_freq);
    stdout.print("\n", .{}) catch unreachable;
    printValue("Avg", results.total, cpu_timer_freq);
    stdout.print("\n", .{}) catch unreachable;
}

pub fn testerError(tester: *RepetitionTester, message: []const u8) void {
    tester.mode = .test_error;
    std.log.err("{s}", .{message});
}

pub fn newTestWave(tester: *RepetitionTester, target_processed_byte_count: u64, cpu_timer_freq: u64, seconds_to_try: u32) void {
    if (tester.mode == .uninitialized) {
        tester.mode = .testing;
        tester.target_processed_byte_count = target_processed_byte_count;
        tester.cpu_timer_freq = cpu_timer_freq;
        tester.print_new_minimums = true;
        tester.results.min.E[@intFromEnum(RepetitionValueType.cpu_timer)] = std.math.maxInt(u64);
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

pub fn beginTime(tester: *RepetitionTester) void {
    tester.open_block_count += 1;

    var accum = &tester.accumulated_on_this_test;
    accum.E[@intFromEnum(RepetitionValueType.cpu_timer)] -%= timer.readCPUTimer();
    accum.E[@intFromEnum(RepetitionValueType.mem_page_faults)] -%= timer.readOSPageFaults();
}

pub fn endTime(tester: *RepetitionTester) void {
    tester.close_block_count += 1;
    var accum = &tester.accumulated_on_this_test;
    accum.E[@intFromEnum(RepetitionValueType.cpu_timer)] +%= timer.readCPUTimer();
    accum.E[@intFromEnum(RepetitionValueType.mem_page_faults)] +%= timer.readOSPageFaults();
}

pub fn countBytes(tester: *RepetitionTester, byte_count: u64) void {
    var accum = &tester.accumulated_on_this_test;
    accum.E[@intFromEnum(RepetitionValueType.byte_count)] += byte_count;
}

pub fn isTesting(tester: *RepetitionTester) bool {
    if (tester.mode == .testing) {
        var accum = &tester.accumulated_on_this_test;

        const current_time = timer.readCPUTimer();

        if (tester.open_block_count > 0) { // Note: Don't count tests that had no timing blocks - assume the took some other path
            if (tester.open_block_count != tester.close_block_count) {
                testerError(tester, "Unbalanced BeginTime/EndTime");
            }
            if (accum.E[@intFromEnum(RepetitionValueType.byte_count)] != tester.target_processed_byte_count) {
                testerError(tester, "Processed byte count mismatch");
            }

            if (tester.mode == .testing) {
                const results = &tester.results;

                accum.E[@intFromEnum(RepetitionValueType.test_count)] = 1;

                for (accum.E, 0..) |_, i| {
                    results.total.E[i] += accum.E[i];
                }

                if (results.max.E[@intFromEnum(RepetitionValueType.cpu_timer)] < accum.E[@intFromEnum(RepetitionValueType.cpu_timer)]) {
                    results.max = accum.*;
                }
                if (results.min.E[@intFromEnum(RepetitionValueType.cpu_timer)] > accum.E[@intFromEnum(RepetitionValueType.cpu_timer)]) {
                    results.min = accum.*;
                    // Note: Whenever we get a new minimum time, reset the clock to the full trial time
                    tester.tests_started_at = current_time;
                    if (tester.print_new_minimums) {
                        printValue("Min", results.min, tester.cpu_timer_freq);
                        stdout.print("                                            \r", .{}) catch unreachable;
                    }
                }

                tester.open_block_count = 0;
                tester.close_block_count = 0;
                tester.accumulated_on_this_test = RepetitionValue{};
            }

            if (current_time - tester.tests_started_at > tester.try_for_time) {
                tester.mode = .completed;
                stdout.print("                                                          \r", .{}) catch unreachable;
                printResults(tester.results, tester.cpu_timer_freq);
            }
        }
    }

    const result = tester.mode == .testing;
    return result;
}

test {
    var allocator = std.testing.allocator;

    const filename = "data_10000000_flex.json";
    const file = try std.fs.cwd().openFile(filename, .{});
    const target_processed_byte_count = (try file.stat()).size;
    const cpu_timer_freq = timer.estimateCPUTimerFreq();
    const seconds_to_try = 1;
    const dest = try allocator.alloc(u8, target_processed_byte_count);
    defer allocator.free(dest);

    try stdout.print("\n", .{});

    var tester = RepetitionTester{};
    newTestWave(&tester, dest.len, cpu_timer_freq, seconds_to_try);

    while (isTesting(&tester)) {
        beginTime(&tester);
        // do something
        endTime(&tester);
        countBytes(&tester, dest.len);
    }
}
