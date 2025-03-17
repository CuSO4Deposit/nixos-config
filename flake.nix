{
  description = "A NixOS Configuration Flake Wrapper";  

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    cus-nixvim = {
      url = "git+https://codeberg.org/cocvu/cus-nixvim?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, cus-nixvim }@inputs: {
    nixosConfigurations = {

      nightcord-lexikos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hosts/lexikos.nix
          nixos-wsl.nixosModules.wsl
        ];
      };

      nightcord-laborari = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hosts/laborari.nix
          nixos-wsl.nixosModules.wsl
        ];
      };

      nightcord-proximo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hosts/proximo.nix
          nixos-wsl.nixosModules.wsl
        ];
      };

    };
  };
}
