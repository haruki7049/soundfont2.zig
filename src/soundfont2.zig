const std = @import("std");
const riff = @import("riff_zig");
const Self = @This();
const Types = @import("./types.zig");

info: Info,
samples: Samples,
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

pub const Samples = []const u16;

pub const PresetData = struct {
    /// # The phdr field
    phdr: Types.PresetHeader,

    /// # The pbag field
    pbag: Types.PresetBag,
};

pub fn create(allocator: std.mem.Allocator, reader: anytype) anyerror!Self {
    const chunk = try riff.read(allocator, reader);
    defer chunk.deinit(allocator);

    const result = switch (chunk) {
        .chunk, .list => @panic("Unexpected chunk instead of RIFF chunk"),
        .riff => try parse_riff_chunk(chunk),
    };
    return result;
}

fn parse_riff_chunk(chunk: riff.Chunk) !Self {
    var info: Info = undefined;
    var sdta: []const u16 = undefined;
    var pdta: PresetData = undefined;

    for (chunk.riff.chunks) |c| {
        switch (c) {
            .chunk, .riff => @panic("Unexpected chunk instead of LIST chunk"),
            .list => |list_chunk| {
                const actual: []const u8 = &list_chunk.four_cc.inner;

                if (std.mem.eql(u8, "INFO", actual)) {
                    // info chunk
                    info = try parse_list_info_chunks(list_chunk.chunks);
                } else if (std.mem.eql(u8, "sdta", actual)) {
                    // sdta chunk
                    sdta = try parse_list_sdta_chunks(list_chunk.chunks);
                } else if (std.mem.eql(u8, "pdta", actual)) {
                    // pdta chunk
                    pdta = try parse_list_pdta_chunks(list_chunk.chunks);
                }
            },
        }
    }

    return .{
        .info = info,
        .samples = sdta,
        .presets = pdta,
    };
}

fn parse_list_info_chunks(chunks: []const riff.Chunk) !Info {
    var result: Info = undefined;

    for (chunks) |c| {
        switch (c) {
            .list, .riff => @panic("Unexpected chunk instead of normal chunk"),
            .chunk => |chunk| {
                const actual: []const u8 = &chunk.four_cc.inner;

                if (std.mem.eql(u8, "ifil", actual)) {
                    try parse_ifil(&result, chunk.data);
                } else if (std.mem.eql(u8, "INAM", actual)) {
                    trim_end_zero(&result, chunk.data, .inam);
                } else if (std.mem.eql(u8, "isng", actual)) {
                    trim_end_zero(&result, chunk.data, .isng);
                } else if (std.mem.eql(u8, "IPRD", actual)) {
                    trim_end_zero(&result, chunk.data, .iprd);
                } else if (std.mem.eql(u8, "ISFT", actual)) {
                    trim_end_zero(&result, chunk.data, .isft);
                } else if (std.mem.eql(u8, "ICOP", actual)) {
                    trim_end_zero(&result, chunk.data, .icop);
                } else if (std.mem.eql(u8, "ICRD", actual)) {
                    trim_end_zero(&result, chunk.data, .icrd);
                } else if (std.mem.eql(u8, "IENG", actual)) {
                    trim_end_zero(&result, chunk.data, .ieng);
                } else if (std.mem.eql(u8, "ICMT", actual)) {
                    trim_end_zero(&result, chunk.data, .icmt);
                }
            },
        }
    }

    return result;
}

fn parse_ifil(info: *Info, data: []const u8) !void {
    // Ensure the data has at least 4 bytes
    if (data.len < 4) return error.InvalidLength;

    // Decode 16-bit little-endian integers
    const major = @as(u16, data[0]) | (@as(u16, data[1]) << 8);
    const minor = @as(u16, data[2]) | (@as(u16, data[3]) << 8);
    info.ifil = Types.VersionTag.create(major, minor);
}

const Target = enum { inam, isng, iprd, isft, icop, icrd, ieng, icmt };

fn trim_end_zero(info: *Info, data: []const u8, target: Target) void {
    var v: []const u8 = std.mem.trimEnd(u8, data, &.{0});
    var t = switch (target) {
        .inam => &info.inam,
        .isng => &info.isng,
        .iprd => &info.iprd.?,
        .isft => &info.isft.?,
        .icop => &info.icop.?,
        .icrd => &info.icrd.?,
        .ieng => &info.ieng.?,
        .icmt => &info.icmt.?,
    };
    t = &v;
}

fn parse_list_sdta_chunks(chunks: []const riff.Chunk) !Samples {
    if (chunks.len != 1)
        return error.InvalidChunksSize;

    switch (chunks[0]) {
        .list, .riff => @panic("Unexpected chunk instead of normal chunk"),
        .chunk => |chunk| {
            const actual: []const u8 = &chunk.four_cc.inner;

            if (std.mem.eql(u8, "smpl", actual)) {
                // Zero-copy cast (Requires @alignOf(u16) alignment and native endianness)
                const samples = std.mem.bytesAsSlice(u16, @alignCast(chunk.data));
                return samples;
            } else {
                @panic("Unexpected FourCC instead of \"smpl\"");
            }
        },
    }
}

fn parse_list_pdta_chunks(chunks: []const riff.Chunk) !PresetData {
    if (chunks.len != 9)
        return error.InvalidChunksSize;

    var result: PresetData = undefined;

    for (chunks) |chunk| {
        switch (chunk) {
            .list, .riff => @panic("Unexpected chunk instead of normal chunk"),
            .chunk => |c| {
                const phdr_four_cc = try riff.FourCC.new("phdr");
                const pbag_four_cc = try riff.FourCC.new("pbag");
                const pmod_four_cc = try riff.FourCC.new("pmod");
                const pgen_four_cc = try riff.FourCC.new("pgen");
                const inst_four_cc = try riff.FourCC.new("inst");
                const ibag_four_cc = try riff.FourCC.new("ibag");
                const imod_four_cc = try riff.FourCC.new("imod");
                const igen_four_cc = try riff.FourCC.new("igen");
                const shdr_four_cc = try riff.FourCC.new("shdr");

                if (phdr_four_cc == c.four_cc) {
                    try pack_presetdata_into(&result, c.data);
                } else if (pbag_four_cc == c.four_cc) {
                    trim_end_zero(&result.inam, c.data);
                } else if (pmod_four_cc == c.four_cc) {
                    trim_end_zero(&result.isng, c.data);
                } else if (pgen_four_cc == c.four_cc) {
                    trim_end_zero(&result.iprd, c.data);
                } else if (inst_four_cc == c.four_cc) {
                    trim_end_zero(&result.isft, c.data);
                } else if (ibag_four_cc == c.four_cc) {
                    trim_end_zero(&result.icop, c.data);
                } else if (imod_four_cc == c.four_cc) {
                    trim_end_zero(&result.icop, c.data);
                } else if (igen_four_cc == c.four_cc) {
                    trim_end_zero(&result.icrd, c.data);
                } else if (shdr_four_cc == c.four_cc) {
                    trim_end_zero(&result.ieng, c.data);
                } else {
                    // Do nothing if there are no matching four_cc
                }
            },
        }
    }

    return result;
}

fn pack_presetdata_into(result: *PresetData, data: []const u8) !void {
    // Check if data has at least 20 bytes for the preset name
    if (data.len < 20) return error.InvalidLength;

    const name = std.mem.sliceTo(data[0..20], 0);
    const preset_name = try Types.PresetName.create(name);
    result.phdr = Types.PresetHeader.create(preset_name);
}

test "create SoundFont from assets/soundfont-files/FluidR3_GM2-2.sf2" {
    const allocator = std.testing.allocator;

    // Load test file
    const chunk_filedata: []const u8 = @embedFile("./assets/soundfont-files/FluidR3_GM2-2.sf2");
    var reader = std.Io.Reader.fixed(chunk_filedata);

    // Parse SoundFont
    const actual: Self = try create(allocator, &reader);
    const expected: Self = Self{
        .info = .{
            .ifil = .{ .major = 2, .minor = 2 },
            .inam = "Fluid R3 GM",
            .isng = "E-mu 10K1",
        },
    };

    try std.testing.expectEqualDeep(expected, actual);
}
