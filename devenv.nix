{ pkgs, inputs, ... }:
{
  devcontainer = {
    enable = true;
  };
  packages = with pkgs; [
    actionlint
    xc
    cloudflared
    openssh
    statix
    golangci-lint
    sops
    jq
    go
    nix
    (pulumi.withPackages (ps: [ ps.pulumi-language-go ]))

    inputs.colmena.packages.${pkgs.system}.colmena
  ];

  scripts = {
    generate-ca-certificate = {
      exec = # bash
        ''
          #!/usr/bin/env bash

          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"
          CA_ROOT="$GIT_ROOT/certs/ca"
          mkdir -p $CA_ROOT
          cd $CA_ROOT

          openssl req \
            -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -nodes \
            -subj "/CN=root" \
            -keyout ca.key \
            -out ca.crt \
            -days 3650
        '';
    };

    decrypt-ca-certificate = {
      exec = # bash
        ''
          #!/usr/bin/env bash

          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"
          cd "$GIT_ROOT"

          CERTS_ROOT="$GIT_ROOT/certs"
          CA_ROOT="$CERTS_ROOT/ca"

          mkdir -p "$CA_ROOT"
          sops \
            --extract "['ca']['cert']" \
            -d "$GIT_ROOT/secrets.yaml" > "$CA_ROOT/ca.crt"
          sops \
            --extract "['ca']['key']" \
            -d "$GIT_ROOT/secrets.yaml" > "$CA_ROOT/ca.key"
        '';
    };

    generate-host-certificate = {
      exec = # bash
        ''
          #!/usr/bin/env bash

          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"
          cd "$GIT_ROOT"

          #decrypt-ca-certificate

          CERTS_ROOT="$GIT_ROOT/certs"
          CA_ROOT="$CERTS_ROOT/ca"
          mkdir -p $CERTS_ROOT
          cd $CERTS_ROOT

          host="$1"; shift
          HOST_DIR="$CERTS_ROOT/$host"
          mkdir -p "$HOST_DIR"

                  #  -addext "certificatePolicies = 1.2.3.4" \
          echo "Creating private key and signing request"
          openssl req \
            -new \
            -newkey rsa:4096 \
            -subj "/C=SE/CN=$host" \
            -addext "subjectAltName = DNS:$host" \
            -keyout "$HOST_DIR/host.key" \
            -nodes \
            -out "$HOST_DIR/host.csr"

          echo "Creating certificate"
          openssl x509 \
            -req \
            -CA "$CA_ROOT/ca.crt" \
            -CAkey "$CA_ROOT/ca.key" \
            -copy_extensions copy \
            -set_serial "0x$(openssl rand -hex 8)" \
            -in "$HOST_DIR/host.csr" \
            -out "$HOST_DIR/host.crt" \
            -days 367 \
            -sha256
        '';
    };
    colmena-expression = {
      exec = # bash
        ''
          #!/usr/bin/env bash
          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"
          expression="$1"
          colmena --experimental-flake-eval --impure eval -E "{ ... }@inputs: (import $GIT_ROOT/colmena/expressions.nix inputs).$expression"
        '';
    };
    get-enabled-node-configs = {
      exec = # bash
        ''
          #!/usr/bin/env bash
          colmena-expression enabledNodeConfigs
        '';
    };
    get-enabled-nodes = {
      exec = # bash
        ''
          #!/usr/bin/env bash
          colmena-expression enabledNodes
        '';
    };
    get-host-key = {
      description = "Get host key from secrets.yaml";
      exec = # bash
        ''
          #!/usr/bin/env bash
          host="$1"
          key="$2"
          GIT_ROOT="$(git rev-parse --show-toplevel)"
          sops --extract "['hosts'][\"$host\"]['hostkey'][\"$key\"]" -d "$GIT_ROOT/secrets.yaml"
        '';
    };

    deploy-pulumi = {
      description = "Deploy pulumi conifguration.";
      exec = # bash
        ''
          #!/usr/bin/env bash
          GIT_ROOT="$(git rev-parse --show-toplevel)"

          set -o allexport
          eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
          set +o allexport

          LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}";
          export LD_LIBRARY_PATH
          pulumi up --cwd "$GIT_ROOT/pulumi" --stack albinvass/infra/prod "$@"
        '';
    };

    deploy-colmena = {
      description = "Deploy colmena conifguration.";
      exec = # bash
        ''
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
      exec = # bash
        ''
          #!/bin/env bash
          trap kill-ssh-agent EXIT
          eval `start-ssh-agent`

          GIT_ROOT=$(git rev-parse --show-toplevel)
          nix run github:numtide/nixos-anywhere -- --flake ''${GIT_ROOT}#''${1} "root@$(pulumi stack output --cwd ''$GIT_ROOT/pulumi --stack albinvass/Hetzner/infra "''${1}-ip")"
        '';
    };
  };
}
