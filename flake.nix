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
    signoz-src = {
      flake = false;
      url = "github:SigNoz/signoz/refs/tags/v0.34.0";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    signoz = pkgs.callPackage ./nix/signoz { inherit inputs; };
  in rec {
    colmena = {
      meta = {
        nixpkgs = pkgs;
      };

      devbox = {name, nodes, ...}: {
        networking.hostName = name;
        deployment = {
          buildOnTarget = true;
          targetHost = "65.108.153.140";
          targetPort = 22;
          targetUser = "root";
        };
        imports = [
          inputs.disko.nixosModules.disko
          ./nixos/hosts/devbox
          self.nixosModules.signoz-frontend
        ];
      };
    };
    nixosModules = signoz.nixosModules;
    nixosConfigurations.nixos-1 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        inputs.disko.nixosModules.disko
        ./nixos/modules/base
      ];
    };
    devShells.${system} = {
      default =  pkgs.callPackage ./nix/devshell.nix {};
    };
    packages.${system} = signoz.packages;
  };
}
