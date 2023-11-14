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

  outputs = { self, nixpkgs, flake-utils, ... }@inputs: {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };

      devbox = {name, nodes, ...}: {
        networking.hostName = name;
        services = {
          postgresql.enabled = false;
          keycloak.enabled = false;
        };
        deployment = {
          buildOnTarget = true;
          targetHost = "65.108.153.140";
          targetPort = 22;
          targetUser = "root";
        };
        imports = [
          inputs.disko.nixosModules.disko
          ./nixos/hosts/devbox
        ];
      };
    };
    nixosConfigurations.nixos-1 = nixpkgs.lib.nixosSystem {
      system="x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        ./nixos/modules/base
      ];
    };

  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      devShells = {
        default =  pkgs.callPackage ./nix/devshell.nix {};
      };
    }
  );
}
