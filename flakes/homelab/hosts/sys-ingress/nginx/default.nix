{ ... }:
let
    preflight = import ./preflight.nix;
in
{
    imports = [
        ./services
    ];
    security.acme = {
        acceptTerms = true;
        defaults.email = "me@dax.gay";
    };
    services.nginx = {
        enable = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        # Only allow PFS-enabled ciphers with AES256
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

        appendHttpConfig = ''
            # Add HSTS header with preloading to HTTPS requests.
            # Adding this header to HTTP requests is discouraged
            map $scheme $hsts_header {
                https   "max-age=31536000; includeSubdomains; preload";
            }
            add_header Strict-Transport-Security $hsts_header;

            proxy_hide_header Access-Control-Allow-Origin;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;

            map $http_origin $allowed_origin {
                default "";  # Block invalid origins
                ~^(https?):\/\/([a-zA-Z0-9-]+\.)*dax\.gay(:\d+)?$ $http_origin;  # Allow valid origins
            }

            add_header 'Access-Control-Allow-Origin' '*' always;
            proxy_buffers 8 512k;
            proxy_buffer_size 256k;
            proxy_busy_buffers_size 512k;
            large_client_header_buffers 8 256k;
        '';
    };
}
