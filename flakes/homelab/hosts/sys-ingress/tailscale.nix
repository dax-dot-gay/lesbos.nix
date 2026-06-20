{ config, ... }:
{
    lesbos.secrets.system."tailscale-auth-key" = { };
    services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets."tailscale-auth-key".path;
        extraSetFlags = [ "--advertise-exit-node" ];
        disableTaildrop = true;
        useRoutingFeatures = "server";
    };
}
