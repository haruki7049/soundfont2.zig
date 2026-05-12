{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs, lib, ... }:
        let
          soundfont2-zig = pkgs.stdenv.mkDerivation {
            name = "soundfont2.zig";
            src = lib.cleanSource ./.;
            doCheck = true;

            nativeBuildInputs = [
              pkgs.zig_0_15.hook
            ];

            postPatch = ''
              ln -s ${pkgs.callPackage ./.deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p

              # Remove NIX_CFLAGS_COMPILE because zig cannot understand it
              unset NIX_CFLAGS_COMPILE
            '';
          };
        in
        {
          treefmt = {
            projectRootFile = ".git/config";

            # Nix
            programs.nixfmt.enable = true;

            # Zig
            programs.zig.enable = true;
            settings.formatter.zig.command = lib.getExe pkgs.zig_0_15;

            # GitHub Actions
            programs.actionlint.enable = true;

            # Markdown
            programs.mdformat.enable = true;

            # Shell Script
            programs.shellcheck.enable = true;
            programs.shfmt.enable = true;
          };

          packages = {
            inherit soundfont2-zig;
            default = soundfont2-zig;
          };

          checks = {
            inherit soundfont2-zig;
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.zig_0_15 # Zig compiler
              pkgs.zls_0_15 # Zig LSP
              pkgs.zon2nix # zon2nix
              pkgs.nil # Nix LSP
            ];

            shellHook = ''
              # Remove NIX_CFLAGS_COMPILE because zig cannot understand it
              unset NIX_CFLAGS_COMPILE
            '';
          };
        };
    };
}
