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
  in {
    devShell.x86_64-linux =  with pkgs; mkShell {
      LC_ALL="C.UTF-8";
      shellHook = ''
        if ! bw login --check > /dev/null 2>&1; then
          echo "Please login to bitwarden"
          export BW_SESSION=$(bw login --raw)
        elif [ -z "$BW_SESSION" ]; then
          echo "Please unlock the bitwarden vault"
          export BW_SESSION=$(bw unlock --raw)
        fi

        if [ -z "$BW_SESSION" ]; then
          echo "Unable to get bitwarden session token."
          exit 1
        fi
      '';
        
      buildInputs = [
        colmena
        bitwarden-cli
        jq
      ];
    };
    colmena = {
      meta = {
        nixpkgs = pkgs;
      };

      devbox = {name, nodes, ...}@hetzner-inputs: with hetzner-inputs; {
        imports = hetznerBaseModules ++ [./nixos/hosts/devbox];
        deployment = {
          buildOnTarget = true;
          targetHost = "65.109.130.106";
          targetPort = 22;
          targetUser = "root";
          keys = {
            "cloudflared-credentials" = {
              keyCommand = [
                "bash" "-c" ''bw list items | jq '.[] | select(.name=="dash.cloudflare.com").fields[] | select(.name=="devbox tunnel").value' | tr -d \"''
              ];
              destDir = "/etc/cloudflared";
              user = "cloudflared";
              group = "cloudflared";
              permissions = "0600";
            };
          };
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
