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
        systemd.tmpfiles.rules = mapAttrsToList (
            _: volume:
            "d ${vol.volume.sourcePath} ${vol.volume.source.ensureSource.mode} ${vol.volume.source.ensureSource.user} ${vol.volume.source.ensureSource.group} - -"
        ) (filterAttrs (_: vol: vol.volume.source.ensureSource.enable) volumes);
    };
}
