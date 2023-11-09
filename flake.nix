{
  description = "Nix deployments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pulumi-hcloud.url = "github:albinvass/nix-pulumi-hcloud";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        system = system;
        config.allowUnfree = true;
      };
      hetznerBaseModules = [
        inputs.disko.nixosModules.disko
        ./nixos/hetzner/configuration.nix
      ];
    in {
      devShells = {
        default =  import ./nix/devshell.nix { inherit pkgs system inputs; };
      };

      colmena = import ./nix/colmena.nix { inherit pkgs; };
      nixosConfigurations.hetzner-cloud = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = hetznerBaseModules;
      };
    }
  );
}
