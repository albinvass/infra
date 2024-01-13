{
  description = "Nix deployments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
        };
        nodeSpecialArgs = {
          steam-servers = with inputs; { inherit steam-fetcher; };
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
          ./nixos/hosts/devbox
        ];
      };

      #devbox-arm = {name, nodes, ...}: {
      #  networking.hostName = name;
      #  deployment = {
      #    targetHost = "devbox-arm.dev.albinvass.se";
      #    targetUser = "root";
      #    tags = [
      #      "pulumi:vm:server_type:cax21"
      #    ];
      #    keys = {
      #      "ssh_host_ed25519_key" = {
      #        destDir = "/etc/ssh";
      #        keyCommand = ["get-host-key" name "ssh_host_ed25519_key"];
      #        user = "root";
      #        group = "root";
      #        permissions = "0600";
      #      };
      #      "ssh_host_ed25519_key.pub" = {
      #        destDir = "/etc/ssh";
      #        keyCommand = ["get-host-key" name "ssh_host_ed25519_key.pub"];
      #        user = "root";
      #        group = "root";
      #        permissions = "0644";
      #      };
      #    };
      #  };

      #  imports = [
      #    inputs.disko.nixosModules.disko
      #    inputs.sops-nix.nixosModules.sops
      #    ./nixos/hosts/devbox-arm
      #  ];
      #};

      steam-servers = {name, nodes, ...}: {
        networking.hostName = name;
        deployment = {
          targetHost = "steam-servers.dev.albinvass.se";
          targetUser = "avass";
          tags = [
            "pulumi:vm:server_type:cpx21"
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
          ./nixos/hosts/steam-servers
        ];
      };
    };

    nixosConfigurations.nixos-base-x86_64 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        ./nixos/modules/base
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
