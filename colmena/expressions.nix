{ nodes, ... }:
rec {
  enabledNodeConfigs = (
    builtins.filter
      (node: node.enabled)
      (map
        (node: with (nodes.${node}.config); {
          name=node; deployment=deployment; enabled=builtins.elem "enabled" deployment.tags;
        })
        (builtins.attrNames nodes))
  );
  enabledNodes = map (node: node.name) enabledNodeConfigs;
}
