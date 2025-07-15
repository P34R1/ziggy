{
  description = "Description for the project";

  inputs = {
    flake-utils.follows = "zig2nix/flake-utils";
    zig2nix.url = "github:Cloudef/zig2nix";
  };

  outputs =
    {
      self,
      flake-utils,
      zig2nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        env = zig2nix.outputs.zig-env.${system} { };
      in
      with env.pkgs.lib;
      rec {
        packages.foreign = env.package {
          src = cleanSource ./.;

          # Packages required for compiling
          nativeBuildInputs = with env.pkgs; [ ];
          # Packages required for linking
          buildInputs = with env.pkgs; [ ];

          # Smaller binaries and avoids shipping glibc.
          zigPreferMusl = true;
          # This disables LD_LIBRARY_PATH mangling, binary patching etc...
          # The package won't be usable inside nix.
          zigDisableWrap = true;
        };

        packages.default = packages.foreign.override (attrs: {
          # Prefer nix friendly settings.
          zigPreferMusl = false;
          zigDisableWrap = false;

          # Executables required for runtime
          # These packages will be added to the PATH
          zigWrapperBins = with env.pkgs; [ ];

          # Libraries required for runtime
          # These packages will be added to the LD_LIBRARY_PATH
          zigWrapperLibs = attrs.buildInputs or [ ];
        });

        # nix run .#zon2lock
        apps.zon2lock = env.app [ ] "zig2nix zon2lock build.zig.zon";

        devShells.default = env.mkShell {
          # Packages required for compiling, linking and running
          # Libraries added here will be automatically added to the LD_LIBRARY_PATH and PKG_CONFIG_PATH
          nativeBuildInputs =
            [ ]
            ++ packages.default.nativeBuildInputs
            ++ packages.default.buildInputs
            ++ packages.default.zigWrapperBins
            ++ packages.default.zigWrapperLibs;
        };
      }
    );
}
