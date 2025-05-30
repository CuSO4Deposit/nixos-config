{
  description = "A NixOS Configuration Flake Wrapper";

  inputs = {
    cus-nixvim = {
      url = "git+https://codeberg.org/cocvu/cus-nixvim?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    {
      self,
      home-manager,
      nixpkgs,
      nixos-wsl,
      nur,
      ...
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = nixpkgs.legacyPackages.${system};
      system = "x86_64-linux";
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      checks = forAllSystems (system: {
        inherit inputs;
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            markdownlint.enable = true;
            nixfmt-rfc-style.enable = true;
          };
        };
      });

      devShells = forAllSystems (system: {
        default = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });

      nixosConfigurations =
        let
          wslConfig =
            hostname:
            nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = {
                inherit inputs;
              };
              modules = [
                ./configuration.nix
                ./hosts/${hostname}.nix
                nixos-wsl.nixosModules.wsl
              ];
            };
          wslHostnames = [
            "laborari"
            "lexikos"
            "proximo"
          ];
        in
        {

          nightcord-dynamica = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
            };
            modules = [
              ./configuration.nix
              ./hosts/dynamica.nix
              nur.modules.nixos.default # This adds the NUR overlay
              home-manager.nixosModules.home-manager
              {
                home-manager.backupFileExtension = "backup";
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.cuso4d = import ./home;
              }
            ];
          };
        }
        // builtins.listToAttrs (
          map (name: {
            name = "nightcord-${name}";
            value = wslConfig name;
          }) wslHostnames
        );
    };
}
