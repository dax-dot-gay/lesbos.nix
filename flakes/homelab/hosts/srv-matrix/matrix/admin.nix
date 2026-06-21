{ ... }:
{
    virtualisation.oci-containers.containers.element-admin = {
        image = "oci.element.io/element-admin:latest";
        ports = [ "0.0.0.0:9080:8080" ];
        environment = {
            SERVER_NAME = "dax.gay";
        };
        autoStart = true;
    };
}
