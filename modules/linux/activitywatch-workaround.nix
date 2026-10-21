# TEMPORARY workaround for two upstream packaging regressions exposed by the
# 2026-10-17 nixpkgs update. Delete this file and its import in desktop.nix
# once the pinned nixpkgs satisfies both conditions:
#   1. python3Packages.aw-core is >= 0.5.18, i.e. NixOS/nixpkgs#573451 merged.
#   2. aw-qt's makeWrapperArgs is split into separate arguments, i.e.
#      NixOS/nixpkgs#575801 merged.
# The overlays exist only to bridge the gap until then.
{ ... }:
{
  nixpkgs.overlays = [
    (_: prev: {
      python3Packages = prev.python3Packages.overrideScope (
        self: super: {
          aw-core = super.aw-core.overridePythonAttrs (old: rec {
            version = "0.5.18";
            src = prev.fetchFromGitHub {
              owner = "ActivityWatch";
              repo = "aw-core";
              rev = "v${version}";
              hash = "sha256-v5cCV3NFk7oz04WjbHgxQr4I72/gOUQRcARIcz6zXjo=";
            };
            patches = (old.patches or [ ]) ++ [
              (prev.fetchpatch {
                name = "datastore-serialize-native-bucket-datetimes.patch";
                url = "https://github.com/ActivityWatch/aw-core/commit/35a48676069e730684421d6ca56e214b163e1fd9.patch";
                hash = "sha256-KTMMdTC2kSZ0+8l5zmf+rDGFwyHJvdPzO7eYevCJUpM=";
              })
            ];
            propagatedBuildInputs = old.propagatedBuildInputs ++ [ self.click ];
          });
        }
      );
    })
    # Must come after the aw-core overlay: prev is the post-overlay fixpoint,
    # so aw-qt is rebuilt against the fixed python3Packages.
    (_: prev: {
      aw-qt = prev.aw-qt.overridePythonAttrs {
        makeWrapperArgs = [
          "--suffix"
          "PATH"
          ":"
          (prev.lib.makeBinPath [ prev.xdg-utils ])
        ];
      };
    })
  ];
}
