//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const iniConfig = @import("ini-config.zig");


fn parse(allocator: std.mem.Allocator, filename: []const u8) !iniConfig.IniConfig {
    const buffer = try readFile(allocator, filename);
    defer allocator.free(buffer);

    var scanner = try lexer.Scanner.init(allocator, buffer);
    defer scanner.deinit(allocator);

    try scanner.scan(allocator);

    var p = parser.Parser.init(allocator, &scanner.tokens);
    //defer p.deinit(allocator);

    return p.parse(allocator);
}

fn readFile(allocator: std.mem.Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    defer file.close();

    const stat = try file.stat();
    const size = stat.size;
    std.debug.print("file size: {d}\n", .{ size });

    const buffer = try allocator.alloc(u8, size); 
    _ = try file.read(buffer);

    return buffer;
}

test "test readFile" {
    const allocator = std.testing.allocator;
    const buffer = try readFile(allocator, "test/files/large.ini");
    defer allocator.free(buffer);

    std.debug.print("{s}\n", .{ buffer });
}

test "parse basic.ini" {
    const allocator = std.testing.allocator;
    var config = try parse(allocator, "test/files/basic.ini");
    defer config.deinit(allocator);

    try std.testing.expectEqualStrings(config.getConfig().get("general").?.get("active").?, "true");
    try std.testing.expectEqualStrings(config.getConfig().get("general").?.get("version").?, "1.0");
    try std.testing.expectEqualStrings(config.getConfig().get("general").?.get("name").?, "TestApp");
}

test "parse comments_and_spaces.ini" {
    const allocator = std.testing.allocator;
    var config = try parse(allocator, "test/files/comments_and_spaces.ini");
    defer config.deinit(allocator);

    try std.testing.expectEqualStrings(config.getConfig().get("paths").?.get("home").?, "/usr/local/bin");
    try std.testing.expectEqualStrings(config.getConfig().get("paths").?.get("data_dir").?, "/var/data");
    try std.testing.expectEqualStrings(config.getConfig().get("paths").?.get("logs").?, "/var/logs");
    
    try std.testing.expectEqualStrings(config.getConfig().get("network").?.get("host").?, "example.com");
    try std.testing.expectEqualStrings(config.getConfig().get("network").?.get("port").?, "8080");
}

test "parse duplicates.ini" {
    const allocator = std.testing.allocator;
    var config = try parse(allocator, "test/files/duplicates.ini");
    defer config.deinit(allocator);


    try std.testing.expectEqualStrings(config.getConfig().get("server").?.get("host").?, "localhost");
    try std.testing.expectEqualStrings(config.getConfig().get("server").?.get("port").?, "8080");
    try std.testing.expectEqualStrings(config.getConfig().get("server").?.get("mode").?, "production");    
}

test "parse large.ini" {
    const allocator = std.testing.allocator;
    var config = try parse(allocator, "test/files/large.ini");
    defer config.deinit(allocator);

    config.print();
    
    try std.testing.expectEqualStrings(config.getConfig().get("section").?.get("key0").?, "value0");
    try std.testing.expectEqualStrings(config.getConfig().get("section").?.get("key999").?, "value999");
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
    var config = try parse(allocator, "test/files/quoted_values.ini");
    defer config.deinit(allocator);

    config.print();
    
    try std.testing.expectEqualStrings(config.getConfig().get("auth").?.get("path").?, "C:\\Program Files\\App");
    try std.testing.expectEqualStrings(config.getConfig().get("auth").?.get("token").?, "abc\ndef\t123");
    try std.testing.expectEqualStrings(config.getConfig().get("empty").?.get("key").?, "");
}
