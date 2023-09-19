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
import ballerinax/'client.config;

# Ballerina Amazon SimpleDB API connector provides the capability to access Amazon SimpleDB Service.
# This connector lets you to create and manage the SimpleDB domains.
#
# + amazonSimpleDBClient - Connector HTTP endpoint
# + accessKeyId - Amazon API access key
# + secretAccessKey - Amazon API secret key
# + securityToken - Security token
# + region - Amazon API Region
# + amazonHost - Amazon host name
@display {label: "Amazon SimpleDB", iconPath: "resources/aws.simpledb.svg"}
public isolated client class Client {
    final string accessKeyId;
    final string secretAccessKey;
    final string? securityToken;
    final string region;
    final string amazonHost;
    final http:Client amazonSimpleDBClient;

    # Initializes the connector.
    #
    # + config - Configuration for the connector
    # + httpClientConfig - HTTP Configuration
    # + return - `http:Error` in case of failure to initialize or `null` if successfully initialized
    public isolated function init(ConnectionConfig config) returns error? {
        self.accessKeyId = config.awsCredentials.accessKeyId;
        self.secretAccessKey = config.awsCredentials.secretAccessKey;
        self.securityToken = (config?.awsCredentials?.securityToken is string) ?
            <string>(config?.awsCredentials?.securityToken) : ();
        self.region = config.region;
        http:ClientConfiguration httpClientConfig = check config:constructHTTPClientConfig(config);
        self.amazonHost = AMAZON_AWS_HOST;
        string baseURL = HTTPS + self.amazonHost;
        check validateCredentials(self.accessKeyId, self.secretAccessKey);
        self.amazonSimpleDBClient = check new (baseURL, httpClientConfig);
    }

    # Create a domain.
    #
    # + domainName - Name of domain
    # + return - `CreateDomainResponse` on success else an `error`
    remote isolated function createDomain(string domainName) returns @tainted CreateDomainResponse|xml|error {
        map<string> parameters = {};
        parameters[ACTION] = check urlEncode(CREATE_DOMAIN);
        parameters[DOMAIN_NAME] = check urlEncode(domainName);
        xml response = check sendRequest(self.amazonSimpleDBClient, generateRequest(),
                                         check generateQueryParameters(parameters, self.accessKeyId, self.secretAccessKey));
        CreateDomainResponse|xml createdDomainResponse = check xmlToCreatedDomain(response);
        return createdDomainResponse;
    }

    # Get information about the domain, including when the domain was created, the number of items and attributes, and the size of attribute names and values.
    #
    # + domainName - Name of domain
    # + return - `DomainMetaDataResponse` on success else an `error`
    remote isolated function getDomainMetaData(string domainName) returns @tainted DomainMetaDataResponse|xml|error {
        map<string> parameters = {};
        parameters[ACTION] = check urlEncode(DOMAIN_METADATA);
        parameters[DOMAIN_NAME] = check urlEncode(domainName);
        xml response = check sendRequest(self.amazonSimpleDBClient, generateRequest(),
                                         check generateQueryParameters(parameters, self.accessKeyId, self.secretAccessKey));
        DomainMetaDataResponse|xml domainMetaDataResponse = check xmlToDomainMetaData(response);
        return domainMetaDataResponse;
    }

    # Select set of attributes that match the select expression.
    #
    # + selectExpression - Select expression to get attributes
    # + consistentRead - True if consistent reads are to be accepted
    # + return - `SelectResponse` on success else an `error`
    remote isolated function 'select(string selectExpression, boolean consistentRead) returns @tainted SelectResponse|xml|error {
        map<string> parameters = {};
        parameters[ACTION] = check urlEncode(SELECT);
        parameters[SELECT_EXPRESSION] = check urlEncode(selectExpression);
        parameters[CONSISTENT_READ] = check urlEncode(consistentRead.toString());
        xml response = check sendRequest(self.amazonSimpleDBClient, generateRequest(),
                                         check generateQueryParameters(parameters, self.accessKeyId, self.secretAccessKey));
        SelectResponse|xml selectResponse = check xmlToSelectResponse(response);
        return selectResponse;
    }

    # list available domains.
    #
    # + return - `ListDomainsResponse` on success else an `error`
    remote isolated function listDomains() returns @tainted ListDomainsResponse|xml|error {
        map<string> parameters = {};
        parameters[ACTION] = check urlEncode(LIST_DOMAIN);
        xml response = check sendRequest(self.amazonSimpleDBClient, generateRequest(),
                                         check generateQueryParameters(parameters, self.accessKeyId, self.secretAccessKey));
        ListDomainsResponse|xml listDomainsResponse = check xmlToListsDomain(response);
        return listDomainsResponse;
    }

    # Delete a domain.
    #
    # + domainName - Name of domain
    # + return - `DeleteDomainResponse` on success else an `error`
    remote isolated function deleteDomain(string domainName) returns @tainted DeleteDomainResponse|xml|error {
        map<string> parameters = {};
        parameters[ACTION] = check urlEncode(DELETE_DOMAIN);
        parameters[DOMAIN_NAME] = domainName;
        xml response = check sendRequest(self.amazonSimpleDBClient, generateRequest(),
                                         check generateQueryParameters(parameters, self.accessKeyId, self.secretAccessKey));
        DeleteDomainResponse|xml deletedDomainResponse = check xmlToDeletedDomain(response);
        return deletedDomainResponse;
    }

    # Get all of the attributes associated with the item.
    #
    # + domainName - Name of domain
    # + itemName - Name of item
    # + consistentRead - True if consistent reads are to be accepted
    # + return - `GetAttributesResponse` on success else an `error`
    remote isolated function getAttributes(string domainName, string itemName, boolean consistentRead) returns @tainted GetAttributesResponse|xml|error {
        map<string> parameters = {};
        parameters[ACTION] = check urlEncode(GET_ATTRIBUTES);
        parameters[DOMAIN_NAME] = check urlEncode(domainName);
        parameters[ITEM_NAME] = check urlEncode(itemName);
        parameters[CONSISTENT_READ] = check urlEncode(consistentRead.toString());
        xml response = check sendRequest(self.amazonSimpleDBClient, generateRequest(),
                                         check generateQueryParameters(parameters, self.accessKeyId, self.secretAccessKey));
        GetAttributesResponse|xml getAttributesResponse = check xmlToGetAttributesResponse(response);
        return getAttributesResponse;
    }

    # Creates or replaces attributes in an item.
    #
    # + domainName - Name of domain
    # + itemName - Name of item
    # + attributes - Attributes to create or replace values
    # + return - `PutAttributesResponse` on success else an `error`
    remote isolated function putAttributes(string domainName, string itemName, Attribute attributes) returns @tainted PutAttributesResponse|xml|error {
        map<string> parameters = {};
        parameters[ACTION] = check urlEncode(PUT_ATTRIBUTES);
        parameters[DOMAIN_NAME] = check urlEncode(domainName);
        parameters[ITEM_NAME] = check urlEncode(itemName);
        xml response = check sendRequest(self.amazonSimpleDBClient, generateRequest(),
                                         check generateQueryParameters(parameters, self.accessKeyId, self.secretAccessKey));
        PutAttributesResponse|xml putAttributesResponse = check xmlToPutAttributesResponse(response);
        return putAttributesResponse;
    }

    # Delete attributes in an item.
    #
    # + domainName - Name of domain
    # + itemName - Name of item
    # + attributes - Attributes to create or replace values
    # + return - `DeleteAttributesResponse` on success else an `error`
    remote isolated function deleteAttributes(string domainName, string itemName, Attribute attributes) returns @tainted DeleteAttributesResponse|xml|error {
        map<string> parameters = {};
        parameters[ACTION] = check urlEncode(DELETE_ATTRIBUTES);
        parameters[DOMAIN_NAME] = check urlEncode(domainName);
        parameters[ITEM_NAME] = check urlEncode(itemName);
        xml response = check sendRequest(self.amazonSimpleDBClient, generateRequest(),
                                         check generateQueryParameters(parameters, self.accessKeyId, self.secretAccessKey));
        DeleteAttributesResponse|xml deleteAttributesResponse = check xmlToDeleteAttributesResponse(response);
        return deleteAttributesResponse;
    }
}
