const std = @import("std");
const token_types = @import("token.zig");

pub const Parser = struct{
    tokens: *[]token_types.Token,

    pub fn init(tokens: *[]token_types.Token) Parser {
        return Parser{
            .tokens = tokens,
        };
    }

    pub fn parse(self: *Parser, allocator: std.mem.Allocator) std.StringHashMap(std.StringHashMap([]u8)) {
        var iniConfig: std.StringHashMap(std.StringHashMap([]u8)) = .init(allocator);
        defer iniConfig.deinit();

        for (self.tokens.*) |token| {
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
};
