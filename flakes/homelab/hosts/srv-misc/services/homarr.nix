{ config, ... }:
{
    lesbos.secrets.system = {
        "homarr/key" = { };
        "homarr/oidc/client_id" = { };
        "homarr/oidc/client_secret" = { };
    };
    sops.templates."homarr.env" = {
        owner = "root";
        group = "root";
        mode = "0400";
        content = ''
            SECRET_ENCRYPTION_KEY=${config.sops.placeholder."homarr/key"}
            AUTH_OIDC_CLIENT_ID=${config.sops.placeholder."homarr/oidc/client_id"}
            AUTH_OIDC_CLIENT_SECRET=${config.sops.placeholder."homarr/oidc/client_secret"}
        '';
    };
    virtualisation.oci-containers.containers.homarr = {
        serviceName = "homarr";
        image = "ghcr.io/homarr-labs/homarr:latest";
        volumes = [
            "/services/homarr:/appdata"
        ];
        ports = [
            "0.0.0.0:7575:7575"
        ];
        environmentFiles = [ config.sops.templates."homarr.env".path ];
        environment = {
            BASE_URL = "https://home.dax.gay";
            NEXTAUTH_URL = "https://home.dax.gay";
            AUTH_PROVIDERS = "oidc,credentials";
            AUTH_OIDC_ISSUER = "https://auth.dax.gay/application/o/homarr/";
            AUTH_OIDC_URI = "https://auth.dax.gay/application/o/authorize/";
            AUTH_OIDC_CLIENT_NAME = "Lesbos SSO";
            AUTH_OIDC_SCOPE_OVERWRITE = "openid email profile all-groups";
            AUTH_OIDC_GROUPS_ATTRIBUTE = "all-groups";
            AUTH_LOGOUT_REDIRECT_URL = "https://auth.dax.gay/application/o/homarr/end-session/";
            AUTH_OIDC_AUTO_LOGIN = "false";
            LOG_LEVEL = "debug";
        };
        autoStart = true;
    };
    networking.firewall.allowedTCPPorts = [ 7575 ];
}
