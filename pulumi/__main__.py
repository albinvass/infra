"""A Python Pulumi program"""

import pulumi

import pulumi_hcloud as hcloud
import pulumi_cloudflare as cloudflare
import pulumi_command

pulumi_config = pulumi.Config()


class Hetzner():
    def __init__(self):
        self._setup_servers()

    def _setup_servers(self):
        self.servers = {}
        with open('nixos-anywhere/user-data.yaml', 'r') as f:
            nixos_anywhere_cloud_init = f.read()

        self.servers["nixos-1"] = hcloud.Server(
            "nixos-1",
            server_type="cpx21",
            image="ubuntu-22.04",
            location="hel1",
            user_data=nixos_anywhere_cloud_init,
            ssh_keys=[hcloud.get_ssh_key(name="hetzner-ssh-key").id],
            #opts=pulumi.ResourceOptions(ignore_changes=["user_data"])
        )
        pulumi_command.remote.Command(
            "nixos-1-mount",
            create="nixos-generate-config --no-filesystems --root /mnt",
            connection=pulumi_command.remote.ConnectionArgs(
                host=self.servers["nixos-1"].ipv4_address,
                user="root",
            ),
        )
        pulumi_command.local.Command(
            "nixos-1-init",
            create=pulumi.Output.format(
                "nixos-anywhere-hetzner {0}",
                self.servers["nixos-1"].ipv4_address,
            )
        )

        pulumi.export("nixos-1", self.servers["nixos-1"].ipv4_address)


class CloudFlare():
    def __init__(self):
        self.account = cloudflare.get_accounts().accounts[0]

        self._setup_identity_providers()
        self._setup_zones()
        self._setup_access_apps()
        self._setup_tunnels()

    def _setup_identity_providers(self):
        self.idps = {}
        self.idps["pinlogin"] = cloudflare.AccessIdentityProvider(
            "pinlogin",
            account_id=self.account.id,
            name="",
            type="onetimepin",
        )

    def _setup_zones(self):
        self.zones = {}
        zone_configs = {
            "albinvass.se": {},
            "albinvass.com": {},
            "vassast.org": {},
        }
        defaults = {
            "account_id": self.account.id,
            "plan": "free",
        }

        for name, zone_config in zone_configs.items():
            config = defaults | zone_config
            config["zone"] = name
            self.zones[name] = cloudflare.Zone(name, **config)

    def _setup_access_apps(self):
        self.access_apps = {}
        app_configs = {
            "devbox": {
                "type": "self_hosted",
                "domain": "dev.albinvass.se",
                "http_only_cookie_attribute": True,
                "allowed_idps": [self.idps["pinlogin"].id],
                "enable_binding_cookie": True,
            }
        }
        for name, app_config in app_configs.items():
            self.access_apps[name] = cloudflare.AccessApplication(
                name,
                name=name,
                account_id=self.account.id,
                **app_config
            )

    def _setup_tunnels(self):
        self.tunnels = {}
        tunnel_configs = {
            "devbox": {
                "config_src": "local",
            }
        }
        defaults = {
            "account_id": self.account.id,
        }

        for name, tunnel_config in tunnel_configs.items():
            config = defaults | tunnel_config
            tunnel_secret_name = f"tunnel-{name}-secret"
            config["secret"] = pulumi_config.require_secret(tunnel_secret_name)
            self.tunnels[name] = cloudflare.Tunnel(
                name,
                name=name,
                **config,
            )
            pulumi.export(tunnel_secret_name, pulumi.Output.json_dumps({
                "TunnelSecret": config["secret"],
                "AccountTag": self.account.id,
                "TunnelID": self.tunnels[name].id,
            }))





def main():
    hz = Hetzner()
    cf = CloudFlare()


if __name__ == "__main__":
    main()
