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
  let 
    hetznerBaseModules = [
      inputs.disko.nixosModules.disko
      ./nixos/modules/hetzner-base/configuration.nix
    ];
  in {
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };

      devbox = {name, nodes, ...}: {
        networking.hostName = name;
        deployment = {
          buildOnTarget = true;
          targetHost = "65.108.153.140";
          targetPort = 22;
          targetUser = "root";
        };
        imports = hetznerBaseModules ++ [ ./nixos/hosts/devbox ];
      };
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
      nixosConfigurations.hetzner-cloud = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = hetznerBaseModules;
      };
    }
  );
}
