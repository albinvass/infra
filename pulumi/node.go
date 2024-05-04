package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	"github.com/pulumi/pulumi-cloudflare/sdk/v5/go/cloudflare"
	"github.com/pulumi/pulumi-hcloud/sdk/go/hcloud"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi/config"
)

type ServerConfig struct {
	Enabled    bool
	Image      string
	ServerType string
	Location   string
}

var ServerDefaultConfig = ServerConfig{
	Enabled:  true,
	Image:    "ubuntu-22.04",
	Location: "hel1",
}

type VolumeConfig struct {
	Size   uint
	Format string
}

var VolumeDefaultConfig = VolumeConfig{
	Size:   0,
	Format: "ext4",
}

type Tunnel struct {
	Ingress map[string]string
}

type TunnelToken struct {
	AccountTag   string
	TunnelSecret string
	TunnelID     string
}

type RawTunnelToken struct {
	A   string
	S string
	T     string
}

type Node struct {
	Name    string
	Server  ServerConfig
	Volume  VolumeConfig
	Tunnels map[string]Tunnel
}

var NodeDefaults = Node{
	Server: ServerDefaultConfig,
	Volume: VolumeDefaultConfig,
}

func (n *Node) Provision(ctx *pulumi.Context, zone *cloudflare.Zone) error {
	var (
		server *hcloud.Server
		err    error
	)

	if n.Server.Enabled {
		server, err = n.provisionServer(ctx)
		if err != nil {
			return err
		}
	}

	if n.Volume.Size > 0 {
		n.provisionVolume(ctx, server)
	}

	if server != nil {
		if err := n.provisionHostRecord(ctx, server, zone); err != nil {
			return err
		}
	}

	if n.Tunnels != nil {
		if err := n.provisionTunnels(ctx, zone); err != nil {
			return err
		}
	}

	return nil
}

func (n *Node) provisionServer(ctx *pulumi.Context) (*hcloud.Server, error) {
	serverArgs := hcloud.ServerArgs{
		ServerType: pulumi.String(n.Server.ServerType),
		Image:      pulumi.String(n.Server.Image),
		Location:   pulumi.String(n.Server.Location),
	}
	server, err := hcloud.NewServer(
		ctx,
		n.Name,
		&serverArgs,
	)
	if err != nil {
		return nil, fmt.Errorf("<%s> failed to provision server: %v", n.Name, err)
	}
	return server, nil
}

func (n *Node) provisionVolume(ctx *pulumi.Context, server *hcloud.Server) error {
	volumeArgs := &hcloud.VolumeArgs{
		Automount:        pulumi.Bool(false),
		DeleteProtection: pulumi.Bool(true),
		Size:             pulumi.Int(n.Volume.Size),
		Format:           pulumi.String(n.Volume.Format),
	}

	if server != nil {
		// See: https://github.com/pulumi/pulumi-hcloud/issues/52
		volumeArgs.ServerId = server.ID().ApplyT(strconv.Atoi).(pulumi.IntOutput)
	}

	_, err := hcloud.NewVolume(
		ctx,
		n.Name,
		volumeArgs,
	)
	if err != nil {
		return fmt.Errorf("<%s> failed to provision volume: %v", n.Name, err)
	}
	return nil
}

func (n *Node) provisionHostRecord(ctx *pulumi.Context, server *hcloud.Server, zone *cloudflare.Zone) error {
	zone.Zone.ApplyT(func(zoneName string) error {
		recordArgs := &cloudflare.RecordArgs{
			Name:    pulumi.String(n.Name),
			Type:    pulumi.String("A"),
			Proxied: pulumi.Bool(false),
			Value:   server.Ipv4Address,
			ZoneId:  zone.ID(),
		}
		_, err := cloudflare.NewRecord(
			ctx,
			n.Name,
			recordArgs,
		)
		if err != nil {
			return fmt.Errorf("failed to create record: %v", err)
		}
		return nil
	})
	return nil
}

func (n *Node) provisionTunnels(ctx *pulumi.Context, zone *cloudflare.Zone) error {
	cfg := config.New(ctx, "")
	for tunnelName, tunnelConfig := range n.Tunnels {
		tunnel, err := cloudflare.NewTunnel(
			ctx,
			tunnelName,
			&cloudflare.TunnelArgs{
				AccountId: zone.AccountId,
				ConfigSrc: pulumi.String("local"),
				Name:      pulumi.String(tunnelName),
				Secret:    cfg.RequireSecret(fmt.Sprintf("tunnel-%s-secret", tunnelName)),
			},
		)
		if err != nil {
			return fmt.Errorf("failed to create tunnel: %v", err)
		}

		tunnelToken := tunnel.TunnelToken.ApplyT(func(token string) TunnelToken {
			data, err := base64.StdEncoding.DecodeString(token)
			if err != nil {
				panic(err)
			}

			rawTunnelToken := RawTunnelToken{}
			err = json.Unmarshal(data, &rawTunnelToken)
			if err != nil {
				panic(err)
			}

			return TunnelToken{
                AccountTag: rawTunnelToken.A,
                TunnelSecret: rawTunnelToken.S,
                TunnelID: rawTunnelToken.T,
            }
		})

		ctx.Export(fmt.Sprintf("%s-tunnel-credentials", tunnelName), pulumi.JSONMarshal(tunnelToken))

		zone.Zone.ApplyT(func(zoneName string) error {
			for ingressName := range tunnelConfig.Ingress {
				var recordName string
				if ingressName != zoneName {
					recordName = strings.TrimPrefix(ingressName, fmt.Sprintf(".%s", zoneName))
				} else {
					recordName = "@"
				}

				_, err := cloudflare.NewRecord(
					ctx,
					ingressName,
					&cloudflare.RecordArgs{
						Name:    pulumi.String(recordName),
						Type:    pulumi.String("CNAME"),
						Proxied: pulumi.Bool(true),
						Value:   tunnel.Cname,
						ZoneId:  zone.ID(),
					},
				)
				if err != nil {
					return err
				}
			}
			return nil
		})
	}
	return nil
}
