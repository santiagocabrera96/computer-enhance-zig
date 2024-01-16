const std = @import("std");
const math = std.math;
const sin = math.sin;
const cos = math.cos;
const asin = math.asin;
const sqrt = math.sqrt;

fn square(x: f64) f64 {
    const result = x * x;
    return result;
}

fn radiansFromDegrees(degrees: f64) f64 {
    const result = 0.01745329251994329577 * degrees;
    return result;
}

pub const HaversinePair = struct { x0: f64, y0: f64, x1: f64, y1: f64 };

// NOTE: EarthRadius is generally expected to be 6372.8
pub fn referenceHaversine(x0: f64, y0: f64, x1: f64, y1: f64, earth_radius: f64) f64 {
    var lat1 = y0;
    var lat2 = y1;
    const lon1 = x0;
    const lon2 = x1;

    const dLat = radiansFromDegrees(lat2 - lat1);
    const dLon = radiansFromDegrees(lon2 - lon1);
    lat1 = radiansFromDegrees(lat1);
    lat2 = radiansFromDegrees(lat2);

    const a = square(sin(dLat / 2.0)) + cos(lat1) * cos(lat2) * square(sin(dLon / 2));
    const c = 2.0 * asin(sqrt(a));

    const result = earth_radius * c;

    return result;
}

const testing = std.testing;
test referenceHaversine {
    const res = referenceHaversine(12.121654, 12.121654, 64.4685, 56.4654, 6372.8);
    try testing.expect(6636.8252050577521 == res);
}
