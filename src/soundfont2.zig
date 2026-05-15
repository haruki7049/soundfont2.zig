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
        .chunk || .list => @panic("Unexpected chunk instead of RIFF chunk"),
        .riff => try parse_riff_chunk(allocator, chunk),
    };
    return result;
}

fn parse_riff_chunk(allocator: std.mem.Allocator, chunk: riff.Chunk) !Self {
    var info: Info = undefined;
    var sdta: []const u16 = undefined;
    var pdta: PresetData = undefined;

    for (chunk.riff.chunks) |c| {
        switch (c) {
            .chunk || .riff => @panic("Unexpected chunk instead of LIST chunk"),
            .list => |list_chunk| {
                const info_four_cc = try riff.FourCC.new("INFO");
                const sdta_four_cc = try riff.FourCC.new("sdta");
                const pdta_four_cc = try riff.FourCC.new("pdta");

                switch (list_chunk.four_cc) {
                    info_four_cc => {
                        info = try parse_list_info_chunks(list_chunk.chunks);
                    },
                    sdta_four_cc => {
                        sdta = try parse_list_sdta_chunks(list_chunk.chunks);
                    },
                    pdta_four_cc => {
                        pdta = try parse_list_pdta_chunks(allocator, list_chunk.chunks);
                    },
                    else => @panic("Unexpected FourCC instead of INFO, sdta and pdta"),
                }
            },
        }
    }
}

fn parse_list_info_chunks(chunks: []const riff.Chunk) !Info {
    var result: Info = undefined;

    for (chunks) |c| {
        switch (c) {
            .list || .riff => @panic("Unexpected chunk instead of normal chunk"),
            .chunk => |chunk| {
                const ifil_four_cc = try riff.FourCC.new("ifil");
                const inam_four_cc = try riff.FourCC.new("INAM");
                const isng_four_cc = try riff.FourCC.new("isng");
                const iprd_four_cc = try riff.FourCC.new("IPRD");
                const isft_four_cc = try riff.FourCC.new("ISFT");
                const icop_four_cc = try riff.FourCC.new("ICOP");
                const icrd_four_cc = try riff.FourCC.new("ICRD");
                const ieng_four_cc = try riff.FourCC.new("IENG");
                const icmt_four_cc = try riff.FourCC.new("ICMT");

                switch (chunk.four_cc) {
                    ifil_four_cc => try parse_ifil(&result, chunk.data),
                    inam_four_cc => trim_end_zero(&result.inam, chunk.data),
                    isng_four_cc => trim_end_zero(&result.isng, chunk.data),
                    iprd_four_cc => trim_end_zero(&result.iprd, chunk.data),
                    isft_four_cc => trim_end_zero(&result.isft, chunk.data),
                    icop_four_cc => trim_end_zero(&result.icop, chunk.data),
                    icrd_four_cc => trim_end_zero(&result.icrd, chunk.data),
                    ieng_four_cc => trim_end_zero(&result.ieng, chunk.data),
                    icmt_four_cc => trim_end_zero(&result.icmt, chunk.data),
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

fn trim_end_zero(target: *[]u8, data: []const u8) void {
    const v: []const u8 = std.mem.trimEnd(u8, data, &.{0});
    target = v;
}

fn parse_list_sdta_chunks(chunks: []const riff.Chunk) !Samples {
    if (chunks.len != 1)
        return error.InvalidChunksSize;

    switch (chunks[0]) {
        .list || .riff => @panic("Unexpected chunk instead of normal chunk"),
        .chunk => |chunk| {
            const smpl_four_cc = try riff.FourCC.new("smpl");

            if (chunk.four_cc == smpl_four_cc) {
                // Zero-copy cast (Requires @alignOf(u16) alignment and native endianness)
                const samples = std.mem.bytesAsSlice(u16, @alignCast(chunk.data));
                return samples;
            } else {
                @panic("Unexpected FourCC instead of \"smpl\"");
            }
        },
    }
}

fn parse_list_pdta_chunks(allocator: std.mem.Allocator, chunks: []const riff.Chunk) !PresetData {
    if (chunks.len != 9)
        return error.InvalidChunksSize;

    var result: PresetData = undefined;

    for (chunks) |chunk| {
        switch (chunk) {
            .list || .riff => @panic("Unexpected chunk instead of normal chunk"),
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

                switch (c.four_cc) {
                    phdr_four_cc => try pack_presetdata_into(&result, c.data),
                    pbag_four_cc => trim_end_zero(&result.inam, c.data),
                    pmod_four_cc => trim_end_zero(&result.isng, c.data),
                    pgen_four_cc => trim_end_zero(&result.iprd, c.data),
                    inst_four_cc => trim_end_zero(&result.isft, c.data),
                    ibag_four_cc => trim_end_zero(&result.icop, c.data),
                    imod_four_cc => trim_end_zero(&result.icop, c.data),
                    igen_four_cc => trim_end_zero(&result.icrd, c.data),
                    shdr_four_cc => trim_end_zero(&result.ieng, c.data),
                }
            },
        }
    }

    return result;
}

// pub fn deinit(self: Self, allocator: std.mem.Allocator) void {}
