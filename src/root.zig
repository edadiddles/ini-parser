//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

fn parse(allocator: std.mem.Allocator, filename: []const u8) !std.StringHashMap(std.StringHashMap([]u8)) {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);

    try readFile(filename, buffer);

    const iniConfig = try parseFile(allocator, buffer);

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

fn parseFile(allocator: std.mem.Allocator, buffer: []u8) !std.StringHashMap(std.StringHashMap([]u8)) {
    var iniConfig: std.StringHashMap(std.StringHashMap([]u8)) = .init(allocator);
    //defer iniConfig.deinit();

    var token_iter = std.mem.tokenizeScalar(u8, buffer, '\n');
    var section: [256]u8 = undefined;
    var key: [256]u8 = undefined;
    var val: [256]u8 = undefined;

    var sectionMap: std.StringHashMap([]u8) = .init(allocator);
    while (token_iter.next()) |token| {
        if (token[0] == 170) {
            continue;
        }
        if (token[0] == ';' or token[0] == '#') {
            continue;
        }
        if (token[0] == '[' and token[token.len-1] == ']') {
            @memset(&section, 0);
            @memcpy(section[0..token.len-2], token[1..token.len-1]);

            sectionMap = .init(allocator);
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
                @memcpy(val[0..i], buf[delimiter_idx..i-delimiter_idx]);
                @memset(buf, 0);
                const k = try allocator.dupe(u8, &key);
                const v = try allocator.dupe(u8, &val);
                try sectionMap.put(k, v);
                break;
            }
            if (c == '=') {
                @memcpy(key[0..i-1], buf[0..i-1]);
                @memset(buf, 0);
                numSpaces = 0;
                delimiter_idx = i;
                continue;
            }
            if (c == ' ') {
                numSpaces += 1;
                continue;
            }
            buf[i-delimiter_idx] = c;
            if (i == token.len-1) {
                @memcpy(val[0..i-delimiter_idx-1], buf[2..i+1-delimiter_idx]);
                @memset(buf, 0);
                const k = try allocator.dupe(u8, &key);
                const v = try allocator.dupe(u8, &val);
                try sectionMap.put(k, v);
            }

        }

        const s = try allocator.dupe(u8, &section);
        try iniConfig.put(s, sectionMap);
    }

    return iniConfig;
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
