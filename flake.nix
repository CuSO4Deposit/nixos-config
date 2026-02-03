{
  description = "A NixOS Configuration Flake Wrapper";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cus-nixvim = {
      url = "git+https://codeberg.org/cocvu/cus-nixvim?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-before-node-breaks.url = "github:NixOS/nixpkgs/ce01d34b50dcbe7cd14286398b5fa9ec36ad6489";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-nvidia-x11-580-95.url = "github:NixOS/nixpkgs/3652b3eb77483e02b018bbb8423a0523606f1291";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        inputs.git-hooks-nix.flakeModule
      ];
      perSystem =
        {
          pkgs,
          config,
          ...
        }:
        {
          pre-commit.settings = {
            src = ./.;
            hooks = {
              markdownlint.enable = true;
              nixfmt-rfc-style.enable = true;
              deadnix.enable = true;
            };
          };

          devShells.default = pkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.shellHook}
            '';
            packages = config.pre-commit.settings.enabledPackages;
          };
        };

      flake = {
        nixosConfigurations =
          let
            inherit (inputs)
              agenix
              home-manager
              nixpkgs
              nixpkgs-nvidia-x11-580-95
              nixos-wsl
              nur
              ;

            pkgs-nvidia-x11-580-95 = import nixpkgs-nvidia-x11-580-95 {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
            mkServer =
              hostname:
              nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [
                  ./configuration.nix
                  ./hosts/${hostname}.nix
                  agenix.nixosModules.default
                ];
              };

            mkWSL =
              hostname:
              nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [
                  ./configuration.nix
                  ./hosts/${hostname}.nix
                  agenix.nixosModules.default
                  nixos-wsl.nixosModules.wsl
                  { environment.systemPackages = [ agenix.packages."x86_64-linux".default ]; }
                ];
              };

            mkDesktop =
              hostname:
              nixpkgs.lib.nixosSystem {
                specialArgs = {
                  inherit inputs;
                  pkgs-nvidia-x11-580-95 = pkgs-nvidia-x11-580-95;
                };
                modules = [
                  ./configuration.nix
                  ./hosts/${hostname}.nix
                  agenix.nixosModules.default
                  nur.modules.nixos.default
                  home-manager.nixosModules.home-manager
                  {
                    environment.systemPackages = [ agenix.packages."x86_64-linux".default ];
                    home-manager.backupFileExtension = "backup";
                    home-manager.extraSpecialArgs.agenix = agenix;
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.cuso4d = import ./home;
                    nixpkgs.config.allowUnfree = true;
                  }
                  (
                    { pkgs, ... }:
                    {
                      nixpkgs.overlays = [
                        (_: _: {
                          terraria-server =
                            (import inputs.nixpkgs-master {
                              system = pkgs.stdenv.hostPlatform.system;
                              config.allowUnfree = true;
                            }).terraria-server;
                        })
                      ];
                    }
                  )
                ];
              };

            serverHostnames = [ "proximo" ];
            wslHostnames = [ ];
            desktopHostnames = [
              "dynamica"
              "laborari"
              "lexikos"
            ];

          in
          builtins.listToAttrs (
            (map (name: {
              name = "nightcord-${name}";
              value = mkServer name;
            }) serverHostnames)
            ++ (map (name: {
              name = "nightcord-${name}";
              value = mkWSL name;
            }) wslHostnames)
            ++ (map (name: {
              name = "nightcord-${name}";
              value = mkDesktop name;
            }) desktopHostnames)
          );
      };
    };
}
