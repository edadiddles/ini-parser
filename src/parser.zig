const std = @import("std");
const token_types = @import("token.zig");

pub const Parser = struct{
    read_pos: u8,

    tokens: *[]token_types.Token,
    parseMap: std.StringHashMap(std.StringHashMap([]const u8)),

    pub fn init(allocator: std.mem.Allocator, tokens: *[]token_types.Token) Parser {
        return Parser{
            .tokens = tokens,
            .parseMap = .init(allocator),
            .read_pos = 0,
        };
    }

    pub fn deinit(self: *Parser, allocator: std.mem.Allocator) void {
        allocator.free(self.parseMap);
    }

    pub fn parse(self: *Parser, allocator: std.mem.Allocator) !std.StringHashMap(std.StringHashMap([]const u8)) {
        var section: []const u8 = ""[0..];
        var sectionMap: std.StringHashMap([]const u8) = .init(allocator);
        while(true) {
            const token = self.read_token();
            std.debug.print("processing token {}\n", .{ token });

            switch(token.type) {
                token_types.TokenType.EOF => {
                    try self.parseMap.put(section, sectionMap);
                    break;
                },
                token_types.TokenType.SECTION => {
                    if (section.len != 0) {
                        try self.parseMap.put(section, sectionMap);
                        sectionMap = .init(allocator);
                    }

                    section = try allocator.dupe(u8, token.literal);
                },
                token_types.TokenType.IDENTIFIER => {
                    const key = try allocator.dupe(u8, token.literal);
                    if(self.peek(0).type != token_types.TokenType.EQUALS) {
                        std.debug.print("unexpected token after identifier: {}", .{ token });
                    }

                    _ = self.read_token();
                    switch(self.peek(0).type) {
                       token_types.TokenType.NUMBER, 
                       token_types.TokenType.STRING,
                       token_types.TokenType.IDENTIFIER => {
                           const t = self.read_token();
                           const val = try allocator.dupe(u8, t.literal);
                           try sectionMap.put(key, val);
                       },
                       else => {
                           std.debug.print("unexpected token after equals: {}", .{ token });
                       },
                    }
                },
                else => {
                    std.debug.print("unknown token: {}", .{ token });
                }
            }
        }

        return self.parseMap;
    }

    fn is_eof(self: Parser) bool {
        return self.tokens.*[self.read_pos].type == token_types.TokenType.EOF;
    }

    fn peek(self: Parser, look_ahead: u8) token_types.Token {
        return self.tokens.*[self.read_pos+look_ahead];
    }

    fn read_token(self: *Parser) token_types.Token {
        const token = self.tokens.*[self.read_pos];
        self.read_pos += 1;
        return token;
    }

};
