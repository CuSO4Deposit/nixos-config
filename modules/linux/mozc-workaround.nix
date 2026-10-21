# TEMPORARY workaround: Qt 6.12's uic rejects the "::"-prefixed custom widget
# class name in mozc's dictionary_tool.ui. Upstream fixed this in
# google/mozc@29c082a. Delete this file and its import in desktop.nix once the
# pinned nixpkgs ships that fix (NixOS/nixpkgs#531687 or an equivalent patch).
{ ... }:
{
  nixpkgs.overlays = [
    (_: prev: {
      mozc = prev.mozc.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch {
            name = "mozc-qt-6.12-uic-custom-widget.patch";
            url = "https://github.com/google/mozc/commit/29c082a64b577b661694148760a2ae19817beb57.patch";
            hash = "sha256-Gft1mnLPSMexDMg/PVhwjUVl9D9g1cVGvVNgFmpK168=";
          })
        ];
      });
    })
  ];
}
