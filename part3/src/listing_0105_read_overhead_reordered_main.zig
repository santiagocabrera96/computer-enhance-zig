const std = @import("std");

const timer = @import("./listing_0074_platform_metrics.zig");
const repetition_tester = @import("./listing_0103_repetition_tester.zig");
const read_fns = @import("./listing_0102_read_overhead_test.zig");
const RepetitionTester = read_fns.RepetitionTester;
const ReadParameters = read_fns.ReadParameters;

const stdout = std.io.getStdOut().writer();

const TestFunction = struct { name: []const u8, func: fn (*RepetitionTester, *ReadParameters) anyerror!void };

const test_functions = [_]TestFunction{ //
    .{ .name = "readViaReadAll", .func = read_fns.readViaReadAll },
    .{ .name = "readViaPReadAll", .func = read_fns.readViaPReadAll },
    .{ .name = "readViaReadToEndAlloc", .func = read_fns.readViaReadToEndAlloc },
};

fn readOverheadMain(filename: []const u8, allocator: std.mem.Allocator) !void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();
    const stat = try std.fs.cwd().statFile(filename);
    const buff = try allocator.alloc(u8, stat.size);
    defer allocator.free(buff);

    const seconds_to_try = 10;

    var params = ReadParameters{ .dest = buff, .filename = filename, .allocator = allocator };

    if (params.dest.len == 0) {
        std.log.err("Test data size must be non-zero", .{});
        return;
    }

    var testers: [test_functions.len]RepetitionTester = [_]RepetitionTester{RepetitionTester{}} ** test_functions.len;

    while (true) {
        inline for (0..test_functions.len) |func_index| {
            const tester: *RepetitionTester = &testers[func_index];
            const test_function = test_functions[func_index];
            repetition_tester.newTestWave(tester, params.dest.len, cpu_timer_freq, seconds_to_try);

            try test_function.func(tester, &params);
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
    std.testing.log_level = .debug;
    stdout.print("", .{}) catch unreachable;

    const filename = "data_10000000_flex.json";
    // const filename = "data_10000000_flex.json";
    try readOverheadMain(filename, std.heap.c_allocator);
}
