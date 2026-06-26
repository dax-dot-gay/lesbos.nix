{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ./services ./options.nix ];

    # Parameters
    datastore = {
        postgres.users = {
            root = {
                clauses.superuser = true;
                clauses.login = true;
                ensureDatabase = true;
                authentication = {
                    source_type = "local";
                    auth_method = "trust";
                    database_access = "all";
                };
            };
            authelia = {
                clauses.login = true;
                ensureDatabase = true;
                authentication = {
                    source_type = "remote";
                    source_address = "192.168.64.14";
                    database_access = "sameuser";
                    auth_method = "password";
                    password = "SCRAM-SHA-256$4096:miP/9bCnD2KvyYCczOgddg==$r0J8Sebz8e3jtsz4lJ2H8wc/E0h12eb8w3dZ5uk9MNM=:nM86G4OcRJEiTuXCgjz7YzKIvSjlJvYKb+fdMce45m4=";
                };
            };
        };
    };

    lesbos = {
        info = {
            canonicalName = "sys-datastore";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
            resources = {
                cores = 6;
                memory = 8192;
            };
            start = {
                order = 2;
                delay_up = 10;
            };
            storage = {
                disk_size = "256G";
                virtiofs = [
                    {
                        name = "data";
                        mount = true;
                        id = "DATA";
                        expose_acl = true;
                        expose_xattr = true;
                    }
                ];
            };
            network.primary.bridge = "vmbr3";
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$34whXohIvUq1NgZ6YTpIg.$YOcuuiUVVQazVyidwpCSZ4Ui.sPT7l6V895PyI1r5S4";
                };
            };
            users = { };
        };
    };
}
