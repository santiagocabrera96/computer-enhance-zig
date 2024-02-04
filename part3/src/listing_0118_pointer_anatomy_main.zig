const std = @import("std");
const virtual_address = @import("./listing_0117_virtual_address.zig");

const stdout = std.io.getStdOut().writer();
fn print(comptime format: []const u8, args: anytype) void {
    stdout.print(format, args) catch unreachable;
}

const stderr = std.io.getStdErr().writer();
fn printErr(comptime format: []const u8, args: anytype) void {
    stderr.print(format, args) catch unreachable;
}

fn printBinaryBits(value: u64, first_bit: u32, bit_count: u32) void {
    for (0..bit_count) |idx| {
        const shift_value: u6 = @truncate(first_bit + bit_count - 1 - idx);
        const bit = (value >> shift_value) & 1;
        const char: u8 = if (bit == 0) '0' else '1';
        print("{c}", .{char});
    }
}

pub fn main() !void {
    for (0..200) |_| {
        const data = try std.os.mmap(null, 1024 * 1024, std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.PRIVATE | std.os.MAP.ANONYMOUS, -1, 0);
        const address = @intFromPtr(data.ptr);
        printBinaryBits(address, 64 - 16, 16);
        print("|", .{});
        printBinaryBits(address, 64 - 16 - 1, 1);
        print("|", .{});
        printBinaryBits(address, 64 - 16 - 1 - 11, 11);
        print("|", .{});
        printBinaryBits(address, 64 - 16 - 1 - 11 - 11, 11);
        print("|", .{});
        printBinaryBits(address, 64 - 16 - 1 - 11 - 11 - 11, 11);
        print("|", .{});
        printBinaryBits(address, 64 - 16 - 1 - 11 - 11 - 11 - 14, 14);
        print("\n", .{});

        virtual_address.printAsLine("16K paging: ", virtual_address.decomposePointer16K(address));
    }
}

test {
    print("\n", .{});
    try main();
}
