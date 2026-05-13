const std = @import("std");
const riff = @import("riff_zig");

test {
    const allocator = std.testing.allocator;

    const chunk_filedata: []const u8 = @embedFile("assets/FluidR3_GM2-2.sf2");
    var reader = std.Io.Reader.fixed(chunk_filedata);
    const chunk: riff.Chunk = try riff.read(allocator, &reader);
    defer chunk.deinit(allocator);

    const expected = riff.Chunk{ .riff = .{
        .four_cc = try riff.FourCC.new("sfbk"),
        .chunks = &.{},
    } };

    try std.testing.expectEqualDeep(expected, chunk);
}
