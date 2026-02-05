const std = @import("std");

const awebo_gif = @import("awebo_gif");
const Repeat = awebo_gif.Repeat;

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debug_allocator.deinit();
    const gpa = debug_allocator.allocator();
    var it: std.process.ArgIterator = try .initWithAllocator(gpa);
    _ = it.skip(); // arg0

    const cmd: Command = .parse(&it);

    switch (cmd) {
        .ascii => |ascii| {
            var stderr_buf: [1024]u8 = undefined;
            const stderr = std.debug.lockStderrWriter(&stderr_buf);
            defer std.debug.unlockStdErr();

            try awebo_gif.playTerminal(stderr, ascii.repeat);
        },
        .gif, .frames => {
            // TODO: Implement this
            fatal("`{t}` subcommand is unimplemented", .{cmd});
        },
    }
}

const Command = union(Subcommand) {
    ascii: struct {
        repeat: Repeat,
    },
    gif,
    frames,

    pub const Subcommand = enum { ascii, gif, frames };

    pub fn parse(it: *std.process.ArgIterator) Command {
        const subcmd_str = it.next() orelse fatal("missing subcommand", .{});

        if (argIsHelp(subcmd_str)) exitHelpTopLevel(0);

        const subcmd = std.meta.stringToEnum(Subcommand, subcmd_str) orelse {
            if (std.mem.startsWith(u8, subcmd_str, "-")) {
                fatal("expected subcommand, found option: '{s}'", .{subcmd_str});
            }

            fatal("invalid subcommand: '{s}'", .{subcmd_str});
        };

        switch (subcmd) {
            .ascii => {
                var repeat: ?Repeat = null;

                while (it.next()) |arg| {
                    if (argIsHelp(arg)) exitHelpSubcommand(.ascii, 0);
                    if (std.mem.eql(u8, arg, "--repeat")) {
                        const repeat_arg = it.next() orelse {
                            fatal("missing value for --repeat", .{});
                        };
                        if (std.meta.stringToEnum(Repeat, repeat_arg)) |r| {
                            repeat = r;
                        } else {
                            repeat = @enumFromInt(std.fmt.parseInt(u32, repeat_arg, 10) catch {
                                fatal("invalid value for --repeat ('once', 'forever', or integer): {s}", .{repeat_arg});
                            });
                        }
                    } else fatal("unknown option: '{s}'", .{arg});
                }

                return .{ .ascii = .{
                    .repeat = repeat orelse .once,
                } };
            },
            .gif, .frames => {
                // TODO: Implement this
                fatal("`{t}` subcommand is unimplemented", .{subcmd});
            },
        }
    }
};

fn exitHelpTopLevel(status: u8) noreturn {
    std.debug.print(
        \\usage: awebo-gif <subcommand>
        \\
        \\Create a little animation of the Awebo bird.
        \\
        \\Subcommands:
        \\  ascii     Print animation to the terminal.
        \\  gif       Create an animated GIF.
        \\  frames    Output animation frames.
        \\
        \\
    , .{});
    std.process.exit(status);
}

fn exitHelpSubcommand(subcmd: Command.Subcommand, status: u8) noreturn {
    switch (subcmd) {
        .ascii => std.debug.print(
            \\usage: awebo-gif {t} [options]
            \\
            \\Print animation to the terminal.
            \\
            \\Optional options:
            \\  --repeat    Number of times to repeat the animation (default: once)
            \\
            \\
        , .{subcmd}),
        .gif, .frames => std.debug.print(
            \\TODO: Help page for `{t}` subcommand
            \\
            \\
        , .{subcmd}),
    }
    std.process.exit(status);
}

fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("error: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}

fn argIsHelp(arg: []const u8) bool {
    return std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h");
}
