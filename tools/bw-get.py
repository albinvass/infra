#!/bin/env python3

import sys
import shlex
import json
import argparse
import subprocess

def create_arg_parser():
    parser = argparse.ArgumentParser(
        description="Retrieve information from Bitwarden."
    )
    subparsers = parser.add_subparsers(
        dest="object",
        help="Specify the object type to retrieve."
    )

    username_parser = subparsers.add_parser(
        "username",
        help="Retrieve information about a username."
    )
    username_parser.add_argument(
        "name",
        help="Specify the name of the item."
    )

    field_parser = subparsers.add_parser(
        "field",
        help="Retrieve information about a field."
    )
    field_parser.add_argument(
        "name",
        help="Specify the name of the item."
    )
    field_parser.add_argument(
        "field_name",
        metavar='field-name',
        help="Specify the name of the field.",
    )

    attachment_parser = subparsers.add_parser(
        "attachment",
        help="Retrieve information about an attachment."
    )
    attachment_parser.add_argument(
        "name",
        help="Specify the name of the item."
    )
    attachment_parser.add_argument(
        "attachment_name",
        metavar='attachment-name',
        help="Specify the name of the attachment.",
    )

    return parser


def get_item(name):
    try:
        output = subprocess.check_output(
            shlex.split(f"bw get item '{name}'"),
            stderr=subprocess.STDOUT,
            encoding="utf-8",
        )
    except subprocess.CalledProcessError as e:
        print(e.output)
        sys.exit(1)

    return json.loads(output)


def get_username(name):
    return get_item(name)["login"]["username"]


def get_attachment(item_name, attachment_name):
    item_id = get_item(item_name)["id"]
    try:
        attachment = subprocess.check_output(
            shlex.split(f"bw get attachment '{attachment_name}' --itemid '{item_id}' --raw"),
            stderr=subprocess.DEVNULL,
            encoding="utf-8",
            )
    except subprocess.CalledProcessError:
        print(f"Attachment `{attachment_name}` not found.", file=sys.stderr)
        return None

    return attachment

def get_field(item_name, field_name):
    fields = get_item(item_name)["fields"]
    field = next((f for f in fields if f["name"] == field_name), None)
    if not field:
        print(f"Field `{field_name}` not found.", file=sys.stderr)
    return field["value"] if field else None

def main():
    parser = create_arg_parser()
    args = parser.parse_args()

    output = ""
    if args.object == "field":
        output = get_field(args.name, args.field_name)
    elif args.object == "attachment":
        output = get_attachment(args.name, args.attachment_name)
    elif args.object == "username":
        output = get_username(args.name)
    else:
        parser.print_help()
        return
    
    if output:
        print(output)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()

