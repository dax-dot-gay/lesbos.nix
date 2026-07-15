{ config, ... }:
{
    lesbos.secrets.system = {
        "resume/database/username" = { };
        "resume/database/password" = { };
        "resume/database/database" = { };
        "resume/auth/secret" = { };
    };

    sops.templates =
        let
            pl = config.sops.placeholder;
        in
        {
            "resume/app.env" = {
                owner = "root";
                group = "root";
                mode = "0444";
                content = ''
                    DATABASE_URL=postgresql://${pl."resume/database/username"}:${pl."resume/database/password"}@${config.lesbos.homelab.net.clients.sys-datastore.address}:5432/${pl."resume/database/database"}
                    AUTH_SECRET=${pl."resume/auth/secret"}
                '';
            };
        };

    virtualisation.oci-containers = {
        backend = "podman";
        containers = {
            resume-app = {
                serviceName = "resume-app";
                image = "amruthpillai/reactive-resume:latest";
                ports = [
                    "0.0.0.0:3000:3000"
                ];
                environmentFiles = [
                    config.sops.templates."resume/app.env".path
                ];
                environment = {
                    TZ = "America/New_York";
                    APP_URL = "https://resume.dax.gay";
                    FLAG_DISABLE_SIGNUPS = "true";
                };
                volumes = [
                    "/services/resume:/app/data"
                ];
                extraOptions = [
                    "--health-cmd='[\"CMD\", \"node\", \"-e\", \"fetch('http://127.0.0.1:3000/api/health').then((r) => { if (!r.ok) process.exit(1); }).catch(() => process.exit(1));\"]'"
                    "--health-interval=30s"
                    "--health-timeout=10s"
                    "--health-retries=3"
                    "--sdnotify=healthy"
                ];
            };
        };
    };
}
