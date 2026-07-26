{
    config,
    lib,
    pkgs,
    ...
}:
with lib;
let
    strategy = "backup";
    cfg = config.lesbos.volumes;

    # Maps volumes into an expanded form, containing extended metadata
    volumes = mapAttrs (
        volname: vol:
        let
            s_name = elemAt (attrNames (filterAttrs (_: strat: strat.enable) vol.strategy)) 0;
        in
        {
            name = volname;
            strategy_name = s_name;
            volume = vol;
            strategy = vol.strategy."${s_name}";
        }
    ) (filterAttrs (_: vol: vol.enable) cfg);

    # Lists the names of all enabled strategies across the volumes
    enabledStrategies = unique (mapAttrsToList (_: vol: vol.strategy_name) volumes);

    # True if `strategy` is enabled for any volume
    strategyEnabled = !(isNull (lists.findFirst (s: s == strategy) null enabledStrategies));

    # Set of volumes enabling this strategy
    relevantVolumes = filterAttrs (_: vol: vol.strategy_name == strategy) volumes;

    catPassword =
        name: path:
        pkgs.writeShellScriptBin "cat-pass-${name}.sh" ''
            cat ${path}
        '';
in
{
    config = mkIf strategyEnabled {
        environment.systemPackages = [
            pkgs.borgbackup
            pkgs.borgmatic
        ];
        systemd.timers = {
            borgmatic.enable = mkForce false;
            borgmatic.wantedBy = mkForce [ ];
        }
        // (mapAttrs' (
            _:
            {
                name,
                volume,
                strategy,
                ...
            }:
            nameValuePair "volume-periodic-backup-${name}" {
                enable = true;
                requires = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                after = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                before = volume.required_by;
                requiredBy = volume.required_by;
                timerConfig = {
                    Unit = "volume-periodic-backup-${name}.service";
                    OnCalendar = strategy.onCalendar;
                };
            }
        ) relevantVolumes);
        services.borgmatic = {
            enable = true;
            enableConfigCheck = true;
            configurations = mapAttrs' (
                _:
                {
                    name,
                    volume,
                    strategy,
                    ...
                }:
                nameValuePair strategy.configurationName (
                    {
                        repositories = [
                            (
                                {
                                    label = strategy.repositoryLabel;
                                    path = volume.sourcePath;
                                    encryption = if strategy.encryption.enable then "repokey-blake2" else "none";
                                    append_only = strategy.append_only;
                                }
                                // (optionalAttrs (!(isNull strategy.quota)) {
                                    quota = strategy.quota;
                                })
                            )
                        ];
                        archive_name_format = strategy.archive_format;
                        keep_hourly = strategy.keep.hourly;
                        keep_daily = strategy.keep.daily;
                        keep_weekly = strategy.keep.weekly;
                        keep_monthly = strategy.keep.monthly;
                        checks = [
                            {
                                name = "repository";
                                frequency = "2 weeks";
                            }
                            {
                                name = "archives";
                                frequency = "1 month";
                            }
                        ];
                        source_directories = [
                            volume.destination
                        ];
                        unknown_unencrypted_repo_access_is_ok = true;
                        relocated_repo_access_is_ok = true;
                        log_file_verbosity = -2;
                        syslog_verbosity = 1;
                        progress = true;
                    }
                    // (optionalAttrs strategy.encryption.enable {
                        encryption_passcommand = "${catPassword name strategy.encryption.passwordFile}/bin/cat-pass-${name}.sh";
                    })
                )
            ) relevantVolumes;
        };

        systemd.services =
            (mapAttrs' (
                _:
                {
                    name,
                    volume,
                    strategy,
                    ...
                }:
                nameValuePair "volume-setup-backup-${name}" {
                    enable = true;
                    requires = [
                        "vols-${volume.source.type}-${volume.source.name}.mount"
                        "volumes-initialize-sources.service"
                    ];
                    after = [
                        "vols-${volume.source.type}-${volume.source.name}.mount"
                        "volumes-initialize-sources.service"
                    ];
                    wantedBy = [
                        "multi-user.target"
                        "volume-periodic-backup-${name}.timer"
                        "lesbos-volumes.target"
                    ]
                    ++ volume.required_by;
                    before = volume.required_by ++ [
                        "volume-periodic-backup-${name}.timer"
                        "lesbos-volumes.target"
                    ];
                    requiredBy = volume.required_by ++ [ "lesbos-volumes.target" ];
                    path = [ pkgs.borgmatic ];
                    serviceConfig = {
                        Type = "oneshot";
                        User = "root";
                        Group = "root";
                    };
                    startLimitIntervalSec = 0;
                    startLimitBurst = 1000;
                    script = ''
                        if [ ! -e "${volume.sourcePath}/config" ]; then
                            echo "Source directory for VOL[${name}] does not contain a borg repo! Creating it..."
                            borgmatic repo-create --repository "${volume.sourcePath}"
                            touch "${volume.sourcePath}/.new-repo"
                        fi

                        if [ ! -d "${volume.destination}" ]; then
                            echo "Destination directory for VOL[${name}] does not exist! Creating it..."
                            mkdir -p "${volume.destination}"
                            chmod -R ${strategy.mode} ${volume.destination}
                            chown -R ${strategy.user}:${strategy.group} ${volume.destination}

                            ${
                                if strategy.restoration then
                                    ''
                                        if [ -e "${volume.sourcePath}/.new-repo" ]; then
                                            rm "${volume.sourcePath}/.new-repo"
                                            ${concatStringsSep "\n" (
                                                map (sub: ''
                                                    mkdir -p "${volume.destination}/${sub}"
                                                    chmod -R ${strategy.mode} "${volume.destination}/${sub}"
                                                    chown -R ${strategy.user}:${strategy.group} "${volume.destination}/${sub}"
                                                '') volume.source.subdirectories
                                            )}
                                        else
                                            echo "Restoration is enabled, restoring from ${volume.sourcePath}..."
                                            cd ${volume.destination}
                                            borgmatic extract --repository "${volume.sourcePath}" --archive latest
                                        fi
                                    ''
                                else
                                    ''
                                        echo "Restoration is disabled, not restoring from ${volume.sourcePath}"
                                        ${concatStringsSep "\n" (
                                            map (sub: ''
                                                mkdir -p "${volume.destination}/${sub}"
                                                chmod -R ${strategy.mode} "${volume.destination}/${sub}"
                                                chown -R ${strategy.user}:${strategy.group} "${volume.destination}/${sub}"
                                            '') volume.source.subdirectories
                                        )}
                                    ''
                            }
                        fi
                    '';
                }
            ) relevantVolumes)
            // (mapAttrs' (
                _:
                {
                    name,
                    volume,
                    ...
                }:
                nameValuePair "volume-periodic-backup-${name}" {
                    enable = true;
                    requires = [
                        "vols-${volume.source.type}-${volume.source.name}.mount"
                        "volume-setup-backup-${name}.service"
                    ];
                    path = [ pkgs.borgmatic ];
                    serviceConfig = {
                        Type = "oneshot";
                        User = "root";
                        Group = "root";
                    };
                    startLimitIntervalSec = 0;
                    startLimitBurst = 1000;
                    script = ''
                        echo "Running backup for VOL[${name}]..."
                        borgmatic create --stats --repository "${volume.sourcePath}"
                    '';
                }
            ) relevantVolumes)
            // {
                borgmatic = {
                    enable = mkForce false;
                };
            };
    };
}
