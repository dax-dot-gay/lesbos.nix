{ lib, config, ... }:
with lib;
let
    cfg = config.lesbos.info;
in
{
    options = {
        lesbos.info = {
            canonicalName = mkOption {
                description = ''
                    The canonical, definitely 100% name that this machine can be referred to as.
                    This should follow standard hostname rules.
                    It *does* define the following:

                    - Machine hostname
                    - Folder within <flake>/hosts where this configuration is stored
                    - What per-system folder to source secrets from
                    - Auto-upgrade hostname

                    If automatically generated with `doohickey`, this will match:

                    - Proxmox VM name, if this is a VM
                    - The flake output name (REQUIRED TO MATCH THIS ANYWAY)
                '';
                type = types.singleLineStr;
            };
            flake = mkOption {
                description = "Which flake this machine is part of";
                type = types.singleLineStr;
            };
            stateVersion = mkOption {
                description = "Value of `system.stateVersion` (sets `system.stateVersion` automatically)";
                type = types.singleLineStr;
            };
            runningVersion = mkOption {
                description = "The nixpkgs version this system is actually running";
                type = types.singleLineStr;
            };
        };
    };

    config = {
        networking.hostName = mkForce cfg.canonicalName;
        system.stateVersion = cfg.stateVersion;
    };
}
