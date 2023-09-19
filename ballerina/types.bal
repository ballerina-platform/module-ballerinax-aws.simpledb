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

import ballerinax/'client.config;

# Represents the AWS SimpleDB Connector configurations.
@display {label: "Connection Config"}
public type ConnectionConfig record {|
    *config:ConnectionConfig;
    never auth?;
    # AWS credentials
    AwsCredentials|AwsTemporaryCredentials awsCredentials;
    # AWS Region
    string region = DEFAULT_REGION;
|};

# Represents AWS credentials.
#
# + accessKeyId - AWS access key  
# + secretAccessKey - AWS secret key
public type AwsCredentials record {
    string accessKeyId;
    @display {
        label: "",
        kind: "password"
    }
    string secretAccessKey;
};

# Represents AWS temporary credentials.
#
# + accessKeyId - AWS access key  
# + secretAccessKey - AWS secret key  
# + securityToken - AWS secret token
public type AwsTemporaryCredentials record {
    string accessKeyId;
    @display {
        label: "",
        kind: "password"
    }
    string secretAccessKey;
    @display {
        label: "",
        kind: "password"
    }
    string securityToken;   
};

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
