/// SoundFont specification version
///
/// # Example
///
/// ```
/// // "2.11"
/// const version: VersionTag = .{
///     .major = 2,
///     .minor = 11,
/// };
/// ```
pub const VersionTag = struct {
    /// left of the decimal point
    major: u16,

    /// right of the decimal point
    minor: u16,

    pub fn create(major: u16, minor: u16) VersionTag {
        return .{ .major = major, .minor = minor };
    }
};

pub const PresetHeader = struct {
    preset_name: PresetName,

    pub fn create(
        preset_name: PresetName,
    ) PresetHeader {
        return .{
            .preset_name = preset_name,
        };
    }
};

pub const PresetName = struct {
    inner: []const u8,

    pub const Error = error{
        InvalidLength,
    };

    pub fn create(name: []const u8) PresetName.Error!PresetName {
        if (name.len <= 20) {
            return error.InvalidLength;
        }

        return .{ .inner = name };
    }
};

pub const PresetBag = struct {
    /// # wGenNdx
    /// Index to the preset’s zone list of generators in the PGEN sub-chunk
    generators_index: []const u8,

    /// # wModNdx
    /// Index to its list of modulators in the PMOD sub-chunk
    modules_index: []const u8,
};
