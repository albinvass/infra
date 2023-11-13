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
      ./nixos/hetzner/configuration.nix
    ];
    pkgs = import nixpkgs {system = "x86_64-linux";};
  in {
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
        imports = hetznerBaseModules ++ [ ./nixos/hosts/devbox ];
      };
    };

    nixosConfigurations.hetzner-cloud = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = hetznerBaseModules;
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
