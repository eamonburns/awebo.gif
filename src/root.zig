const std = @import("std");
const zigimg = @import("zigimg");
const TrueType = @import("TrueType");

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

    var img: zigimg.Image = try .create(gpa, width, height, .grayscale8);
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

pub fn exportFrames(gpa: std.mem.Allocator, basename: []const u8) !void {
    const ttf: TrueType = try .load(@embedFile("font"));
    const vm = ttf.verticalMetrics();

    const scale = ttf.scaleForPixelHeight(100);
    const glyph_height: unit.Font = .fromInt(vm.ascent - vm.descent);
    // const glyph_height_px: unit.Pixel = glyph_height.toPixel(scale);
    const line_height: unit.Font = glyph_height.plus(.fromInt(vm.line_gap));
    const line_height_px: unit.Pixel = line_height.toPixel(scale);
    // std.debug.print("{s}: line_height={d}, line_height_px={d}\n", .{ @src().fn_name, line_height, line_height_px });

    // const glyph_height: usize = @intFromFloat(@as(f32, @floatFromInt(vm.ascent)) * scale);
    // NOTE: It is a monospace font, so HMetrics should be the same for all glyphs
    const hm = ttf.glyphHMetrics(ttf.codepointGlyphIndex('W'));
    const advance_width: unit.Font = .fromInt(hm.advance_width);
    const advance_width_px: unit.Pixel = advance_width.toPixel(scale);
    // const char_width: usize = @intFromFloat(@as(f32, @floatFromInt(hm.advance_width)) * scale);

    const max_character_count = blk: {
        var max: usize = 0;
        for (frames) |frame| {
            max = @max(max, frame.t.len);
        }
        break :blk max;
    };
    // const text = "Testing";
    // const max_character_count = text.len;

    // const image_width = char_width * (max_character_count + 4);
    const image_width = advance_width_px.times(@intCast(max_character_count + 4));
    const image_height: unit.Pixel = line_height_px.times(3);

    for (frames, 0..) |frame, i| {
        const pixels = try textToPixels(gpa, ttf, scale, frame.t, image_width, image_height);

        var img: zigimg.Image = try .create(
            gpa,
            @intCast(@intFromEnum(image_width)),
            @intCast(@intFromEnum(image_height)),
            .grayscale8,
        );
        img.pixels = pixels;
        defer img.deinit(gpa);

        const file_path = try std.fmt.allocPrint(gpa, "{s}_{d:02}.png", .{ basename, i });
        defer gpa.free(file_path);

        std.debug.print("writing file: '{s}' ({d}/{d})\n", .{ file_path, i + 1, frames.len });

        var write_buf: [1024]u8 = undefined;
        try img.writeToFilePath(gpa, file_path, &write_buf, .{ .png = .{} });
    }
}

fn textToPixels(
    gpa: std.mem.Allocator,
    ttf: TrueType,
    scale: f32,
    text: []const u8,
    image_width: unit.Pixel,
    image_height: unit.Pixel,
) !zigimg.color.PixelStorage {
    const vm = ttf.verticalMetrics();
    // NOTE: Monospace font, so it should be identical for all glyphs
    const hm = ttf.glyphHMetrics(ttf.codepointGlyphIndex('W'));
    const glyph_height: unit.Font = .fromInt(vm.ascent - vm.descent);
    // const glyph_height_px: unit.Pixel = glyph_height.toPixel(scale);
    const line_height: unit.Font = glyph_height.plus(.fromInt(vm.line_gap));
    const line_height_px: unit.Pixel = line_height.toPixel(scale);
    // std.debug.print("{s}: line_height={d}, line_height_px={d}\n", .{ @src().fn_name, line_height, line_height_px });
    const advance_width: unit.Font = .fromInt(hm.advance_width);
    const advance_width_px: unit.Pixel = advance_width.toPixel(scale);

    // The origin of the current glyph
    var glyph_origin: unit.Pixel.Pos = blk: {
        const top_baseline_px: unit.Pixel = unit.Font.fromInt(vm.ascent).toPixel(scale);
        const mid_baseline_px = top_baseline_px.plus(line_height_px);
        // std.debug.print("{s}: top_baseline_px={d}, mid_baseline_px={d}\n", .{ @src().fn_name, top_baseline_px, mid_baseline_px });
        const first_char_left = advance_width_px.times(2);
        break :blk .{
            .x = first_char_left,
            .y = mid_baseline_px,
        };
    };
    // std.debug.print("image: width={d}, height={d}\n", .{ image_width, image_height });
    // std.debug.print("origin: x={d}, y={d}\n", .{ glyph_origin.x, glyph_origin.y });

    // const baseline: usize = @intCast(@intFromEnum(glyph_origin.y));
    // const left_edge: usize = @intCast(@intFromEnum(glyph_origin.x));
    const image_width_integer: usize = @intCast(@intFromEnum(image_width));
    const image_height_integer: usize = @intCast(@intFromEnum(image_height));
    var pixels: []zigimg.color.Grayscale8 = try gpa.alloc(
        zigimg.color.Grayscale8,
        image_width_integer * image_height_integer,
    );
    for (0..image_width_integer) |x| {
        for (0..image_height_integer) |y| {
            // const pixel: u8 = if (y == baseline or x == left_edge) 0xaa else 0x00;
            const idx = y * image_width_integer + x;
            pixels[idx].value = 0x00;
        }
    }
    // for (pixels) |*pixel| pixel.value = 0;
    const pixel_storage: zigimg.color.PixelStorage = .{ .grayscale8 = pixels };

    // const codepoint = blk: {
    const view: std.unicode.Utf8View = try .init(text);
    var it = view.iterator();

    // break :blk it.nextCodepoint() orelse @panic("missing a codepoint");
    // };

    var buffer: std.ArrayList(u8) = .empty;
    defer buffer.deinit(gpa);
    while (it.nextCodepoint()) |codepoint| {
        blk: switch (ttf.codepointGlyphIndex(codepoint)) {
            _ => |glyph| {
                if (codepoint <= std.math.maxInt(u8) and std.ascii.isWhitespace(@intCast(codepoint))) break :blk;
                buffer.clearRetainingCapacity();
                const dims = ttf.glyphBitmap(gpa, &buffer, glyph, scale, scale) catch |err| {
                    std.debug.print("error getting glyphBitmap: {t}\n", .{err});
                    std.debug.print("glyph: {d}, codepoint: 0x{x:08}", .{ glyph, codepoint });
                    return err;
                };
                const dim_x_off_px: unit.Pixel = @enumFromInt(dims.off_x);
                const dim_y_off_px: unit.Pixel = @enumFromInt(dims.off_y);
                const glyph_pixels = buffer.items;

                // const origin_x: unit.Pixel = .fromInt();
                // const origin_y = 10;

                for (0..dims.width) |x_off| {
                    for (0..dims.height) |y_off| {
                        // const idx = (origin_y + y_off) * image_width + (origin_x + x_off);
                        const x_off_px: unit.Pixel = @enumFromInt(x_off);
                        const y_off_px: unit.Pixel = @enumFromInt(y_off);
                        const calculated_x: unit.Pixel = glyph_origin.y.plus(y_off_px).plus(dim_y_off_px).times(@intFromEnum(image_width));
                        const calculated_y: unit.Pixel = glyph_origin.x.plus(x_off_px).plus(dim_x_off_px);
                        // const idx: usize = @intCast(@intFromEnum(().plus(glyph_origin.x.plus(x_off_px))));
                        const idx: usize = @intCast(@intFromEnum(calculated_y.plus(calculated_x)));
                        if (idx > pixels.len) continue;
                        // var calculated_y = y + y_off;
                        // if (dims.off_y < 0) {
                        //     calculated_y += @intCast(@abs(dims.off_y));
                        // } else calculated_y -|= @intCast(dims.off_y);
                        // var calculated_x = x + x_off;
                        // if (dims.off_x < 0) {
                        //     calculated_x += @intCast(@abs(dims.off_x));
                        // } else calculated_x -|= @intCast(dims.off_x);
                        // const idx = (y + y_off + dims.off_y) * image_width + (x + x_off + dims.off_x);
                        // const idx = calculated_y * image_width + calculated_x;

                        // if (x_off == 0 or x_off == dims.width - 1 or y_off == 0 or y_off == dims.height - 1) {
                        //     pixels[idx].value = @max(0x88, glyph_pixels[y_off * dims.width + x_off]);
                        // } else {
                        pixels[idx].value = glyph_pixels[y_off * dims.width + x_off];
                        // }
                    }
                }
            },
            .notdef => std.debug.print("no glyph for codepoint: 0x{x:02}\n", .{codepoint}),
        }

        glyph_origin.x = glyph_origin.x.plus(advance_width_px);
    }

    return pixel_storage;

    // const glyphs = blk: {
    //     const view: std.unicode.Utf8View = try .init(text);
    //     var it = view.iterator();
    //
    //     var gs: std.ArrayList(TrueType.GlyphBitmap) = .empty;
    //     errdefer gs.deinit(gpa);
    //     while (it.nextCodepoint()) |codepoint| {
    //         try gs.append(gpa, );
    //     }
    //     break :blk try gs.toOwnedSlice(gpa);
    // };
    // defer gpa.free(glyphs);
}

const unit = struct {
    /// Unscaled font units
    pub const Font = enum(i16) {
        _,

        pub fn fromInt(integer: i16) Font {
            return @enumFromInt(integer);
        }

        pub fn toPixel(font: Font, scale: f32) Pixel {
            const font_float: f32 = @floatFromInt(@intFromEnum(font));
            const pixel_integer: i32 = @intFromFloat(font_float * scale);
            return @enumFromInt(pixel_integer);
        }

        pub fn plus(font: Font, other: Font) Font {
            const font_integer: i16 = @intFromEnum(font);
            const other_integer: i16 = @intFromEnum(other);
            return @enumFromInt(font_integer + other_integer);
        }

        pub fn minus(font: Font, other: Font) Font {
            const font_integer: i16 = @intFromEnum(font);
            const other_integer: i16 = @intFromEnum(other);
            return @enumFromInt(font_integer - other_integer);
        }
    };

    /// Raw pixels
    pub const Pixel = enum(i32) {
        _,

        pub const Pos = struct {
            x: Pixel,
            y: Pixel,
        };

        pub fn times(pixel: Pixel, integer: i32) Pixel {
            const pixel_integer: i32 = @intFromEnum(pixel);
            return @enumFromInt(pixel_integer * integer);
        }

        pub fn plus(pixel: Pixel, other: Pixel) Pixel {
            const pixel_integer: i32 = @intFromEnum(pixel);
            const other_integer: i32 = @intFromEnum(other);
            return @enumFromInt(pixel_integer + other_integer);
        }

        pub fn minus(pixel: Pixel, other: Pixel) Pixel {
            const pixel_integer: i32 = @intFromEnum(pixel);
            const other_integer: i32 = @intFromEnum(other);
            return @enumFromInt(pixel_integer - other_integer);
        }
    };
};
