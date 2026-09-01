## Overview

[Amazon SimpleDB](https://aws.amazon.com/simpledb/) is a highly available NoSQL data store that offloads the work of database administration. Data is organised into *domains*, each holding *items* identified by a name, and each item holding *attributes* that are name–value pairs. Attributes are schemaless — different items in the same domain may carry entirely different attributes — and every value is indexed automatically, so a domain can be queried with a SQL-like `select` expression without defining indexes up front.

### Key features

- Domain management: `createDomain`, `listDomains`, `getDomainMetaData`, and `deleteDomain`
- Item and attribute operations: `putAttributes`, `getAttributes`, `deleteAttributes`, and the SQL-like `select`
- Flexible credential configuration: static keys, AWS credentials file profiles, STS assume-role, web identity (OIDC), IAM Identity Center (SSO), an external credential process, or the default AWS credential provider chain (EKS Pod Identity, ECS task roles, EC2 instance profiles, environment variables)
- Automatic refresh of expiring temporary credentials
- Endpoint resolution from the AWS SDK's endpoint metadata, including custom endpoint overrides

## Setup guide

### Confirm SimpleDB availability

SimpleDB is a legacy service. It has no AWS Management Console UI and is available in only eight regions:

| Region | Endpoint |
|---|---|
| `us-east-1` | `sdb.amazonaws.com` |
| `us-west-1` | `sdb.us-west-1.amazonaws.com` |
| `us-west-2` | `sdb.us-west-2.amazonaws.com` |
| `eu-west-1` | `sdb.eu-west-1.amazonaws.com` |
| `ap-southeast-1` | `sdb.ap-southeast-1.amazonaws.com` |
| `ap-southeast-2` | `sdb.ap-southeast-2.amazonaws.com` |
| `ap-northeast-1` | `sdb.ap-northeast-1.amazonaws.com` |
| `sa-east-1` | `sdb.sa-east-1.amazonaws.com` |

Note that `us-east-1` uses the region-less `sdb.amazonaws.com` host; the connector resolves this for you. AWS recommends [Amazon DynamoDB](https://aws.amazon.com/dynamodb/) for new applications.

### Obtain IAM user credentials

To create an IAM user and generate an access key, follow the [obtaining IAM user credentials](https://central.ballerina.io/ballerinax/aws/latest#obtaining-iam-user-credentials) guide.

Attach the SimpleDB permissions your application needs to the user. SimpleDB actions are scoped to a domain ARN, while `ListDomains` and `CreateDomain` cannot be scoped to a domain that does not exist yet:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sdb:ListDomains",
                "sdb:CreateDomain"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sdb:DomainMetadata",
                "sdb:DeleteDomain",
                "sdb:GetAttributes",
                "sdb:PutAttributes",
                "sdb:DeleteAttributes",
                "sdb:Select"
            ],
            "Resource": "arn:aws:sdb:<REGION>:<ACCOUNT_ID>:domain/<DOMAIN_NAME>"
        }
    ]
}
```

## Quickstart

To use the `aws.simpledb` connector in your Ballerina project, modify the `.bal` file as follows:

### Step 1: Import the connector

Import the `ballerinax/aws.simpledb` and `ballerinax/aws` packages into your Ballerina project.

```ballerina
import ballerinax/aws;
import ballerinax/aws.simpledb;
```

### Step 2: Instantiate a new connector

Create a new `simpledb:Client` by providing the region and authentication configurations.

```ballerina
simpledb:Client simpleDb = check new ({
    region: aws:US_EAST_1,
    auth: {
      accessKeyId: "<AWS_ACCESS_KEY_ID>",
      secretAccessKey: "<AWS_SECRET_ACCESS_KEY>"
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

```ballerina
public function main() returns error? {
    _ = check simpleDb->createDomain("products");

    _ = check simpleDb->putAttributes("products", "item-1", [{name: "colour", value: "blue"}]);

    simpledb:GetAttributesResponse|xml attributes =
        check simpleDb->getAttributes("products", "item-1", true);
    io:println(attributes);

    simpledb:SelectResponse|xml result =
        check simpleDb->'select("select * from products where colour = 'blue'", true);
    io:println(result);
}
```

### Step 4: Run the Ballerina application

Use the following command to compile and run the Ballerina program.

```bash
bal run
```

### Alternative authentication methods

#### Profile-based authentication

You can use AWS profile-based authentication as an alternative to static credentials.

```ballerina
simpledb:Client simpleDb = check new ({
    region: aws:US_EAST_1,
    auth: {
        profileName: "myAwsProfile",
        credentialsFilePath: "/path/to/custom/credentials"
    }
});
```

#### Default credential provider chain

Resolves credentials automatically from the AWS SDK's default chain. This is the recommended option when the application runs on AWS infrastructure (EC2 instance roles, ECS task roles, EKS Pod Identity/IRSA), since no long-lived credentials need to be stored with the application. The assume-role, web identity, SSO, and credential-process options below also work without long-term access keys, when you need to select a specific source explicitly.

```ballerina
import ballerinax/aws.auth;

simpledb:Client simpleDb = check new ({
    region: aws:US_EAST_1,
    auth: auth:DEFAULT_CREDENTIALS
});
```

> **Note:** Beyond the three options above, the `auth` field also accepts `auth:AssumeRoleConfig` (STS assume-role), `auth:WebIdentityConfig` (web identity / OIDC), `auth:SsoAuthConfig` (IAM Identity Center), and `auth:ProcessAuthConfig` (external credential process). See the [`Ballerina AWS`](https://central.ballerina.io/ballerinax/aws/latest) documentation for details.

## Examples

The `aws.simpledb` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-aws.simpledb/tree/main/examples).

1. [Domain management](https://github.com/ballerina-platform/module-ballerinax-aws.simpledb/tree/main/examples/domain-management)
   This example shows how to create a domain, inspect its metadata, list the domains in the account, and delete it.

2. [Product catalogue](https://github.com/ballerina-platform/module-ballerinax-aws.simpledb/tree/main/examples/product-catalogue)
   This example shows how to store item attributes and query them back with a `select` expression.
