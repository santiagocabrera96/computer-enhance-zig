const std = @import("std");
const profiler = @import("./listing_0100_bandwidth_profiler.zig");
const haversine_formula = @import("./listing_0065_haversine_formula.zig");
const referenceHaversine = haversine_formula.referenceHaversine;
const parseHaversinePairs = @import("./listing_0100_profiled_lookup_json_parser.zig").parseHaversinePairs;
const HaversinePair = haversine_formula.HaversinePair;

fn readEntireFile(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const block = profiler.timeBlockStart(@src().fn_name);
    defer profiler.timeBlockEnd(block);

    errdefer |err| std.log.err("ERROR: {s} Unable to read \"{s}\".\n", .{ @errorName(err), filename });
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const stat = try file.stat();
    const file_size = stat.size;
    const fread_block = profiler.timeBandwidth("readToEndAlloc", file_size);

    const result = try file.readToEndAlloc(allocator, file_size);
    profiler.timeBlockEnd(fread_block);

    return result;
}

fn sumHaversineDistances(pair_count: u64, pairs: []const HaversinePair) f64 {
    const block = profiler.timeBandwidth(@src().fn_name, pair_count * @sizeOf(HaversinePair));
    defer profiler.timeBlockEnd(block);

    var sum: f64 = 0;
    const sum_coef: f64 = 1 / @as(f64, @floatFromInt(pair_count));
    for (pairs, 0..) |pair, idx| {
        if (idx >= pair_count) {
            break;
        }
        const earth_radius: f64 = 6372.8;
        const dist = referenceHaversine(pair.x0, pair.y0, pair.x1, pair.y1, earth_radius);
        sum += (sum_coef * dist);
    }
    return sum;
}

pub fn simpleHaversineMain(allocator: std.mem.Allocator, input_json_filename: []const u8, answers_filename: ?[]const u8) !void {
    profiler.beginProfile(true);

    const input_json = try readEntireFile(allocator, input_json_filename);
    defer allocator.free(input_json);

    const minimum_json_pair_encoding: u32 = 6 * 4;
    const max_pair_count = input_json.len / minimum_json_pair_encoding;

    if (max_pair_count == 0) {
        std.log.err("ERROR: Malformed input JSON\n", .{});
        return;
    }
    const pairs: []HaversinePair = try allocator.alloc(HaversinePair, max_pair_count);
    defer allocator.free(pairs);

    const pair_count = parseHaversinePairs(allocator, input_json, max_pair_count, pairs);

    const sum = sumHaversineDistances(pair_count, pairs);

    std.log.info("Input size: {d}", .{input_json.len});
    std.log.info("Pair count: {d}", .{pair_count});
    std.log.info("Haversine sum: {d:.16}", .{sum});

    profiler.endAndPrintProfile();

    if (answers_filename) |_| {
        const answers_f64 = try readEntireFile(allocator, answers_filename.?);
        defer allocator.free(answers_f64);

        if (answers_f64.len >= @sizeOf(f64)) {
            const answer_values: []f64 = std.mem.bytesAsSlice(f64, @as([]align(@sizeOf(f64)) u8, @alignCast(answers_f64)));
            std.log.info("", .{});
            std.log.info("Validation", .{});
            const ref_answer_count = answer_values.len - 1;
            if (pair_count != ref_answer_count) {
                std.log.err("FAILED - pair count doesn't match {d}.", .{pair_count});
            }

            const ref_sum = answer_values[ref_answer_count];
            std.log.info("Reference sum: {d:.16}", .{ref_sum});
            std.log.info("Difference: {d:.16}", .{sum - ref_sum});
            std.log.info("", .{});
        }
    }
}

pub fn main() !void {
    const allocator = std.heap.c_allocator;

    if (std.os.argv.len != 2 and std.os.argv.len != 3) {
        std.log.err("Usage: {s} [haversine_input.json]\n", .{std.os.argv[0]});
        std.log.err("       {s} [haversine_input.json] [answers.f64]\n", .{std.os.argv[0]});
        return;
    }

    const input_json_filename = std.mem.sliceTo(std.os.argv[1], 0);
    const answers_filename = if (std.os.argv.len == 3) std.mem.sliceTo(std.os.argv[2], 0) else null;
    try simpleHaversineMain(allocator, input_json_filename, answers_filename);
}

test {
    // const allocator = std.testing.allocator;
    // try simpleHaversineMain(allocator, "data_10_flex.json", "data_10_haveranswer.f64");
    std.debug.print("{d}\n", .{@sizeOf(HaversinePair)});
}
