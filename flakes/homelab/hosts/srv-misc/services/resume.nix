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
                    DATABASE_URL=postgresql://${pl."resume/database/username"}:${pl."resume/database/password"}@host.containers.internal:15432/${pl."resume/database/database"}
                    AUTH_SECRET=${pl."resume/auth/secret"}
                '';
            };
            "resume/postgres.env" = {
                owner = "root";
                group = "root";
                mode = "0444";
                content = ''
                    POSTGRES_DB=${pl."resume/database/database"}
                    POSTGRES_USER=${pl."resume/database/username"}
                    POSTGRES_PASSWORD=${pl."resume/database/password"}
                '';
            };
        };

    virtualisation.oci-containers = {
        backend = "podman";
        containers = {
            resume-postgres = {
                serviceName = "resume-postgres";
                image = "postgres:latest";
                environmentFiles = [ config.sops.templates."resume/postgres.env".path ];
                ports = [
                    "localhost:15432:5432"
                ];
                volumes = [
                    "/services/resume/postgres:/var/lib/postgresql"
                ];
                extraOptions = [
                    "--health-cmd='[\"CMD-SHELL\", \"pg_isready -U postgres -d postgres\"]'"
                    "--health-interval=10s"
                    "--health-timeout=5s"
                    "--health-retries=10"
                    "--sdnotify=healthy"
                ];
            };
            resume-app = {
                serviceName = "resume-app";
                dependsOn = [ "resume-postgres" ];
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
                    FLAG_DISABLE_SIGNUPS = "false";
                };
                volumes = [
                    "/services/resume/app:/app/data"
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
