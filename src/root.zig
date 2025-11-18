//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const token_types = @import("token.zig");
const lexer = @import("lexer.zig");

fn scan(allocator: std.mem.Allocator, filename: []const u8) !void {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);

    try readFile(filename, buffer);

    var scanner = try lexer.Scanner.init(allocator, buffer);
    defer scanner.deinit(allocator);
    scanner.scan(); 
}

fn parse(allocator: std.mem.Allocator, filename: []const u8) !std.StringHashMap(std.StringHashMap([]u8)) {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);

    try readFile(filename, buffer);

    var scanner = try lexer.Scanner.init(allocator, buffer);
    defer scanner.deinit(allocator);

    scanner.scan();

    const iniConfig = parseFile(allocator, &scanner.tokens);
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

fn parseFile(allocator: std.mem.Allocator, tokens: *[]token_types.Token) std.StringHashMap(std.StringHashMap([]u8)) {
    var iniConfig: std.StringHashMap(std.StringHashMap([]u8)) = .init(allocator);
    defer iniConfig.deinit();

    for (tokens.*) |token| {
        switch(token.type) {
            .EOF => break,
            .SECTION => break,
            //.IDENTIFIER => 
            else => { break; },
        }
        if (token.type == .EOF) {
            break;
        } else
        std.debug.print("processing token {}...\n", .{ token });
    }

    return iniConfig;
}

test "test scanner" {
    const allocator = std.testing.allocator;
    try scan(allocator, "test/files/basic.ini");
}

test "parse basic.ini" {
    const allocator = std.testing.allocator;
    const config = try parse(allocator, "test/files/basic.ini");

    var section: [256]u8 = undefined;
    var key: [256]u8 = undefined;
    var val: [256]u8 = undefined;

    @memset(&section, 0);
    @memset(&key, 0);
    @memset(&val, 0);
    @memcpy(section[0..7], "general");
    @memcpy(key[0..6], "active");
    @memcpy(val[0..4], "true");
    try std.testing.expectEqualStrings(config.get(&section).?.get(&key).?, &val);
    
    @memset(&section, 0);
    @memset(&key, 0);
    @memset(&val, 0);
    @memcpy(section[0..7], "general");
    @memcpy(key[0..7], "version");
    @memcpy(val[0..3], "1.0");
    try std.testing.expectEqualStrings(config.get(&section).?.get(&key).?, &val);
    
    @memset(&section, 0);
    @memset(&key, 0);
    @memset(&val, 0);
    @memcpy(section[0..7], "general");
    @memcpy(key[0..4], "name");
    @memcpy(val[0..7], "TestApp");
    try std.testing.expectEqualStrings(config.get(&section).?.get(&key).?, &val);
}

test "parse comments_and_spaces.ini" {
    const allocator = std.testing.allocator;
    _ = try parseFile(allocator, "test/files/comments_and_spaces.ini");

    try std.testing.expectEqual(1,1);
}

test "parse duplicates.ini" {
    const allocator = std.testing.allocator;
    _ = try parseFile(allocator, "test/files/duplicates.ini");

    try std.testing.expectEqual(1,1);
}

test "parse large.ini" {
    const allocator = std.testing.allocator;
    _ = try parseFile(allocator, "test/files/large.ini");

    try std.testing.expectEqual(1,1);
}

test "parse malformed.ini" {
    const allocator = std.testing.allocator;
    _ = try parseFile(allocator, "test/files/malformed.ini");

    try std.testing.expectEqual(1,1);
}

test "parse missing_section.ini" {
    const allocator = std.testing.allocator;
    _ = try parseFile(allocator, "test/files/missing_section.ini");

    try std.testing.expectEqual(1,1);
}

test "parse nested_like.ini" {
    const allocator = std.testing.allocator;
    _ = try parseFile(allocator, "test/files/nested_like.ini");

    try std.testing.expectEqual(1,1);
}

test "parse quoted_values.ini" {
    const allocator = std.testing.allocator;
    _ = try parseFile(allocator, "test/files/quoted_values.ini");

    try std.testing.expectEqual(1,1);
}
