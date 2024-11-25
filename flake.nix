{
  description = "A NixOS Configuration Flake Wrapper";  

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, nixvim }@inputs: {
    nixosConfigurations.nightcord-lexikos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        nixos-wsl.nixosModules.wsl
        nixvim.nixosModules.nixvim
      ];
    };
  };
}
