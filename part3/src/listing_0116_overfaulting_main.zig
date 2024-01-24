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
    var data_or_err = std.os.mmap(null, total_size, std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.PRIVATE | std.os.MAP.ANONYMOUS, -1, 0);
    if (data_or_err) |data| {
        defer std.os.munmap(data);

        const start_fault_count = timer.readOSPageFaults();

        var prior_over_fault_count: u64 = 0;
        var prior_page_index: u64 = 0;

        for (0..page_count) |page_index| {
            data[total_size - 1 - page_size * page_index] = @truncate(page_index);
            const end_fault_count = timer.readOSPageFaults();

            const over_fault_count = (end_fault_count - start_fault_count) - page_index;
            if (over_fault_count > prior_over_fault_count) {
                print("Page {d}: {d} extra faults ({d} pages since last increase)\n", .{ page_index, over_fault_count, (page_index - prior_page_index) });
                prior_over_fault_count = over_fault_count;
                prior_page_index = page_index;
            }
        }
    } else |_| {
        printErr("ERROR: Unable to allocate memory\n", .{});
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
    print("\n", .{});
    const number_of_pages = 1024 * 16;
    try osFaultCounter(number_of_pages);
}
