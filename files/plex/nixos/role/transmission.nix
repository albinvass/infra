{config, pkgs, lib, ...}:
let
  nixos-unstable = (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/d9f759f2ea8d265d974a6e1259bd510ac5844c5d);
  nixpkgs-unstable = import (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/d9f759f2ea8d265d974a6e1259bd510ac5844c5d)
  {};
in
{
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        9091
        9696
        8989
      ];
      extraCommands = ''
        iptables -t nat -A POSTROUTING -p tcp --dport 9091 -j SNAT --to-source 192.168.100.10
        iptables -t nat -A POSTROUTING -p tcp --dport 8989 -j SNAT --to-source 192.168.100.10
        iptables -t nat -A POSTROUTING -p tcp --dport 9696 -j SNAT --to-source 192.168.100.10
        iptables -t nat -A POSTROUTING -p tcp --dport 7878 -j SNAT --to-source 192.168.100.10
        iptables -t nat -A POSTROUTING -p tcp --dport 8787 -j SNAT --to-source 192.168.100.10
        '';
    };
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "ens18";
      forwardPorts = [
        # transmission
        {
          sourcePort = 9091;
          proto = "tcp";
          destination = "192.168.100.11";
        }
        # sonarr
        {
          sourcePort = 8989;
          proto = "tcp";
          destination = "192.168.100.11";
        }
        # prowlarr
        {
          sourcePort = 9696;
          proto = "tcp";
          destination = "192.168.100.11";
        }
        # radarr
        {
          sourcePort = 7878;
          proto = "tcp";
          destination = "192.168.100.11";
        }
        # readarr
        {
          sourcePort = 8787;
          proto = "tcp";
          destination = "192.168.100.11";
        }
      ];
    };
  };
  containers.transmission = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    forwardPorts = [
      {
        hostPort = 9091;
      }
      # sonarr
      {
        hostPort = 8989;
      }
      # prowlarr
      {
        hostPort = 9696;
      }
      # radarr
      {
        hostPort = 7878;
      }
      # readarr
      {
        hostPort = 8787;
      }
    ];
    bindMounts = {
      "/opt/data" = {
        hostPath = "/opt/data";
        isReadOnly = false;
      };
      "/etc/wg/" = {
        hostPath = "/etc/wg/";
        isReadOnly = true;
      };
    };
    config = { config, pkgs, ... }: {
      imports = [
        "${nixos-unstable}/nixos/modules/services/misc/readarr.nix"
      ];
      environment.etc."sonarr-codec.sh" = {
        source = ./sonarr-codec.sh;
        user = "sonarr";
        group = "media";
        mode = "0755";
      };
      environment.systemPackages = with pkgs; [
        ffmpeg-headless
        vim
        bash
        coreutils
        at
      ];

      system.stateVersion = "23.05";
      users.groups."media".gid = 10001;
      services.readarr = { 
        enable = true;
        package = nixpkgs-unstable.readarr;
        openFirewall = true;
        dataDir = "/opt/data/readarr";
        group = "media";
      };
      services.prowlarr = { 
        enable = true;
        openFirewall = true;
      };
      services.sonarr = { 
        enable = true;
        openFirewall = true;
        dataDir = "/opt/data/sonarr";
        group = "media";
      };
      systemd.services.sonarr = {
        path = with pkgs; [
          ffmpeg
          bash
          coreutils
          at
        ];
      };
      services.radarr = { 
        enable = true;
        openFirewall = true;
        dataDir = "/opt/data/radarr";
        group = "media";
      };
      services.atd = { 
        enable = true;
        allowEveryone = true;
      };
      services.transmission = { 
        enable = true;
        group = "media";
        extraFlags = [
          "--log-debug"
          "--bind-address-ipv4" "10.67.247.178/32"
          "--bind-address-ipv6" "fc00:bbbb:bbbb:bb01::4:f7b1/128"
        ];
        home = "/opt/data/transmission";
        settings = {
          peer-port = 57276;
          rpc-bind-address = "192.168.100.11";
          rpc-whitelist = "192.168.100.10,192.168.100.11,127.0.0.1";
          rpc-host-whitelist = "*";
        };
        openRPCPort = true;
      };
      networking.nameservers = ["10.64.0.1"];

      networking.firewall = {
        allowedUDPPorts = [ 57276 ];
        allowedTCPPorts = [
          9091
          57276
          8989
        ];
      };
      # Instead of a long list of cidrs in allowedIPs we whitelist individual ips with routes
      # https://www.procustodibus.com/blog/2021/03/wireguard-allowedips-calculator/#a-better-alternative
      networking.interfaces.eth0.ipv4.routes = [
        { address = "185.213.154.70"; prefixLength = 32; via = "192.168.100.10";}
      ];

      networking.wireguard.interfaces = {
        wg0 = {
          ips = ["10.67.247.178/32"];
          listenPort = 51820;
          privateKeyFile = "/etc/wg/private-key";
          peers = [{
            publicKey = "B8UVAeNkAW4NiGHd1lpl933Drh4y7pMqpXJpH0SrGjQ=";
            endpoint = "185.213.154.70:51820";
            allowedIPs = [
               "0.0.0.0/0"
            ];
            persistentKeepalive = 25;
          }];
        };
      };

      services.mullvad-vpn.enable = true;
    };
  };
}

