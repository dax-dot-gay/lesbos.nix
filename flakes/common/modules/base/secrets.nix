{ config, lib, ... }:
with lib;
let
    cfg = config.lesbos.secrets;
    secretType = types.submodule (
        { config, ... }:
        {
            options = {
                name = lib.mkOption {
                    type = lib.types.str;
                    default = config._module.args.name;
                    description = ''
                        Name of the file used in /run/secrets
                    '';
                };
                path = lib.mkOption {
                    type = lib.types.str;
                    default =
                        if config.neededForUsers then
                            "/run/secrets-for-users/${config.name}"
                        else
                            "/run/secrets/${config.name}";
                    defaultText = "/run/secrets-for-users/$name when neededForUsers is set, /run/secrets/$name when otherwise.";
                    description = ''
                        Path where secrets are symlinked to.
                        If the default is kept no symlink is created.
                    '';
                };
                format = lib.mkOption {
                    type = lib.types.enum [
                        "yaml"
                        "json"
                        "binary"
                        "dotenv"
                        "ini"
                    ];
                    default = cfg.defaultSopsFormat;
                    description = ''
                        File format used to decrypt the sops secret.
                        Binary files are written to the target file as is.
                    '';
                };
                mode = lib.mkOption {
                    type = lib.types.str;
                    default = "0400";
                    description = ''
                        Permissions mode of the in octal.
                    '';
                };
                owner = lib.mkOption {
                    type = with lib.types; nullOr str;
                    default = null;
                    description = ''
                        User of the file. Can only be set if uid is 0.
                    '';
                };
                uid = lib.mkOption {
                    type = with lib.types; nullOr int;
                    default = 0;
                    description = ''
                        UID of the file, only applied when owner is null. The UID will be applied even if the corresponding user doesn't exist.
                    '';
                };
                group = lib.mkOption {
                    type = with lib.types; nullOr str;
                    default = if config.owner != null then users.${config.owner}.group else null;
                    defaultText = lib.literalMD "{option}`config.users.users.\${owner}.group`";
                    description = ''
                        Group of the file. Can only be set if gid is 0.
                    '';
                };
                gid = lib.mkOption {
                    type = with lib.types; nullOr int;
                    default = 0;
                    description = ''
                        GID of the file, only applied when group is null. The GID will be applied even if the corresponding group doesn't exist.
                    '';
                };
                restartUnits = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    example = [ "sshd.service" ];
                    description = ''
                        Names of units that should be restarted when this secret changes.
                        This works the same way as <xref linkend="opt-systemd.services._name_.restartTriggers" />.
                    '';
                };
                reloadUnits = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    example = [ "sshd.service" ];
                    description = ''
                        Names of units that should be reloaded when this secret changes.
                        This works the same way as <xref linkend="opt-systemd.services._name_.reloadTriggers" />.
                    '';
                };
                neededForUsers = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = ''
                        Enabling this option causes the secret to be decrypted before users and groups are created.
                        This can be used to retrieve user's passwords from sops-nix.
                        Setting this option moves the secret to /run/secrets-for-users and disallows setting owner and group to anything else than root.
                    '';
                };
            };
        }
    );
in
{
    options = {
        lesbos.secrets = {
            global = mkOption {
                description = "Secrets sourced from secrets/global.yaml";
                type = types.attrsOf secretType;
                default = { };
            };
            flake = mkOption {
                description = "Secrets sourced from secrets/<flake>/global.yaml";
                type = types.attrsOf secretType;
                default = { };
            };
            system = mkOption {
                description = "Secrets sourced from secrets/<flake>/per-system/<name>/global.yaml";
                type = types.attrsOf secretType;
                default = { };
            };
        };
    };

    config.sops = {
        defaultSopsFormat = "yaml";
        defaultSopsFile = ../../../../secrets/global.yaml;
        secrets = mkMerge [
            (mapAttrs (
                name: secret:
                {
                    sopsFile = ../../../../secrets/global.yaml;
                }
                // secret
            ) cfg.global)
            (mapAttrs (
                name: secret:
                {
                    sopsFile = ../../../../secrets/${config.lesbos.info.flake}/global.yaml;
                }
                // secret
            ) cfg.flake)
            (mapAttrs (
                name: secret:
                {
                    sopsFile = ../../../../secrets/${config.lesbos.info.flake}/per-system/${config.lesbos.info.canonicalName}/system.yaml;
                }
                // secret
            ) cfg.global)
        ];
    };
}
