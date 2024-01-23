const std = @import("std");

const timer = @import("./listing_0108_platform_metrics.zig");

const page_size = 16 * 1024;
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

fn print(comptime format: []const u8, args: anytype) void {
    stdout.print(format, args) catch unreachable;
}

fn printErr(comptime format: []const u8, args: anytype) void {
    stderr.print(format, args) catch unreachable;
}

fn osFaultCounter(page_count: u64) !void {
    const total_size = page_count * page_size;

    print("Page Count, Touch Count, Fault Count, Extra Faults \n", .{});

    for (0..page_count) |touch_count| {
        const touch_size = page_size * touch_count;

        var data_or_err = std.os.mmap(null, total_size, std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.PRIVATE | std.os.MAP.ANONYMOUS, -1, 0);
        if (data_or_err) |data| {
            defer std.os.munmap(data);

            const start_fault_count = timer.readOSPageFaults();
            for (0..touch_size) |index| {
                data[index] = @truncate(index);
            }
            const end_fault_count = timer.readOSPageFaults();
            const fault_count = end_fault_count - start_fault_count;

            print("{d}, {d}, {d}, {d}\n", .{ page_count, touch_count, fault_count, (fault_count - touch_count) });
        } else |_| {
            printErr("ERROR: Unable to allocate memory\n", .{});
        }
    }
}

pub fn main() !void {
    if (std.os.argv.len < 2) {
        printErr("Usage: {s} [# of pages to allocate]\n", .{std.os.argv[0]});
        return;
    }
    const page_count = std.fmt.parseInt(u64, std.mem.sliceTo(std.os.argv[1], 0), 10);
    try osFaultCounter(page_count);
}

test {
    const number_of_pages = 4096;
    try osFaultCounter(number_of_pages);
}
