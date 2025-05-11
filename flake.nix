{
  description = "A NixOS Configuration Flake Wrapper";  

  inputs = {
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
    cus-nixvim = {
      url = "git+https://codeberg.org/cocvu/cus-nixvim?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, home-manager, nixpkgs, nixos-wsl, nur, cus-nixvim }@inputs: {
    nixosConfigurations = let
        wslConfig = hostname: nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./configuration.nix
            ./hosts/${hostname}.nix
            nixos-wsl.nixosModules.wsl
          ];
        };
        wslHostnames = [ "laborari" "lexikos" "proximo" ];
      in {

      nightcord-dynamica = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hosts/dynamica.nix
          nur.modules.nixos.default # This adds the NUR overlay
          home-manager.nixosModules.home-manager {
            home-manager.backupFileExtension = "backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.cuso4d = import ./home.nix;
          }
        ];
      };
    }  // builtins.listToAttrs (map (name: {
            name = "nightcord-${name}";
            value = wslConfig name;
          }) wslHostnames);
  };
}
