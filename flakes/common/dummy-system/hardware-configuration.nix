{ lib, system, ... }:

{
    boot.loader.systemd-boot = {
        enable = true;
    };

    boot.loader.efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
    };

    boot.initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];

    fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        autoResize = true;
        fsType = "ext4";
    };

    fileSystems."/boot" = {
        device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
    };

    # reduce size of the VM
    services.fstrim = {
        enable = true;
        interval = "weekly";
    };

    nixpkgs.hostPlatform = lib.mkDefault system;
}
