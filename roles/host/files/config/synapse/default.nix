{ config, lib, pkgs, ... }:
{
  age.secrets.vassast-org-homeserver-yaml.file = ./vassast-org-homeserver-yaml.age;
  age.secrets.vassast-org-log-config.file = ./vassast-org-log-config.age;
  age.secrets.vassast-org-signing-key.file = ./vassast-org-signing-key.age;
  config.virtualisation.oci-containers.containers = {
    synapse = {
      image = "matrixdotorg/synapse:v1.34.0";
      ports = [ "8008:8008" ];
    };
  };
}
