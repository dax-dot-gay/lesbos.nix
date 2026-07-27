{
    config,
    pkgs,
    lib,
    ...
}:
with lib;
let
    cfg = config.lesbos.backups;
    enabledBackups = filterAttrs (
        _:
        {
            enable,
            sources,
            repositories,
            ...
        }:
        if enable then
            (
                if (any ({ enable, ... }: enable) (attrValues repositories)) then
                    true
                else
                    (any ({ enable, ... }: enable) (attrValues sources))
            )
        else
            false
    ) cfg;

    mkRepoPath = {
        volume = repo: "/backup-volumes/${repo.label}";
        local = repo: "${repo.local.path}";
        ssh = repo: "${repo.ssh.url}";
        rclone = repo: "rclone:${repo.rclone.remote}:${repo.rclone.path}";
    };

    mkRepos = _: repo: {
        label = repo.label;
        path = mkRepoPath."${repo.type}" repo;
    };

    mkPasswordScript =
        config_name: path:
        pkgs.writeShellScriptBin "backups-cat-password-${config_name}.sh" ''
            cat ${path}
        '';

    needVolumes = attrValues (
        filterAttrs (
            _: { repositories, ... }: any (s: (s.type == "volume") && s.enable) (attrValues repositories)
        ) enabledBackups
    );
    volumeInfo = flatten (
        map (
            { name, repositories, ... }:
            map (
                { label, volume, ... }:
                {
                    backup_name = name;
                    repo_label = label;
                    source_info = volume;
                }
            ) (attrValues repositories)
        ) needVolumes
    );
    getSources =
        backup: type:
        mapAttrsToList (name: source: {
            name = name;
            options = source."${type}";
        }) (filterAttrs (_: s: (s.type == type) && s.enable) backup.sources);

    ifSources =
        backup: type: wrapper: iterator:
        let
            sources = getSources backup type;
        in
        (optionalAttrs ((length sources) > 0) (wrapper (map iterator sources)));
    
    actuallyEnabled = ((length (attrValues enabledBackups)) > 0);
in
{
    imports = [
        ./options.nix
    ];

    config = {
            environment.systemPackages = optionals actuallyEnabled ([
                pkgs.borgbackup
                pkgs.borgmatic
            ]
            ++ (optional (any (v: (any (r: r.type == "rclone") (attrValues v.repositories))) (
                attrValues enabledBackups
            )) pkgs.rclone)
            ++ (optional (any (v: (any (r: r.type == "postgresql") (attrValues v.sources))) (
                attrValues enabledBackups
            )) pkgs.postgresql)
            ++ (optional (any (v: (any (r: r.type == "sqlite") (attrValues v.sources))) (
                attrValues enabledBackups
            )) pkgs.sqlite));

            lesbos.secrets.system = mapAttrs' (
                _:
                { settings, ... }:
                {
                    name = settings.encryption.secret;
                    value = {
                        mode = "0400";
                        owner = "root";
                        group = "root";
                    };
                }
            ) (filterAttrs (_: { settings, ... }: settings.encryption.enable) enabledBackups);

            systemd.services =
                (mapAttrs' (
                    _:
                    {
                        name,
                        settings,
                        ...
                    }:
                    nameValuePair "lesbos-backup-${name}-setup" {
                        enable = true;
                        requires = [ "lesbos-volumes.target" ];
                        wantedBy = [ "multi-user.target" ];
                        path = [ "/run/current-system/sw" ];
                        serviceConfig = {
                            Type = "oneshot";
                            User = "root";
                            Group = "root";
                            /*ReadWritePaths = map (r: r.path) (
                                filter (r: (hasPrefix "/" r.path) || (hasPrefix "~" r.path)) (mapAttrsToList mkRepos repositories)
                            );*/
                        };
                        startLimitIntervalSec = 0;
                        startLimitBurst = 1000;
                        script = ''
                            borgmatic --config /etc/borgmatic.d/${name}.yaml repo-create ${optionalString settings.encryption.enable "-e repokey"} --repository "${name}.*" ${optionalString settings.append_only "--append-only"} ${
                                optionalString (!(isNull settings.quota)) "--storage-quota ${settings.quota}"
                            }
                        '';
                    }
                ) enabledBackups)
                // (mapAttrs' (
                    _:
                    {
                        name,
                        ...
                    }:
                    nameValuePair "lesbos-backup-${name}-run" {
                        enable = true;
                        path = [ "/run/current-system/sw" ];
                        serviceConfig = {
                            Type = "oneshot";
                            User = "root";
                            Group = "root";
                            /*ReadWritePaths = map (r: r.path) (
                                filter (r: (hasPrefix "/" r.path) || (hasPrefix "~" r.path)) (mapAttrsToList mkRepos repositories)
                            );*/
                        };
                        startLimitIntervalSec = 0;
                        startLimitBurst = 1000;
                        script = ''
                            borgmatic --config /etc/borgmatic.d/${name}.yaml create --stats
                        '';
                    }
                ) enabledBackups)
                // {
                    borgmatic = {
                        enable = mkForce false;
                    };
                };

            systemd.timers = {
                borgmatic.enable = mkForce false;
                borgmatic.wantedBy = mkForce [ ];
            }
            // (mapAttrs' (
                _:
                {
                    name,
                    schedule,
                    ...
                }:
                nameValuePair "lesbos-backup-${name}-run" {
                    enable = true;
                    wantedBy = [ "multi-user.target" ];
                    requires = [ "lesbos-backup-${name}-setup.service" ];
                    timerConfig = {
                        Unit = "lesbos-backup-${name}-run.service";
                        OnCalendar = schedule;
                    };
                }
            ) enabledBackups);

            services.borgmatic = {
                enable = true;
                enableConfigCheck = true;
                configurations = mapAttrs' (
                    _:
                    {
                        name,
                        settings,
                        repositories,
                        ...
                    }@backup:
                    {
                        name = name;
                        value = {
                            archive_name_format = settings.archive_format;
                            keep_hourly = settings.keep.hourly;
                            keep_daily = settings.keep.daily;
                            keep_weekly = settings.keep.weekly;
                            keep_monthly = settings.keep.monthly;
                            repositories = mapAttrsToList mkRepos repositories;
                        }
                        // (optionalAttrs (!(isNull settings.ssh_command)) { ssh_command = settings.ssh_command; })
                        // (optionalAttrs settings.encryption.enable {
                            encryption_passcommand = "${mkPasswordScript name
                                config.sops.secrets."${settings.encryption.secret}".path
                            }/bin/backups-cat-password-${name}.sh";
                        })
                        // (ifSources backup "paths" (paths: {
                            source_directories = flatten paths;
                        }) ({ options, ... }: options.source_directories))
                        // (ifSources backup "postgresql"
                            (configs: {
                                postgresql_databases = configs;
                            })
                            (
                                { options, ... }:
                                {
                                    name = options.database;
                                    label = options.label;
                                    hostname = options.hostname;
                                    format = options.format;
                                    username = options.username;
                                    pg_dump_command =
                                        if options.database == "all" then options.commands.pg_dumpall else options.commands.pg_dump;
                                    pg_restore_command = options.commands.pg_restore;
                                    psql_command = options.commands.psql;
                                }
                                // (optionalAttrs (!(isNull options.container)) { container = options.container; })
                                // (optionalAttrs (!(isNull options.port)) { port = options.port; })
                                // (optionalAttrs (!(isNull options.passwordFile)) {
                                    password = "{credential file ${options.passwordFile}}";
                                })
                            )
                        )
                        // (ifSources backup "sqlite"
                            (configs: {
                                sqlite_databases = configs;
                            })
                            (
                                { options, ... }:
                                {
                                    name = options.label;
                                    label = options.label;
                                    path = options.path;
                                    sqlite_command = options.commands.sqlite3;
                                    sqlite_restore_command = options.commands.sqlite3;
                                }
                            )
                        );
                    }
                ) enabledBackups;
            };
            lesbos.volumes = listToAttrs (
                map (
                    {
                        backup_name,
                        repo_label,
                        source_info,
                    }:
                    {
                        name = "lesbos-backup-${backup_name}-repo-${repo_label}-volume";
                        value = {
                            enable = true;
                            source = {
                                ensureSource.enable = true;
                            }
                            // source_info;
                            destination = "/backup-volumes/${repo_label}";
                            strategy.bind.enable = true;
                        };
                    }
                ) volumeInfo
            );
        };
}
