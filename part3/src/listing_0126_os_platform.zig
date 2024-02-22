const std = @import("std");

const vm_statistics = @cImport(@cInclude("mach/vm_statistics.h"));
const metrics = @import("./listing_0108_platform_metrics.zig");

pub fn main() !void {
    const pages = 1000;

    const size = 1024 * 16 * pages;

    var page_faults = metrics.readOSPageFaults();
    var initial_page_faults = metrics.readOSPageFaults();
    var mem0 = try std.os.mmap(null, size, std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.ANONYMOUS | std.os.MAP.PRIVATE, -1, 0);
    defer std.os.munmap(mem0);
    for (0..pages) |idx| {
        mem0[1024 * 16 * idx] = 1;
        page_faults = metrics.readOSPageFaults() - initial_page_faults;
    }
    page_faults = metrics.readOSPageFaults() - initial_page_faults;
    std.log.info("{d}", .{page_faults});

    initial_page_faults = metrics.readOSPageFaults();
    const mem = try std.os.mmap(null, size, std.os.PROT.READ | std.os.PROT.WRITE, std.os.MAP.ANONYMOUS | std.os.MAP.PRIVATE, vm_statistics.VM_MAKE_TAG(vm_statistics.VM_MEMORY_MALLOC_LARGE), 0);
    defer std.os.munmap(mem);
    for (0..pages) |idx| {
        mem[1024 * 16 * idx] = 1;
        page_faults = metrics.readOSPageFaults() - initial_page_faults;
    }
    page_faults = metrics.readOSPageFaults() - initial_page_faults;
    std.log.info("{d}", .{page_faults});

    // NOTE: Macos doesn't have support for large pages :(
    // vm_statistics.VM_MAKE_TAG(vm_statistics.VM_MEMORY_MALLOC_LARGE) is just a tag in the memory that might
    // be useful for an allocator, but the behavior is the same.
}

test {
    std.testing.log_level = .debug;
    std.log.info("", .{});
    try main();
}
