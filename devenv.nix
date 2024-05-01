{ pkgs, inputs, ... }:

{
  devcontainer = {
    enable = true;
  };
  packages = with pkgs; [
    actionlint
    cloudflared
    openssh
    statix
    sops
    (pulumi.withPackages (ps: with ps; [pulumi-language-python]))

    inputs.colmena.packages.${pkgs.system}.colmena
  ];

  scripts = {
    get-enabled-node-configs = {
      exec = /* bash */ ''
        colmena --impure eval -E '{ ... }@inputs: (import ./colmena/expressions.nix inputs).enabledNodeConfigs'
      '';
    };
    get-enabled-nodes = {
      exec = ''
        colmena --impure eval -E '{ ... }@inputs: (import ./colmena/expressions.nix inputs).enabledNodes'
      '';
    };
    get-host-key = {
      description = "Get host key from secrets.yaml";
      exec = /* bash */ ''
        #!/bin/env bash
        host="$1"
        key="$2"
        GIT_ROOT="$(git rev-parse --show-toplevel)"
        sops --extract "['hosts'][\"$host\"]['hostkey'][\"$key\"]" -d "$GIT_ROOT/secrets.yaml"
      '';
    };

    deploy-pulumi = {
      description = "Deploy pulumi conifguration.";
      exec = /* bash */ ''
        #!/bin/env bash
        GIT_ROOT="$(git rev-parse --show-toplevel)"
        set -o allexport
        eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
        set +o allexport

        LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}";
        export LD_LIBRARY_PATH
        pulumi up --cwd "$GIT_ROOT/pulumi" --stack albinvass/infra/infra "$@"
      '';
    };

    deploy-colmena = {
      description = "Deploy colmena conifguration.";
      exec = /* bash */ ''
        #!/usr/bin/env bash
        set -euo pipefail
        GIT_ROOT="$(git rev-parse --show-toplevel)"

        set -o allexport
        eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
        set +o allexport

        SSH_CONFIG_FILE="$GIT_ROOT/ssh/config"
        export SSH_CONFIG_FILE
        trap 'ssh-agent -k' EXIT
        eval "$(ssh-agent | sed '/^echo.*/d')"
        ssh-add <(sops --extract '["hetzner"]["ssh"]["id_ed25519"]' -d "$GIT_ROOT/secrets.yaml")

        colmena "$@"
      '';
    };

    nixos-init = {
      description = "";
      exec = /* bash */ ''
        #!/bin/env bash
        trap kill-ssh-agent EXIT
        eval `start-ssh-agent`

        GIT_ROOT=$(git rev-parse --show-toplevel)
        nix run github:numtide/nixos-anywhere -- --flake ''${GIT_ROOT}#''${1} "root@$(pulumi stack output --cwd ''$GIT_ROOT/pulumi --stack albinvass/Hetzner/infra "''${1}-ip")"
      '';
    };
  };
}
