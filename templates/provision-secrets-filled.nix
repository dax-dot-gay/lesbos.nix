{ lib, ... }:
{
    environment.etc = {
        "provisioning/ssh/ssh_host_ecdsa_key" = {
            mode = "0600";
            source = ./.host-secrets/etc/ssh/ssh_host_ecdsa_key;
            user = "root";
            group = "root";
        };
        "provisioning/ssh/ssh_host_ecdsa_key.pub" = {
            mode = "0600";
            source = ./.host-secrets/etc/ssh/ssh_host_ecdsa_key.pub;
            user = "root";
            group = "root";
        };
        "provisioning/ssh/ssh_host_ed25519_key" = {
            mode = "0600";
            source = ./.host-secrets/etc/ssh/ssh_host_ed25519_key;
            user = "root";
            group = "root";
        };
        "provisioning/ssh/ssh_host_ed25519_key.pub" = {
            mode = "0600";
            source = ./.host-secrets/etc/ssh/ssh_host_ed25519_key.pub;
            user = "root";
            group = "root";
        };
        "provisioning/ssh/ssh_host_rsa_key" = {
            mode = "0600";
            source = ./.host-secrets/etc/ssh/ssh_host_rsa_key;
            user = "root";
            group = "root";
        };
        "provisioning/ssh/ssh_host_rsa_key.pub" = {
            mode = "0600";
            source = ./.host-secrets/etc/ssh/ssh_host_rsa_key.pub;
            user = "root";
            group = "root";
        };
    };
    system.activationScripts = {
        provisionHostKeys = {
            # Run after /dev has been mounted
            deps = [ "specialfs" ];
            text = ''
                cp /etc/provisioning/ssh/* /etc/ssh/
            '';
        };
        setupSecrets.deps = [ "provisionHostKeys" ];
        setupSecrets.text = lib.mkDefault "";
        setupSecretsForUsers.deps = [ "provisionHostKeys" ];
        setupSecretsForUsers.text = lib.mkDefault "";
    };
}
