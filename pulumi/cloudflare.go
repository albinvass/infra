package main

import (
	"fmt"

	"github.com/pulumi/pulumi-cloudflare/sdk/v5/go/cloudflare"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

type Cloudflare struct {
	Account *cloudflare.GetAccountsAccount
	Zones   map[string]*cloudflare.Zone
}

func CloudflareInit(ctx *pulumi.Context) (*Cloudflare, error) {
	var err error
	accounts, err := cloudflare.GetAccounts(
		ctx,
		&cloudflare.GetAccountsArgs{
			Name: pulumi.StringRef("Albin Vass"),
		},
	)
	if err != nil {
		return &Cloudflare{}, fmt.Errorf("failed to get account: %v", err)
	} else if len(accounts.Accounts) == 0 {
		return &Cloudflare{}, fmt.Errorf("no accounts found")
	} else if len(accounts.Accounts) > 1 {
		return &Cloudflare{}, fmt.Errorf("too many accounts found")
	}

	account := &accounts.Accounts[0]

	defaults := cloudflare.ZoneArgs{
		AccountId: pulumi.String(*account.Id),
		Plan:      pulumi.String("free"),
	}

	allZoneArgs := map[string]cloudflare.ZoneArgs{
		"albinvass.se":  defaults,
		"albinvass.com": defaults,
		"vassast.org":   defaults,
	}

	zones := make(map[string]*cloudflare.Zone, len(allZoneArgs))

	for name, zoneArgs := range allZoneArgs {
		args := zoneArgs
		args.Zone = pulumi.String(name)
		zone, err := cloudflare.NewZone(ctx, name, &args)
		if err != nil {
			return &Cloudflare{}, fmt.Errorf("<%s> failed to create zone: %v", name, err)
		}
		zones[name] = zone
	}

	cloudflare := &Cloudflare{
		Account: &accounts.Accounts[0],
		Zones:   zones,
	}

	return cloudflare, err
}
