{ config, lib, ... }:
with lib;
let
    cfg = config.lesbos.reboot;
in
{
    options = {
        lesbos.reboot = {
            enable = mkEnableOption "automatic timed reboot";
            calendar = mkOption {
                description = "Value for OnCalendar";
                type = types.str;
                default = "*-*-* 03:00:00";
            };
            randomDelay = mkOption {
                description = "Value for RandomizedDelaySec";
                type = types.str;
                default = "1m";
            };
        };
    };

    config = mkIf cfg.enable {
        systemd.services.lesbos-reboot = {
            script = ''
                #bash
                               echo "Rebooting automatically..."
                               systemctl reboot
            '';
            serviceConfig = {
                Type = "oneshot";
                User = "root";
            };
        };
        systemd.timers.lesbos-reboot = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = cfg.calendar;
                RandomizedDelaySec = cfg.randomDelay;
                Unit = "lesbos-reboot.service";
                Persistent = true;
            };
        };
    };
}
