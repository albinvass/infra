"""A Python Pulumi program"""


import base64
import json
import pulumi
import pulumi_hcloud as hcloud
import pulumi_cloudflare as cloudflare
import pulumi_command

pulumi_config = pulumi.Config()


class CloudFlare():
    def __init__(self):
        self.account = cloudflare.get_accounts().accounts[0]
        self._setup_zones()

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


class Node():
    def __init__(self, name, zone):
        self.name = name
        self.zone = zone
        self.loadNodeConfig()
        self.parseTags()
        self.vm()
        self.volume()
        self.hostRecord(zone)
        self.tunnels()

    def loadNodeConfig(self):
        self.node_config = json.loads(pulumi_command.local.run(
            command=f"colmena eval -E '{{ nodes, ... }}: nodes.{self.name}.config.deployment'",
        ).stdout)

    def parseTags(self):

        defaults = {
            "vm": {
                "image": "ubuntu-22.04",
                "location": "hel1",
            },
            "volume": {
                "size": 0,
                "format": "ext4",
            }
        }
        config_tags = [tag for tag in self.node_config["tags"] 
                       if tag.startswith("pulumi:")]
        config = {
            "vm": {},
            "volume": {}
        }

        for tag in config_tags:
            _, resource, attr, value = tag.split(":")
            if attr in config[resource]:
                raise Exception(f"pulumi:{resource}:{attr} is set multiple times.")
            else:
                if attr == "server_type":
                    self.arch = "x86_64" if attr.startswith("cpx") else "aarch64"
                config[resource][attr] = int(value) if value.isdigit() else value

        self.config = {}
        for key in defaults.keys():
            self.config[key] = defaults[key] | config[key]

    def vm(self):
        with open(f'nixos-anywhere/user-data-{self.arch}.yaml', 'r') as f:
            nixos_anywhere_cloud_init = f.read()

        self.vm = hcloud.Server(
            self.name,
            **self.config["vm"],
            user_data=nixos_anywhere_cloud_init,
            ssh_keys=[hcloud.get_ssh_key(name="hetzner-ssh-key").id],
            opts=pulumi.ResourceOptions(ignore_changes=["user_data"])
        )
        pulumi.export(f"{self.name}-ip", self.vm.ipv4_address)

    def volume(self):
        if self.config["volume"]["size"] > 0:
            self.volume = hcloud.Volume(
                f"{self.name}-data",
                **self.config["volume"],
                server_id = self.vm.id,
                automount=False,
                delete_protection=True,
            )

    def hostRecord(self, zone):
        self.hostRecord = cloudflare.Record(
            self.node_config["targetHost"],
            name=self.node_config["targetHost"].removesuffix(f".{self.zone.zone}"),
            type="A",
            proxied=False,
            value=self.vm.ipv4_address,
            zone_id=zone.id,
        )

    def tunnels(self):
        self.tunnels = {}

        def generate_cnames(tunnel, ingresses):
            records = {}
            for cname in ingresses:
                if cname != self.zone.zone:
                    record_name = cname.removesuffix(f".{self.zone.zone}")
                else:
                    record_name = "@"
                records[cname] = cloudflare.Record(
                    cname,
                    name=record_name,
                    type="CNAME",
                    proxied=True,
                    value=self.tunnels[tunnel].cname,
                    zone_id=self.zone.id,
                )
            return records

        cloudflare_tunnels = json.loads(pulumi_command.local.run(
            command=f"colmena eval -E '{{ nodes, ... }}: attrNames nodes.{self.name}.config.services.cloudflared.tunnels'",
        ).stdout)

        for tunnel in cloudflare_tunnels:
            tunnel_secret = pulumi_config.require_secret(f"tunnel-{tunnel}-secret")
            self.tunnels[tunnel] = cloudflare.Tunnel(
                tunnel,
                account_id=self.zone.account_id,
                name=tunnel,
                secret=tunnel_secret,
                config_src="local",
            )

            def token_convert(token):
                token["AccountTag"] = token.pop("a")
                token["TunnelSecret"] = token.pop("s")
                token["TunnelID"] = token.pop("t")
                return token

            token = pulumi.Output.json_loads(self.tunnels[tunnel].tunnel_token.apply(
                lambda token: base64.b64decode(token)
            )).apply(token_convert)

            pulumi.export(f"{tunnel}-tunnel-credentials", pulumi.Output.json_dumps(token))
            ingresses = json.loads(pulumi_command.local.run(
                command=f"colmena eval -E '{{ nodes, ... }}: attrNames nodes.{self.name}.config.services.cloudflared.tunnels.{tunnel}.ingress'",
            ).stdout)
            generate_cnames(tunnel, ingresses)



def main():
    cf = CloudFlare()

    nodes = json.loads(pulumi_command.local.run(
        command="colmena eval -E '{ nodes, ... }: attrNames nodes'",
    ).stdout)

    for node in nodes:
        Node(node, cf.zones["albinvass.se"])


if __name__ == "__main__":
    main()
