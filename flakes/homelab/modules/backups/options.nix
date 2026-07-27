{ lib, ... }:
with lib;
let

    repoKind = types.enum [
        "volume"
        "local"
        "ssh"
        "rclone"
    ];
    srcKind = types.enum [
        "paths"
        "postgresql"
        "sqlite"
    ];

    mkRepoType =
        type: desc: opts:
        (mkOption {
            description = "Configuration for `type == ${type}`: ${desc}";
            type = types.submodule {
                options = opts;
            };
        });

    mkRepoOptions =
        backup_name:
        (types.attrsOf (
            types.submodule (
                { config, ... }:
                {
                    options = {
                        enable = (mkEnableOption "this repository") // {
                            default = true;
                        };
                        type = mkOption {
                            description = "What type of repository this is";
                            type = repoKind;
                        };
                        label = mkOption {
                            description = "Repository label";
                            type = types.singleLineStr;
                            default = "${backup_name}.${config._module.args.name}";
                            readOnly = true;
                        };
                        volume = mkRepoType "volume" "Repository stored on VirtioFS volume" {
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
                        };
                        local = mkRepoType "local" "Repository stored locally" {
                            path = mkOption {
                                description = "Path for local repository";
                                type = types.str;
                            };
                        };
                        ssh = mkRepoType "ssh" "Repository stored on an SSH/SFTP remote" {
                            url = mkOption {
                                description = "SSH/SFTP URL";
                                type = types.str;
                            };
                        };
                        rclone = mkRepoType "rclone" "Repository stored on an rclone remote" {
                            remote = mkOption {
                                description = "Name of rclone remote";
                                type = types.str;
                            };
                            path = mkOption {
                                description = "Path on the selected remote";
                                type = types.str;
                            };
                        };
                    };
                }
            )
        ));

    mkCommands =
        commands:
        (listToAttrs (
            map (cmd: {
                name = cmd;
                value = mkOption {
                    description = "Override default command for `${cmd}`";
                    type = types.str;
                    default = cmd;
                };
            }) commands
        ));

    mkPrefixedCommands = prefix: commands: (listToAttrs (
            map (cmd: {
                name = cmd;
                value = mkOption {
                    description = "Override default command for `${cmd}`";
                    type = types.str;
                    default = "${prefix}${cmd}";
                };
            }) commands
        ));

    mkSrcType =
        type: desc: opts:
        (mkOption {
            description = "Configuration for `type == ${type}`: ${desc}";
            type = types.submodule {
                options = opts;
            };
        });

    srcOptions = types.attrsOf (
        types.submodule (
            { config, ... }:
            {
                options = {
                    enable = (mkEnableOption "this source") // {
                        default = true;
                    };
                    type = mkOption {
                        description = "What type of source this is";
                        type = srcKind;
                    };
                    paths = mkSrcType "paths" "Backup selected source directories" {
                        source_directories = mkOption {
                            description = "Directories to source from";
                            type = types.listOf types.str;
                        };
                    };
                    postgresql = mkSrcType "postgresql" "Backup selected postgresql database(s)" {
                        database = mkOption {
                            description = "Database name to backup, or `all` for all databases";
                            type = types.str;
                        };
                        label = mkOption {
                            description = "Label in backup";
                            type = types.str;
                            default = "psql-${config._module.args.name}";
                        };
                        container = mkOption {
                            description = "Container to connect to instead of host";
                            type = types.nullOr types.str;
                            default = null;
                        };
                        hostname = mkOption {
                            description = "Hostname to connect to, or unix socket";
                            type = types.str;
                            default = "/run/postgresql";
                        };
                        port = mkOption {
                            description = "Port to connect to over the network";
                            type = types.nullOr types.port;
                            default = null;
                        };
                        format = mkOption {
                            description = "Dump output format";
                            type = types.enum [
                                "plain"
                                "custom"
                                "directory"
                                "tar"
                            ];
                            default = "custom";
                        };
                        username = mkOption {
                            description = "Username to pass to the database";
                            type = types.str;
                            default = "postgres";
                        };
                        passwordFile = mkOption {
                            description = "Path to a file containing the connection password, or null";
                            type = types.nullOr types.path;
                            default = null;
                        };
                        commands = mkPrefixedCommands "sudo -u postgres " [
                            "pg_dump"
                            "pg_dumpall"
                            "pg_restore"
                            "psql"
                        ];
                    };
                    sqlite = mkSrcType "sqlite" "Backup selected sqlite database" {
                        path = mkOption {
                            description = "Path to sqlite file";
                            type = types.str;
                        };
                        label = mkOption {
                            description = "Label in backup";
                            type = types.str;
                            default = "sqlite-${config._module.args.name}";
                        };
                        commands = mkCommands [ "sqlite3" ];
                    };
                };
            }
        )
    );

    backupOptions = types.submodule (
        { config, ... }:
        {
            options = {
                enable = (mkEnableOption "this backup") // {
                    default = true;
                };
                name = mkOption {
                    description = "Name of this configuration";
                    type = types.singleLineStr;
                    default = config._module.args.name;
                };
                settings = {
                    encryption = {
                        enable = mkEnableOption "repository encryption";
                        secret = mkOption {
                            description = "Name of the sops secret to configure and retrieve the password from";
                            type = types.singleLineStr;
                            default = "backups/${config._module.args.name}/key";
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
                        default = "volumes-${config._module.args.name}-{now}";
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
                    ssh_command = mkOption {
                        description = "SSH command to use instead of `ssh`";
                        type = types.nullOr types.str;
                        default = null;
                    };
                };
                repositories = mkOption {
                    description = "Repository configurations";
                    type = mkRepoOptions config._module.args.name;
                };
                sources = mkOption {
                    description = "Source configurations";
                    type = srcOptions;
                };
                schedule = mkOption {
                    description = "When to run the backup task, as an argument to OnCalendar";
                    type = types.singleLineStr;
                    default = "daily";
                };
            };
        }
    );
in
{
    options = {
        lesbos.backups = mkOption {
            description = "Mapping of automated backup configurations";
            type = types.attrsOf backupOptions;
            default = { };
        };
    };
}
