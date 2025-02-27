{
  description = "Nix deployments";

  inputs = {
    attic.url = "github:zhaofengli/attic";
    colmena.url = "github:zhaofengli/colmena";
    crowdsec = {
      url = "git+https://codeberg.org/kampka/nix-flake-crowdsec.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    splitfree = {
      url = "github:albinvass/splitfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
    steam-fetcher = {
      url = "github:aidalgol/nix-steam-fetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    matrix-synapse = {
      url = "github:element-hq/synapse";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      formatter.x86_64-linux = pkgs.nixfmt-rfc-style;
      colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
      colmena = {
        meta = {
          nixpkgs = pkgs;
          nodeNixpkgs =
            let
              pkgs-arm = import nixpkgs {
                system = "aarch64-linux";
                config.allowUnfree = true;
              };
            in
            {
              devbox-arm = pkgs-arm;
              nixpi = pkgs-arm;
              reverse-proxy = pkgs-arm;
            };
          nodeSpecialArgs = {
            steam-servers = {
              inherit inputs;
            };
            nixpi = {
              inherit inputs;
            };
            nixos-1 = {
              inherit inputs;
            };
            reverse-proxy = {
              inherit inputs;
            };
          };
        };

        nixos-1 =
          { name, nodes, ... }:
          {
            networking.hostName = name;
            deployment = {
              targetHost = "nixos-1.dev.albinvass.se";
              targetUser = "root";
              tags = [
                "enabled"
                ''
                  pulumi:{
                                    "Server": {
                                      "Enabled": true,
                                      "ServerType": "cpx21"
                                    },
                                    "Volume": {
                                      "Size": 20
                                    }
                                  }''
              ];
              keys = {
                "ssh_host_ed25519_key" = {
                  destDir = "/etc/ssh";
                  keyCommand = [
                    "get-host-key"
                    name
                    "ssh_host_ed25519_key"
                  ];
                  user = "root";
                  group = "root";
                  permissions = "0600";
                };
                "ssh_host_ed25519_key.pub" = {
                  destDir = "/etc/ssh";
                  keyCommand = [
                    "get-host-key"
                    name
                    "ssh_host_ed25519_key.pub"
                  ];
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

        reverse-proxy =
          { name, nodes, ... }:
          {
            networking.hostName = name;
            deployment = {
              targetHost = "reverse-proxy.albinvass.se";
              targetUser = "root";
              tags = [
                "enabled"
                ''
                  pulumi:{
                                    "Server": {
                                      "Enabled": true,
                                      "ServerType": "cax11"
                                    }
                                  }''
              ];
              keys = {
                "ssh_host_ed25519_key" = {
                  destDir = "/etc/ssh";
                  keyCommand = [
                    "get-host-key"
                    name
                    "ssh_host_ed25519_key"
                  ];
                  user = "root";
                  group = "root";
                  permissions = "0600";
                };
                "ssh_host_ed25519_key.pub" = {
                  destDir = "/etc/ssh";
                  keyCommand = [
                    "get-host-key"
                    name
                    "ssh_host_ed25519_key.pub"
                  ];
                  user = "root";
                  group = "root";
                  permissions = "0644";
                };
              };
            };

            imports = [
              inputs.disko.nixosModules.disko
              inputs.sops-nix.nixosModules.sops
              ./nixos/hosts/reverse-proxy
            ];
          };

        nixpi =
          { name, nodes, ... }:
          {
            networking.hostName = name;
            deployment = {
              targetHost = "${name}-ssh.albinvass.se";
              targetUser = "avass";
              tags = [ "enabled" ];
              keys = {
                "ssh_host_ed25519_key" = {
                  destDir = "/etc/ssh";
                  keyCommand = [
                    "get-host-key"
                    name
                    "ssh_host_ed25519_key"
                  ];
                  user = "root";
                  group = "root";
                  permissions = "0600";
                };
                "ssh_host_ed25519_key.pub" = {
                  destDir = "/etc/ssh";
                  keyCommand = [
                    "get-host-key"
                    name
                    "ssh_host_ed25519_key.pub"
                  ];
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
      };

      nixosConfigurations = {
        reverse-proxy = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            inputs.disko.nixosModules.disko
            ./nixos/modules/base
            ./nixos/hosts/reverse-proxy/disk-config
          ];
        };
        devbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            inputs.disko.nixosModules.disko
            ./nixos/modules/base
            ./nixos/modules/disk-config
          ];
        };
        nixos-base-arm64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            inputs.disko.nixosModules.disko
            ./nixos/modules/base
            ./nixos/modules/disk-config
          ];
        };
      };
    };
}
