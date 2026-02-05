const std = @import("std");

const Frame = struct {
    /// Text
    t: []const u8,
    /// Seconds
    s: f32,
};

const frames: []const Frame = &.{
    .{ .t = "/ôô>", .s = 0.5 },
    .{ .t = "/ôô>", .s = 0.3 },
    .{ .t = "/ôô=", .s = 0.03 },
    .{ .t = "/ôô< awebo", .s = 0.4 },
    .{ .t = "/ôô=", .s = 0.03 },
    .{ .t = "/ôô>", .s = 0.9 },
    .{ .t = "/ôô=", .s = 0.03 },
    .{ .t = "/ôô< Awebo", .s = 0.4 },
    .{ .t = "/ōō=", .s = 0.03 },
    .{ .t = "/ŏŏ>", .s = 1.2 },
    .{ .t = "/ŏŏ=", .s = 0.03 },
    .{ .t = "/ŏŏ< AWEBO!!", .s = 0.7 },
    .{ .t = "/ŏŏ=", .s = 0.03 },
    .{ .t = "/ŏŏ>", .s = 1 },
    .{ .t = "/ōō>", .s = 0.03 },
    .{ .t = "/ôô>", .s = 0 },
};

pub const Repeat = enum(u32) {
    once = 1,
    forever = std.math.maxInt(u32),
    _,

    pub fn fromInt(integer: u32) Repeat {
        return @enumFromInt(integer);
    }

    pub fn toInt(repeat: Repeat) u32 {
        return @intFromEnum(repeat);
    }

    pub fn next(repeat: *Repeat) bool {
        if (repeat.* == .forever) return true;

        const integer = repeat.toInt();
        if (integer == 0) return false;

        repeat.* = .fromInt(integer - 1);
        return true;
    }
};

/// Play the Awebo animation in the terminal.
pub fn playTerminal(stderr: *std.Io.Writer, repeat: Repeat) std.Io.Writer.Error!void {
    try stderr.writeAll("\x1be"); // Clear screen
    try stderr.writeAll("\x1b[?25l"); // Hide cursor
    try stderr.writeByte('\n');

    var r = repeat;
    while (r.next()) {
        for (frames) |frame| {
            try stderr.print("\r  {s}\x1b[J", .{frame.t});
            try stderr.flush();
            std.Thread.sleep(@intFromFloat(frame.s * std.time.ns_per_s));
        }
    }

    try stderr.writeAll("\n\n\x1b[?25h");
    try stderr.flush();
}
