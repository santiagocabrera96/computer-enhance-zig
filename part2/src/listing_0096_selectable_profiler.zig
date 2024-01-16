const std = @import("std");

const timer = @import("./listing_0074_platform_metrics.zig");

const ProfileAnchor = struct {
    tsc_elapsed_exclusive: u64 = 0, // Note: Without children
    tsc_elapsed_inclusive: u64 = 0, // Note: With children
    hit_count: u64 = 0,
    label: []const u8 = undefined,
};

const Profiler = struct {
    anchors: [4096]ProfileAnchor = [_]ProfileAnchor{ProfileAnchor{}} ** 4096,
    anchors_used: u64 = 0,
    start_tsc: u64 = undefined,
    end_tsc: u64 = undefined,
    do_profile: bool = false,
};

var global_profiler = Profiler{};
var global_profiler_parent: u64 = 0;

pub var use_os_timer = false;

fn readTimer() u64 {
    if (use_os_timer) {
        return timer.readOSTimer();
    }
    return timer.readCPUTimer();
}

fn getTimerFreq() u64 {
    if (use_os_timer) {
        return timer.getOSTimerFreq();
    }
    return timer.estimateCPUTimerFreq();
}

// Calling convention
// const block = profiler.timeBlockStart(@src().fn_name);
// defer profiler.timeBlockEnd(block);
pub inline fn timeBlockStart(name: []const u8) struct { index: u64, start_tsc: u64, parent_index: u64, old_tsc_elapsed_inclusive: u64 } {
    if (!global_profiler.do_profile) return .{ .index = 0, .start_tsc = 0, .parent_index = 0, .old_tsc_elapsed_inclusive = 0 };

    const I = struct {
        var idx: u64 = 0;
    };

    if (I.idx == 0) {
        std.debug.assert(global_profiler.anchors_used < global_profiler.anchors.len);
        global_profiler.anchors_used += 1;
        I.idx = global_profiler.anchors_used;
        global_profiler.anchors[I.idx] = ProfileAnchor{ .label = name };
    }
    const anchor = global_profiler.anchors[I.idx];

    const start_tsc = readTimer();
    const parent_index = global_profiler_parent;

    global_profiler_parent = I.idx;

    return .{ .index = I.idx, .start_tsc = start_tsc, .parent_index = parent_index, .old_tsc_elapsed_inclusive = anchor.tsc_elapsed_inclusive };
}

pub fn timeBlockEnd(block: anytype) void {
    if (!global_profiler.do_profile) return;

    global_profiler_parent = block.parent_index;

    const elapsed = readTimer() -% block.start_tsc;

    var parent = &global_profiler.anchors[block.parent_index];
    parent.tsc_elapsed_exclusive -%= elapsed;

    var anchor = &global_profiler.anchors[block.index];
    anchor.tsc_elapsed_exclusive +%= elapsed;
    anchor.tsc_elapsed_inclusive = elapsed +% block.old_tsc_elapsed_inclusive;
    anchor.hit_count += 1;
}

pub fn beginProfile(do_profile: bool) void {
    global_profiler.do_profile = do_profile;
    global_profiler.start_tsc = readTimer();
}

pub fn endAndPrintProfile() void {
    global_profiler.end_tsc = readTimer();
    const timer_freq = getTimerFreq();

    const stdout = std.io.getStdOut().writer();

    const total_elapsed_f64: f64 = @floatFromInt(global_profiler.end_tsc -% global_profiler.start_tsc);

    const total_elapsed_time_ms: f64 = total_elapsed_f64 * (1000 / @as(f64, @floatFromInt(timer_freq)));
    std.log.info("Total time: {d:.4}ms (CPU freq {})", .{ total_elapsed_time_ms, timer_freq });

    for (global_profiler.anchors) |anchor| {
        if (anchor.tsc_elapsed_inclusive > 0) {
            const percent_elapsed = @as(f64, @floatFromInt(anchor.tsc_elapsed_exclusive)) * 100 / total_elapsed_f64;
            stdout.print("info:   {s}[{}]: {} ({d:.2}%", .{ anchor.label, anchor.hit_count, anchor.tsc_elapsed_exclusive, percent_elapsed }) catch unreachable;
            if (anchor.tsc_elapsed_exclusive != anchor.tsc_elapsed_inclusive) {
                const percent_elapsed_with_children = @as(f64, @floatFromInt(anchor.tsc_elapsed_inclusive)) * 100 / total_elapsed_f64;
                stdout.print(", {d:.2}% w/children", .{percent_elapsed_with_children}) catch unreachable;
            }
            stdout.print(")\n", .{}) catch unreachable;
        }
    }
}
