{ nodes, lib, ... }:
rec {
  nodeConfigs = map (
    node: with nodes.${node}.config; {
      name = node;
      inherit deployment;
      enabled = builtins.elem "enabled" deployment.tags;
    }
  ) (builtins.attrNames nodes);
  cloudNode =
    node:
    builtins.elem "pulumi" (
      builtins.map (
        tag: (if lib.strings.hasPrefix "pulumi:" tag then "pulumi" else tag)
      ) node.deployment.tags
    );
  getPulumiConfig =
    node:
    if cloudNode node then
      builtins.fromJSON (
        lib.strings.removePrefix "pulumi:" (
          builtins.elemAt (builtins.filter (tag: lib.strings.hasPrefix "pulumi:" tag) node.deployment.tags) 0
        )
      )
    else
      {
        Server = {
          Enabled = false;
        };
      };
  pulumiConfigs = builtins.map (
    node:
    {
      Name = node.deployment.targetHost;
      VirtualHosts = builtins.attrNames nodes.${node.name}.config.services.nginx.virtualHosts;
    }
    // getPulumiConfig node
  ) nodeConfigs;
  enabledNodeConfigs = builtins.filter (node: node.enabled) nodeConfigs;
  enabledNodes = map (node: node.name) enabledNodeConfigs;
  virtualHosts = builtins.map (node: nodes.${node.name}.config.services.nginx.virtualHosts) nodeConfigs;
}
