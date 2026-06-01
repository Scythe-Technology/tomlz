const std = @import("std");
const Io = std.Io;
const testing = std.testing;
const lex = @import("lexer.zig");
const parser = @import("parser.zig");

export fn cmain() void {
    main() catch unreachable;
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer std.debug.assert(gpa.deinit() == .ok);
    var allocator = gpa.allocator();

    var threaded: Io.Threaded = .init(allocator, .{});
    const io = threaded.io();

    const stdin = std.Io.File.stdin();
    var buf: [8192]u8 = undefined;
    var stdin_reader = stdin.reader(io, &buf);
    var reader = &stdin_reader.interface;

    const data = try reader.allocRemaining(allocator, .unlimited);
    defer allocator.free(data);

    const lexer = parser.Lexer{ .real = try lex.Lexer.init(allocator, data) };
    var p = try parser.Parser.init(allocator, lexer);
    defer p.deinit();

    var table = p.parse() catch |err| {
        std.debug.print("error parsing {}\n", .{err});
        std.debug.print("{?}\n", .{p.diag});
        return;
    };
    defer table.deinit(allocator);
}
