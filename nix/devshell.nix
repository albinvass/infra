{ pkgs }:
let
  start-ssh-agent = pkgs.writeScriptBin "start-ssh-agent" ''
    eval `ssh-agent | sed '/^echo.*/d'`
    ssh-add <(bws-get hcloud-ssh-key)
    echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    echo "export SSH_AGENT_PID=$SSH_AGENT_PID"
  '';
  kill-ssh-agent = pkgs.writeScriptBin "kill-ssh-agent" ''
    ssh-agent -k
  '';
  bws = pkgs.rustPlatform.buildRustPackage rec {
    pname = "bws";
    version = "0.3.1";

    cargoBuildFlags = ["--package=bws"];
    src = pkgs.fetchFromGitHub {
      owner = "bitwarden";
      repo = "sdk";
      rev = "bws-v${version}";
      hash = "sha256-71MbpnGBkLMa2DaXERq5af8cQ0+RILsPTm3M6mzcv2U=";
    };
    # See: https://artemis.sh/2023/07/08/nix-rust-project-with-git-dependencies.html
    cargoLock = {
      lockFile = "${src}/Cargo.lock";
      outputHashes = {
        "uniffi-0.24.1"= "sha256-m+8A1jkp6xXdRlWFFpz8cMEwHkmImM46SV8Ch1unzNE=";
      };
    };
    nativeBuildInputs = [
      pkgs.perl
      pkgs.python3
    ];

    meta = {
      description = "Bitwarden Secrets Manager SDK";
      homepage = "https://github.com/bitwarden/sdk";
    };
  };
  bws-get = pkgs.stdenv.mkDerivation {
    name = "bws-get";
    dontUnpack = true;
    installPhase = "install -Dm755 ${../tools/bws-get.py} $out/bin/bws-get";
    propagatedBuildInputs = [ bws ];
  };
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
    set -o allexport
    eval $(sops --output-type dotenv --extract '["env"]' -d secrets.yaml)
    set +o allexport
  '';

  buildInputs = [
    bashInteractive
    colmena
    jq
    openssh
    terraform
    terragrunt
    (pulumi.withPackages (ps: with ps; [pulumi-language-python]))
    bws-get
    hcloud
    nixos-init
    statix
    start-ssh-agent
    kill-ssh-agent
  ];
}
