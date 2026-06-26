{ config, lib, ... }:
with lib;
let
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
in
{
    imports = [
        ./options.nix
        ./strategies
    ];

    config = {
        systemd.targets.lesbos-volumes-pre = {
            enable = true;
            wantedBy = ["volumes-initialize-sources.service"];
            before = ["volumes-initialize-sources.service"];
            wants = ["systemd-tmpfiles-setup.service"];
            after = ["systemd-tmpfiles-setup.service"];
        };
        systemd.services.volumes-initialize-sources = {
            enable = true;
            requires = ["network.target" "local-fs.target"];
            after = ["network.target"];
            requiredBy = ["lesbos-volumes.target"];
            startLimitIntervalSec = 0;
            startLimitBurst = 1000;
            serviceConfig = {
                Type = "oneshot";
                RequiresMountsFor = mapAttrsToList (_: vol: vol.volume.sourcePath) (filterAttrs (_: vol: vol.volume.source.ensureSource.enable) volumes);
            };
            script = concatStringsSep "\n" (
                mapAttrsToList (_: vol: ''
                    if [ ! -d "${vol.volume.sourcePath}" ]; then
                        echo "Creating source path: ${vol.volume.sourcePath}"
                        mkdir -p "${vol.volume.sourcePath}"

                        ${concatStringsSep "\n" (map (s: ''
                            mkdir -p "${vol.volume.sourcePath}/${s}"
                        '') vol.volume.source.subdirectories)}

                        chown -R ${vol.volume.source.ensureSource.user}:${vol.volume.source.ensureSource.group} "${vol.volume.sourcePath}"
                        chmod -R ${vol.volume.source.ensureSource.mode} "${vol.volume.sourcePath}"
                    fi
                '') (filterAttrs (_: vol: vol.volume.source.ensureSource.enable) volumes)
            );
        };

        systemd.targets.lesbos-volumes = {
            enable = true;
            description = "All lesbos volumes are set up and functional";
            wantedBy = ["multi-user.target"];
            before = ["multi-user.target"];
            requiredBy = unique (flatten (mapAttrsToList (_: v: v.volume.required_by) (filterAttrs (_: vol: vol.volume.source.ensureSource.enable) volumes)));
        };
    };
}
