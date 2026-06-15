_: {
  services.resolved.settings.Resolve.DNSStubListener = false;
  services.adguardhome = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall.allowedUDPPorts = [ 53 ];
}
