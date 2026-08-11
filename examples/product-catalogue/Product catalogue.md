# Product catalogue

This use case shows how the Amazon SimpleDB API can be used to store and query item attributes. The example stores an
attribute on a product item, reads it back with a consistent read, finds the item again with a SQL-like `select`
expression, and then removes the attribute.

It illustrates the two properties that distinguish SimpleDB from a relational store: items are schemaless, so an item
is created by the first `putAttributes` call that names it and carries only the attributes it is given; and every
attribute value is indexed on write, so it is queryable without declaring an index.

## Prerequisites

### 1. Setup AWS account

Refer to the [Setup guide](https://github.com/ballerina-platform/module-ballerinax-aws.simpledb/blob/main/README.md#setup-guide)
to obtain the necessary credentials (access key ID, secret access key, region).

The IAM user needs `sdb:CreateDomain`, `sdb:PutAttributes`, `sdb:GetAttributes`, `sdb:Select`, and
`sdb:DeleteAttributes`.

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
