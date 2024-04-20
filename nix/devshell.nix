{ pkgs, colmena-flake }:
let
  get-host-key = pkgs.writeScriptBin "get-host-key" /* bash */ ''
    #!/bin/env bash
    host="$1"
    key="$2"
    GIT_ROOT="$(git rev-parse --show-toplevel)"
    sops --extract "['hosts'][\"$host\"]['hostkey'][\"$key\"]" -d "$GIT_ROOT/secrets.yaml"
  '';
  start-ssh-agent = pkgs.writeScriptBin "start-ssh-agent" /* bash */ ''
    #!/bin/env bash
    eval `ssh-agent | sed '/^echo.*/d'`
    GIT_ROOT="$(git rev-parse --show-toplevel)"
    ssh-add <(sops --extract '["hetzner"]["ssh"]["id_ed25519"]' -d "$GIT_ROOT/secrets.yaml")
    echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    echo "export SSH_AGENT_PID=$SSH_AGENT_PID"
  '';
  kill-ssh-agent = pkgs.writeScriptBin "kill-ssh-agent" /* bash */ ''
    #!/bin/env bash
    ssh-agent -k
  '';
  nixos-init = pkgs.writeScriptBin "nixos-init" /* bash */ ''
    #!/bin/env bash
    trap kill-ssh-agent EXIT
    eval `start-ssh-agent`

    GIT_ROOT=$(git rev-parse --show-toplevel)
    nix run github:numtide/nixos-anywhere -- --flake ''${GIT_ROOT}#''${1} "root@$(pulumi stack output --cwd ''$GIT_ROOT/pulumi --stack albinvass/Hetzner/infra "''${1}-ip")"
  '';
  deploy-pulumi = pkgs.writeScriptBin "deploy-pulumi" /* bash */ ''
    #!/bin/env bash

    GIT_ROOT="$(git rev-parse --show-toplevel)"

    set -o allexport
    eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
    set +o allexport

    LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.stdenv.cc.cc ];
    export LD_LIBRARY_PATH
    pulumi up --cwd "$GIT_ROOT/pulumi" --stack albinvass/infra/infra "$@"
  '';
  deploy-colmena = pkgs.writeScriptBin "deploy-colmena" /* bash */ ''
    #!/usr/bin/env bash
    set -euo pipefail
    GIT_ROOT="$(git rev-parse --show-toplevel)"

    SSH_CONFIG_FILE="$GIT_ROOT/ssh/config"
    export SSH_CONFIG_FILE

    set -o allexport
    eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
    set +o allexport

    trap kill-ssh-agent EXIT
    eval "$(start-ssh-agent)"
    colmena "$@"
  '';
in with pkgs; mkShell {
  LC_ALL="C.UTF-8";
  buildInputs = [
    bashInteractive
    colmena-flake.packages.${pkgs.system}.colmena
    openssh
    terraform
    terragrunt
    (pulumi.withPackages (ps: with ps; [pulumi-language-python]))
    hcloud
    nixos-init
    statix
    start-ssh-agent
    kill-ssh-agent
    get-host-key
    deploy-pulumi
    deploy-colmena
    cloudflared
    sops
  ];
}
