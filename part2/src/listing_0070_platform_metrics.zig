const std = @import("std");

pub fn getOSTimerFreq() u64 {
    return 1000000000;
}

pub fn readOSTimer() u64 {
    var ts: std.os.timespec = undefined;
    std.os.clock_gettime(std.os.CLOCK.REALTIME, &ts) catch |err| switch (err) {
        error.UnsupportedClock, error.Unexpected => return 0, // "Precision of timing depends on hardware and OS".
    };

    return @as(u64, @bitCast(ts.tv_sec * std.time.ns_per_s)) + @as(u64, @bitCast(ts.tv_nsec));
}

pub fn readCPUTimer() u64 {
    return asm ("MRS X0, CNTVCT_EL0"
        : [ret] "={x0}" (-> usize),
    );
}
