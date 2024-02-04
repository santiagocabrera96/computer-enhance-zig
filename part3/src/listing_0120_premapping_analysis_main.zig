const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");
const virtual_address = @import("./listing_0117_virtual_address.zig");

const stdout = std.io.getStdOut().writer();
fn print(comptime format: []const u8, args: anytype) void {
    stdout.print(format, args) catch unreachable;
}

const stderr = std.io.getStdErr().writer();
fn printErr(comptime format: []const u8, args: anytype) void {
    stderr.print(format, args) catch unreachable;
}

fn premappingAnalysis(page_count: u64) !void {
    const page_size = 1024 * 16;
    const total_size = page_count * page_size;

    print("Page count, Touch count, Fault count, Extra faults, L1 TransTable, L2 TransTable, L3 TransTable\n", .{});

    for (0..page_count) |touch_count| {
        const touch_size = page_size * touch_count;
        const data_or_err = std.os.mmap(null, total_size, std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.PRIVATE | std.os.MAP.ANONYMOUS, -1, 0);
        if (data_or_err) |data| {
            defer std.os.munmap(data);

            const start_fault_count = timer.readOSPageFaults();
            for (0..touch_size) |index| {
                data[index] = @truncate(index);
            }
            const end_fault_count = timer.readOSPageFaults();
            const fault_count = end_fault_count - start_fault_count;

            var address = virtual_address.decomposePointer16K(@intFromPtr(data.ptr));
            if (touch_size > 0) {
                address = virtual_address.decomposePointer16K(@intFromPtr(data.ptr) + touch_size - 1);
            }

            print("{d}, {d}, {d}, {d}, {d}, {d}, {d}\n", .{ page_count, touch_count, fault_count, (fault_count - touch_count), address.l1_translation_table, address.l2_translation_table, address.l3_translation_table });
        } else |_| {
            printErr("ERROR: Unable to allocate memory\n", .{});
        }
    }
}

pub fn main() !void {
    if (std.os.argv.len < 2) {
        printErr("Usage: {s} [# of 16k pages to allocate]\n", .{std.os.argv[0]});
        return error.BadUsage;
    }
    const page_count = try std.fmt.parseInt(u64, std.mem.sliceTo(std.os.argv[1], 0), 10);
    try premappingAnalysis(page_count);
}

test {
    try premappingAnalysis(2049);
}
