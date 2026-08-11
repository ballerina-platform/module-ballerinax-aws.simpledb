# Change Log
This file contains all the notable changes done to the Ballerina AWS SimpleDB package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

This release revamps the connector's authentication and region configuration to use the shared
[`ballerinax/aws`](https://github.com/ballerina-platform/module-ballerinax-aws) package, so that all AWS
connectors share a single, consistent credential model.

It contains breaking changes. See the "Migrating from 2.x" section below.

### Changed

- **[Breaking]** Credentials are now supplied through a single `ConnectionConfig.auth` field of type
  `auth:AuthConfig`, sourced from `ballerinax/aws.auth` instead of being defined locally by this package.
  In 2.x, credentials were passed as `awsCredentials`, which accepted static keys only. Every 2.x
  credential source remains supported, with six new ones added.
- **[Breaking]** `ConnectionConfig` no longer includes `ballerinax/client.config:ConnectionConfig`. The
  HTTP configuration fields are now declared directly on the record, which additionally makes
  `socketConfig`, `validation` and `laxDataBinding` available.
- **[Breaking]** The `ConnectionConfig.region` field type changed from `string` to `aws:Region|string`, and
  it is now required. It previously defaulted to `"us-east-1"`, which was misleading because the value was
  never used — see the corresponding entry under "Fixed".
- **[Breaking]** The `attributes` parameter of `putAttributes` and `deleteAttributes` is now an
  `Attribute[]` rather than a single `Attribute`, so an item can be written or trimmed in one call as the
  API allows — SimpleDB accepts up to 256 attributes per call. Passing an empty array to
  `deleteAttributes` deletes the whole item.
- Temporary credentials (STS assume-role, SSO, container and instance profiles) are now refreshed
  transparently by the credential provider, instead of the connector holding a single set of keys
  resolved at initialization time.
- The endpoint host is now resolved from the AWS SDK's endpoint metadata via `aws:resolveEndpoint`, rather
  than being hardcoded.
- The package now requires Ballerina distribution `2201.12.0`.

### Removed

- **[Breaking]** The `ConnectionConfig.awsCredentials` field, and the `AwsCredentials` and
  `AwsTemporaryCredentials` records it accepted, have been removed in favour of `ConnectionConfig.auth`.
- **[Breaking]** The `OperationError`, `DataMappingError` and `FileReadFailed` error types have been
  removed. They were declared but never returned by any operation.
- The Java interop declarations used to format the request timestamp have been removed in favour of
  `ballerina/time`, leaving the package with no Java dependencies.

### Added

- Support for six additional AWS credential sources, available through `auth:AuthConfig`:
  - `auth:ProfileAuthConfig` — credentials read from a named profile in the shared credentials file.
  - `auth:AssumeRoleConfig` — temporary credentials obtained by assuming an IAM role via AWS STS.
  - `auth:WebIdentityConfig` — web identity (OIDC) federation, including IAM Roles for Service Accounts (IRSA).
  - `auth:SsoAuthConfig` — AWS IAM Identity Center (SSO).
  - `auth:ProcessAuthConfig` — credentials sourced from an external credential process.
  - `auth:DEFAULT_CREDENTIALS` — the AWS default credential provider chain.
- A new optional `ConnectionConfig.endpoint` field of type `aws:EndpointConfig`, for selecting FIPS or
  dualstack endpoint variants and for overriding the endpoint entirely (for example, VPC interface
  endpoints).

### Fixed

- Temporary credentials now work. In 2.x, `AwsTemporaryCredentials.securityToken` was accepted by the
  configuration and then never sent, so any request made with temporary credentials was rejected by AWS.
  The session token is now sent as the `SecurityToken` parameter, and is covered by the request signature.
- The configured region is now honoured. In 2.x, `ConnectionConfig.region` was stored and never read: every
  request went to `sdb.amazonaws.com` and the string to sign hardcoded that host, so the connector could
  only ever reach `us-east-1`.
- `putAttributes` and `deleteAttributes` no longer discard their `attributes` argument. In 2.x the argument
  was accepted and never added to the request, so `putAttributes` created an item with no attributes and
  `deleteAttributes` deleted every attribute of the item rather than the one named. The helper that was
  meant to build these parameters also mapped the record's field names rather than the attribute's own name
  and value, and did not URL-encode them, which would have broken the request signature.
- `deleteDomain` now URL-encodes the domain name, as every other operation already did. A domain name
  requiring encoding previously produced a signature mismatch.

### Migrating from 2.x

Add an `import ballerinax/aws;` alongside the existing SimpleDB import, move the credential fields under
`auth`, and pass the region explicitly:

```ballerina
// 2.x
import ballerinax/aws.simpledb;

simpledb:ConnectionConfig config = {
    awsCredentials: {accessKeyId, secretAccessKey}
};
```

```ballerina
// 3.0.0
import ballerinax/aws;
import ballerinax/aws.simpledb;

simpledb:ConnectionConfig config = {
    auth: {accessKeyId, secretAccessKey},
    region: aws:US_EAST_1
};
```

Temporary credentials move from `securityToken` to `sessionToken` inside `auth`. Note that these did not
work at all in 2.x:

```ballerina
// 2.x
simpledb:ConnectionConfig config = {
    awsCredentials: {accessKeyId, secretAccessKey, securityToken}
};
```

```ballerina
// 3.0.0
simpledb:ConnectionConfig config = {
    auth: {accessKeyId, secretAccessKey, sessionToken},
    region: aws:US_EAST_1
};
```

Deployments that should resolve credentials from the environment rather than from hardcoded keys can now
use the default credential provider chain:

```ballerina
// 3.0.0
import ballerinax/aws;
import ballerinax/aws.auth;

simpledb:ConnectionConfig config = {
    auth: auth:DEFAULT_CREDENTIALS,
    region: aws:US_EAST_1
};
```

## [2.2.0] - 2023-09-25

### Changed
- Bumped the module and distribution versions.

## [2.0.0] - 2023-08-14

### Changed
- Restructured the repository root directory.

## [1.0.0] - 2021-10-26

### Added
- Initial release of the AWS SimpleDB connector.
