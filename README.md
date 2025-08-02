# XC

This project uses [xc](https://github.com/joerdav/xc) for to align documentation and maintenance commands.

# Tasks

## Bootstrap

Bootstraps a hetzner node

Inputs: NODE

```bash

nix run github:numtide/nixos-anywhere -- \
    --flake ".#${NODE}" \
    --build-on-remote \
    "root@${NODE}.albinvass.se"
```

See: https://discourse.nixos.org/t/nixos-on-hetzner-cloud-arm/29186/2
See: [nixos-anywhere quickstart](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md#steps-required-to-run-nixos-anywhere)


## generate-host-certificate

Generates a new certificate for a host.

Inputs: HOSTNAME

```bash
generate-host-certificate "${HOSTNAME}"
```
