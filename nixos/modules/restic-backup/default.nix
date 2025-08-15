{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.albinvass.resticBackup;

in {
  options.albinvass.resticBackup = {
    services = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          paths = mkOption {
            type = types.listOf types.str;
            description = "Paths to backup";
          };
          exclude = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Paths to exclude from backup";
          };
          pruneOpts = mkOption {
            type = types.listOf types.str;
            default = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 3"
            ];
            description = "Prune options for the backup";
          };
          backupPrepareCommand = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Command to run before backup";
          };
          backupCleanupCommand = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Command to run after backup";
          };
          useRunitor = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to wrap restic with runitor";
          };
        };
      });
      default = {};
      description = "Restic backup configurations";
    };
  };

  config = mkIf (cfg.services != {}) {
    sops.secrets = mkMerge (mapAttrsToList (name: backupConfig: {
      "${name}/restic/passwordFile" = {
        owner = "root";
        group = "root";
        mode = "0600";
      };
      "${name}/restic/repositoryFile" = {
        owner = "root";
        group = "root";
        mode = "0600";
      };
      "${name}/restic/environmentFile" = {
        owner = "root";
        group = "root";
        mode = "0600";
      };
    }) cfg.services);

    services.restic.backups = mapAttrs (name: backupConfig: {
      initialize = true;
      package = if backupConfig.useRunitor then let
        runitorWrappedRestic = pkgs.writeShellScriptBin "restic" ''
          #!${pkgs.bash}/bin/bash
          ${pkgs.runitor}/bin/runitor -- ${pkgs.restic}/bin/restic "$@"
        '';
      in runitorWrappedRestic else pkgs.restic;
      passwordFile = config.sops.secrets."${name}/restic/passwordFile".path;
      repositoryFile = config.sops.secrets."${name}/restic/repositoryFile".path;
      environmentFile = config.sops.secrets."${name}/restic/environmentFile".path;
      paths = backupConfig.paths;
      exclude = backupConfig.exclude;
      pruneOpts = backupConfig.pruneOpts;
    } // (optionalAttrs (backupConfig.backupPrepareCommand != null) {
      backupPrepareCommand = backupConfig.backupPrepareCommand;
    }) // (optionalAttrs (backupConfig.backupCleanupCommand != null) {
      backupCleanupCommand = backupConfig.backupCleanupCommand;
    })) cfg.services;
  };
}