{ lib, ... }:
with lib;
{
  options.systemd.services = mkOption {
    type = types.attrsOf (types.submodule ({ name, config, ... }: {
      options.vpnConfinement = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = mdDoc ''
            Whether to confine the systemd service in a
            networking namespace which routes traffic through a
            VPN tunnel and forces a specified DNS.
          '';
        };
        vpnNamespace = mkOption {
          type = types.str;
          default = null;
          example = "wg";
          description = mdDoc ''
            Name of the VPN networking namespace to
            use for the systemd service.
          '';
        };
      };

      imports = [
        (mkRenamedOptionModule [ "vpnconfinement" "enable" ] [ "vpnConfinement" "enable" ])
        (mkRenamedOptionModule [ "vpnconfinement" "vpnnamespace" ] [ "vpnConfinement" "vpnNamespace" ])
      ];

      config = let
        vpn = config.vpnConfinement.vpnNamespace;
      in mkIf config.vpnConfinement.enable {
        bindsTo = [ "${vpn}.service" ];
        after = [ "${vpn}.service" ];

        serviceConfig = {
          NetworkNamespacePath = "/var/run/netns/${vpn}";

          InaccessiblePaths = [
            "/var/run/nscd"
            "/var/run/resolvconf"
          ];

          BindReadOnlyPaths = [
            "/etc/netns/${vpn}/resolv.conf:/etc/resolv.conf:norbind"
          ];
        };
      };
    }));
  };
}
