{ lib, ... }:
with lib;
let
    submod =
        options:
        (types.submodule {
            options = options;
        });

    unitOption = mkOptionType {
        name = "systemd option";
        merge =
            loc: defs:
            if any (def: isList def.value) defs then
                concatMap (def: toList def.value) defs
            else
                mergeEqualOption loc defs;
    };

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

    ownershipOptions = {
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
    };

    replicationOptions = {
        timerConfig = mkOption {
            description = "Configuration for the associated systemd timer (see `systemd.timer(5)` and `systemd.time(7)`)";
            type = types.attrsOf unitOption;
            default = {
                OnActiveSec = "2h";
            };
        };
        restoration = mkOption {
            description = ''
                Enable restoration of data to the destination from the source.

                If enabled, on each boot the setup service will check if the destination directory exists, copying all data from the source to it if it does not.
                Services that rely on this volume will not be started until restoration is complete.
            '';
            type = types.bool;
            default = true;
        };
    };

    borgmaticOptions = configName: {
        configurationName = mkOption {
            description = "Name of this borgmatic configuration";
            type = types.str;
            default = configName;
        };
        repositoryLabel = mkOption {
            description = "Label of the associated borgmatic repository";
            type = types.str;
            default = "${configName}-repo";
        };
        encryption = mkOption {
            description = "Config for encrypting this repository";
            type = types.submodule {
                options = {
                    enable = mkEnableOption "repository encryption";
                    passwordFile = mkOption {
                        description = "Non-store path to a file containing the repository's password";
                        type = types.path;
                    };
                };
            };
            default = {
                enable = false;
            };
        };
        quota = mkOption {
            description = "Storage quota (sets only on repository creation)";
            type = types.nullOr types.singleLineStr;
            default = null;
            example = "5G";
        };
        append_only = mkOption {
            description = "Whether the repository should be append-only (sets only on repository creation)";
            type = types.bool;
            default = false;
        };
        archive_format = mkOption {
            description = "Archive name format";
            type = types.str;
            default = "volumes-${configName}-{now}";
        };
        keep = {
            hourly = mkOption {
                description = "Keep this many hourly backups";
                type = types.ints.unsigned;
                default = 6;
            };
            daily = mkOption {
                description = "Keep this many daily backups";
                type = types.ints.unsigned;
                default = 7;
            };
            weekly = mkOption {
                description = "Keep this many weekly backups";
                type = types.ints.unsigned;
                default = 2;
            };
            monthly = mkOption {
                description = "Keep this many monthly backups";
                type = types.ints.unsigned;
                default = 4;
            };
        };
        onCalendar = mkOption {
            description = "Setting for systemd timer";
            type = types.str;
            default = "hourly";
        };
        restoration = mkOption {
            description = ''
                Enable restoration of data to the destination from the source.

                If enabled, on each boot the setup service will check if the destination directory exists, copying all data from the source to it if it does not.
                Services that rely on this volume will not be started until restoration is complete.
            '';
            type = types.bool;
            default = false;
        };
    };

    mkStrategyOptions = configName: {
        bind = mkStrategy "Bind-mount this path as the owning user" {
            read_only = mkEnableOption "Mount as read-only";
        };
        bindMapped = mkStrategy "Use bindfs to mount this path as a specific user" (
            {
                read_only = mkEnableOption "Mount as read-only";
                permissions = mkOption {
                    description = "BindFS permission specification (see `bindfs(1)`)";
                    type = types.str;
                    default = "0644,a+D";
                };
            }
            // ownershipOptions
        );
        sync =
            mkStrategy
                ''
                    Performs periodic `rclone sync`s from the destination to the source, optionally restoring data if the destination does not yet exist.

                    This does not provide any direct mount for the endpoint, and may overwrite/delete stored data on the source if changes occur on the destination.
                    This strategy should not be used for data shared between machines/volumes
                ''
                (
                    {
                        mode = mkOption {
                            description = "Mode of the created directory";
                            type = types.str;
                            default = "0770";
                        };
                    }
                    // ownershipOptions
                    // replicationOptions
                );
        backup =
            mkStrategy
                ''
                    Uses `borgmatic` to clone the destination to the source, optionally restoring data if the destination folder does not yet exist.

                    This does not provide any direct mount for the endpoint, and data on the source will only be accessible by this machine.
                ''
                (
                    (borgmaticOptions configName)
                    // ownershipOptions
                    // {
                        mode = mkOption {
                            description = "Mode of the created directory";
                            type = types.str;
                            default = "0770";
                        };
                    }
                );
        custom =
            mkStrategy
                ''
                    Delegate to a custom script for backup and restore. This script will run as root.

                    All scripts are passed the following environment variables:
                    - VOL_SOURCE: Volume source path
                    - VOL_DEST: Volume destination path
                ''
                (
                    {
                        customClass = mkOption {
                            description = "Custom class for this custom operation (ie a descriptive name)";
                            type = types.str;
                            default = "generic";
                        };
                        mode = mkOption {
                            description = "Mode of the created directory";
                            type = types.str;
                            default = "0770";
                        };
                        timerConfig = mkOption {
                            description = "Configuration for the associated systemd timer (see `systemd.timer(5)` and `systemd.time(7)`)";
                            type = types.attrsOf unitOption;
                            default = {
                                OnActiveSec = "2h";
                            };
                        };
                        setupScript = mkOption {
                            description = "Script that runs on boot if both the source and destination paths are empty.";
                            type = types.nullOr types.package;
                            default = null;
                        };
                        backupScript = mkOption {
                            description = "Script that runs periodically to back up data";
                            type = types.nullOr types.package;
                            default = null;
                        };
                        restoreScript = mkOption {
                            description = "Script that runs if the destination path is empty";
                            type = types.nullOr types.package;
                            default = null;
                        };
                        packages = mkOption {
                            description = "Packages to share between scripts";
                            type = types.listOf types.package;
                            default = [ ];
                        };
                    }
                    // ownershipOptions
                );
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
                        type = types.enum [
                            "disk"
                            "share"
                        ];
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
                    subdirectories = mkOption {
                        description = "A list of subdirectories (as relative paths from the source path) to create in the source directory";
                        type = types.listOf types.str;
                        default = [ ];
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
                        options = mkStrategyOptions config._module.args.name;
                    };
                };
                required_by = mkOption {
                    description = "Systemd unit names that require this volume to be active and functional before starting";
                    type = types.listOf types.str;
                    default = [ ];
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
            default = { };
        };
    };
}
