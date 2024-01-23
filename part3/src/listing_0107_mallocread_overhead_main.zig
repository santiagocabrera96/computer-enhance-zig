const std = @import("std");

const timer = @import("./listing_0074_platform_metrics.zig");
const repetition_tester = @import("./listing_0103_repetition_tester.zig");
const read_fns = @import("./listing_0106_mallocread_overhead_test.zig");
const RepetitionTester = read_fns.RepetitionTester;
const ReadParameters = read_fns.ReadParameters;

const stdout = std.io.getStdOut().writer();

const test_functions = [_]fn (*RepetitionTester, *ReadParameters) anyerror!void{
    read_fns.readViaPReadAll,
    read_fns.readViaReadAll,
    read_fns.readViaReadToEndAlloc,
};

fn readOverheadMain(filename: []const u8, allocator: std.mem.Allocator) !void {
    const cpu_timer_freq = timer.estimateCPUTimerFreq();
    const stat = try std.fs.cwd().statFile(filename);
    var buff = try allocator.alloc(u8, stat.size);
    defer allocator.free(buff);

    const seconds_to_try = 10;

    var params = ReadParameters{ .dest = buff, .filename = filename, .allocator = allocator, .allocation_type = .none };

    if (params.dest.len == 0) {
        std.log.err("Test data size must be non-zero", .{});
        return;
    }

    const allocation_types = comptime std.enums.values(read_fns.AllocationType);
    var testers = [_][allocation_types.len]RepetitionTester{ //
    [_]RepetitionTester{RepetitionTester{}} ** allocation_types.len} ** test_functions.len;

    while (true) {
        inline for (0..test_functions.len) |func_index| {
            const test_function = test_functions[func_index];
            inline for (allocation_types, 0..) |allocation_type, idx| {
                var tester: *RepetitionTester = &testers[func_index][idx];
                params.allocation_type = allocation_type;
                repetition_tester.newTestWave(tester, params.dest.len, cpu_timer_freq, seconds_to_try);
                try test_function(tester, &params);
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
