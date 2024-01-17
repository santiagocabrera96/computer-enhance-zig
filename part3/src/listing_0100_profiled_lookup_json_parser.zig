const std = @import("std");
const profiler = @import("./listing_0100_bandwidth_profiler.zig");
const haversine_formula = @import("listing_0065_haversine_formula.zig");
const HaversinePair = haversine_formula.HaversinePair;
const Allocator = std.mem.Allocator;

const JsonTokenType = enum { end_of_stream, err, open_brace, open_bracket, close_brace, close_bracket, comma, colon, semi_colon, string_literal, number, true, false, null };
const JsonToken = struct { type: JsonTokenType, value: []const u8 };
const JsonElement = struct { label: []const u8, value: []const u8, first_sub_element: ?*JsonElement, next_sibling: ?*JsonElement };
const JsonParser = struct { source: []const u8, at: u64 = 0, had_error: bool = false };
const InvalidJsonError = error{InvalidJson} || std.mem.Allocator.Error;

fn isJsonDigit(source: []const u8, at: u64) bool {
    var result = false;
    if (at < source.len) {
        const val = source[at];
        result = (val >= '0' and val <= '9');
    }
    return result;
}

fn isJsonWhitespace(source: []const u8, at: u64) bool {
    var result = false;
    if (at < source.len) {
        const val = source[at];
        result = (val == ' ' or val == '\t' or val == '\n' or val == '\r');
    }
    return result;
}

fn isParsing(parser: JsonParser) bool {
    const result = !parser.had_error and parser.source.len > parser.at;
    return result;
}

fn parserError(parser: *JsonParser, token: JsonToken, message: []const u8) void {
    parser.had_error = true;
    std.log.err("ERROR: \"{d}\" - {s}", .{ token.value, message });
}

fn parseKeyword(source: []const u8, at: *u64, keyword_remaining: []const u8, token_type: JsonTokenType, result: *JsonToken) void {
    if ((source.len - at.*) >= keyword_remaining.len) {
        const check = source[at.*..(at.* + keyword_remaining.len)];
        if (std.mem.eql(u8, check, keyword_remaining)) {
            result.type = token_type;
            result.value.len += keyword_remaining.len;
            at.* = at.* + keyword_remaining.len;
        }
    }
}

fn getJsonToken(parser: *JsonParser) JsonToken {
    var result: JsonToken = undefined;
    const source = parser.source;
    var at = parser.at;

    while (isJsonWhitespace(source, at)) {
        at += 1;
    }

    if (source.len > at) {
        result.type = JsonTokenType.err;
        result.value = source[at .. at + 1];
        var val = source[at];
        at += 1;
        switch (val) {
            '{' => result.type = JsonTokenType.open_brace,
            '[' => result.type = JsonTokenType.open_bracket,
            '}' => result.type = JsonTokenType.close_brace,
            ']' => result.type = JsonTokenType.close_bracket,
            ',' => result.type = JsonTokenType.comma,
            ':' => result.type = JsonTokenType.colon,

            'f' => {
                parseKeyword(source, &at, "alse", JsonTokenType.false, &result);
            },

            'n' => {
                parseKeyword(source, &at, "ull", JsonTokenType.null, &result);
            },

            't' => {
                parseKeyword(source, &at, "rue", JsonTokenType.true, &result);
            },

            '"' => {
                result.type = JsonTokenType.string_literal;
                const string_start = at;
                while (source.len > at and source[at] != '"') {
                    if (source.len > (at + 1) and
                        source[at] == '\\' and
                        source[at + 1] == '"')
                    {
                        // NOTE: Skip escaped quotation marks
                        at += 1;
                    }
                    at += 1;
                }
                result.value = source[string_start..at];
                if (source.len > at) {
                    at += 1;
                }
            },

            '-', '0'...'9' => {
                const start = at - 1;
                result.type = JsonTokenType.number;

                // NOTE: Move past negative sign if exists.
                if (val == '-' and source.len > at) {
                    val = source[at];
                    at += 1;
                }

                // NOTE: If the leading digit wasn't 0, parse any digits before the decimal point
                if (val != '0') {
                    while (isJsonDigit(source, at)) {
                        at += 1;
                    }
                }

                // NOTE: If there is a decimal point, parse any digits after the decimal point
                if (source.len > at and source[at] == '.') {
                    at += 1;
                    while (isJsonDigit(source, at)) {
                        at += 1;
                    }
                }

                // NOTE: If it's in scientific notation, parse any digits after the "e"
                if (source.len > at and source[at] == 'e' or source[at] == 'E') {
                    at += 1;
                    if (source.len > at and source[at] == '+' or source[at] == '-') {
                        at += 1;
                    }

                    while (isJsonDigit(source, at)) {
                        at += 1;
                    }
                }

                result.value = source[start..at];
            },

            else => {},
        }
    }

    parser.at = at;

    return result;
}

fn parseJsonList(allocator: Allocator, parser: *JsonParser, end_type: JsonTokenType, has_labels: bool) Allocator.Error!*JsonElement {
    var first_element: *JsonElement = undefined;
    var last_element: ?*JsonElement = null;

    while (isParsing(parser.*)) {
        var label: []const u8 = "";
        var value = getJsonToken(parser);
        if (has_labels) {
            if (value.type == JsonTokenType.string_literal) {
                label = value.value;

                const colon = getJsonToken(parser);
                if (colon.type == JsonTokenType.colon) {
                    value = getJsonToken(parser);
                } else {
                    parserError(parser, colon, "Expected colon after field name");
                }
            } else if (value.type != end_type) {
                parserError(parser, value, "Unexpected token in JSON");
            }
        }

        const element = try parseJsonElement(allocator, parser, label, value);
        if (element) |element_value| {
            if (last_element) |last_element_value| {
                last_element_value.next_sibling = element_value;
            } else {
                first_element = element_value;
            }

            last_element = element_value;
        } else if (value.type == end_type) {} else {
            parserError(parser, value, "Unexpected token in JSON");
        }

        const comma = getJsonToken(parser);
        if (comma.type == end_type) {
            break;
        } else if (comma.type != .comma) {
            parserError(parser, comma, "Unexpected token in JSON");
        }
    }
    return first_element;
}

fn parseJsonElement(allocator: Allocator, parser: *JsonParser, label: []const u8, value: JsonToken) Allocator.Error!?*JsonElement {
    var sub_element: ?*JsonElement = null;
    switch (value.type) {
        .open_bracket => sub_element = try parseJsonList(allocator, parser, JsonTokenType.close_bracket, false),
        .open_brace => sub_element = try parseJsonList(allocator, parser, JsonTokenType.close_brace, true),
        .string_literal, .true, .false, .null, .number => {},
        else => return null,
    }

    const result = try allocator.create(JsonElement);
    result.* = JsonElement{ .label = label, .value = value.value, .first_sub_element = sub_element, .next_sibling = null };
    return result;
}

fn parseJson(allocator: Allocator, input_json: []const u8) !?*JsonElement {
    const block = profiler.timeBlockStart(@src().fn_name);
    defer profiler.timeBlockEnd(block);

    var parser = JsonParser{ .source = input_json };

    const result = try parseJsonElement(allocator, &parser, "", getJsonToken(&parser));
    return result;
}

fn lookupElement(object: ?*JsonElement, element_name: []const u8) ?*JsonElement {
    var result: ?*JsonElement = null;

    if (object) |object_value| {
        var search = object_value.first_sub_element;

        while (search) |search_v| {
            if (std.mem.eql(u8, search_v.label, element_name)) {
                result = search;
                break;
            }
            search = search_v.next_sibling;
        }
    }
    return result;
}

fn convertJsonSign(source: []const u8, at_result: *u64) f64 {
    var at = at_result.*;
    var result: f64 = 1.0;
    if (source.len > at and source[at] == '-') {
        result = -1.0;
        at += 1;
    }
    at_result.* = at;
    return result;
}

fn convertJsonNumber(source: []const u8, at_result: *u64) f64 {
    var at = at_result.*;
    var result: f64 = 0.0;
    while (source.len > at) {
        var char: u8 = source[at] -% '0';
        if (char < 10) {
            result = 10.0 * result + @as(f64, @floatFromInt(char));
            at += 1;
        } else {
            break;
        }
    }
    at_result.* = at;
    return result;
}

fn convertElementToF64(object: *JsonElement, element_name: []const u8) f64 {
    var result: f64 = 0;

    const element_opt = lookupElement(object, element_name);
    if (element_opt) |element| {
        const source = element.value;
        var at: u64 = 0;
        const sign = convertJsonSign(source, &at);
        var number = convertJsonNumber(source, &at);

        if (source.len > at and source[at] == '.') {
            at += 1;
            var c: f64 = 1.0 / 10.0;
            while (source.len > at) {
                const char: u8 = source[at] -% '0';
                if (char < 10) {
                    number = number + c * @as(f64, @floatFromInt(char));
                    c *= 1.0 / 10.0;
                    at += 1;
                } else {
                    break;
                }
            }
        }

        if (source.len > at and (source[at] == 'e' or source[at] == 'E')) {
            at += 1;
            if (source.len > at and source[at] == '+') {
                at += 1;
            }

            const exponent_sign = convertJsonSign(source, &at);
            const exponent = exponent_sign * convertJsonNumber(source, &at);
            number *= std.math.pow(f64, 10.0, exponent);
        }

        result = sign * number;
    }

    return result;
}

fn freeJson(allocator: Allocator, element: ?*JsonElement) void {
    var element_op: ?*JsonElement = element;
    while (element_op) |e| {
        var free_element = e;
        element_op = e.next_sibling;
        freeJson(allocator, e.first_sub_element);
        allocator.destroy(free_element);
    }
}

pub fn parseHaversinePairs(allocator: Allocator, input_json: []const u8, max_pair_count: u64, pairs: []HaversinePair) u64 {
    const block = profiler.timeBlockStart(@src().fn_name);
    defer profiler.timeBlockEnd(block);

    var pair_count: u64 = 0;

    const json: ?*JsonElement = parseJson(allocator, input_json) catch null;
    defer {
        const free_json_block = profiler.timeBlockStart("FreeJSON");
        freeJson(allocator, json);
        defer profiler.timeBlockEnd(free_json_block);
    }
    const pairs_array_opt = lookupElement(json, "pairs");
    if (pairs_array_opt) |pairs_array| {
        const lookup_block = profiler.timeBlockStart("Lookup and convert");
        defer profiler.timeBlockEnd(lookup_block);

        var element_opt = pairs_array.first_sub_element;
        while (element_opt) |element| {
            if (pair_count > max_pair_count) {
                break;
            }
            var pair: *HaversinePair = &pairs[pair_count];
            pair_count += 1;

            pair.x0 = convertElementToF64(element, "x0");
            pair.y0 = convertElementToF64(element, "y0");
            pair.x1 = convertElementToF64(element, "x1");
            pair.y1 = convertElementToF64(element, "y1");
            element_opt = element.next_sibling;
        }
    }
    return pair_count;
}

test {
    const allocator = std.testing.allocator;
    const input_json = try std.fs.cwd().readFileAlloc(allocator, "data_10_flex.json", std.math.maxInt(u64));
    defer allocator.free(input_json);
    const pairs = try allocator.alloc(HaversinePair, 10);
    defer allocator.free(pairs);
    try std.testing.expect(10 == parseHaversinePairs(allocator, input_json, 10, pairs));
}
