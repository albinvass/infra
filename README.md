# Bootstrap

```
ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" <user>@<host> nixos-generate-config --no-filesystems --root /mnt/
nix run github:nix-community/nixos-anywhere -- --flake .#<host> root@<host>
```

# Tasks

## Arm setup

Bootstraps an arm node

Inputs: NODE

```bash

KEXEC="$(nix build --print-out-paths github:nix-community/nixos-images#packages.aarch64-linux.kexec-installer-nixos-2311-noninteractive)/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz"
nix run github:numtide/nixos-anywhere -- \
    --flake ".#${NODE}" \
    --kexec "$KEXEC" \
    --build-on-remote \
    "root@${NODE}.albinvass.se"
```

See: https://discourse.nixos.org/t/nixos-on-hetzner-cloud-arm/29186/2
See: [nixos-anywhere quickstart](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md#steps-required-to-run-nixos-anywhere)
