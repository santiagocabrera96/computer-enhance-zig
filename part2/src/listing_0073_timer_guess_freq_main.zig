const std = @import("std");
const timer = @import("./listing_0070_platform_metrics.zig");

pub fn main() !void {
    var milliseconds_to_wait: u64 = 1000;
    if (std.os.argv.len == 2) {
        milliseconds_to_wait = try std.fmt.parseInt(u64, std.mem.sliceTo(std.os.argv[1], 0), 10);
    }

    const os_freq = timer.getOSTimerFreq();
    std.log.info("OS Freq: {}", .{os_freq});
    const cpu_start = timer.readCPUTimer();
    const os_start = timer.readOSTimer();
    var os_end: u64 = 0;
    var os_elapsed: u64 = 0;
    const os_wait_time: u64 = os_freq * milliseconds_to_wait / 1000;
    while (os_elapsed < os_wait_time) {
        os_end = timer.readOSTimer();
        os_elapsed = os_end - os_start;
    }
    const cpu_end = timer.readCPUTimer();
    const cpu_elapsed = cpu_end - cpu_start;
    var cpu_freq: u64 = 0;
    if (os_elapsed > 0) {
        cpu_freq = os_freq * cpu_elapsed / os_elapsed;
    }

    std.log.info("OS timer: {} -> {} = {} elapsed", .{ os_start, os_end, os_elapsed });
    std.log.info("OS seconds: {d:.4}", .{@as(f64, @floatFromInt(os_elapsed)) / @as(f64, @floatFromInt(os_freq))});
    std.log.info("CPU timer: {} -> {} = {} elapsed", .{ cpu_start, cpu_end, cpu_elapsed });
    std.log.info("CPU freq: {} (guessed)", .{cpu_freq});
}
