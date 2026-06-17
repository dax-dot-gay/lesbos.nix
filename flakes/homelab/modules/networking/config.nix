{ config, lib, ... }:
with lib;
let
    cfg = config.lesbos.homelab.net;
in
{
    config = {#mkIf (!config.nixos-utilities.systems.router.enable) {
        
    };
}
