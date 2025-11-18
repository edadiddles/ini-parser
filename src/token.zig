pub const TokenType = enum{
    LEFT_SQ_BRACKET, RIGHT_SQ_BRACKET,
    EQUALS,
    SEMI_COLON, POUND_SIGN,
    DBL_QUOTE,
    IDENTIFIER, NUMBER, STRING, SECTION,
    EOF,
};

pub const Token = struct{
    type: TokenType,
    literal: []const u8,

    pub fn init(t: TokenType, l: []const u8) Token {
        return Token{
            .type = t,
            .literal = l,
        };
    }
};

