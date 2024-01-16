const std = @import("std");

const timer = @import("./listing_0074_platform_metrics.zig");

const ProfileAnchor = struct {
    tsc_elapsed: u64 = 0,
    hit_count: u64 = 0,
    label: []const u8 = undefined,
};

const Profiler = struct {
    anchors: [4096]ProfileAnchor = [_]ProfileAnchor{ProfileAnchor{}} ** 4096,
    anchors_used: u64 = 0,
    start_tsc: u64 = undefined,
    end_tsc: u64 = undefined,
};

var global_profiler = Profiler{};

// Calling convention
// const block = profiler.timeBlockStart(@src().fn_name);
// defer profiler.timeBlockEnd(block);
pub inline fn timeBlockStart(name: []const u8) struct { index: u64, start: u64 } {
    const Idx = struct {
        var curr: u64 = 0;
    };

    if (Idx.curr == 0) {
        std.debug.assert(global_profiler.anchors_used < global_profiler.anchors.len);
        global_profiler.anchors_used += 1;
        Idx.curr = global_profiler.anchors_used;
        global_profiler.anchors[Idx.curr] = ProfileAnchor{ .label = name };
    }

    const start = timer.readCPUTimer();

    return .{ .index = Idx.curr, .start = start };
}

pub fn timeBlockEnd(block: anytype) void {
    global_profiler.anchors[block.index].tsc_elapsed += timer.readCPUTimer() - block.start;
    global_profiler.anchors[block.index].hit_count += 1;
}

pub fn beginProfile() void {
    global_profiler.start_tsc = timer.readCPUTimer();
}

pub fn endAndPrintProfile() void {
    global_profiler.end_tsc = timer.readCPUTimer();
    const timer_freq = timer.estimateCPUTimerFreq();

    const total_elapsed_f64: f64 = @floatFromInt(global_profiler.end_tsc - global_profiler.start_tsc);

    const total_elapsed_time_ms: f64 = total_elapsed_f64 * (1000 / @as(f64, @floatFromInt(timer_freq)));
    std.log.info("Total time: {d:.4}ms (CPU freq {})", .{ total_elapsed_time_ms, timer_freq });

    for (global_profiler.anchors) |anchor| {
        if (anchor.tsc_elapsed > 0) {
            std.log.info("  {s}[{}]: {} ({d:.2}%)", .{ anchor.label, anchor.hit_count, anchor.tsc_elapsed, @as(f64, @floatFromInt(anchor.tsc_elapsed)) * 100 / total_elapsed_f64 });
        }
    }
}
