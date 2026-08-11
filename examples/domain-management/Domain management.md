# Domain management

This use case shows how the Amazon SimpleDB API can be used to manage domains — the containers that hold items in
SimpleDB. The example creates a domain, reads back its metadata to confirm it is empty, lists the domains in the
account, and finally deletes it.

The listing step prints only the first page of domains. `listDomains` returns a `nextToken` when more pages remain, but
it does not currently accept one, so the example cannot request the pages that follow.

Each run creates its own domain, named `inventory-<uuid>`, and deletes only that domain when it finishes. Nothing that
already exists in the account is read or removed, so the example is safe to run repeatedly and against an account
holding real data.

## Prerequisites

- AWS Account with SimpleDB access
- AWS Access Key ID and Secret Access Key
- Ballerina Swan Lake 2201.12.0 or later

## Configuration

Create a `Config.toml` file in the example's root directory and provide your AWS account-related configurations as
follows:

```toml
accessKeyId = "<AWS_ACCESS_KEY_ID>"
secretAccessKey = "<AWS_SECRET_ACCESS_KEY>"
region = "us-east-1"
```

## Run the example

Execute the following command to run the example:

```bash
bal run
```
