{
  description = "Nix deployments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
  in rec {
    devShell = pkgs.mkShell {
      LC_ALL="C.UTF-8";
      buildInputs = with pkgs; [
        colmena
      ];
    };
    colmena = {
      meta = {
        nixpkgs = pkgs;
      };

      hetzner-nixos = {
        deployment = {
          targetHost = "";
          targetPort = 22;
          targetUser = "root";
        };
      };
    };
    nixosConfigurations.hetzner-cloud = pkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        ./hetzner/configuration.nix
      ];
    };
  };
}
