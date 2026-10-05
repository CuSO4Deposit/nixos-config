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
    nixpkgs-logseq-electron-39.url = "github:NixOS/nixpkgs/a2c09b4c8254bf88503c9e475c92a4b46eb5e047";
    # Pin Zotero to a nixpkgs revision whose Firefox ESR is 140, which Zotero
    # 10.x strictly requires. Newer nixpkgs bumped firefox-esr to 153 and the
    # package fails to build. See NixOS/nixpkgs#568692 and the fix PR #569006.
    nixpkgs-zotero.url = "github:NixOS/nixpkgs/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-opencode.url = "github:NixOS/nixpkgs/229c5ce718318ff369cae88074fab7aed7a69bca";
    nixpkgs-wemeet-system-132.url = "github:NixOS/nixpkgs/b40629efe5d6ec48dd1efba650c797ddbd39ace0";
    # nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-cuso4d = {
      url = "github:CuSO4Deposit/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    api-laborari = {
      url = "github:CuSO4Deposit/ideal-spork";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    observable-cuso4d = {
      url = "github:CuSO4Deposit/fantastic-disco";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vita-grid = {
      url = "github:CuSO4Deposit/vita-grid";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    inputs@{
      flake-parts,
      nix-ld,
      nix-darwin,
      nur-cuso4d,
      ...
    }:
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
              nixfmt.enable = true;
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
              # nixos-wsl
              nur
              ;

            mkServer =
              hostname:
              nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [
                  ./modules/linux/base.nix
                  ./hosts/${hostname}
                  agenix.nixosModules.default
                  inputs.vita-grid.nixosModules.vitaGrid
                  nix-ld.nixosModules.nix-ld
                  nur-cuso4d.nixosModules.ghorg
                ];
              };

            mkWSL =
              hostname:
              nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [
                  ./modules/linux/base.nix
                  ./hosts/${hostname}
                  agenix.nixosModules.default
                  # nixos-wsl.nixosModules.wsl
                  nix-ld.nixosModules.nix-ld
                  { environment.systemPackages = [ agenix.packages."x86_64-linux".default ]; }
                ];
              };

            mkDesktop =
              hostname:
              nixpkgs.lib.nixosSystem {
                specialArgs = {
                  inherit inputs;
                };
                modules = [
                  ./modules/linux/base.nix
                  ./hosts/${hostname}
                  agenix.nixosModules.default
                  inputs.api-laborari.nixosModules.default
                  inputs.vita-grid.nixosModules.vitaGrid
                  nix-ld.nixosModules.nix-ld
                  nur.modules.nixos.default
                  home-manager.nixosModules.home-manager
                  {
                    environment.systemPackages = [ agenix.packages."x86_64-linux".default ];
                    home-manager.backupFileExtension = "backup";
                    home-manager.overwriteBackup = true;
                    home-manager.extraSpecialArgs.agenix = agenix;
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.cuso4d = import ./home/linux;
                    nixpkgs.config.allowUnfree = true;
                  }
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

        darwinConfigurations."nightcord-neo" = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/neo
            inputs.agenix.darwinModules.default
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager.backupFileExtension = "backup";
              home-manager.overwriteBackup = true;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.cuso4d = import ./home/darwin;
            }
          ];
        };

        homeConfigurations."CuSO4D@racknerd" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit inputs; };
          modules = [
            inputs.agenix.homeManagerModules.default
            ./hosts/racknerd/home.nix
          ];
        };
      };
    };
}
