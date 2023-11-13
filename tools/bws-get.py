#!/bin/env python3

import sys
import shlex
import json
import argparse
import subprocess

def create_arg_parser():
    parser = argparse.ArgumentParser(
        description="Retrieve information from Bitwarden Secrets Manager."
    )
    parser.add_argument(
        "name",
        help="Specify the name of the item."
    )

    return parser


def command(cmd):
    try:
        output = subprocess.check_output(
            shlex.split(cmd),
            stderr=subprocess.STDOUT,
            encoding="utf-8",
        )
    except subprocess.CalledProcessError as e:
        print(e.output)
        sys.exit(1)
    return json.loads(output)

def list_secrets():
    return command("bws secret list")

def get_secret(name):
    secrets = list_secrets()
    try:
        return next((secret for secret in secrets if secret["key"] == name))["value"]
    except StopIteration:
        print("Secret not found.", file=sys.stderr)
        sys.exit(1)


def main():
    parser = create_arg_parser()
    args = parser.parse_args()
    print(get_secret(args.name))
    

if __name__ == "__main__":
    main()


