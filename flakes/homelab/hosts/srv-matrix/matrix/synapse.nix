{ config, ... }:
{
    services.matrix-synapse = {
        enable = true;
        extraConfigFiles = [ "${config.sops.secrets."matrix/synapse.yaml".path}" ];
        settings.server_name = "dax.gay";
        settings.public_baseurl = "https://matrix.dax.gay";
        settings.listeners = [
            {
                port = 8008;
                bind_addresses = [
                    "0.0.0.0"
                    "::1"
                ];
                type = "http";
                tls = false;
                x_forwarded = true;
                resources = [
                    {
                        names = [
                            "client"
                            "federation"
                        ];
                        compress = true;
                    }
                ];
            }
        ];
        settings.trusted_key_servers = [
            {
                server_name = "matrix.org";
            }
            {
                server_name = "mozilla.org";
            }
        ];
        settings.experimental_features = {
            msc3266_enabled = true;
            msc4222_enabled = true;
            msc4140_enabled = true;
            msc2965_enabled = true;
        };
        settings.max_event_delay_duration = "24h";
        settings.auto_join_rooms = [
            "#cat-tower:dax.gay"
            "#cat-tower-general-room:dax.gay"
            "#cat-tower-verification-room:dax.gay"
        ];
        settings.room_list_publication_rules = [
            {
                user_id = "*:dax.gay";
                action = "allow";
            }
            {
                user_id = "@asterisms_apsis:matrix.org";
                action = "allow";
            }
        ];
        settings.app_service_config_files = [
            config.sops.secrets."hookshot/registration.yml".path
        ];
    };
    lesbos.volumes = {
        matrix-media = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/systems/srv-matrix/media";
                ensureSource.enable = true;         
            };
            destination = "/var/lib/matrix-synapse";
            strategy.bindMapped = {
                enable = true;
                permissions = "0700";
                user = "matrix-synapse";
                group = "matrix-synapse";
            };
            required_by = ["matrix-synapse.service"];
        };
    };
}
