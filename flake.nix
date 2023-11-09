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
      ./nixos/hetzner/configuration.nix
    ];
  in {
    devShell.x86_64-linux =  with pkgs; mkShell {
      LC_ALL="C.UTF-8";
      shellHook = ''
        if ! bw login --check > /dev/null 2>&1; then
          echo "Please login to bitwarden"
          export BW_SESSION=$(bw login --raw)
        elif ! bw unlock --check > /dev/null 2>&1; then
          echo "Please unlock the bitwarden vault"
          export BW_SESSION=$(bw unlock --raw)
        fi

        if [ -z "$BW_SESSION" ]; then
          echo "Unable to get bitwarden session token."
          exit 1
        fi

        # `nix develop --command` doens't start a new shell so it never
        # triggers the exit trap.
        # Therefore we only start an ssh agent if we're in an interactive shell
        # See: https://serverfault.com/a/146747
        if [[ $- == *i* ]]; then
          trap "ssh-agent -k" EXIT
          eval `ssh-agent`
          ssh-add ~/.ssh/id_rsa
        fi
      '';

      buildInputs = [
        bashInteractive
        colmena
        bitwarden-cli
        jq
        openssh
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
            "cloudflared-cert.pem" = {
              name = "cert.pem";
              destDir = "/etc/cloudflared";
              keyCommand = [
                "./tools/bw-get.py" "attachment" "dash.cloudflare.com" "devbox-cert.pem"
              ];
              user = "cloudflared";
              group = "cloudflared";
              permissions = "0600";
            };
            "cloudflared-credentials.json" = {
              name = "credentials.json";
              destDir = "/etc/cloudflared";
              keyCommand = [
                "./tools/bw-get.py" "field" "dash.cloudflare.com" "devbox tunnel"
              ];
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
