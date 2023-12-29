# Bootstrap

```
ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" <user>@<host> nixos-generate-config --no-filesystems --root /mnt/
nix run github:nix-community/nixos-anywhere -- --flake .#<host> root@<host>
```

See: [nixos-anywhere quickstart](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md#steps-required-to-run-nixos-anywhere)
