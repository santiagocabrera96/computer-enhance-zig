const std = @import("std");

const DecomposedVirtualAddress = struct {
    unused_bits: u16,
    l0_translation_table: u1,
    l1_translation_table: u11,
    l2_translation_table: u11,
    l3_translation_table: u11,
    offset: u11,
};

const stdout = std.io.getStdOut().writer();
fn print(comptime format: []const u8, args: anytype) void {
    stdout.print(format, args) catch unreachable;
}

const stderr = std.io.getStdErr().writer();
fn printErr(comptime format: []const u8, args: anytype) void {
    stderr.print(format, args) catch unreachable;
}

fn printAddress(address: DecomposedVirtualAddress) void {
    print("|{d:5}|{d:1}|{d:4}|{d:4}|{d:4}|{d:5}|", address);
}

pub fn printAsLine(label: []const u8, address: DecomposedVirtualAddress) void {
    print("{s}", .{label});
    printAddress(address);
    print("\n", .{});
}

pub fn decomposePointer16K(address: u64) DecomposedVirtualAddress {
    const result = DecomposedVirtualAddress{
        .unused_bits = @truncate((address >> (64 - 16)) & (1 << 16)),
        .l0_translation_table = @truncate((address >> (64 - 16 - 1)) & std.math.maxInt(u1)),
        .l1_translation_table = @truncate((address >> (64 - 16 - 1 - 11)) & std.math.maxInt(u11)),
        .l2_translation_table = @truncate((address >> (64 - 16 - 1 - 11 - 11)) & std.math.maxInt(u11)),
        .l3_translation_table = @truncate((address >> (64 - 16 - 1 - 11 - 11 - 11)) & std.math.maxInt(u11)),
        .offset = @truncate((address >> (64 - 16 - 1 - 11 - 11 - 11 - 14)) & std.math.maxInt(u14)),
    };
    return result;
}

test {
    print("\n", .{});
    const page_size = 1024 * 16;
    const page_count = 1;
    const total_size = page_size * page_count;

    var data = try std.os.mmap(null, total_size, std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.PRIVATE | std.os.MAP.ANONYMOUS, -1, 0);
    defer std.os.munmap(data);

    print("|", .{});
    inline for (@typeInfo(DecomposedVirtualAddress).Struct.fields) |field| {
        print("{s}|", .{field.name});
    }
    print("\n", .{});
    printAddress(decomposePointer16K(@intFromPtr(data.ptr)));
    print("\n", .{});
}
