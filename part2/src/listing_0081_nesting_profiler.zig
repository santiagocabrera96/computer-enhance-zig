const std = @import("std");

const timer = @import("./listing_0074_platform_metrics.zig");

const ProfileAnchor = struct {
    tsc_elapsed: u64 = 0,
    tsc_elapsed_children: u64 = 0,
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
var global_profiler_parent: u64 = 0;

// Calling convention
// const block = profiler.timeBlockStart(@src().fn_name);
// defer profiler.timeBlockEnd(block);
pub inline fn timeBlockStart(name: []const u8) struct { index: u64, start: u64, parent_index: u64 } {
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
    const parent_index = global_profiler_parent;

    global_profiler_parent = Idx.curr;

    return .{ .index = Idx.curr, .start = start, .parent_index = parent_index };
}

pub fn timeBlockEnd(block: anytype) void {
    global_profiler_parent = block.parent_index;

    const elapsed = timer.readCPUTimer() - block.start;

    var parent = &global_profiler.anchors[block.parent_index];
    parent.tsc_elapsed_children += elapsed;

    var anchor = &global_profiler.anchors[block.index];
    anchor.tsc_elapsed += elapsed;
    anchor.hit_count += 1;
}

pub fn beginProfile() void {
    global_profiler.start_tsc = timer.readCPUTimer();
}

pub fn endAndPrintProfile() void {
    global_profiler.end_tsc = timer.readCPUTimer();
    const timer_freq = timer.estimateCPUTimerFreq();

    const stdout = std.io.getStdOut().writer();

    const total_elapsed_f64: f64 = @floatFromInt(global_profiler.end_tsc - global_profiler.start_tsc);

    const total_elapsed_time_ms: f64 = total_elapsed_f64 * (1000 / @as(f64, @floatFromInt(timer_freq)));
    std.log.info("Total time: {d:.4}ms (CPU freq {})", .{ total_elapsed_time_ms, timer_freq });

    for (global_profiler.anchors) |anchor| {
        if (anchor.tsc_elapsed > 0) {
            const elapsed = anchor.tsc_elapsed - anchor.tsc_elapsed_children;
            const percent_elapsed = @as(f64, @floatFromInt(elapsed)) * 100 / total_elapsed_f64;
            stdout.print("info:   {s}[{}]: {} ({d:.2}%", .{ anchor.label, anchor.hit_count, elapsed, percent_elapsed }) catch unreachable;
            if (anchor.tsc_elapsed_children > 0) {
                const percent_elapsed_with_children = @as(f64, @floatFromInt(anchor.tsc_elapsed)) * 100 / total_elapsed_f64;
                stdout.print(", {d:.2}% w/children", .{percent_elapsed_with_children}) catch unreachable;
            }
            stdout.print(")\n", .{}) catch unreachable;
        }
    }
}
