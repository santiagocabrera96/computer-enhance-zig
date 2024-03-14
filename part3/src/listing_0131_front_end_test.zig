// How to run:
// as src/listing_0132_nop_loop.asm -o zig-out/bin/listing_0132_nop_loop.out
// libtool zig-out/bin/listing_0132_nop_loop.out -o zig-out/bin/liblisting_0132_nop_loop.a
// zig build-exe -llisting_0132_nop_loop -L./zig-out/bin -femit-bin=zig-out/bin/listing_0131_front_end_test src/listing_0131_front_end_test.zig -OReleaseSmall -fno-strip
// ./zig-out/bin/listing_0131_front_end_test

const std = @import("std");
const timer = @import("./listing_0108_platform_metrics.zig");
const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
pub const RepetitionTester = repetition_tester.RepetitionTester;
pub const AllocationType = enum { none, malloc };
pub const ReadParameters = struct { dest: []u8, filename: []const u8, allocator: std.mem.Allocator, allocation_type: AllocationType };
const stdout = std.io.getStdOut().writer();

pub fn describeAllocationType(allocation_type: AllocationType) []const u8 {
    const result = switch (allocation_type) {
        .none => "",
        .malloc => "malloc",
    };
    return result;
}

pub fn handleAllocation(params: *ReadParameters, buffer: *[]u8) !void {
    switch (params.allocation_type) {
        .malloc => buffer.* = try params.allocator.alloc(u8, params.dest.len),
        .none => {},
    }
}

pub fn handleDeallocation(params: *ReadParameters, buffer: *[]u8) void {
    switch (params.allocation_type) {
        .malloc => params.allocator.free(buffer.*),
        .none => {},
    }
}

fn printName(fn_name: []const u8, params: *ReadParameters) void {
    stdout.print("\n--- {s}{s}{s} ---\n", .{ describeAllocationType(params.allocation_type), if (params.allocation_type == .none) "" else " + ", fn_name }) catch unreachable;
}

export fn iterateBuffer(dest_buffer_len: usize, dest_buffer: [*]u8) void {
    for (0..dest_buffer_len) |idx| {
        dest_buffer[idx] = @truncate(idx);
    }
}

pub fn writeToAllBytes(tester: *repetition_tester.RepetitionTester, params: *ReadParameters) anyerror!void {
    printName(@src().fn_name, params);
    while (repetition_tester.isTesting(tester)) {
        var dest_buffer = params.dest;
        try handleAllocation(params, &dest_buffer);
        defer handleDeallocation(params, &dest_buffer);

        repetition_tester.beginTime(tester);
        iterateBuffer(dest_buffer.len, @ptrCast(dest_buffer.ptr));
        repetition_tester.endTime(tester);
        repetition_tester.countBytes(tester, dest_buffer.len);
    }
}

extern fn MOVAllBytesAsm(dest_buffer_len: usize, dest_buffer: [*]u8) void;

pub fn writeToAllBytesAsm(tester: *repetition_tester.RepetitionTester, params: *ReadParameters) anyerror!void {
    printName(@src().fn_name, params);
    while (repetition_tester.isTesting(tester)) {
        var dest_buffer = params.dest;
        try handleAllocation(params, &dest_buffer);
        defer handleDeallocation(params, &dest_buffer);

        repetition_tester.beginTime(tester);
        MOVAllBytesAsm(dest_buffer.len, @ptrCast(dest_buffer.ptr));
        repetition_tester.endTime(tester);
        repetition_tester.countBytes(tester, dest_buffer.len);
    }
}

extern fn NOPAllBytesAsm(dest_buffer_len: usize, dest_buffer: [*]u8) void;

pub fn NOPToAllBytesAsm(tester: *repetition_tester.RepetitionTester, params: *ReadParameters) anyerror!void {
    printName(@src().fn_name, params);
    while (repetition_tester.isTesting(tester)) {
        var dest_buffer = params.dest;
        try handleAllocation(params, &dest_buffer);
        defer handleDeallocation(params, &dest_buffer);

        repetition_tester.beginTime(tester);
        NOPAllBytesAsm(dest_buffer.len, @ptrCast(dest_buffer.ptr));
        repetition_tester.endTime(tester);
        repetition_tester.countBytes(tester, dest_buffer.len);
    }
}

extern fn CMPAllBytesAsm(dest_buffer_len: usize, dest_buffer: [*]u8) void;

pub fn CMPToAllBytesAsm(tester: *repetition_tester.RepetitionTester, params: *ReadParameters) anyerror!void {
    printName(@src().fn_name, params);
    while (repetition_tester.isTesting(tester)) {
        var dest_buffer = params.dest;
        try handleAllocation(params, &dest_buffer);
        defer handleDeallocation(params, &dest_buffer);

        repetition_tester.beginTime(tester);
        CMPAllBytesAsm(dest_buffer.len, @ptrCast(dest_buffer.ptr));
        repetition_tester.endTime(tester);
        repetition_tester.countBytes(tester, dest_buffer.len);
    }
}

extern fn DECAllBytesAsm(dest_buffer_len: usize, dest_buffer: [*]u8) void;

pub fn DECToAllBytesAsm(tester: *repetition_tester.RepetitionTester, params: *ReadParameters) anyerror!void {
    printName(@src().fn_name, params);
    while (repetition_tester.isTesting(tester)) {
        var dest_buffer = params.dest;
        try handleAllocation(params, &dest_buffer);
        defer handleDeallocation(params, &dest_buffer);

        repetition_tester.beginTime(tester);
        DECAllBytesAsm(dest_buffer.len, @ptrCast(dest_buffer.ptr));
        repetition_tester.endTime(tester);
        repetition_tester.countBytes(tester, dest_buffer.len);
    }
}

pub fn main() !void {
    const filename = "data_10000000_flex.json";
    const file = try std.fs.cwd().openFile(filename, .{});
    const target_processed_byte_count = (try file.stat()).size;
    const cpu_timer_freq = timer.estimateCPUTimerFreq();
    const seconds_to_try = 10;
    var allocator = std.heap.c_allocator;
    const dest = try allocator.alloc(u8, target_processed_byte_count);
    defer allocator.free(dest);

    try stdout.print("\n", .{});

    const test_functions = [_]fn (*repetition_tester.RepetitionTester, *ReadParameters) anyerror!void{ //
        writeToAllBytes, writeToAllBytesAsm, NOPToAllBytesAsm, CMPToAllBytesAsm, DECToAllBytesAsm,
    };

    var testers = [_]repetition_tester.RepetitionTester{repetition_tester.RepetitionTester{}} ** test_functions.len;

    var read_parameters = ReadParameters{ .dest = dest, .filename = filename, .allocator = allocator, .allocation_type = .none };
    inline for (0..test_functions.len) |func_index| {
        const test_function = test_functions[func_index];

        const tester: *repetition_tester.RepetitionTester = &testers[func_index];
        repetition_tester.newTestWave(tester, dest.len, cpu_timer_freq, seconds_to_try);
        try test_function(tester, &read_parameters);
    }
}

test {
    try main();
}
