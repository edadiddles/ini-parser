//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

fn parseFile(allocator: std.mem.Allocator, filename: []const u8) !void {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    const stat = try file.stat();
    const size = stat.size;
    _ = size;

    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);

    _ = try file.read(buffer);

    const iniConfig = std.StringHashMap(std.StringHashMap([]const u8)).init(allocator);
    _ = iniConfig;

    var token_iter = std.mem.tokenizeScalar(u8, buffer, '\n');
    var section: [256]u8 = undefined;
    var key: [256]u8 = undefined;
    @memset(&key, 0);
    var val: [256]u8 = undefined;
    @memset(&val, 0);
    while (token_iter.next()) |token| {
        std.debug.print("Token: |{s}|\n", .{ token });
        if (token[0] == 170) {
            continue;
        }
        if (token[0] == ';' or token[0] == '#') {
            continue;
        }
        if (token[0] == '[' and token[token.len-1] == ']') {
            @memset(&section, 0);
            @memcpy(section[0..token.len-2], token[1..token.len-1]);
            std.debug.print("Section: |{s}|\n", .{ section });
            continue;
        }
        
        @memset(&key, 0);
        @memset(&val, 0);
        const buf = try allocator.alloc(u8, 256);
        defer allocator.free(buf);
        var numSpaces: u8 = 0;
        var delimiter_idx: usize = 0;
        for (token,0..) |c,i| {
            if (c == ';' or c == '#') {
                @memcpy(val[0..i-delimiter_idx], buf[0..i-delimiter_idx]);
                @memset(buf, 0);
                std.debug.print("Val: |{s}|\n", .{ val });
                break;
            }
            if (c == '=') {
                @memcpy(key[0..i], buf[0..i]);
                @memset(buf, 0);
                numSpaces = 0;
                delimiter_idx = i;
                std.debug.print("Key: |{s}|\n", .{ key });
                continue;
            }
            if (c == ' ') {
                numSpaces += 1;
                continue;
            }
            buf[i-delimiter_idx] = c;
            if (i == token.len-1) {
                @memcpy(val[0..i-delimiter_idx+1], buf[0..i-delimiter_idx+1]);
                @memset(buf, 0);
                std.debug.print("Val: |{s}|\n", .{ val });
            }

        }
        
    }
    // std.StringHashMap
}


test "parse basic.ini" {
    const allocator = std.testing.allocator;
    try parseFile(allocator, "test/files/basic.ini");

    try std.testing.expectEqual(1,1);
}

test "parse comments_and_spaces.ini" {
    const allocator = std.testing.allocator;
    try parseFile(allocator, "test/files/comments_and_spaces.ini");

    try std.testing.expectEqual(1,1);
}

test "parse duplicates.ini" {
    const allocator = std.testing.allocator;
    try parseFile(allocator, "test/files/duplicates.ini");

    try std.testing.expectEqual(1,1);
}

test "parse large.ini" {
    const allocator = std.testing.allocator;
    try parseFile(allocator, "test/files/large.ini");

    try std.testing.expectEqual(1,1);
}

test "parse malformed.ini" {
    const allocator = std.testing.allocator;
    try parseFile(allocator, "test/files/malformed.ini");

    try std.testing.expectEqual(1,1);
}

test "parse missing_section.ini" {
    const allocator = std.testing.allocator;
    try parseFile(allocator, "test/files/missing_section.ini");

    try std.testing.expectEqual(1,1);
}

test "parse nested_like.ini" {
    const allocator = std.testing.allocator;
    try parseFile(allocator, "test/files/nested_like.ini");

    try std.testing.expectEqual(1,1);
}

test "parse quoted_values.ini" {
    const allocator = std.testing.allocator;
    try parseFile(allocator, "test/files/quoted_values.ini");

    try std.testing.expectEqual(1,1);
}
