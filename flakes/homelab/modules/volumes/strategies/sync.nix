{
    config,
    lib,
    pkgs,
    ...
}:
with lib;
let
    strategy = "sync";
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
in
{
    config = mkIf strategyEnabled {
        environment.systemPackages = [ pkgs.rclone ];
        systemd.services =
            (mapAttrs' (
                _:
                {
                    name,
                    volume,
                    strategy,
                    ...
                }:
                {
                    name = "volume-setup-sync-${name}";
                    value = {
                        enable = true;
                        requires = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                        after = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                        wantedBy = [ "multi-user.target" ];
                        before = volume.required_by;
                        path = [ pkgs.rclone ];
                        serviceConfig = {
                            Type = "oneshot";
                            User = "root";
                            Group = "root";
                        };
                        script = ''
                            if [ ! -d "${volume.destination}" ]; then
                                echo "Destination directory for VOL[${name}] does not exist! Creating it..."
                                mkdir -p "${volume.destination}"
                                chmod -R ${strategy.mode} ${volume.destination}
                                chown -R ${strategy.user}:${strategy.group} ${volume.destination}

                                ${
                                    if strategy.restoration then
                                        ''
                                            echo "Restoration is enabled, restoring from ${volume.sourcePath}..."
                                            rclone copy ${volume.sourcePath} ${volume.destination} --create-empty-src-dirs
                                        ''
                                    else
                                        ''
                                            echo "Restoration is disabled, not restoring from ${volume.sourcePath}"
                                        ''
                                }
                            fi
                        '';
                    };
                }
            ) relevantVolumes)
            // (mapAttrs' (
                _:
                { name, volume, ... }:
                {
                    name = "volume-periodic-sync-${name}";
                    value = {
                        enable = true;
                        requires = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                        serviceConfig = {
                            Type = "oneshot";
                            User = "root";
                            Group = "root";
                        };
                        path = [ pkgs.rclone ];
                        script = ''
                            if [ -d "${volume.destination}" ] && [ -d "${volume.sourcePath}" ]; then
                                echo "Syncing VOL[${name}] to ${volume.sourcePath}"
                                rclone sync ${volume.destination} ${volume.sourcePath}
                            else
                                echo "Unable to sync VOL[${name}], source or destination do not exist"
                            fi
                        '';
                    };
                }
            ) relevantVolumes);
        systemd.timers = mapAttrs' (
            _:
            {
                name,
                volume,
                strategy,
                ...
            }:
            {
                name = "volume-periodic-sync-timer-${name}";
                value = {
                    enable = true;
                    requires = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                    after = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                    before = volume.required_by;
                    requiredBy = volume.required_by;
                    timerConfig = strategy.timerConfig // {
                        Unit = "volume-periodic-sync-${name}.service";
                    };
                };
            }
        ) relevantVolumes;
    };
}
