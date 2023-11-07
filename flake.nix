{
  description = "Nix deployments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    hetznerBaseModules = [
      inputs.disko.nixosModules.disko
      ./hetzner/configuration.nix
    ];
  in rec {
    devShell.x86_64-linux = pkgs.mkShell {
      LC_ALL="C.UTF-8";
      buildInputs = [
        pkgs.colmena
      ];
    };
    colmena = {
      meta = {
        nixpkgs = pkgs;
      };

      devbox = {name, nodes, ...}@hetzner-inputs: with hetzner-inputs; {
        imports = hetznerBaseModules;
        deployment = {
          buildOnTarget = true;
          targetHost = "65.109.130.106";
          targetPort = 22;
          targetUser = "root";
        };

        networking.hostName = name;
      };
    };
    nixosConfigurations.hetzner-cloud = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = hetznerBaseModules;
    };
  };
}
