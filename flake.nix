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
          targetUser = "root";
          keys = {
            "ssh_host_ed25519_key" = {
              destDir = "/etc/ssh";
              keyCommand = ["get-host-key" name "ssh_host_ed25519_key"];
              user = "root";
              group = "root";
              permissions = "0600";
            };
            "ssh_host_ed25519_key.pub" = {
              destDir = "/etc/ssh";
              keyCommand = ["get-host-key" name "ssh_host_ed25519_key.pub"];
              user = "root";
              group = "root";
              permissions = "0644";
            };
          };
        };

        imports = [
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          ./nixos/hosts/devbox
        ];
      };

      steam-servers = {name, nodes, ...}: {
        networking.hostName = name;
        deployment = {
          targetHost = "135.181.250.128";
          targetUser = "avass";
          keys = {
            "ssh_host_ed25519_key" = {
              destDir = "/etc/ssh";
              keyCommand = ["get-host-key" name "ssh_host_ed25519_key"];
              user = "root";
              group = "root";
              permissions = "0600";
            };
            "ssh_host_ed25519_key.pub" = {
              destDir = "/etc/ssh";
              keyCommand = ["get-host-key" name "ssh_host_ed25519_key.pub"];
              user = "root";
              group = "root";
              permissions = "0644";
            };
          };
        };
        imports = [
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          ./nixos/hosts/steam-servers
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
    nixosConfigurations.steam-servers = nixpkgs.lib.nixosSystem {
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
