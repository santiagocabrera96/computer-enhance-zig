const std = @import("std");

const page_size = std.mem.page_size;

const timer = @import("./listing_0074_platform_metrics.zig");

fn deallocateCircularBuffer(memory: []align(page_size) const u8, rep_count: u8) void {
    std.os.munmap(memory.ptr[0..(memory.len * rep_count)]);
}

fn allocateCircularBuffer(minimum_size: u32, rep_count: u8) ![]align(page_size) u8 {
    const number_of_pages = (minimum_size / (page_size + 1)) + 1;
    const total_size = page_size * number_of_pages;
    var buf: [1024]u8 = undefined;
    const res: [:0]const u8 = try std.fmt.bufPrintZ(&buf, "circular_buffer_{d}", .{timer.readCPUTimer()});
    const fd = std.os.darwin.shm_open(res, std.os.O.CREAT | std.os.O.RDWR, 0);
    std.debug.assert(std.os.darwin.shm_unlink(res) == 0);
    std.debug.assert(std.os.darwin.ftruncate(fd, total_size) == 0);

    const base = try std.os.mmap(
        null,
        total_size * rep_count,
        std.os.PROT.NONE,
        std.os.MAP.PRIVATE | std.os.MAP.ANONYMOUS,
        -1,
        0,
    );

    for (0..rep_count) |idx| {
        _ = try std.os.mmap(
            @alignCast(base[(total_size * idx)..].ptr),
            total_size,
            std.os.PROT.READ | std.os.PROT.WRITE,
            std.os.MAP.SHARED | std.os.MAP.FIXED,
            fd,
            0,
        );
    }

    return base[0..total_size];
}

pub fn main() !void {
    const size = 1024 * 16;
    const rep_count = 10;
    const memory = try allocateCircularBuffer(size, rep_count);
    defer deallocateCircularBuffer(memory, rep_count);

    const hello_world = "Hello, world";
    const number_of_bytes_to_print = hello_world.len;

    std.mem.copyForwards(u8, memory, hello_world);

    std.log.info("", .{});
    for (0..rep_count) |idx| {
        const mem: []const u8 = memory.ptr[idx * memory.len .. ((idx + 1) * memory.len)];
        std.log.info("Ptr: {x}  [{d}]: {s}", .{ @intFromPtr(mem.ptr), idx * memory.len, mem[0..number_of_bytes_to_print] });
    }
}

test {
    std.testing.log_level = .info;
    try main();
}
