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
        systemd.services.volumes-init = {
            enable = true;
            requires = mapAttrsToList (_: {volume, ...}: "vols-${volume.source.type}-${volume.source.name}.mount") volumes;
            after = mapAttrsToList (_: {volume, ...}: "vols-${volume.source.type}-${volume.source.name}.mount") volumes;
            wantedBy = ["multi-user.target"];
            serviceConfig = {
                Type = "oneshot";
                User = "root";
                Group = "root";
            };
            script = ''
                ${concatStringsSep "\n" (mapAttrsToList (_: {name, strategy_name, volume, strategy}: ''
                    # Setup volume ${name} with strategy ${strategy_name}
                    if [ ! -d ${volume.destination} ]; then
                        mkdir -p ${volume.destination}
                        touch ${volume.destination}/.new-volume
                        chmod -R ${volume.resolvedPermission.mode} ${volume.destination}
                        chown -R ${volume.resolvedPermission.user}:${volume.resolvedPermission.group}
                    fi
                '') volumes)}
            '';
        };
        systemd.services.volumes-fill = {
            enable = true;
            wantedBy = ["multi-user.target"];
            serviceConfig = {
                Type = "oneshot";
                User = "root";
                Group = "root";
            };
            script = ''
                ${concatStringsSep "\n" (mapAttrsToList (_: {name, strategy_name, volume, strategy}: ''
                    # Ensure existence of subdirectories for volume: ${name}
                    ${concatStringsSep "\n" (map (subdir: ''
                        if [ ! -d "${volume.destination}/${subdir}" ]; then
                            mkdir -p "${volume.destination}/${subdir}"
                            chmod -R ${volume.resolvedPermission.mode} "${volume.destination}/${subdir}"
                            chown -R ${volume.resolvedPermission.user}:"${volume.destination}/${subdir}"
                        fi
                    '') volume.source.subdirectories)}
                '') volumes)}
            '';
        };
    };
}
