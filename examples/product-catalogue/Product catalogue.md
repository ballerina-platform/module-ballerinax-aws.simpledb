# Product catalogue

This use case shows how the Amazon SimpleDB API can be used to store and query item attributes. The example stores an
attribute on a product item, reads it back with a consistent read, finds the item again with a SQL-like `select`
expression, and then removes the attribute.

It illustrates the two properties that distinguish SimpleDB from a relational store: items are schemaless, so an item
is created by the first `putAttributes` call that names it and carries only the attributes it is given; and every
attribute value is indexed on write, so it is queryable without declaring an index.

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
domainName = "<DOMAIN_RESERVED_FOR_THIS_EXAMPLE>"
```

`domainName` must identify a domain reserved for this example. The example creates the domain if it is absent, writes
an attribute to the item `sku-1024` in it, and then deletes that attribute — so pointing it at a domain holding real
data will modify that data. There is no default: the example fails at startup if `domainName` is not configured.

## Run the example

Execute the following command to run the example:

```bash
bal run
```
