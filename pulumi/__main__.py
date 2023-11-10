"""A Python Pulumi program"""

import pulumi

import pulumi_hcloud as hcloud
import pulumi_cloudflare as cloudflare


def setup_hetzner():
    with open('nixos-anywhere/user-data.yaml', 'r') as f:
        nixos_anywhere_cloud_init = f.read()

    vm = hcloud.Server(
        "nixos-1",
        server_type="cpx21",
        image="ubuntu-22.04",
        location="hel1",
        user_data=nixos_anywhere_cloud_init,
    )



class CloudFlareZones():
    def __init__(self):
        self.account = cloudflare.get_accounts().accounts[0]

        self._setup_identity_providers()
        self._setup_zones()
        self._setup_access_apps()

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



def main():
    #hetzner_resources = setup_hetzner()

    CloudFlareZones()


if __name__ == "__main__":
    main()
