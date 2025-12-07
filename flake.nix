{
  description = "A NixOS Configuration Flake Wrapper";

  inputs = {
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
    nixpkgs-nvidia-x11-580-95.url = "github:NixOS/nixpkgs/3652b3eb77483e02b018bbb8423a0523606f1291";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks.url = "github:cachix/git-hooks.nix/50b9238891e388c9fdc6a5c49e49c42533a1b5ce";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    {
      self,
      agenix,
      home-manager,
      nixpkgs,
      nixpkgs-nvidia-x11-580-95,
      nixos-wsl,
      nur,
      ...
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-nvidia-x11-580-95 = import nixpkgs-nvidia-x11-580-95 {
        system = "${system}";
        config.allowUnfree = true;
      };
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
          serverConfig =
            hostname:
            nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = {
                inherit inputs;
              };
              modules = [
                ./configuration.nix
                ./hosts/${hostname}.nix
                agenix.nixosModules.default
              ];
            };
          serverHostnames = [
            "proximo"
          ];
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
                agenix.nixosModules.default
                nixos-wsl.nixosModules.wsl
                {
                  environment.systemPackages = [ agenix.packages.${system}.default ];
                }
              ];
            };
          wslHostnames = [ ];
          desktopConfig =
            hostname:
            nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = {
                inherit inputs;
                pkgs-nvidia-x11-580-95 = pkgs-nvidia-x11-580-95;
              };
              modules = [
                ./configuration.nix
                ./hosts/${hostname}.nix
                agenix.nixosModules.default
                nur.modules.nixos.default # This adds the NUR overlay
                home-manager.nixosModules.home-manager
                {
                  environment.systemPackages = [ agenix.packages.${system}.default ];
                  home-manager.backupFileExtension = "backup";
                  # https://github.com/ryantm/agenix/issues/305#issuecomment-2603003925
                  home-manager.extraSpecialArgs.agenix = agenix;
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.cuso4d = import ./home;
                  nixpkgs.config.allowUnfree = true;
                }
              ];
            };
          desktopHostnames = [
            "dynamica"
            "laborari"
            "lexikos"
          ];
        in
        builtins.listToAttrs (
          map (name: {
            name = "nightcord-${name}";
            value = serverConfig name;
          }) serverHostnames
        )
        // builtins.listToAttrs (
          map (name: {
            name = "nightcord-${name}";
            value = wslConfig name;
          }) wslHostnames
        )
        // builtins.listToAttrs (
          map (name: {
            name = "nightcord-${name}";
            value = desktopConfig name;
          }) desktopHostnames
        );
    };
}
