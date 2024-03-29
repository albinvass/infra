{ pkgs }:
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
in with pkgs; mkShell {
  LC_ALL="C.UTF-8";
  shellHook = ''
    GIT_ROOT="$(git rev-parse --show-toplevel)"
    set -o allexport
    eval $(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")
    set +o allexport
  '';
  # Fix for pulumi
  LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.stdenv.cc.cc ];
  buildInputs = [
    bashInteractive
    colmena
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
  ];
}
