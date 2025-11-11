const std = @import("std");
const ini_parser = @import("ini_parser");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    _ = ini_parser;
}

