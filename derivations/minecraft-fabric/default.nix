{ pkgs }:
let
  maven = "https://maven.fabricmc.net";

  vanillaServer = pkgs.minecraftServers.vanilla-26-3.src;

  fabricLoaderLibs = [
    (pkgs.fetchurl {
      url = "${maven}/org/ow2/asm/asm/9.11/asm-9.11.jar";
      hash = "sha256-X+O0abhkblvFOol4QJUtY7cS1JI9KnomrrxYXx/sdnY=";
    })
    (pkgs.fetchurl {
      url = "${maven}/org/ow2/asm/asm-analysis/9.11/asm-analysis-9.11.jar";
      hash = "sha256-oUIcIJeMoKMw8kGxeSOnUaI/sclCP9oaunWRuwhrAdg=";
    })
    (pkgs.fetchurl {
      url = "${maven}/org/ow2/asm/asm-commons/9.11/asm-commons-9.11.jar";
      hash = "sha256-/P835qAiep9e6Bp8B/USSTB/oViJtWo1mub3c8Fkwis=";
    })
    (pkgs.fetchurl {
      url = "${maven}/org/ow2/asm/asm-tree/9.11/asm-tree-9.11.jar";
      hash = "sha256-2orSTQv377BnSpBvWafUQWkrZBcYNx87zmdisZGhaf0=";
    })
    (pkgs.fetchurl {
      url = "${maven}/org/ow2/asm/asm-util/9.11/asm-util-9.11.jar";
      hash = "sha256-1aI6Z38xuKfSQZiVkG4fy9msmVvv+yCUTIYQwbw3dgk=";
    })
    (pkgs.fetchurl {
      url = "${maven}/net/fabricmc/sponge-mixin/0.17.5+mixin.0.8.7/sponge-mixin-0.17.5+mixin.0.8.7.jar";
      hash = "sha256-A/AGUCO/wwRdcb+5mHJFHZrVoIAKWg2sNKuMfVwTT10=";
    })
    (pkgs.fetchurl {
      url = "${maven}/net/fabricmc/fabric-loader/0.20.0/fabric-loader-0.20.0.jar";
      hash = "sha256-kRrWCfb68wlAH65PXIog5mXBG0ddZr78Qd016m9B4V4=";
    })
  ];

  intermediary = pkgs.fetchurl {
    url = "${maven}/net/fabricmc/intermediary/26.3/intermediary-26.3.jar";
    hash = "sha256-LgDFJ/HLesmWpZqSzLRpeNKfs9oEqj1LUhycc37jy3Q=";
  };

  fabricApi = pkgs.fetchurl {
    url = "${maven}/net/fabricmc/fabric-api/fabric-api/0.163.0%2B26.3/fabric-api-0.163.0+26.3.jar";
    hash = "sha256-SWn1GX6+2vaBzJE+QljIvRfMuYAp21KinptI6Zgmei0=";
  };
  numenFabric = pkgs.fetchurl {
    url = "https://github.com/CuSO4Deposit/minecraft-numen/releases/download/v0.1.4.2-26.3/numen-fabric-26.3-0.1.4.2.jar";
    hash = "sha256-79WltsjgST2/uiN27vMd/BnRT87/djsS3lEKI3k/MgA=";
  };
  easyAuth = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/aZj58GfX/versions/Qd0CWVQP/easyauth-mc26.3-3.4.4.jar";
    hash = "sha256-QAMJ5UdVXc2t292SW/EG28P5S09njMV10w48mbZSHuQ=";
  };
  skinsRestorer = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/TsLS8Py5/versions/XuyP5rdG/SkinsRestorer-Mod-Fabric-15.12.6.jar";
    hash = "sha256-YALQQnotVNRofiRSv1+eiCKJjXS+KEaitEmFz9Xbhlk=";
  };

  mods = pkgs.runCommand "minecraft-fabric-mods" { } ''
    mkdir -p $out
    ln -s ${fabricApi} $out/fabric-api-0.163.0+26.3.jar
    ln -s ${numenFabric} $out/numen-fabric-26.3-0.1.4.2.jar
    ln -s ${easyAuth} $out/easyauth-mc26.3-3.4.4.jar
    ln -s ${skinsRestorer} $out/SkinsRestorer-Mod-Fabric-15.12.6.jar
  '';

  vanillaUnbundled =
    pkgs.runCommand "minecraft-26.3-unbundled"
      {
        nativeBuildInputs = [ pkgs.unzip ];
      }
      ''
        mkdir -p $out
        unzip -q -o ${vanillaServer} 'META-INF/libraries/*' -d $out
        mv $out/META-INF/libraries $out/libraries
        unzip -q -o ${vanillaServer} 'META-INF/versions/26.3/server-26.3.jar' -d $out
        mv $out/META-INF/versions/26.3/server-26.3.jar $out/server.jar
        rm -rf $out/META-INF
      '';

  classpathFile = pkgs.runCommand "minecraft-fabric-classpath" { } ''
    printf '%s' "${
      pkgs.lib.concatStringsSep ":" (map toString (fabricLoaderLibs ++ [ intermediary ]))
    }" > $out
    printf ':%s' "${vanillaUnbundled}/server.jar" >> $out
    find ${vanillaUnbundled}/libraries -type f -name '*.jar' | sort | while read -r jar; do
      printf ':%s' "$jar"
    done >> $out
  '';

  server = pkgs.writeShellScriptBin "minecraft-fabric-server" ''
    export LD_LIBRARY_PATH=${
      pkgs.lib.makeLibraryPath [ pkgs.udev ]
    }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    exec ${pkgs.jdk25}/bin/java \
      -Xmx2048M -Xms2048M \
      -Dfabric.gameJarPath.server=${vanillaUnbundled}/server.jar \
      -cp "$(cat ${classpathFile})" \
      net.fabricmc.loader.impl.launch.knot.KnotServer nogui "$@"
  '';
in
{
  inherit mods server;
}
