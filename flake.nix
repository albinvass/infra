{
  description = "Nix deployments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, ... }@inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    colmena = {
      meta = {
        nixpkgs = pkgs;
      };

      devbox = {name, nodes, ...}: {
        networking.hostName = name;
        deployment = {
          targetHost = "65.108.153.140";
          targetPort = 22;
          targetUser = "root";
        };
        imports = [
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          ./nixos/hosts/devbox
        ];
      };
    };
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
  };
}
