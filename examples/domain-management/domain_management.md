# Domain management

This use case shows how the Amazon SimpleDB API can be used to manage domains — the containers that hold items in
SimpleDB. The example creates a domain, reads back its metadata to confirm it is empty, lists the domains in the
account, and finally deletes it.

Both `createDomain` and `deleteDomain` are idempotent, so the example can be run repeatedly without special handling.

## Prerequisites

### 1. Setup AWS account

Refer to the [Setup guide](https://github.com/ballerina-platform/module-ballerinax-aws.simpledb/blob/main/README.md#setup-guide)
to obtain the necessary credentials (access key ID, secret access key, region).

The IAM user needs `sdb:CreateDomain`, `sdb:DomainMetadata`, `sdb:ListDomains`, and `sdb:DeleteDomain`.

### 2. Configuration

Create a `Config.toml` file in the example's root directory and provide your AWS account related configurations as
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
