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
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-claude-code-2-1-86.url = "github:NixOS/nixpkgs/8110df5ad7abf5d4c0f6fb0f8f978390e77f9685";
    nixpkgs-logseq-electron-39.url = "github:NixOS/nixpkgs/a2c09b4c8254bf88503c9e475c92a4b46eb5e047";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-before-node-breaks.url = "github:NixOS/nixpkgs/ce01d34b50dcbe7cd14286398b5fa9ec36ad6489";
    nixpkgs-nvidia-x11-580-95.url = "github:NixOS/nixpkgs/3652b3eb77483e02b018bbb8423a0523606f1291";
    nixpkgs-wemeet-system-132.url = "github:NixOS/nixpkgs/b40629efe5d6ec48dd1efba650c797ddbd39ace0";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-ld = {
      url = "github:Mic92/nix-ld";
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
                  nix-ld.nixosModules.nix-ld
                  nur-cuso4d.nixosModules.ghorg
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
                  nix-ld.nixosModules.nix-ld
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
                    home-manager.users.cuso4d = import ./home;
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
      };
    };
}
