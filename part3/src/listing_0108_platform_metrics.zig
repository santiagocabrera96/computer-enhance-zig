const std = @import("std");

pub fn getOSTimerFreq() u64 {
    return 1000000;
}

pub fn readOSTimer() u64 {
    return @bitCast(std.time.microTimestamp());
}

pub fn estimateCPUTimerFreq() u64 {
    return asm ("MRS X0, CNTFRQ_EL0"
        : [ret] "={x0}" (-> usize),
    );
}

pub fn readCPUTimer() u64 {
    return asm ("MRS X0, CNTPCT_EL0"
        : [ret] "={x0}" (-> usize),
    );
}

pub fn readOSPageFaults() u64 {
    const rusage = std.os.getrusage(std.os.rusage.SELF);
    const result: u64 = @as(u64, @bitCast(rusage.minflt + rusage.majflt));
    return result;
}

pub fn initializeOSMetrics() !void {
    // Note: This only exists because if the code were to be moved to Windows it would need some initialization.
}

test {
    const rusage = readOSPageFaults();
    _ = &rusage;
}
