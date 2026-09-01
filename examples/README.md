# Examples

The `ballerinax/aws.simpledb` connector provides practical examples illustrating usage in various scenarios.

1. [Domain management](domain-management) - Create a domain, inspect its metadata, list the domains in the account, and delete it.
2. [Product catalogue](product-catalogue) - Store item attributes and query them back with a `select` expression.

## Prerequisites

1. Generate AWS credentials as described in the [Setup guide](../README.md#setup-guide).

2. For each example, create a `Config.toml` file with your AWS credentials. Here's an example of how your `Config.toml` file should look:

    ```toml
    accessKeyId = "<AWS_ACCESS_KEY_ID>"
    secretAccessKey = "<AWS_SECRET_ACCESS_KEY>"
    region = "us-east-1"
    ```

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Because of the absence of support for reading local repositories for single Ballerina files, the bala of
the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your
local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
