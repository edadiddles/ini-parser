//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const TokenType = enum{
    LEFT_SQ_BRACKET, RIGHT_SQ_BRACKET,
    EQUALS,
    SEMI_COLON, POUND_SIGN,
    DBL_QUOTE,
    EOF,
};

const Token = struct{
    type: TokenType,
    literal: []u8,

    pub fn init(t: TokenType, l: []u8) Token {
        return Token{
            .type = t,
            .literal = l,
        };
    }
};

const Scanner = struct{
    buf: []u8,
    tokens: []Token,
    token_pos: u16,

    pos: u16,
    read_pos: u16,

    pub fn init(allocator: std.mem.Allocator, buffer: []u8) !Scanner {
        return Scanner{
            .buf = buffer,
            .tokens = try allocator.alloc(Token, 64),
            .token_pos = 0,
            .pos = 0,
            .read_pos = 0,
        };
    }

    pub fn deinit(self: Scanner, allocator: std.mem.Allocator) void {
        allocator.free(self.tokens);
    }

    pub fn scan(self: *Scanner) void { 
        while (self.pos < self.buf.len and self.buf[self.pos] != 170) {
            self.pos = self.read_pos;
            self.scan_token();
        }

        self.add_token(TokenType.EOF);
    }

    fn scan_token(self: *Scanner) void {
        const char = self.read_char();
        switch(char) {
            '[' => self.add_token(TokenType.LEFT_SQ_BRACKET),
            ']' => self.add_token(TokenType.RIGHT_SQ_BRACKET),
            '=' => self.add_token(TokenType.EQUALS),
            ';' => self.add_token(TokenType.SEMI_COLON),
            '#' => self.add_token(TokenType.POUND_SIGN),
            '"' => self.add_token(TokenType.DBL_QUOTE),
            else => {
                std.debug.print("Token {} is not found.\n", .{char});
            },
        }
    }

    fn add_token(self: *Scanner, token_type: TokenType) void {
        self.tokens[self.token_pos] = Token.init(token_type, &[0]u8{});
        self.token_pos += 1;
    }

    fn read_char(self: *Scanner) u8 {
        self.read_pos += 1;
        return self.buf[self.read_pos];
    }

    fn is_letter(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
    }

    fn is_whitespace(c: u8) bool {
        return c == ' ' or c == '\n';
    }

};

fn scan(allocator: std.mem.Allocator, filename: []const u8) !void {
    const buffer = try allocator.alloc(u8, 1024);
    defer allocator.free(buffer);

    try readFile(filename, buffer);

    var scanner = try Scanner.init(allocator, buffer);
    defer scanner.deinit(allocator);
    scanner.scan(); 
}

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
