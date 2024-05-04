package main

import (
	"encoding/json"
	"fmt"

	command "github.com/pulumi/pulumi-command/sdk/go/command/local"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func getNodes(ctx *pulumi.Context) ([]*Node, error) {
	result, err := command.Run(
		ctx,
		&command.RunArgs{
			Command: "colmena-expression pulumiConfigs",
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get nodes from flake.nix: %v", err)
	}

    allJson := []json.RawMessage{}
	err = json.Unmarshal([]byte(result.Stdout), &allJson)
	if err != nil {
		return nil, fmt.Errorf(
			"failed to unmarshal nodes: %v, error: %v",
			result.Stdout,
			err,
		)
	}

    nodes := make([]*Node, len(allJson))
    for i, v := range allJson {
        node := NodeDefaults
        nodes[i] = &node
        err = json.Unmarshal(v, nodes[i])
        if err != nil {
            return nil, fmt.Errorf("failed to unmarshal node: %v", err)
        }
    }

	return nodes, err
}

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
        cf, err := CloudflareInit(ctx)
        if err != nil {
            return fmt.Errorf("failed to provision cloudflare: %v", err)
        }

		nodes, err := getNodes(ctx)
		if err != nil {
			return err
		}
		for _, node := range nodes {
			ctx.Log.Debug(fmt.Sprintf("provisioning: %s", node.Name), nil)
            err := node.Provision(ctx, cf.Zones["albinvass.se"])
			if err != nil {
				return fmt.Errorf("failed to provision node %s: %v", node.Name, err)
			}
		}
		return nil
	})
}
