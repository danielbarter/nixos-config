{
  pkgs,
  config,
  ...
}:

{

  # verbose systemd logging
  systemd.globalEnvironment = {
    SYSTEMD_LOG_LEVEL = "debug";
  };

  # store all debug symbols on dev machines
  environment.enableDebugInfo = config.dev-machine;

  # switch to doas instead of sudo
  security = {
    doas = {
      enable = true;
      extraRules = [
        {
          users = ["danielbarter"];
          keepEnv = true; # retain user environment variables
          persist = true; # only require password verification once
        }
      ];
    };
    sudo.enable = false;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    grub.enable = false;
    efi.canTouchEfiVariables = true;
  };

  # use systemd in stage 1. Easier to diagnose issues when they arise
  boot.initrd.systemd = {
    enable = true;
    emergencyAccess = true;
  };

  hardware.enableAllFirmware = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # List packages installed in system profile

  documentation = {
    dev.enable = true;
    enable = true;
    man.enable = true;
  };

  # RealtimeKit is a D-Bus system service that changes the scheduling
  # policy of user processes/threads to SCHED_RR (i.e. realtime scheduling
  # mode) on request. It is intended to be used as a secure mechanism to
  # allow real-time scheduling to be used by normal user processes.
  security.rtkit.enable = true;
  services.dbus.enable = true;

  # enable gpg
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  # allow processes to persist after logout
  services.logind.killUserProcesses = false;
}
