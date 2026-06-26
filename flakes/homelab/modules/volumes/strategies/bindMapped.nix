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
        systemd.mounts = mapAttrsToList (_: volume: let
                    ensure = volume.volume.source.ensureSource;
                    source_user = if ensure.enable then ensure.user else "root";
                    source_group = if ensure.enable then ensure.group else "root";
                in {
            type = "fuse.bindfs";
            what = volume.volume.sourcePath;
            where = volume.volume.destination;
            requiredBy = ["lesbos-volumes.target"] ++ volume.volume.required_by;
            requires = ["volumes-initialize-sources.service"];
            after = ["volumes-initialize-sources.service"];
            options = "map=${source_user}/${volume.strategy.user}:@${source_group}/@${volume.strategy.group},perms=${volume.strategy.permissions},nofail" + (optionalString volume.strategy.read_only ",ro");
        }) relevantVolumes;
        systemd.services.volumes-bind-pre = {
            enable = true;
            requiredBy = ["lesbos-volumes-pre.target"];
            requires = ["systemd-tmpfiles-setup.service"];
            after = ["systemd-tmpfiles-setup.service"];
            serviceConfig = {Type = "oneshot";};
            script = ''
                ${
                    concatStringsSep "\n" (mapAttrsToList (_: vol: ''
                        if ! mountpoint -q -- "${vol.volume.destination}"; then
                            echo "$(ls -la ${vol.volume.destination})"
                            echo "Would run: rm -rf ${vol.volume.destination}/*"
                        fi
                    '') relevantVolumes)
                }
            '';
        };
    };
}
