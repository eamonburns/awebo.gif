//! Reference: <https://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html>

const std = @import("std");

/// <https://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html#header_block>
/// In this case, we will only support version 89a
pub const header = "GIF89a";

/// <https://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html#logical_screen_descriptor_block>
pub const LogicalScreenDescriptor = struct {
    canvas_width: u16,
    canvas_height: u16,

    have_global_color_table: bool,
    color_resolution: u3,
    colors_sorted: bool,
    // NOTE: I don't think this was described in the reference material
    global_color_table_size: u3,

    background_color_index: u8,
    pixel_aspect_ratio: u8,

    pub fn write(lsd: LogicalScreenDescriptor, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.writeInt(u16, lsd.canvas_width, .little);
        try writer.writeInt(u16, lsd.canvas_height, .little);

        const flags: packed struct(u8) {
            have_global_color_table: bool,
            color_resolution: u3,
            colors_sorted: bool,
            global_color_table_size: u3,
        } = .{
            .have_global_color_table = lsd.have_global_color_table,
            .color_resolution = lsd.color_resolution,
            .colors_sorted = lsd.colors_sorted,
            .global_color_table_size = lsd.global_color_table_size,
        };
        try writer.writeByte(@bitCast(flags));

        try writer.writeByte(lsd.background_color_index);
        try writer.writeByte(lsd.pixel_aspect_ratio);
    }
};

test LogicalScreenDescriptor {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const w = &aw.writer;

    const lsd: LogicalScreenDescriptor = .{
        .canvas_width = 0x0a00,
        .canvas_height = 0x0a00,
        .have_global_color_table = true,
        .color_resolution = 1,
        .colors_sorted = false,
        .global_color_table_size = 1,
        .background_color_index = 0,
        .pixel_aspect_ratio = 0,
    };

    try lsd.write(w);
    for (aw.written()) |byte| {
        std.debug.print("{x:02} ", .{byte});
    }
    std.debug.print("\n", .{});
}
