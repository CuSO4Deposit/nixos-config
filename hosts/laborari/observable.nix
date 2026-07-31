{ ... }:
{
  age.secrets."observable-nginx.conf" = {
    file = ../../secrets/observable-nginx.conf.age;
    owner = "nginx";
    group = "nginx";
  };

  age.secrets."observable-htpasswd" = {
    file = ../../secrets/observable-htpasswd.age;
    owner = "nginx";
    group = "nginx";
  };
}
