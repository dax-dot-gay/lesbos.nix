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
        systemd.tmpfiles.settings = mapAttrs' (_: {name, volume, ...}: {
            name = "10-lsb-volumes-${name}";
            value = {
                "${volume.sourcePath}" = {
                    d = {
                        user = volume.source.ensureSource.user;
                        group = volume.source.ensureSource.group;
                        mode = volume.source.ensureSource.mode;
                    };
                };
            };
        }) (filterAttrs (_: vol: vol.volume.source.ensureSource.enable) volumes);
    };
}
