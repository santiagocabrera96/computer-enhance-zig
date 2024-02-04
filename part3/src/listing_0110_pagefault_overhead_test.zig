const std = @import("std");

const repetition_tester = @import("./listing_0109_pagefault_repetition_tester.zig");
pub const RepetitionTester = repetition_tester.RepetitionTester;
pub const AllocationType = enum { malloc, none };
pub const ReadParameters = struct { dest: []u8, filename: []const u8, allocator: std.mem.Allocator, allocation_type: AllocationType };
const stdout = std.io.getStdOut().writer();

pub fn describeAllocationType(allocation_type: AllocationType) []const u8 {
    const result = switch (allocation_type) {
        .none => "",
        .malloc => "malloc",
    };
    return result;
}

fn handleAllocation(params: *ReadParameters, buffer: *[]u8) !void {
    switch (params.allocation_type) {
        .malloc => buffer.* = try params.allocator.alloc(u8, params.dest.len),
        .none => {},
    }
}

fn handleDeallocation(params: *ReadParameters, buffer: *[]u8) void {
    switch (params.allocation_type) {
        .malloc => params.allocator.free(buffer.*),
        .none => {},
    }
}

fn printName(fn_name: []const u8, params: *ReadParameters) void {
    stdout.print("\n--- {s}{s}{s} ---\n", .{ describeAllocationType(params.allocation_type), if (params.allocation_type == .none) "" else " + ", fn_name }) catch unreachable;
}

pub fn readViaReadToEndAlloc(tester: *RepetitionTester, params: *ReadParameters) anyerror!void {
    printName(@src().fn_name, params);
    while (repetition_tester.isTesting(tester)) {
        var file: std.fs.File = undefined;
        {
            errdefer repetition_tester.testerError(tester, "openFile failed");
            file = try std.fs.cwd().openFile(params.filename, .{});
        }
        defer file.close();

        var allocator = params.allocator;

        errdefer repetition_tester.testerError(tester, "readToEndAlloc failed");

        repetition_tester.beginTime(tester);
        const res = try file.readToEndAlloc(allocator, params.dest.len);
        repetition_tester.endTime(tester);

        defer allocator.free(res);

        repetition_tester.countBytes(tester, res.len);
    }
}

pub fn readViaPReadAll(tester: *RepetitionTester, params: *ReadParameters) anyerror!void {
    printName(@src().fn_name, params);
    while (repetition_tester.isTesting(tester)) {
        var file: std.fs.File = undefined;
        {
            errdefer repetition_tester.testerError(tester, "openFile failed");
            file = try std.fs.cwd().openFile(params.filename, .{});
        }
        defer file.close();

        errdefer repetition_tester.testerError(tester, "readViaPReadAll failed");

        var dest_buffer = params.dest;
        try handleAllocation(params, &dest_buffer);
        defer handleDeallocation(params, &dest_buffer);

        repetition_tester.beginTime(tester);
        const size_read = try file.preadAll(dest_buffer, 0);
        repetition_tester.endTime(tester);

        repetition_tester.countBytes(tester, size_read);
    }
}

pub fn readViaReadAll(tester: *RepetitionTester, params: *ReadParameters) anyerror!void {
    printName(@src().fn_name, params);
    while (repetition_tester.isTesting(tester)) {
        var file: std.fs.File = undefined;
        {
            errdefer repetition_tester.testerError(tester, "openFile failed");
            file = try std.fs.cwd().openFile(params.filename, .{});
        }
        defer file.close();

        errdefer repetition_tester.testerError(tester, "readViaReadAll failed");

        var dest_buffer = params.dest;
        try handleAllocation(params, &dest_buffer);
        defer handleDeallocation(params, &dest_buffer);

        repetition_tester.beginTime(tester);
        const bytes_read_total = try file.readAll(dest_buffer);
        repetition_tester.endTime(tester);

        repetition_tester.countBytes(tester, bytes_read_total);
    }
}

pub fn writeToAllBytes(tester: *RepetitionTester, params: *ReadParameters) anyerror!void {
    printName(@src().fn_name, params);
    while (repetition_tester.isTesting(tester)) {
        var dest_buffer = params.dest;
        try handleAllocation(params, &dest_buffer);
        defer handleDeallocation(params, &dest_buffer);

        repetition_tester.beginTime(tester);
        for (0..dest_buffer.len) |idx| {
            dest_buffer[idx] = @truncate(idx);
        }
        repetition_tester.endTime(tester);
        repetition_tester.countBytes(tester, dest_buffer.len);
    }
}

pub fn main() !void {
    const timer = @import("./listing_0108_platform_metrics.zig");
    const filename = "data_10000000_flex.json";
    const file = try std.fs.cwd().openFile(filename, .{});
    const target_processed_byte_count = (try file.stat()).size;
    const cpu_timer_freq = timer.estimateCPUTimerFreq();
    const seconds_to_try = 10;
    var allocator = std.heap.c_allocator;
    const dest = try allocator.alloc(u8, target_processed_byte_count);
    defer allocator.free(dest);

    try stdout.print("\n", .{});

    const test_functions = [_]fn (*RepetitionTester, *ReadParameters) anyerror!void{
        writeToAllBytes,
        readViaPReadAll,
        readViaReadAll,
        readViaReadToEndAlloc,
    };

    const allocation_types = comptime std.enums.values(AllocationType);
    var testers = [_][allocation_types.len]RepetitionTester{ //
    [_]RepetitionTester{RepetitionTester{}} ** allocation_types.len} ** test_functions.len;

    var read_parameters = ReadParameters{ .dest = dest, .filename = filename, .allocator = allocator, .allocation_type = .none };
    inline for (0..test_functions.len) |func_index| {
        const test_function = test_functions[func_index];
        inline for (allocation_types, 0..) |allocation_type, idx| {
            read_parameters.allocation_type = allocation_type;
            const tester: *RepetitionTester = &testers[func_index][idx];
            repetition_tester.newTestWave(tester, dest.len, cpu_timer_freq, seconds_to_try);
            try test_function(tester, &read_parameters);
        }
    }
}

test {
    const timer = @import("./listing_0074_platform_metrics.zig");
    // const filename = "data_1_flex.json";
    const filename = "data_10000000_flex.json";
    const file = try std.fs.cwd().openFile(filename, .{});
    const target_processed_byte_count = (try file.stat()).size;
    const cpu_timer_freq = timer.estimateCPUTimerFreq();
    const seconds_to_try = 10;
    var allocator = std.testing.allocator;
    const dest = try allocator.alloc(u8, target_processed_byte_count);
    defer allocator.free(dest);

    try stdout.print("\n", .{});

    const test_functions = [_]fn (*RepetitionTester, *ReadParameters) anyerror!void{
        writeToAllBytes,
        readViaPReadAll,
        readViaReadAll,
        readViaReadToEndAlloc,
    };

    const allocation_types = comptime std.enums.values(AllocationType);
    var testers = [_][allocation_types.len]RepetitionTester{ //
    [_]RepetitionTester{RepetitionTester{}} ** allocation_types.len} ** test_functions.len;

    var read_parameters = ReadParameters{ .dest = dest, .filename = filename, .allocator = allocator, .allocation_type = .none };
    inline for (0..test_functions.len) |func_index| {
        const test_function = test_functions[func_index];
        inline for (allocation_types, 0..) |allocation_type, idx| {
            read_parameters.allocation_type = allocation_type;
            const tester: *RepetitionTester = &testers[func_index][idx];
            repetition_tester.newTestWave(tester, dest.len, cpu_timer_freq, seconds_to_try);
            try test_function(tester, &read_parameters);
        }
    }
}
