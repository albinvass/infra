{pkgs, system, inputs}:
let
  bw-get = pkgs.stdenv.mkDerivation {
    name = "bw-get";
    dontUnpack = true;
    installPhase = "install -Dm755 ${../tools/bw-get.py} $out/bin/bw-get";
    buildInputs = [
      pkgs.python3
      pkgs.bitwarden-cli
    ];
  };
in with pkgs; mkShell {
  LC_ALL="C.UTF-8";
  shellHook = ''
    bw sync
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

    export HCLOUD_TOKEN=$(bw-get field "accounts.hetzner.com" "dev-token")
    export CLOUDFLARE_EMAIL=$(bw-get username "dash.cloudflare.com")
    export CLOUDFLARE_API_KEY=$(bw-get field "dash.cloudflare.com" "global-key")

    # `nix develop --command` doens't start a new shell so it never
    # triggers the exit trap.
    # Therefore we only start an ssh agent if we're in an interactive shell
    # See: https://serverfault.com/a/146747
    if [[ $- == *i* ]]; then
      trap "ssh-agent -k" EXIT
      eval `ssh-agent`
      ssh-add <(bw-get attachment "accounts.hetzner.com" "hetzner-ssh-key")
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
    bw-get
    hcloud
  ];
}
