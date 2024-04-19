{
  description = "Nix deployments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    avass-nixos.url = "github:albinvass/nixos";
    steam-fetcher = {
      url = "github:aidalgol/nix-steam-fetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        nodeNixpkgs = let
          pkgs-arm = import nixpkgs {
            system = "aarch64-linux";
            config.allowUnfree = true;
          };
        in {
          devbox-arm = pkgs-arm;
          nixpi = pkgs-arm;
        };
        nodeSpecialArgs = {
          steam-servers = { inherit inputs; };
        };
      };

      nixos-1 = {name, nodes, ...}: {
        networking.hostName = name;
        deployment = {
          targetHost = "nixos-1.dev.albinvass.se";
          targetUser = "root";
          tags = [
            "pulumi:vm:server_type:cpx21"
            "pulumi:volume:size:20"
          ];
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
          inputs.avass-nixos.nixosModules.devtools
          ./nixos/hosts/devbox
        ];
      };

      nixpi = {name, nodes, ...}: {
        networking.hostName = name;
        deployment = {
          targetHost = "nixpi";
          targetUser = "avass";
          tags = [
            "pulumi:state:enabled:false"
          ];
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
          inputs.sops-nix.nixosModules.sops
          ./nixos/hosts/nixpi
        ];
      };

      steam-servers = {name, nodes, ...}: {
        networking.hostName = name;
        deployment = {
          targetHost = "${name}-ssh.albinvass.se";
          targetUser = "avass";
          tags = [
            "pulumi:state:enabled:false"
            "pulumi:vm:server_type:cx41"
            "pulumi:volume:size:100"
          ];
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
          ./nixos/hosts/steam-servers
        ];
      };
    };

    nixosConfigurations.devbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        ./nixos/modules/base
      ];
    };
    nixosConfigurations.steam-servers = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./nixos/hosts/steam-servers
      ];
    };
    nixosConfigurations.nixos-base-arm64 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
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
