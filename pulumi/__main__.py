"""A Python Pulumi program"""


import base64
import json
import pulumi
import pulumi_hcloud as hcloud
import pulumi_cloudflare as cloudflare
import pulumi_command

pulumi_config = pulumi.Config()


class Hetzner():
    def __init__(self):
        self.servers = {}
        self.volumes = {}
        self._setup_servers()

    def _setup_servers(self):
        with open('nixos-anywhere/user-data.yaml', 'r') as f:
            nixos_anywhere_cloud_init = f.read()

        self.servers["nixos-1"] = hcloud.Server(
            "nixos-1",
            server_type="cpx21",
            image="ubuntu-22.04",
            location="hel1",
            user_data=nixos_anywhere_cloud_init,
            ssh_keys=[hcloud.get_ssh_key(name="hetzner-ssh-key").id],
            opts=pulumi.ResourceOptions(ignore_changes=["user_data"])
        )
        self.volumes["nixos-1-data"] = hcloud.Volume(
            "nixos-1-data",
            size=20,
            server_id = self.servers["nixos-1"].id,
            automount=False,
            format="ext4",
            delete_protection=True,
        )
        pulumi.export("nixos-1-ip", self.servers["nixos-1"].ipv4_address)
        #pulumi.export("nixos-1-data", self.volumes["nixos-1-data"].id)
        #sleep = pulumi_command.local.Command(
        #    "nixos-1-pre-generate-config-sleep",
        #    create="sleep 10",
        #    triggers=[self.servers["nixos-1"]],
        #    opts=pulumi.ResourceOptions(
        #        parent=self.servers["nixos-1"],
        #        depends_on=[self.servers["nixos-1"]]
        #    )
        #)
        #nixos_generate_config = pulumi_command.remote.Command(
        #    "nixos-1-generate-config",
        #    create="nixos-generate-config --no-filesystems --root /mnt",
        #    connection=pulumi_command.remote.ConnectionArgs(
        #        host=self.servers["nixos-1"].ipv4_address,
        #        user="root",
        #    ),
        #    triggers=[self.servers["nixos-1"]],
        #    opts=pulumi.ResourceOptions(
        #        parent=self.servers["nixos-1"],
        #        depends_on=[sleep],
        #    )
        #)


class CloudFlare():
    def __init__(self):
        self.records = {}
        self.access_apps = {}
        self.access_groups = {}
        self.account = cloudflare.get_accounts().accounts[0]

        self._setup_identity_providers()
        self._setup_zones()
        self._devbox_tunnel()

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

    def _devbox_tunnel(self):
        self.tunnels = {}
        devbox_tunnel_secret = pulumi_config.require_secret("tunnel-devbox-secret")
        self.tunnels["devbox"] = cloudflare.Tunnel(
            "devbox",
            account_id=self.account.id,
            name="devbox",
            secret=devbox_tunnel_secret,
            config_src="local",
        )

        def token_convert(token):
            token["AccountTag"] = token.pop("a")
            token["TunnelSecret"] = token.pop("s")
            token["TunnelID"] = token.pop("t")
            return token

        token = pulumi.Output.json_loads(self.tunnels["devbox"].tunnel_token.apply(
            lambda token: base64.b64decode(token)
        )).apply(token_convert)
        pulumi.export("devbox-tunnel-credentials", pulumi.Output.json_dumps(token))

        self.records["code.albinvass.se"] = cloudflare.Record(
            "code.albinvass.se",
            name="code",
            type="CNAME",
            proxied=True,
            value=self.tunnels["devbox"].cname,
            zone_id=self.zones["albinvass.se"].id,
        )
        self.records["minio.albinvass.se"] = cloudflare.Record(
            "minio.albinvass.se",
            name="minio",
            type="CNAME",
            proxied=True,
            value=self.tunnels["devbox"].cname,
            zone_id=self.zones["albinvass.se"].id,
        )
        self.records["s3.albinvass.se"] = cloudflare.Record(
            "s3.albinvass.se",
            name="s3",
            type="CNAME",
            proxied=True,
            value=self.tunnels["devbox"].cname,
            zone_id=self.zones["albinvass.se"].id,
        )
        self.records["keycloak.albinvass.se"] = cloudflare.Record(
            "keycloak.albinvass.se",
            name="keycloak",
            type="CNAME",
            proxied=True,
            value=self.tunnels["devbox"].cname,
            zone_id=self.zones["albinvass.se"].id,
        )
        self.records["matrix.albinvass.se"] = cloudflare.Record(
            "matrix.albinvass.se",
            name="matrix",
            type="CNAME",
            proxied=True,
            value=self.tunnels["devbox"].cname,
            zone_id=self.zones["albinvass.se"].id,
        )
        self.records["vault.albinvass.se"] = cloudflare.Record(
            "vault.albinvass.se",
            name="vault",
            type="CNAME",
            proxied=True,
            value=self.tunnels["devbox"].cname,
            zone_id=self.zones["albinvass.se"].id,
        )
        self.access_apps["devbox"] = cloudflare.AccessApplication(
            "devbox",
            name="devbox",
            account_id=self.account.id,
            type="self_hosted",
            domain="code.albinvass.se",
            http_only_cookie_attribute=True,
            allowed_idps=[self.idps["pinlogin"].id],
            enable_binding_cookie=True,
        )

        self.access_groups["admins"] = cloudflare.AccessGroup(
            "admins",
            name="admins",
            account_id=self.account.id,
            includes=[cloudflare.AccessGroupIncludeArgs(
                emails=["albin.vass@gmail.com"],
            )],
        )

        cloudflare.AccessPolicy(
            "devbox_allow_admins",
            account_id=self.account.id,
            application_id=self.access_apps["devbox"].id,
            name="admins",
            precedence=1,
            decision="allow",
            includes=[cloudflare.AccessPolicyIncludeArgs(
                groups=[self.access_groups["admins"].id],
            )],
        )


def main():
    hz = Hetzner()
    cf = CloudFlare()


if __name__ == "__main__":
    main()
