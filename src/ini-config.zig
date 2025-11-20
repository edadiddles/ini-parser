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
        if (std.mem.eql(u8, section, self.section)) {
            return;
        }
        std.debug.print("putting section...\n", .{});
        try self.putSection();

        if(self.map.get(section)) |sectionMap| {
            std.debug.print("reusing existing section map...\n", .{});
            self.sectionMap = sectionMap;
            self.section = self.map.getKey(section).?;
        } else {
            std.debug.print("creating new section map...\n", .{});
            self.section = try allocator.dupe(u8, section);
            self.initSectionMap(allocator);
        }
    }

    pub fn addPair(self: *IniConfig, allocator: std.mem.Allocator, key: []const u8, val: []const u8) !void {
        const k = self.sectionMap.getKey(key) orelse try allocator.dupe(u8, key);
        if (self.sectionMap.getEntry(k)) |e| {
            allocator.free(e.value_ptr.*);
        }
        try self.sectionMap.put(k, try allocator.dupe(u8, val));
    }

    fn putSection(self: *IniConfig) !void {
        if(self.section.len == 0) {
            return;
        }

        try self.map.put(self.section, self.sectionMap);
    }

    pub fn finalize(self: *IniConfig) !void {
        try self.putSection();
    }

    pub fn getConfig(self: IniConfig) std.StringHashMap(std.StringHashMap([]const u8)) {
        return self.map;
    }

    pub fn print(self: IniConfig) void {
        var key_iter = self.map.keyIterator();
        while (key_iter.next()) |key| {
            std.debug.print("Section: {s}\n", .{ key.* });
            var k_iter = self.map.get(key.*).?.keyIterator();
            while (k_iter.next()) |k| {
                const v = self.map.get(key.*).?.get(k.*).?;
                std.debug.print("  ({s},{s})\n", .{ k.*, v });
            }
        }
    }

    fn initSectionMap(self: *IniConfig, allocator: std.mem.Allocator) void {
        self.sectionMap = .init(allocator);
    }

    fn initMap(self: *IniConfig, allocator: std.mem.Allocator) void {
        self.map = .init(allocator);
    }
};
