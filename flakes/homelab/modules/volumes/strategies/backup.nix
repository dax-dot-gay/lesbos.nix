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
in
{
    config = mkIf strategyEnabled {
        environment.systemPackages = [ pkgs.borgbackup ];
        systemd.services = (
            mapAttrs' (
                _:
                {
                    name,
                    volume,
                    strategy,
                    ...
                }:
                {
                    name = "volume-setup-backup-${name}";
                    value = {
                        enable = true;
                        requires = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                        after = [ "vols-${volume.source.type}-${volume.source.name}.mount" ];
                        wantedBy = [
                            "multi-user.target"
                            "borgbackup-job-volume-${name}.timer"
                        ]
                        ++ volume.required_by;
                        before = volume.required_by ++ [ "borgbackup-job-${name}.timer" ];
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
                            fi
                        '';
                    };
                }
            ) relevantVolumes
        );
        services.borgbackup.jobs = (
            mapAttrs' (
                _:
                {
                    name,
                    volume,
                    strategy,
                    ...
                }:
                {
                    name = "volume-${name}";
                    value = {
                        paths = volume.destination;
                        encryption =
                            if strategy.encryption.enable then
                                {
                                    mode = "repokey";
                                    passCommand = "cat ${strategy.encryption.passwordFile}";
                                }
                            else
                                { mode = "none"; };
                        compression = strategy.compression;
                        startAt = strategy.startAt;
                    };
                }
            ) relevantVolumes
        );
    };
}
