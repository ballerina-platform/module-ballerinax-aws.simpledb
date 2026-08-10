// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerinax/aws;
import ballerinax/aws.auth;

# Represents the AWS SimpleDB Connector configurations.
@display {label: "Connection Config"}
public type ConnectionConfig record {|
    # Authentication configuration: any standard credential source supported by
    # AWS — static credentials, an AWS profile, STS assume-role,
    # web identity (OIDC), IAM Identity Center (SSO), an external credential
    # process, or the default credential provider chain
    auth:AuthConfig auth;
    # AWS region: an `aws:Region` enum member or a plain region
    # string (e.g., `"us-east-1"`) for regions not yet in the enum
    aws:Region|string region;
    # Optional endpoint options: FIPS/dualstack variants, or a custom
    # endpoint override (e.g. VPC interface endpoints)
    aws:EndpointConfig endpoint?;
    # The HTTP version understood by the client
    http:HttpVersion httpVersion = http:HTTP_2_0;
    # Configurations related to HTTP/1.x protocol
    http:ClientHttp1Settings http1Settings = {};
    # Configurations related to HTTP/2 protocol
    http:ClientHttp2Settings http2Settings = {};
    # The maximum time to wait (in seconds) for a response before closing the connection
    decimal timeout = 30;
    # The choice of setting `forwarded`/`x-forwarded` header
    string forwarded = "disable";
    # Configurations associated with Redirection
    http:FollowRedirects followRedirects?;
    # Configurations associated with request pooling
    http:PoolConfiguration poolConfig?;
    # HTTP caching related configurations
    http:CacheConfig cache = {};
    # Specifies the way of handling compression (`accept-encoding`) header
    http:Compression compression = http:COMPRESSION_AUTO;
    # Configurations associated with the behaviour of the Circuit Breaker
    http:CircuitBreakerConfig circuitBreaker?;
    # Configurations associated with retrying
    http:RetryConfig retryConfig?;
    # Configurations associated with cookies
    http:CookieConfig cookieConfig?;
    # Configurations associated with inbound response size limits
    http:ResponseLimitConfigs responseLimits = {};
    # SSL/TLS-related options
    http:ClientSecureSocket secureSocket?;
    # Proxy server related options
    http:ProxyConfig proxy?;
    # Provides settings related to client socket configuration
    http:ClientSocketConfig socketConfig = {};
    # Enables the inbound payload validation functionality which provided by the constraint package. Enabled by default
    boolean validation = true;
    # Enables relaxed data binding on the client side. When enabled, `nil` values are treated as optional,
    # and absent fields are handled as `nilable` types. Enabled by default
    boolean laxDataBinding = true;
|};

# An attribute for the item
#
# + name - Name of the attribute  
# + value - Value of the attribute 
public type Attribute record {
    string name;
    string value;
};

# Create domain response
#
# + responseMetadata - Response metadata 
public type CreateDomainResponse record {
    ResponseMetadata responseMetadata;
};

# Delete domain response
#
# + responseMetadata - Response metadata 
public type DeleteDomainResponse record {
    ResponseMetadata responseMetadata;
};

# List domains response
#
# + listDomainsResult - Result of domain list
# + responseMetadata - Response metadata 
public type ListDomainsResponse record {
    ListDomainsResult listDomainsResult;
    ResponseMetadata responseMetadata;
};

# Result of domain list
#
# + domainNames - Domain names 
# + nextToken - Next token of returned list items more than page size 
public type ListDomainsResult record {
    string domainNames;
    string nextToken;
};

# Select response
#
# + selectResult - Result of selectn  
# + responseMetadata - Response metadata  
public type SelectResponse record {
    SelectResult selectResult;
    ResponseMetadata responseMetadata;
};

# Result of select
#
# + items - items available 
public type SelectResult record {
    string items;
};

# Get attributes response
#
# + getAttributesResult - Result of get attributes  
# + responseMetadata - Response metadata  
public type GetAttributesResponse record {
    GetAttributesResult getAttributesResult;
    ResponseMetadata responseMetadata;
};

# Result of get attributes 
#
# + attributes - Attribute names
public type GetAttributesResult record {
    string attributes;
};

# Put attributes response
#
# + responseMetadata - Response metadata  
public type PutAttributesResponse record {
    ResponseMetadata responseMetadata;
};

# Delete attributes response
#
# + responseMetadata - Response metadata  
public type DeleteAttributesResponse record {
    ResponseMetadata responseMetadata;
};

# Domain metadata response
#
# + domainMetadataResult - Result of domain metadata 
# + responseMetadata - Response metadata 
public type DomainMetaDataResponse record {
    DomainMetadataResult domainMetadataResult;
    ResponseMetadata responseMetadata;
};

# Domain metadata result
#
# + itemCount - Number of items available 
# + itemNamesSizeBytes - Items names size in bytes
# + attributeNameCount - Number of attributes available  
# + attributeNamesSizeBytes - Attributes names size in bytes
# + attributeValueCount - Value of attributes available  
# + attributeValuesSizeBytes - Attributes values size in bytes
# + timestamp - Timestamp 
public type DomainMetadataResult record {
    string itemCount;
    string itemNamesSizeBytes;
    string attributeNameCount;
    string attributeNamesSizeBytes;
    string attributeValueCount;
    string attributeValuesSizeBytes;
    string timestamp;
};

# Denote response metadata
#
# + requestId - A unique ID for tracking the request
# + boxUsage - The measure of machine utilization for this request
public type ResponseMetadata record {
    string requestId;
    string boxUsage;
};
