{ ... }:
{
    lesbos.base.ssh = {
        enable = true;
        public_keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAiAboVZPRR/NJirG0zeB3SBdOYzJ1n3/kYKKRDGu3wq dax@dax.gay"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFsoY66q/ej1AfjYuJ1d2t7RWdKizRi2TCJ73vEP0iq root@lesbos.peer"
        ];
        allow_root = true;
    };
}
