{ config, pkgs, ... }:
{
    environment.systemPackages = [ pkgs.matrix-authentication-service ];
    systemd.services.matrix-authentication-service = {
        enable = true;
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
        before = [ "matrix-synapse.service" ];
        requiredBy = [ "matrix-synapse.service" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [
            coreutils
            matrix-authentication-service
        ];
        script = ''
            mas-cli server --config ${config.sops.secrets."matrix/matrix-authentication/config.yaml".path}
        '';
        serviceConfig = {
            RemainAfterExit = "yes";
            User = "matrix-authentication-service";
        };
    };
}
