{ config, pkgs, ... }:
{
  users.users = {
    annasavage = {
      isNormalUser = true;
      extraGroups = [ "libvirtd" ];
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOFQPx3v0jpbhPbeLwjzbrdVXJQjba7vB22RCJ8NUBfiZ9RDtL/buxD95+lUQewnC5GmHfbiUuaRExODeYAjBcX0Yqf5WlrqAAcuLKFm1D1gr2gP9+SFYdtG7iQUAVPptEgGhgfm0PGDDj3bu+2bKAlYW6B8hhN8aOoJ8UD6t6JEv1UZq64v1acvcNv3BQ+S0/vQI0W48AYknSj2j1JrqKDzxSPXpzLiy8iSLEAq0lcFsb6wPnZvyzt87Wp+jRd+NPCYzER+DLYI+U0LmZQg4H03qKC+2ZVFzyeiB8uG9X+4LLBUoSE9eMIb8h0jJ5/3BgWE83P5pJgLxgn4vEw6NtulzhxUyFOmvYGiayEbwHyflAYBGVNcUZlPTef+qVI/JTvLf327JQKNBgm6mkzgiSpU3wAZmyu/XhYWaXlPWYVs/ItkiTujcnP32oYbke66u70nRNky3fRhG6zCcOLGyS+Bil8OWxDTM/oKMEDEMbg7O4uVlQYgydPoh/YqqPFnc= savagea@pyxis" ];
    };

    danielbarterPhone = {
      isNormalUser = true;
      extraGroups = [ "libvirtd" "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCz2BYy9cwbZsAdNP3UI6Dwl7aP12gNm5PMFetuvf8EXd8LGpiI3FJkUi7KS9FwYuPIZHU/IrKZ4/O852uk0EvVZfG70BNdAbfc60sZswQCFuh8ugMGvVUzySqLVm7eTlWmDaDIvE/ITCKwfJt4uG974h7FQCRBDnOJbtpN5wuDvevrKuR9+1SsTY21egAKN9/qFjIaRtcE0hb4ogKmnYqJG9+Odiubg28VPa3JZZ7VFNBn+RqAnnKct8HrLnNFqeEuoR8tGvir1dljVmlLMpJPCF9FmL8JkLig++vM/7pw1HtGEv7FNXm8g4NznAoeU6iolIaw2R7B9F5HFL91Wx+5 phone" ];
  };


    danielbarter = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "audio" "adbusers" "libvirtd"];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./secrets/ssh/id_rsa.pub)
      ];
    };
  };

}
