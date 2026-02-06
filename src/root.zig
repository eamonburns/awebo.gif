const std = @import("std");
const zigimg = @import("zigimg");

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

pub fn exportGif(gpa: std.mem.Allocator, filename: []const u8) !void {
    const Grayscale8 = zigimg.color.Grayscale8;
    const width = 100;
    const height = 100;

    var img = try zigimg.Image.create(gpa, width, height, .grayscale8);
    defer img.deinit(gpa);

    const pixels0: []Grayscale8 = try gpa.alloc(Grayscale8, width * height);
    defer gpa.free(pixels0);
    for (pixels0) |*pixel| {
        pixel.value = 0;
    }
    const frame0: zigimg.Image.AnimationFrame = .{
        .pixels = .{ .grayscale8 = pixels0 },
        .duration = 1,
    };
    try img.animation.frames.append(gpa, frame0);

    const pixels1: []Grayscale8 = try gpa.alloc(Grayscale8, width * height);
    for (pixels1) |*pixel| {
        pixel.value = 64;
    }
    const frame1: zigimg.Image.AnimationFrame = .{
        .pixels = .{ .grayscale8 = pixels1 },
        .duration = 1,
    };
    try img.animation.frames.append(gpa, frame1);

    const pixels2: []Grayscale8 = try gpa.alloc(Grayscale8, width * height);
    for (pixels2) |*pixel| {
        pixel.value = 128;
    }
    const frame2: zigimg.Image.AnimationFrame = .{
        .pixels = .{ .grayscale8 = pixels2 },
        .duration = 1,
    };
    try img.animation.frames.append(gpa, frame2);

    const pixels3: []Grayscale8 = try gpa.alloc(Grayscale8, width * height);
    for (pixels3) |*pixel| {
        pixel.value = 192;
    }
    const frame3: zigimg.Image.AnimationFrame = .{
        .pixels = .{ .grayscale8 = pixels3 },
        .duration = 1,
    };
    try img.animation.frames.append(gpa, frame3);

    var write_buf: [1024]u8 = undefined;
    try img.writeToFilePath(gpa, filename, &write_buf, .{ .gif = .{ .auto_convert = true } });
}
