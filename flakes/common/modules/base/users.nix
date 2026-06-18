{ config, lib, ... }:
with lib;
let
    cfg = config.lesbos.base.users;
    userType = types.submodule {
        options = {
            enable = mkEnableOption ''
                Whether this user should be enabled

                Disabled users will still exist, but will not be able to login by any method
            '';
            ssh = {
                enable = mkEnableOption "Allow SSH login for this user";
                authorizedKeys = mkOption {
                    description = "SSH public keys allowed to login";
                    type = types.listOf types.str;
                    default = if config.lesbos.base.ssh.enable then config.lesbos.base.ssh.public_keys else [ ];
                };
            };
            password = {
                enable = mkEnableOption "Allow login with a password";
                hash = mkOption {
                    description = "Password hash";
                    type = types.str;
                };
            };
            groups = mkOption {
                description = "Extra groups to add";
                type = types.listOf types.str;
                default = [ ];
            };
            shell = mkOption {
                description = "Shell to use, or null for default";
                type = types.nullOr types.package;
                default = null;
            };
            sudo = mkEnableOption "Whether to enable sudo";
        };
    };
in
{
    options = {
        lesbos.base.users = {
            root = mkOption {
                description = "Configuration for the root user";
                type = userType;
                default = {
                    enable = false;
                };
            };
            users = mkOption {
                description = "Other users to create";
                type = types.attrsOf userType;
                default = { };
            };
        };
    };

    config = {
        users.users = mkMerge [
            (optionalAttrs cfg.root.enable {
                root = {
                    openssh.authorizedKeys.keys = mkIf (
                        cfg.root.ssh.enable && cfg.root.enable
                    ) cfg.root.ssh.authorizedKeys;
                    hashedPassword = mkIf (cfg.root.password.enable && cfg.root.enable) cfg.root.password.hash;
                    shell =
                        if (isNull cfg.root.shell) && cfg.root.enable then
                            config.users.defaultUserShell
                        else
                            cfg.root.shell;
                };
            })
            (mapAttrs (username: settings: {
                openssh.authorizedKeys.keys = mkIf (
                    settings.ssh.enable && settings.enable
                ) settings.ssh.authorizedKeys;
                hashedPassword = mkIf (settings.password.enable && settings.enable) settings.password.hash;
                shell = mkForce (
                    if settings.enable then
                        (if isNull settings.shell then config.users.defaultUserShell else settings.shell)
                    else
                        "/bin/nologin"
                );
                isNormalUser = true;
                extraGroups = settings.groups ++ (optional settings.sudo "wheel");
            }) cfg.users)
        ];
    };
}
