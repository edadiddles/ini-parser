const std = @import("std");


pub const IniConfig = struct{
    section: []const u8,
    sectionMap: std.StringHashMap([]const u8),
    map: std.StringHashMap(std.StringHashMap([]const u8)),

    pub fn init(allocator: std.mem.Allocator) IniConfig {
        return IniConfig{
            .section = "",
            .sectionMap = .init(allocator),
            .map = .init(allocator),
        };
    }

    pub fn deinit(self: *IniConfig, allocator: std.mem.Allocator) void {
        var key_iter = self.map.keyIterator();
        while(key_iter.next()) |key| {
            var k_iter = self.map.get(key.*).?.keyIterator();
            while(k_iter.next()) |k| {
                allocator.free(self.map.get(key.*).?.get(k.*).?);
                allocator.free(k.*);
            }
            self.map.getEntry(key.*).?.value_ptr.deinit();
            allocator.free(key.*);
        }
        self.map.deinit();
    }

    pub fn setSection(self: *IniConfig, allocator: std.mem.Allocator, section: []const u8) !void {
        self.section = try allocator.dupe(u8, section);
    }

    pub fn addPair(self: *IniConfig, allocator: std.mem.Allocator, key: []const u8, val: []const u8) !void {
        try self.sectionMap.put(try allocator.dupe(u8, key), try allocator.dupe(u8, val));
    }

    pub fn putSection(self: *IniConfig, allocator: std.mem.Allocator) !void {
        if(self.section.len == 0) {
            return;
        }
        try self.map.put(self.section, self.sectionMap);
        self.initSectionMap(allocator);
    }

    pub fn finalize(self: *IniConfig, allocator: std.mem.Allocator) !void {
        try self.putSection(allocator);
    }

    pub fn getConfig(self: IniConfig) std.StringHashMap(std.StringHashMap([]const u8)) {
        return self.map;
    }

    fn initSectionMap(self: *IniConfig, allocator: std.mem.Allocator) void {
        self.sectionMap = .init(allocator);
    }

    fn initMap(self: *IniConfig, allocator: std.mem.Allocator) void {
        self.map = .init(allocator);
    }
};
