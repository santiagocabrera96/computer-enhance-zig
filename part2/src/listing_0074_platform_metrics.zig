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
