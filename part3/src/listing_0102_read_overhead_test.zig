const std = @import("std");

const repetition_tester = @import("./listing_0103_repetition_tester.zig");
pub const RepetitionTester = repetition_tester.RepetitionTester;
pub const ReadParameters = struct { dest: []u8, filename: []const u8, allocator: std.mem.Allocator };

pub fn readViaReadToEndAlloc(tester: *RepetitionTester, params: *ReadParameters) anyerror!void {
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
    while (repetition_tester.isTesting(tester)) {
        var file: std.fs.File = undefined;
        {
            errdefer repetition_tester.testerError(tester, "openFile failed");
            file = try std.fs.cwd().openFile(params.filename, .{});
        }
        defer file.close();

        errdefer repetition_tester.testerError(tester, "readToEndAlloc failed");

        repetition_tester.beginTime(tester);
        const size_read = try file.preadAll(params.dest, 0);
        repetition_tester.endTime(tester);

        repetition_tester.countBytes(tester, size_read);
    }
}

pub fn readViaReadAll(tester: *RepetitionTester, params: *ReadParameters) anyerror!void {
    while (repetition_tester.isTesting(tester)) {
        var file: std.fs.File = undefined;
        {
            errdefer repetition_tester.testerError(tester, "openFile failed");
            file = try std.fs.cwd().openFile(params.filename, .{});
        }
        defer file.close();

        errdefer repetition_tester.testerError(tester, "readToEndAlloc failed");

        repetition_tester.beginTime(tester);
        const bytes_read_total = try file.readAll(params.dest);
        repetition_tester.endTime(tester);

        repetition_tester.countBytes(tester, bytes_read_total);
    }
}
