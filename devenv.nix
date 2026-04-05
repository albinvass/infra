{ pkgs, inputs, ... }:
{
  devcontainer = {
    enable = true;
  };
  packages = with pkgs; [
    actionlint
    (octodns.withProviders (ps: [ octodns-providers.hetzner ]))
    xc
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

          trap "rm -rf $GIT_ROOT/certs/ca" EXIT
          decrypt-ca-certificate

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

          echo "Success! New certificate is located at $HOST_DIR"
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

    deploy-hosts = {
      description = "Deploy colmena conifguration.";
      exec = # bash
        ''
          #!/usr/bin/env bash
          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"

          set -o allexport
          eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
          set +o allexport

          export SSH_CONFIG_FILE
          trap 'ssh-agent -k' EXIT
          eval "$(ssh-agent | sed '/^echo.*/d')"
          ssh-add <(sops --extract '["hetzner"]["ssh"]["id_ed25519"]' -d "$GIT_ROOT/secrets.yaml")

          colmena "$@"
        '';
    };

    save-generation = {
      description = "Save the current NixOS system generation path for a node to a file.";
      exec = # bash
        ''
          #!/usr/bin/env bash
          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"
          node="$1"
          output_file="$2"

          set -o allexport
          eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
          set +o allexport

          trap 'ssh-agent -k' EXIT
          eval "$(ssh-agent | sed '/^echo.*/d')"
          ssh-add <(sops --extract '["hetzner"]["ssh"]["id_ed25519"]' -d "$GIT_ROOT/secrets.yaml")

          echo "Saving current generation of $node..."
          gen=$(colmena exec --on "$node" -- readlink /run/current-system 2>/dev/null \
            | grep -oP '/nix/store/[^\s]+' | head -1)
          echo "$gen" > "$output_file"
          echo "Saved generation: $gen"
        '';
    };

    build-hosts = {
      description = "Build colmena configuration on target without activating.";
      exec = # bash
        ''
          #!/usr/bin/env bash
          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"

          set -o allexport
          eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
          set +o allexport

          export SSH_CONFIG_FILE
          trap 'ssh-agent -k' EXIT
          eval "$(ssh-agent | sed '/^echo.*/d')"
          ssh-add <(sops --extract '["hetzner"]["ssh"]["id_ed25519"]' -d "$GIT_ROOT/secrets.yaml")

          colmena build --build-on-target "$@"
        '';
    };

    schedule-rollback = {
      description = "Schedule a rollback canary timer on a node before activation.";
      exec = # bash
        ''
          #!/usr/bin/env bash
          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"
          node="$1"
          gen_file="$2"

          set -o allexport
          eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
          set +o allexport

          trap 'ssh-agent -k' EXIT
          eval "$(ssh-agent | sed '/^echo.*/d')"
          ssh-add <(sops --extract '["hetzner"]["ssh"]["id_ed25519"]' -d "$GIT_ROOT/secrets.yaml")

          gen=$(cat "$gen_file")
          echo "Scheduling rollback canary timer on $node (fires in 15 minutes if not cancelled)..."
          colmena exec --on "$node" -- sudo systemd-run \
            --unit=nixos-rollback-canary \
            --on-active=15min \
            -- sh -c "nix-env -p /nix/var/nix/profiles/system --set '$gen' && '$gen/bin/switch-to-configuration' switch"
          echo "Rollback canary timer scheduled."
        '';
    };

    activate-hosts = {
      description = "Activate a previously built colmena configuration on target.";
      exec = # bash
        ''
          #!/usr/bin/env bash
          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"

          set -o allexport
          eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
          set +o allexport

          export SSH_CONFIG_FILE
          trap 'ssh-agent -k' EXIT
          eval "$(ssh-agent | sed '/^echo.*/d')"
          ssh-add <(sops --extract '["hetzner"]["ssh"]["id_ed25519"]' -d "$GIT_ROOT/secrets.yaml")

          colmena switch --build-on-target "$@"
        '';
    };

    cancel-rollback = {
      description = "Cancel the rollback canary timer on a node after a successful deployment.";
      exec = # bash
        ''
          #!/usr/bin/env bash
          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"
          node="$1"

          set -o allexport
          eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
          set +o allexport

          trap 'ssh-agent -k' EXIT
          eval "$(ssh-agent | sed '/^echo.*/d')"
          ssh-add <(sops --extract '["hetzner"]["ssh"]["id_ed25519"]' -d "$GIT_ROOT/secrets.yaml")

          echo "Cancelling rollback canary timer on $node..."
          colmena exec --on "$node" -- sudo systemctl stop nixos-rollback-canary.timer 2>/dev/null || true
          colmena exec --on "$node" -- sudo systemctl stop nixos-rollback-canary.service 2>/dev/null || true
          echo "Rollback canary timer cancelled."
        '';
    };

    rollback-hosts = {
      description = "Rollback a node to its previously saved NixOS generation.";
      exec = # bash
        ''
          #!/usr/bin/env bash
          set -euo pipefail
          GIT_ROOT="$(git rev-parse --show-toplevel)"
          node="$1"
          gen_file="$2"

          set -o allexport
          eval "$(sops --output-type dotenv --extract '["env"]' -d "$GIT_ROOT/secrets.yaml")"
          set +o allexport

          trap 'ssh-agent -k' EXIT
          eval "$(ssh-agent | sed '/^echo.*/d')"
          ssh-add <(sops --extract '["hetzner"]["ssh"]["id_ed25519"]' -d "$GIT_ROOT/secrets.yaml")

          if ! colmena exec --on "$node" -- true 2>/dev/null; then
            echo "WARNING: SSH connection to $node failed — the SSH configuration may have been broken by the deployment."
            echo "The rollback canary timer scheduled before deployment will automatically restore the previous generation within 15 minutes."
            echo "No further action is required."
            exit 0
          fi

          if [[ -s "$gen_file" ]]; then
            gen=$(cat "$gen_file")
            echo "Rolling back $node to saved generation: $gen"
            colmena exec --on "$node" -- sudo nix-env -p /nix/var/nix/profiles/system --set "$gen"
            colmena exec --on "$node" -- sudo "$gen/bin/switch-to-configuration" switch
          else
            echo "No saved generation found for $node, falling back to nixos-rebuild --rollback"
            colmena exec --on "$node" -- sudo nixos-rebuild --rollback switch
          fi
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
