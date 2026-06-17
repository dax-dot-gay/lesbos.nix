{
    config,
    lib,
    pkgs,
    ...
}:
with lib;
let
    cfg = config.lesbos.base.ssh;
in
{
    options = {
        lesbos.base.ssh = {
            enable = mkEnableOption "ssh server";
            clientOnly = mkOption {
                description = "Whether to only enable the ssh client";
                type = types.bool;
                default = cfg.enable;
            };
            public_keys = mkOption {
                description = "Default public keys to set for users";
                type = types.listOf types.str;
                default = [
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAboVZPRR/NJirG0zeB3SBdOYzJ1n3/kYKKRDGu3wq dax@dax.gay"
                ];
            };
            allow_root = mkOption {
                description = "Allow root to login";
                type = types.bool;
                default = false;
            };
        };
    };

    config = {
        services.openssh = mkIf cfg.enable {
            enable = true;
            ports = [ 22 ];
            allowSFTP = true;
            openFirewall = true;
            settings = {
                PermitRootLogin = if cfg.allow_root then "prohibit-password" else "no";
                PasswordAuthentication = false;
                UseDns = true;
            };
        };
        programs.ssh = mkIf (cfg.enable || cfg.clientOnly) {
            startAgent = true;
        };
        environment.systemPackages = mkIf (cfg.enable || cfg.clientOnly) [ pkgs.openssh ];
    };
}
