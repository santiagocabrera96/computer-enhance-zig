const std = @import("std");
const haversine_formula = @import("listing_0065_haversine_formula.zig");
const referenceHaversine = haversine_formula.referenceHaversine;

const RandomSeries = struct { a: u64, b: u64, c: u64, d: u64 };

fn rotateLeft(v: u64, comptime shift: comptime_int) u64 {
    const result = ((v << shift) | (v >> (64 - shift)));
    return result;
}

fn randomU64(series: *RandomSeries) u64 {
    var a = series.a;
    var b = series.b;
    var c = series.c;
    var d = series.d;

    const e = a -% rotateLeft(b, 27);

    a = (b ^ rotateLeft(c, 17));
    b = c +% d;
    c = d +% e;
    d = e +% a;

    series.a = a;
    series.b = b;
    series.c = c;
    series.d = d;

    return d;
}

fn seed(value: u64) RandomSeries {
    var series = RandomSeries{ .a = 0xf1ea5eed, .b = value, .c = value, .d = value };
    for (0..20) |_| {
        _ = randomU64(&series);
    }
    return series;
}

fn randomInRange(series: *RandomSeries, min: f64, max: f64) f64 {
    const rand: f64 = @floatFromInt(randomU64(series));
    const t: f64 = rand / std.math.maxInt(u64);
    const result = (1 - t) * min + t * max;
    return result;
}

fn open(pair_count: u128, label: []const u8, extension: []const u8) std.fs.File.OpenError!std.fs.File {
    var buffer: [256]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = std.fmt.allocPrint(allocator, "data_{}_{s}.{s}", .{ pair_count, label, extension }) catch "";

    errdefer |err| std.log.err("{s}. Unable to open \"{s}\" for writing.\n", .{ @errorName(err), filename });

    const file = try std.fs.cwd().createFile(filename, .{ .read = true });

    return file;
}

fn randomDegree(series: *RandomSeries, center: f64, radius: f64, max_allowed: f64) f64 {
    const min_val = @min(center - radius, -max_allowed);
    const max_val = @max(center + radius, max_allowed);

    const result = randomInRange(series, min_val, max_val);
    return result;
}

fn parseArg(index: u8) [:0]const u8 {
    return std.mem.sliceTo(std.os.argv[index], 0);
}

fn generateHaversine(method_name_param: []const u8, seed_value: u64, pair_count: u64) !void {
    var method_name = method_name_param;
    if (!std.mem.eql(u8, method_name, "cluster") and !std.mem.eql(u8, method_name, "uniform")) {
        method_name = "uniform";
        std.log.err("WARNING: Unrecognized method name. Using 'uniform'.\n", .{});
    }

    var cluster_count_left: u64 = std.math.maxInt(u64);
    const max_allowed_x: f64 = 180;
    const max_allowed_y: f64 = 90;
    var x_center: f64 = 0;
    var y_center: f64 = 0;
    var x_radius: f64 = max_allowed_x;
    var y_radius: f64 = max_allowed_y;

    if (std.mem.eql(u8, method_name, "cluster")) {
        cluster_count_left = 0;
    }

    var series = seed(seed_value);
    const max_pair_count: u64 = (1 << 34);

    if (pair_count >= max_pair_count) {
        std.log.err("To avoid accidentally generating massive files, number of pairs must be less than {}.\n", .{max_pair_count});
        return error.PairCountBiggerThanMax;
    }
    const cluster_count_max = 1 + (pair_count / 64);
    const flex_json = try open(pair_count, "flex", "json");
    const haver_answers = try open(pair_count, "haveranswer", "f64");

    try flex_json.writeAll("{\"pairs\":[\n");
    var sum: f64 = 0;
    var sum_coef: f64 = 1.0 / @as(f64, @floatFromInt(pair_count));

    for (0..pair_count) |pair_index| {
        if (cluster_count_left == 0) {
            cluster_count_left = cluster_count_max;
            x_center = randomInRange(&series, -max_allowed_x, max_allowed_x);
            y_center = randomInRange(&series, -max_allowed_y, max_allowed_y);
            x_radius = randomInRange(&series, 0, max_allowed_x);
            y_radius = randomInRange(&series, 0, max_allowed_y);
        }
        cluster_count_left -= 1;

        const x0 = randomDegree(&series, x_center, x_radius, max_allowed_x);
        const y0 = randomDegree(&series, y_center, y_radius, max_allowed_y);
        const x1 = randomDegree(&series, x_center, x_radius, max_allowed_x);
        const y1 = randomDegree(&series, y_center, y_radius, max_allowed_y);

        const earth_radius: f64 = 6372.8;
        const haversine_distance = referenceHaversine(x0, y0, x1, y1, earth_radius);

        sum += sum_coef * haversine_distance;

        const json_sep = if (pair_index == (pair_count - 1)) "\n" else ",\n";
        try std.fmt.format(flex_json.writer(), "    {{\"x0\":{d:.16}, \"y0\":{d:.16}, \"x1\":{d:.16}, \"y1\":{d:.16}}}{s}", .{ x0, y0, x1, y1, json_sep });
        try haver_answers.writeAll(std.mem.asBytes(&haversine_distance));
    }
    try flex_json.writeAll("]}\n");
    try haver_answers.writeAll(std.mem.asBytes(&sum));

    std.log.info("Method: {s}\n", .{method_name});
    std.log.info("Random seed: {d}\n", .{seed_value});
    std.log.info("Pair count: {d}\n", .{pair_count});
    std.log.info("Expected sum: {d:.16}\n", .{sum});
}

pub fn main() !void {
    if (std.os.argv.len != 4) {
        std.log.err("Usage: {s} [uniform/cluster] [random seed] [number of coordinate pairs to generate]\n", .{std.os.argv[0]});
        return;
    }

    var method_name = parseArg(1);
    const seed_value = try std.fmt.parseInt(u64, parseArg(2), 10);
    const pair_count = try std.fmt.parseInt(u64, parseArg(3), 10);

    try generateHaversine(method_name, seed_value, pair_count);
}

test {
    try generateHaversine("uniform", 10, 2);
}
