const std = @import("std");
const riff = @import("riff_zig");

test {
    const allocator = std.testing.allocator;
    const assertion_data = struct {
        pub const sdta = struct {
            pub const smpl = struct {
                pub const data = @embedFile("./assets/chunk-data/FluidR3_GM2-2.sfbk.sdta.smpl.data.bin");
            };
        };
        pub const pdta = struct {
            pub const phdr = struct {
                pub const data = @embedFile("./assets/chunk-data/FluidR3_GM2-2.sfbk.pdta.phdr.data.bin");
            };
            pub const pbag = struct {
                pub const data = @embedFile("./assets/chunk-data/FluidR3_GM2-2.sfbk.pdta.pbag.data.bin");
            };
            pub const pgen = struct {
                pub const data = @embedFile("./assets/chunk-data/FluidR3_GM2-2.sfbk.pdta.pgen.data.bin");
            };
            pub const inst = struct {
                pub const data = @embedFile("./assets/chunk-data/FluidR3_GM2-2.sfbk.pdta.inst.data.bin");
            };
            pub const ibag = struct {
                pub const data = @embedFile("./assets/chunk-data/FluidR3_GM2-2.sfbk.pdta.ibag.data.bin");
            };
            pub const imod = struct {
                pub const data = @embedFile("./assets/chunk-data/FluidR3_GM2-2.sfbk.pdta.imod.data.bin");
            };
            pub const igen = struct {
                pub const data = @embedFile("./assets/chunk-data/FluidR3_GM2-2.sfbk.pdta.igen.data.bin");
            };
            pub const shdr = struct {
                pub const data = @embedFile("./assets/chunk-data/FluidR3_GM2-2.sfbk.pdta.shdr.data.bin");
            };
        };
    };

    const chunk_filedata: []const u8 = @embedFile("assets/soundfont-files/FluidR3_GM2-2.sf2");
    var reader = std.Io.Reader.fixed(chunk_filedata);
    const chunk: riff.Chunk = try riff.read(allocator, &reader);
    defer chunk.deinit(allocator);

    const expected = riff.Chunk{ .riff = .{
        .four_cc = try riff.FourCC.new("sfbk"),
        .chunks = &.{
            .{ .list = .{
                .four_cc = try riff.FourCC.new("INFO"),
                .chunks = &.{
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("ifil"), .data = &.{ 2, 0, 2, 0 } } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("INAM"), .data = "Fluid R3 GM" ++ .{0} } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("isng"), .data = "E-mu 10K1" ++ .{0} } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("IPRD"), .data = "SBAWE32" ++ .{0} } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("ISFT"), .data = "SFEDT v1.28:SFEDT v1.36:" ++ .{ 0, 0 } } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("ICOP"), .data = "Frank Wen 2000-2002" ++ .{0} } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("ICRD"), .data = "20th June 2013" ++ .{ 0, 0 } } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("IENG"), .data = "Frank Wen" ++ .{0} } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("ICMT"), .data = "DO NOT REDISTRIBUTE ANY OF THESE SAMPLES. Violin fixed by Church Organist " ++ .{ 0, 0 } } },
                },
            } },
            .{ .list = .{
                .four_cc = try riff.FourCC.new("sdta"),
                .chunks = &.{
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("smpl"), .data = assertion_data.sdta.smpl.data } },
                },
            } },
            .{ .list = .{
                .four_cc = try riff.FourCC.new("pdta"),
                .chunks = &.{
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("phdr"), .data = assertion_data.pdta.phdr.data } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("pbag"), .data = assertion_data.pdta.pbag.data } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("pmod"), .data = &.{ 0, 0, 0, 0, 0, 0, 0, 0, 1, 0 } } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("pgen"), .data = assertion_data.pdta.pgen.data } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("inst"), .data = assertion_data.pdta.inst.data } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("ibag"), .data = assertion_data.pdta.ibag.data } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("imod"), .data = assertion_data.pdta.imod.data } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("igen"), .data = assertion_data.pdta.igen.data } },
                    .{ .chunk = .{ .four_cc = try riff.FourCC.new("shdr"), .data = assertion_data.pdta.shdr.data } },
                },
            } },
        },
    } };

    try std.testing.expectEqualDeep(expected, chunk);
}
