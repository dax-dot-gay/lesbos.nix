{ lib, ... }:
with lib;
let
    submod =
        options:
        (types.submodule {
            options = options;
        });

    mkStrategy =
        description: options:
        mkOption {
            description = ''
                ${description}
            '';
            type = submod (
                {
                    enable = mkEnableOption "Enable this strategy";
                }
                // options
            );
            default = {
                enable = false;
            };
        };

    strategies = {
        bind = mkStrategy "Bind-mount this path as the owning user" {
            read_only = mkEnableOption "Mount as read-only";
        };
        bindMapped = mkStrategy "Use bindfs to mount this path as a specific user" {
            read_only = mkEnableOption "Mount as read-only";
            user = mkOption {
                description = "User to show as owning all files & directories";
                type = types.str;
                default = "root";
            };
            group = mkOption {
                description = "Group to show as owning all files & directories";
                type = types.str;
                default = "root";
            };
            permissions = mkOption {
                description = "BindFS permission specification (see `bindfs(1)`)";
                type = types.str;
                default = "0644,a+D";
            };
        };
    };

    volumeType = types.submodule (
        { config, ... }:
        {
            options = {
                enable = mkOption {
                    description = "Enable this mount";
                    type = types.bool;
                    default = true;
                };
                name = mkOption {
                    description = "Name of this mount for naming related services etc";
                    type = types.str;
                    default = config._module.args.name;
                };
                source = {
                    type = mkOption {
                        description = "Source volume type (disk or virtiofs share)";
                        type = types.enum ["disk" "share"];
                    };
                    name = mkOption {
                        description = "Name of source volume (volume mounted at `/vols/<type>/<name>`)";
                        type = types.singleLineStr;
                    };
                    path = mkOption {
                        description = "Path within the source volume to expose/refer to (must begin with `/`)";
                        type = types.singleLineStr // {
                            check = (x: hasPrefix "/" x);
                        };
                        default = "/";
                    };
                    ensureSource = {
                        enable = mkEnableOption "Ensure the source path exists & has the required owner/group/mode";
                        user = mkOption {
                            description = "Ensures that the source has the specified owner (name or UID)";
                            type = types.str;
                            default = "root";
                        };
                        group = mkOption {
                            description = "Ensures that the source has the specified group (name or GID)";
                            type = types.str;
                            default = "root";
                        };
                        mode = mkOption {
                            description = "Ensures that the source has the specified ownership mode (0xxx)";
                            type = types.strMatching "^0[0-7]{3}$";
                            default = "0770";
                        };
                    };
                };
                sourcePath = mkOption {
                    description = "Utility option for retrieving the full source path. Automatically generated";
                    readOnly = true;
                    type = types.str;
                    default = "/vols/${config.source.type}/${config.source.name}${config.source.path}";
                };
                destination = mkOption {
                    description = "Destination path. Additional options configured by the `strategy`";
                    type = types.str;
                };
                strategy = mkOption {
                    description = "Which strategy to use. Exactly one must be enabled";
                    type = types.submodule {
                        options = strategies;
                    };
                };
                required_by = mkOption {
                    description = "Systemd unit names that require this volume to be active and functional before starting";
                    type = types.listOf types.str;
                    default = [];
                };
            };
        }
    );
in
{
    options = {
        lesbos.volumes = mkOption {
            description = ''
                Multiple methods of mapping mounts from /vols/* (extra disks, virtiofs shares, etc) to target paths with defined access patterns.
            '';
            type = types.attrsOf volumeType;
            default = {};
        };
    };
}
