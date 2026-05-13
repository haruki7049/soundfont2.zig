const std = @import("std");
const riff = @import("riff_zig");
const Self = @This();
const Types = @import("./types.zig");

info: Info,
samples: []const u16,
presets: PresetData,

pub const Info = struct {
    /// # The ifil field
    /// SoundFont specification version
    ifil: Types.VersionTag,

    /// # The INAM field
    /// SoundFont compatible bank
    /// ASCII string
    inam: []const u8,

    /// # The isng field
    /// ASCII string to identify the wavetable sound engine for which the file was optimized
    isng: []const u8,
    irom: ?[]const u8,
    iver: ?[]const u8,
    icrd: ?[]const u8,
    ieng: ?[]const u8,
    iprd: ?[]const u8,
    icop: ?[]const u8,
    icmt: ?[]const u8,
    isft: ?[]const u8,
};

pub const PresetData = struct {
    phdr: Types.PresetHeader,
    pbag: Types.PresetBag,
};

pub fn read(allocator: std.mem.Allocator, reader: anytype) anyerror!Self {
    const chunk = try riff.read(allocator, reader);
    defer chunk.deinit(allocator);
}

// pub fn deinit(self: Self, allocator: std.mem.Allocator) void {}
