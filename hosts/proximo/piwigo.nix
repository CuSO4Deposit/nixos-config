{ config, pkgs, ... }:
{
  systemd.tmpfiles.rules = [
    "d /data/piwigo 0750 cuso4d users -"
    "d /data/piwigo/app 0750 cuso4d users -"
    "d /data/piwigo/scripts 0750 cuso4d users -"
  ];

  systemd.services.piwigo-mysql-setup = {
    description = "Create MariaDB database and user for Piwigo";
    after = [ "mysql.service" ];
    requires = [ "mysql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "mysql";
      Group = "mysql";
    };
    script = ''
      password="$(${pkgs.coreutils}/bin/cat ${config.age.secrets.piwigo-db-password.path})"
      case "$password" in
        *"'"*)
          echo "piwigo-db-password must not contain single quotes" >&2
          exit 1
          ;;
      esac

      ${pkgs.mariadb}/bin/mysql --batch <<SQL
      CREATE DATABASE IF NOT EXISTS piwigo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
      CREATE USER IF NOT EXISTS 'piwigo'@'%' IDENTIFIED BY '$password';
      ALTER USER 'piwigo'@'%' IDENTIFIED BY '$password';
      GRANT ALL PRIVILEGES ON piwigo.* TO 'piwigo'@'%';
      FLUSH PRIVILEGES;
      SQL
    '';
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.piwigo = {
      image = "piwigo/piwigo:latest";
      environment = {
        TZ = "Etc/UTC";
        PIWIGO_UID = "1000";
        PIWIGO_GID = "100";
      };
      ports = [
        "10.20.0.1:8080:80"
      ];
      volumes = [
        "/data/piwigo/app:/var/www/html/piwigo"
        "/data/piwigo/scripts:/usr/local/bin/scripts"
      ];
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
      ];
    };
  };

  systemd.services.docker-piwigo = {
    after = [ "piwigo-mysql-setup.service" ];
    requires = [ "piwigo-mysql-setup.service" ];
  };
}
