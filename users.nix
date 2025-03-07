{ config, pkgs, ... }:
{
  users.users = {
    annasavage = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOFQPx3v0jpbhPbeLwjzbrdVXJQjba7vB22RCJ8NUBfiZ9RDtL/buxD95+lUQewnC5GmHfbiUuaRExODeYAjBcX0Yqf5WlrqAAcuLKFm1D1gr2gP9+SFYdtG7iQUAVPptEgGhgfm0PGDDj3bu+2bKAlYW6B8hhN8aOoJ8UD6t6JEv1UZq64v1acvcNv3BQ+S0/vQI0W48AYknSj2j1JrqKDzxSPXpzLiy8iSLEAq0lcFsb6wPnZvyzt87Wp+jRd+NPCYzER+DLYI+U0LmZQg4H03qKC+2ZVFzyeiB8uG9X+4LLBUoSE9eMIb8h0jJ5/3BgWE83P5pJgLxgn4vEw6NtulzhxUyFOmvYGiayEbwHyflAYBGVNcUZlPTef+qVI/JTvLf327JQKNBgm6mkzgiSpU3wAZmyu/XhYWaXlPWYVs/ItkiTujcnP32oYbke66u70nRNky3fRhG6zCcOLGyS+Bil8OWxDTM/oKMEDEMbg7O4uVlQYgydPoh/YqqPFnc= savagea@pyxis"
      ];
    };

    root = {
      extraGroups = [ "wheel" ];
    };

    danielbarter = {

      # creates /var/lib/systemd/linger/danielbarter
      linger = true;
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "audio"
      ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ./public/ssh/id_rsa.pub)

        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDVf4aFiu/viLpvGoOTogDVAHhO/OnLbxMGoHog9h0TWUlKrofH4OCD2pNYSDt3nUNXqxK55rhr5zgLgI/rhH4PNMJYWo2coiS5NoLXk9QQeY0CJExgMylR2euD8LlzYXlvfqmm5Cj3yiyGcqISL/a8H8OAPQFCTuPr/Pw1q4mC77eV1LSKUhBc0zmIxx5HARr5933T0HosGqDPC1o0ukpMjCvh1IBXdJVw0tJa5cn0nGgii8xMJtotnK18Ka7eGHJzUAXGOnX8/u3tNrGCjje/8TiVXGxjb9behSXjOJV8N+veKvFuMU8hC/3Zpo46wu9V3/va0fmVvIVx4T+PfD2pdpohTVre6ypzh6ZYqco/WF26sdEY28H8E06R4zyIsvC1ZIrp05u+STfLTOQP24o4jzdtVexJa6lETpMEEMSPsvWf1p57lGYGQ7dPaQTYgez4oVpZ5QZNJtixS+AGQQ5FruhUMTfQkA2Ce6fCB9OmkPV3qUtYkh+tUNndqwqlU6muZWnJjU1UC5m0Mu2m/Mw+UXbve0IK2KOemXDCAmklE3rOQOZEtDqPm9HribZcxi+E/NmWgbD09alq9I/ht1UCkLjL5X+R2OC2TIKGxP6JzCVvsDZ+45lYrjWNDUeMfEds2IjqBPnOB1Tg8jqBswdAPna/y9k5K5eUpgee+KzTQ== phone"
      ];
    };
  };
}
