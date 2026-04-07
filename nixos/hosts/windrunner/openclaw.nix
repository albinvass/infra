{ inputs, ... }: {
  imports = [ inputs.microvm.nixosModules.host ];

  systemd.network.netdevs."10-microvm".netdevConfig = {
    Kind = "bridge";
    Name = "microvm";
  };
  systemd.network.networks."10-microvm" = {
    matchConfig.Name = "microvm";
    networkConfig = {
      DHCPServer = true;
      IPv6SendRA = true;
    };
    addresses = [{
      addressConfig.Address = "10.0.0.1/24";
    } {
      addressConfig.Address = "fd12:3456:789a::1/64";
    }];
    ipv6Prefixes = [{
      ipv6PrefixConfig.Prefix = "fd12:3456:789a::/64";
    }];
  };

  systemd.network.networks."11-microvm" = {
    matchConfig.Name = "vm-*";
    networkConfig.Bridge = "microvm";
  };

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    externalInterface = "enp8s0";
    internalInterfaces = [ "microvm" ];
  };

  networking.firewall.allowedUDPPorts = [ 67 ];

  microvm.vms = {
    openclaw = {
      config = {
        microvm = {
          vsock.cid = 100;
          interfaces = [{
            type = "tap";
            id = "vm-openclaw";
            mac = "02:00:00:00:00:01";
          }];
          shares = [{
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            tag = "ro-store";
            proto = "virtiofs";
          }];
        };
      };
    };
  };
}

