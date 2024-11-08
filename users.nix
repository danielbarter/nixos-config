{ config, pkgs, ... }:
{
  users.users = {
    annasavage = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOFQPx3v0jpbhPbeLwjzbrdVXJQjba7vB22RCJ8NUBfiZ9RDtL/buxD95+lUQewnC5GmHfbiUuaRExODeYAjBcX0Yqf5WlrqAAcuLKFm1D1gr2gP9+SFYdtG7iQUAVPptEgGhgfm0PGDDj3bu+2bKAlYW6B8hhN8aOoJ8UD6t6JEv1UZq64v1acvcNv3BQ+S0/vQI0W48AYknSj2j1JrqKDzxSPXpzLiy8iSLEAq0lcFsb6wPnZvyzt87Wp+jRd+NPCYzER+DLYI+U0LmZQg4H03qKC+2ZVFzyeiB8uG9X+4LLBUoSE9eMIb8h0jJ5/3BgWE83P5pJgLxgn4vEw6NtulzhxUyFOmvYGiayEbwHyflAYBGVNcUZlPTef+qVI/JTvLf327JQKNBgm6mkzgiSpU3wAZmyu/XhYWaXlPWYVs/ItkiTujcnP32oYbke66u70nRNky3fRhG6zCcOLGyS+Bil8OWxDTM/oKMEDEMbg7O4uVlQYgydPoh/YqqPFnc= savagea@pyxis"
      ];
    };

    danielbarter = {

      # creates /var/lib/systemd/linger/danielbarter
      linger = true;
      isNormalUser = true;
      extraGroups = [
        "video"
        "audio"
      ];
      openssh.authorizedKeys.keys = [ (builtins.readFile ./public/ssh/id_rsa.pub) ];
    };
  };
}
