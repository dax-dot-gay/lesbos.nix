{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [
        ./provision-secrets.nix
    ];

    lesbos = {
        info = {
            canonicalName = "{{a_hostname}}";
            flake = "{{a_flake}}";
            stateVersion = "{{a_state_version}}";
            runningVersion = "{{a_state_version}}";
        };
        proxmox = {
            enable = true;
        };
        base.users = {
@root            root = {
@root                enable = {{a_enable_root}};
@root                ssh.enable = true;
@root                password = {
@root                    enable = true;
@root                    hash = "{{root_passhash}}";
@root                };
@root            };
            
            users = {
@user                "{{a_user_name}}" = {
@user                    enable = true;
@user                    ssh.enable = true;
@user                    password = {
@user                        enable = true;
@user                        hash = "{{user_passhash}}";
@user                    };
@user                    sudo = {{a_user_wheel}};
@user                };
            };
        };
    };
}
