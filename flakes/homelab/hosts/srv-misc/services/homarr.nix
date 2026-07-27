{ config, ... }:
{
    lesbos.secrets.system."homarr/key" = { };
    sops.templates."homarr.env" = {
        owner = "root";
        group = "root";
        mode = "0400";
        content = ''
            SECRET_ENCRYPTION_KEY=${config.sops.placeholder."homarr/key"}
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
        autoStart = true;
    };
    networking.firewall.allowedTCPPorts = [ 7575 ];
}
