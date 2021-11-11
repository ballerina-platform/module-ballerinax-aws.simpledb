## Overview
The Ballerina AWS SimpleDB provides the capability to manage domains in [AWS SimpleDB](https://aws.amazon.com/simpledb/).

This module supports [Amazon SimpleDB REST API](https://docs.aws.amazon.com/AmazonSimpleDB/latest/DeveloperGuide/Welcome.html) `2009-04-15` version.
 
## Prerequisites
Before using this connector in your Ballerina application, complete the following:
1. Create an [AWS account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=default&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start)
2. [Obtain tokens](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

## Quickstart
To use the AWS SimpleDB connector in your Ballerina application, update the .bal file as follows:

### Step 1: Import connector
Import the `ballerinax/aws.simpledb` module into the Ballerina project.
```ballerina
import ballerinax/aws.simpledb;
```
### Step 2: Create a new connector instance

You can now enter the credentials in the SimpleDB client configuration and create the SimpleDB client by passing the configuration as follows.

```ballerina
simpledb:AwsCredentials awsCredentials = {
    accessKey: "<ACCESS_KEY_ID>",
    secretKey: "<SECRET_ACCESS_KEY>"
};

simpledb:ConnectionConfig config = {
    credentials:awsCredentials,
    region: <REGION>
};

simpledb:Client amazonSimpleDBClient = check new (config);
```

### Step 3: Invoke connector operation

1. You can create a domain in Amazon SimpleDB as follows with `createDomain` method for a preferred domain name.

    ```ballerina
    simpledb:CreateDomainResponse|error response = amazonSimpleDBClient->createDomain("NewTDomain");
    if (response is simpledb:CreateDomainResponse) {
        log:printInfo("Created Domain: " + response.toString());
    }
    ```
2. Use `bal run` command to compile and run the Ballerina program. 

**[You can find more samples here](https://github.com/ballerina-platform/module-ballerinax-aws.simpledb/tree/master/simpledb/samples)**
