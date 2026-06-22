{
    config,
    lib,
    pkgs,
    ...
}:
with lib;
let
    strategy = "custom";
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
                    name = "volume-setup-custom-${strategy.customClass}-${name}";
                    value = {
                        enable = true;
                        requires = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                        after = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                        wantedBy = [ "multi-user.target" ];
                        before = volume.required_by;
                        requiredBy = volume.required_by;
                        path = strategy.packages;
                        environment = {
                            VOL_SOURCE = volume.sourcePath;
                            VOL_DEST = volume.destination;
                        };
                        serviceConfig = {
                            Type = "oneshot";
                            User = "root";
                            Group = "root";
                        };
                        script = ''
                            ${
                                if !(isNull strategy.setupScript) then
                                    ''
                                        if [ ! -e "${volume.sourcePath}/config" ]; then
                                            ${strategy.setupScript}
                                        fi
                                    ''
                                else
                                    ""
                            }
                            if [ ! -d "${volume.destination}" ]; then
                                echo "Destination directory for VOL[${name}] does not exist! Creating it..."
                                mkdir -p "${volume.destination}"
                                chmod -R ${strategy.mode} ${volume.destination}
                                chown -R ${strategy.user}:${strategy.group} ${volume.destination}

                                ${
                                    if !(isNull strategy.restoreScript) then
                                        ''
                                            echo "Restoration is enabled, restoring from ${volume.sourcePath}..."
                                            ${strategy.restoreScript}
                                        ''
                                    else
                                        ''
                                            echo "Restoration is disabled, not restoring from ${volume.sourcePath}"
                                            ${concatStringsSep "\n" (map (sub: ''
                                                mkdir -p "${volume.destination}/${sub}"
                                                chmod -R ${strategy.mode} "${volume.destination}/${sub}"
                                                chown -R ${strategy.user}:${strategy.group} "${volume.destination}/${sub}"
                                            '') volume.source.subdirectories)}
                                        ''
                                }
                            fi
                        '';
                    };
                }
            ) relevantVolumes)
            // (mapAttrs' (
                _:
                { name, volume, strategy, ... }:
                {
                    name = "volume-periodic-custom-${strategy.customClass}-${name}";
                    value = {
                        enable = true;
                        requires = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                        serviceConfig = {
                            Type = "oneshot";
                            User = "root";
                            Group = "root";
                        };
                        path = strategy.packages;
                        environment = {
                            VOL_SOURCE = volume.sourcePath;
                            VOL_DEST = volume.destination;
                        };
                        script =
                            if !(isNull strategy.backupScript) then
                                ''
                                    if [ -d "${volume.destination}" ] && [ -d "${volume.sourcePath}" ]; then
                                        echo "Running backup of VOL[${name}]"
                                        ${strategy.backupScript}
                                    else
                                        echo "Unable to sync VOL[${name}], source or destination do not exist"
                                    fi
                                ''
                            else
                                "echo 'No backup script configured'";
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
                name = "volume-periodic-custom-timer-${strategy.customClass}-${name}";
                value = {
                    enable = true;
                    requires = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                    after = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                    before = volume.required_by;
                    requiredBy = volume.required_by;
                    timerConfig = strategy.timerConfig // {
                        Unit = "volume-periodic-custom-${strategy.customClass}-${name}.service";
                    };
                };
            }
        ) relevantVolumes;
    };
}
