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

pub fn main() !void {
    const page_size = 1024 * 16;
    const page_count = 16384;
    const total_size = page_count * page_size;

    const data_or_err = std.os.mmap(null, total_size, std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.PRIVATE | std.os.MAP.ANONYMOUS, -1, 0);
    if (data_or_err) |data| {
        defer std.os.munmap(data);

        virtual_address.printAsLine("Buffer base: ", virtual_address.decomposePointer16K(@intFromPtr(data.ptr)));
        print("\n", .{});

        const start_fault_count = timer.readOSPageFaults();
        var prior_over_fault_count: u64 = 0;

        var prior_page_index: u64 = 0;
        for (0..page_count) |page_index| {
            data[total_size - 1 - (page_size * page_index)] = @truncate(page_index);
            const end_fault_count = timer.readOSPageFaults();

            const over_fault_count = (end_fault_count - start_fault_count) - page_index;
            if (over_fault_count > prior_over_fault_count) {
                print("Page {d}: {d} extra faults ({d} pages since last increase)\n", .{ page_index, over_fault_count, (page_index - prior_page_index) });
                if (page_index > 0) {
                    virtual_address.printAsLine("     Previous Pointer: ", virtual_address.decomposePointer16K(@intFromPtr(data.ptr) + total_size - 1 - (page_size * (page_index - 1))));
                }
                virtual_address.printAsLine("         This Pointer: ", virtual_address.decomposePointer16K(@intFromPtr(data.ptr) + total_size - 1 - (page_size * page_index)));

                prior_over_fault_count = over_fault_count;
                prior_page_index = page_index;
            }
        }
    } else |_| {
        printErr("ERROR: Unable to allocate memory\n", .{});
    }
}

test {
    print("\n", .{});
    try main();
    print("\n", .{});
}
