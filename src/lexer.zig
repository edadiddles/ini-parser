const std = @import("std");
const token_types = @import("token.zig");


pub const Scanner = struct{
    buf: []u8,
    tokens: []token_types.Token,
    token_pos: u16,

    pos: u16,
    read_pos: u16,

    pub fn init(allocator: std.mem.Allocator, buffer: []u8) !Scanner {
        return Scanner{
            .buf = buffer,
            .tokens = try allocator.alloc(token_types.Token, 64),
            .token_pos = 0,
            .pos = 0,
            .read_pos = 0,
        };
    }

    pub fn deinit(self: Scanner, allocator: std.mem.Allocator) void {
        allocator.free(self.tokens);
    }

    pub fn scan(self: *Scanner) void { 
        while (!self.is_eof()) {
            self.pos = self.read_pos;
            self.scan_token();
        }

        self.add_token(token_types.TokenType.EOF, "eof");
        self.print_tokens();
    }

    fn scan_token(self: *Scanner) void {
        const char = self.read_char();
        switch(char) {
            '[' => self.section(),
            '=' => self.add_token(token_types.TokenType.EQUALS, self.buf[self.pos..self.read_pos]),
            ';','#' => self.comment(),
            '"' => self.string(),
            '/' => self.fspath(),
            else => {
                if (self.is_letter(char)) {
                    self.identifier();
                } else if(self.is_number(char)) {
                    self.number();
                } else if (self.is_whitespace(char)) {
                    // pass
                } else if (self.is_newline(char)) {
                    // pass
                } else {
                    std.debug.print("Token {c} is not found.\n", .{char});
                }
            },
        }
    }

    fn add_token(self: *Scanner, token_type: token_types.TokenType, literal: []const u8) void {
        self.tokens[self.token_pos] = token_types.Token.init(token_type, literal);
        self.token_pos += 1;
    }

    fn identifier(self: *Scanner) void {
        while(self.is_alphanumeric(self.peek(0))) {
            _ = self.read_char();
        }

        self.add_token(token_types.TokenType.IDENTIFIER, self.buf[self.pos..self.read_pos]);
    }

    fn string(self: *Scanner) void {
        while(self.peek(0) != '"') {
            _ = self.read_char();
        }

        self.add_token(token_types.TokenType.STRING, self.buf[self.pos..self.read_pos]);
    }

    fn number(self: *Scanner) void {
        while(self.is_number(self.peek(0))) {
            _ = self.read_char();
        }

        if (self.peek(0) == '.' and self.is_number(self.peek(1))) {
            _ = self.read_char();

            while(self.is_number(self.peek(0))) {
                _ = self.read_char();
            }
        }

        self.add_token(token_types.TokenType.NUMBER, self.buf[self.pos..self.read_pos]);
    }

    fn fspath(self: *Scanner) void {
        while(self.is_letter(self.peek(0)) or self.peek(0) == '/') {
            _ = self.read_char();
        }

        self.add_token(token_types.TokenType.FS_PATH, self.buf[self.pos..self.read_pos]);
    }

    fn section(self: *Scanner) void {
        while(self.peek(0) != ']') {
            _ = self.read_char();
        }

        self.add_token(token_types.TokenType.SECTION, self.buf[self.pos+1..self.read_pos]);
        _ = self.read_char(); // consume the ]
    }

    fn comment(self: *Scanner) void {
        while(!self.is_newline(self.peek(0)) and !self.is_eof()) {
            _ = self.read_char();
        }

        if (self.is_newline(self.peek(0))) {
            _ = self.read_char();
        }
    }

    fn peek(self: Scanner, look_ahead: u8) u8 {
        if (self.is_eof()) {
            return 170;
        }

        return self.buf[self.read_pos + look_ahead];
    }

    fn read_char(self: *Scanner) u8 {
        const char = self.buf[self.read_pos];
        self.read_pos += 1;
        return char;
    }

    fn is_eof(self: Scanner) bool {
        return self.read_pos >= self.buf.len or self.buf[self.read_pos] == 170;
    }

    fn is_letter(_: Scanner, c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c == '_') or (c == '.');
    }

    fn is_number(_: Scanner, c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn is_alphanumeric(self: Scanner, c: u8) bool {
        return self.is_letter(c) or self.is_number(c);
    }

    fn is_whitespace(_: Scanner, c: u8) bool {
        return c == ' ';
    }

    fn is_newline(_: Scanner, c: u8) bool {
        return c == '\n';
    }

    fn print_tokens(self: Scanner) void {
        for (self.tokens) |token| {
            if (token.type == token_types.TokenType.EOF) {
                break;
            }
        }
    }

};
