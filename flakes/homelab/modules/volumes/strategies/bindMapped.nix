{
    config,
    lib,
    pkgs,
    ...
}:
with lib;
let
    strategy = "bindMapped";
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
        environment.systemPackages = [ pkgs.bindfs ];
        fileSystems = mapAttrs' (_: volume: {
            name = volume.volume.destination;
            value =
                let
                    ensure = volume.volume.source.ensureSource;
                    source_user = if ensure.enable then ensure.user else "root";
                    source_group = if ensure.enable then ensure.group else "root";
                in
                {
                    depends = [
                        volume.volume.sourcePath
                    ];
                    device = volume.volume.sourcePath;
                    fsType = "fuse.bindfs";
                    options = concatLists [
                        [
                            "x-systemd.requires=systemd-tmpfiles-setup.service"
                            "x-systemd.after=systemd-tmpfiles-setup.service"
                            "map=${source_user}/${volume.strategy.user}:@${source_group}/@${volume.strategy.group}"
                            "perms=${volume.strategy.permissions}"
                            "nofail"
                        ]
                        (optional volume.strategy.read_only "ro")
                        (map (r: "x-systemd.requiredBy=${r}") volume.volume.required_by)
                    ];
                };
        }) relevantVolumes;
    };
}
