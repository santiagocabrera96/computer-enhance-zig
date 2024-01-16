const std = @import("std");
const timer = @import("./listing_0070_platform_metrics.zig");

pub fn main() void {
    const os_freq = timer.getOSTimerFreq();
    std.log.info("OS Freq: {}", .{os_freq});
    const cpu_start = timer.readCPUTimer();
    const os_start = timer.readOSTimer();
    var os_end: u64 = 0;
    var os_elapsed: u64 = 0;
    while (os_elapsed < os_freq) {
        os_end = timer.readOSTimer();
        os_elapsed = os_end - os_start;
    }
    const cpu_end = timer.readCPUTimer();
    const cpu_elapsed = cpu_end - cpu_start;
    std.log.info("OS timer: {} -> {} = {} elapsed", .{ os_start, os_end, os_elapsed });
    std.log.info("OS seconds: {d:.4}", .{@as(f64, @floatFromInt(os_elapsed)) / @as(f64, @floatFromInt(os_freq))});
    std.log.info("CPU timer: {} -> {} = {} elapsed", .{ cpu_start, cpu_end, cpu_elapsed });
}
