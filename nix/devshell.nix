{ pkgs }:
let
  bws = pkgs.rustPlatform.buildRustPackage rec {
    pname = "bws";
    version = "0.3.1";

    cargoBuildFlags = ["--package=bws"];
    #buildAndTestSubdir = "bws";
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

    meta = with pkgs.lib; {
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
  nixos-anywhere-hetzner = pkgs.writeScriptBin "nixos-anywhere-hetzner"
    ''
    #!/bin/env bash
    nix run github:numtide/nixos-anywhere -- --flake $(git rev-parse --show-toplevel)#hetzner-cloud "root@$@"
    '';
in with pkgs; mkShell {
  LC_ALL="C.UTF-8";
  shellHook = ''
    if [ -z "$BW_SESSION" ]; then
      echo "Unable to get bitwarden session token."
      exit 1
    fi

    export PULUMI_ACCESS_TOKEN=$(bws-get pulumi-access-token)
    export HCLOUD_TOKEN=$(bws-get hcloud-dev-token)
    export CLOUDFLARE_EMAIL=$(bws-get cloudflare-global-key | jq -r '.email')
    export CLOUDFLARE_API_KEY=$(bws-get cloudflare-global-key | jq -r '.key')

    # `nix develop --command` doens't start a new shell so it never
    # triggers the exit trap.
    # Therefore we only start an ssh agent if we're in an interactive shell
    # See: https://serverfault.com/a/146747
    if [[ $- == *i* ]]; then
      trap "ssh-agent -k" EXIT
      eval `ssh-agent`
      ssh-add <(bws-get hcloud-ssh-key)
    fi
  '';

  buildInputs = [
    bashInteractive
    colmena
    jq
    openssh
    terraform
    terragrunt
    pulumi
    pulumiPackages.pulumi-language-python
    bws-get
    hcloud
    nixos-anywhere-hetzner
    statix
  ];
}
