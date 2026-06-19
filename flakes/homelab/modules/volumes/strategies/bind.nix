{
    config,
    lib,
    ...
}:
with lib;
let
    strategy = "bind";
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
        fileSystems = mapAttrs' (_: volume: {
            name = volume.volume.destination;
            value = {
                depends = [
                    volume.volume.sourcePath
                ];
                device = volume.volume.sourcePath;
                fsType = "none";
                options = concatLists [
                    [
                        "bind"
                        "x-systemd.requires=systemd-tmpfiles-setup.service"
                        "nofail"
                    ]
                    (optional volume.strategy.read_only "ro")
                    (map (r: "x-systemd.requiredBy=${r}") volume.volume.required_by)
                ];
            };
        }) relevantVolumes;
    };
}
