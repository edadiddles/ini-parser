//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");


fn parse(allocator: std.mem.Allocator, filename: []const u8) !std.StringHashMap(std.StringHashMap([]const u8)) {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);

    try readFile(filename, buffer);

    var scanner = try lexer.Scanner.init(allocator, buffer);
    defer scanner.deinit(allocator);

    scanner.scan();

    var p = parser.Parser.init(allocator, &scanner.tokens);
    //defer p.deinit(allocator);

    const iniConfig = p.parse(allocator);
    return iniConfig;
}

fn readFile(filename: []const u8, buffer: []u8) !void {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    const stat = try file.stat();
    const size = stat.size;
    _ = size;


    _ = try file.read(buffer);
}

test "parse basic.ini" {
    const allocator = std.testing.allocator;
    const config = try parse(allocator, "test/files/basic.ini");

    var key_iter = config.keyIterator();
    while(key_iter.next()) |key| {
        std.debug.print("Section: {s}\n", .{ key.* });
        var k_iter = config.get(key.*).?.keyIterator();
        while(k_iter.next()) |k| {
            std.debug.print("{s}={s}\n", .{ k.*, config.get(key.*).?.get(k.*).? });
        }
    }

    try std.testing.expectEqualStrings(config.get("general").?.get("active").?, "true");
    try std.testing.expectEqualStrings(config.get("general").?.get("version").?, "1.0");
    try std.testing.expectEqualStrings(config.get("general").?.get("name").?, "TestApp");
}

test "parse comments_and_spaces.ini" {
    const allocator = std.testing.allocator;
    _ = try parse(allocator, "test/files/comments_and_spaces.ini");

    try std.testing.expectEqual(1,1);
}

test "parse duplicates.ini" {
    const allocator = std.testing.allocator;
    _ = try parse(allocator, "test/files/duplicates.ini");

    try std.testing.expectEqual(1,1);
}

test "parse large.ini" {
    const allocator = std.testing.allocator;
    _ = try parse(allocator, "test/files/large.ini");

    try std.testing.expectEqual(1,1);
}

test "parse malformed.ini" {
    const allocator = std.testing.allocator;
    _ = try parse(allocator, "test/files/malformed.ini");

    try std.testing.expectEqual(1,1);
}

test "parse missing_section.ini" {
    const allocator = std.testing.allocator;
    _ = try parse(allocator, "test/files/missing_section.ini");

    try std.testing.expectEqual(1,1);
}

test "parse nested_like.ini" {
    const allocator = std.testing.allocator;
    _ = try parse(allocator, "test/files/nested_like.ini");

    try std.testing.expectEqual(1,1);
}

test "parse quoted_values.ini" {
    const allocator = std.testing.allocator;
    _ = try parse(allocator, "test/files/quoted_values.ini");

    try std.testing.expectEqual(1,1);
}
