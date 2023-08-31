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

import ballerina/crypto;
import ballerina/http;
import ballerina/lang.array;
import ballerina/time;
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
        self.amazonHost = "sdb.amazonaws.com";
        string baseURL = "https://" + self.amazonHost;
        check validateCredentials(self.accessKeyId, self.secretAccessKey);
        self.amazonSimpleDBClient = check new (baseURL, httpClientConfig);
    }

    # Create a domain.
    #
    # + domainName - Name of domain
    # + return - `CreateDomainResponse` on success else an `error`
    remote isolated function createDomain(string domainName) returns @tainted CreateDomainResponse|xml|error {
        map<string> parameters = {};
        parameters["Action"] = "CreateDomain";
        parameters["DomainName"] = domainName;
        string timestamp = check self.generateTimestamp();
        string signatureString = check self.generateSignature(buildPayload(parameters), timestamp, parameters["Action"].toString());
        http:Request|error request = self.generateRequest(buildPayload(parameters), timestamp, signatureString, parameters["Action"].toString());
        string queryParameters = check self.generateQueryParameters(buildPayload(parameters), timestamp, signatureString);
        xml response = check sendRequest(self.amazonSimpleDBClient, request, queryParameters);
        CreateDomainResponse|xml createdDomainResponse = check xmlToCreatedDomain(response);
        return createdDomainResponse;
    }

    # Get information about the domain, including when the domain was created, the number of items and attributes, and the size of attribute names and values.
    #
    # + domainName - Name of domain
    # + return - `DomainMetaDataResponse` on success else an `error`
    remote isolated function getDomainMetaData(string domainName) returns @tainted DomainMetaDataResponse|xml|error {
        map<string> parameters = {};
        parameters["Action"] = "DomainMetadata";
        parameters["DomainName"] = domainName;
        string timestamp = check self.generateTimestamp();
        string signatureString = check self.generateSignature(buildPayload(parameters), timestamp, parameters["Action"].toString());
        http:Request|error request = self.generateRequest(buildPayload(parameters), timestamp, signatureString, parameters["Action"].toString());
        string queryParameters = check self.generateQueryParameters(buildPayload(parameters), timestamp, signatureString);
        xml response = check sendRequest(self.amazonSimpleDBClient, request, queryParameters);
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
        parameters["Action"] = "Select";
        parameters["SelectExpression"] = selectExpression;
        parameters["ConsistentRead"] = consistentRead.toString();
        string timestamp = check self.generateTimestamp();
        string signatureString = check self.generateSignature(buildPayload(parameters), timestamp, parameters["Action"].toString());
        http:Request|error request = self.generateRequest(buildPayload(parameters), timestamp, signatureString, parameters["Action"].toString());
        string queryParameters = check self.generateQueryParameters(buildPayload(parameters), timestamp, signatureString);
        xml response = check sendRequest(self.amazonSimpleDBClient, request, queryParameters);
        SelectResponse|xml selectResponse = check xmlToSelectResponse(response);
        return selectResponse;
    }

    # list available domains.
    #
    # + return - `ListDomainsResponse` on success else an `error`
    remote isolated function listDomains() returns @tainted ListDomainsResponse|xml|error {
        map<string> parameters = {};     
        parameters["Action"] = "ListDomains";
        string timestamp = check self.generateTimestamp();
        string signatureString = check self.generateSignature(buildPayload(parameters), timestamp, parameters["Action"].toString());
        http:Request|error request = self.generateRequest(buildPayload(parameters), timestamp, signatureString, parameters["Action"].toString());
        string queryParameters = check self.generateQueryParameters(buildPayload(parameters), timestamp, signatureString);
        xml response = check sendRequest(self.amazonSimpleDBClient, request, queryParameters);
        ListDomainsResponse|xml listDomainsResponse = check xmlToListsDomain(response);
        return listDomainsResponse;
    }

    # Delete a domain.
    #
    # + domainName - Name of domain
    # + return - `DeleteDomainResponse` on success else an `error`
    remote isolated function deleteDomain(string domainName) returns @tainted DeleteDomainResponse|xml|error {
        map<string> parameters = {};
        parameters["Action"] = "DeleteDomain";
        parameters["DomainName"] = domainName;
        string timestamp = check self.generateTimestamp();
        string signatureString = check self.generateSignature(buildPayload(parameters), timestamp, parameters["Action"].toString());
        http:Request|error request = self.generateRequest(buildPayload(parameters), timestamp, signatureString, parameters["Action"].toString());
        string queryParameters = check self.generateQueryParameters(buildPayload(parameters), timestamp, signatureString);
        xml response = check sendRequest(self.amazonSimpleDBClient, request, queryParameters);
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
        parameters["Action"] = "GetAttributes";
        parameters["DomainName"] = domainName;
        parameters["ItemName"] = itemName;
        parameters["ConsistentRead"] = consistentRead.toString();
        string timestamp = check self.generateTimestamp();
        string signatureString = check self.generateSignature(buildPayload(parameters), timestamp, parameters["Action"].toString());
        http:Request|error request = self.generateRequest(buildPayload(parameters), timestamp, signatureString, parameters["Action"].toString());
        string queryParameters = check self.generateQueryParameters(buildPayload(parameters), timestamp, signatureString);
        xml response = check sendRequest(self.amazonSimpleDBClient, request, queryParameters);
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
        parameters["Action"] = "PutAttributes";
        parameters["DomainName"] = domainName;
        parameters["ItemName"] = itemName;
        parameters = setAttributes(parameters, attributes);
        string timestamp = check self.generateTimestamp();
        string signatureString = check self.generateSignature(buildPayload(parameters), timestamp, parameters["Action"].toString());
        http:Request|error request = self.generateRequest(buildPayload(parameters), timestamp, signatureString, parameters["Action"].toString());
        string queryParameters = check self.generateQueryParameters(buildPayload(parameters), timestamp, signatureString);
        xml response = check sendRequest(self.amazonSimpleDBClient, request, queryParameters);
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
        parameters["Action"] = "DeleteAttributes";
        parameters["DomainName"] = domainName;
        parameters["ItemName"] = itemName;
        parameters = setAttributes(parameters, attributes);
        string timestamp = check self.generateTimestamp();
        string signatureString = check self.generateSignature(buildPayload(parameters), timestamp, parameters["Action"].toString());
        http:Request|error request = self.generateRequest(buildPayload(parameters), timestamp, signatureString, parameters["Action"].toString());
        string queryParameters = check self.generateQueryParameters(buildPayload(parameters), timestamp, signatureString);
        xml response = check sendRequest(self.amazonSimpleDBClient, request, queryParameters);
        DeleteAttributesResponse|xml deleteAttributesResponse = check xmlToDeleteAttributesResponse(response);
        return deleteAttributesResponse;
    }

    private isolated function generateTimestamp() returns string|error {
        [int, decimal] & readonly currentTime = time:utcNow();
        string amzDate = check utcToString(currentTime, ISO8601_FORMAT);
        return amzDate;
    }

    private isolated function generateSignature(string payload, string timestampCreated, string action)
        returns string|error {
        string actionName = action;
        string signaturemethod = "HmacSHA256";
        string signatureversion = "2";
        string 'version = VERSION_NUMBER;
        string stringToSign = "GET" + NEW_LINE + "sdb.amazonaws.com" + NEW_LINE + ENDPOINT + NEW_LINE + "AWSAccessKeyId=" + self.accessKeyId + "&Action=" + actionName + "&SignatureMethod=" + signaturemethod + "&SignatureVersion=" + signatureversion + "&Timestamp=" + timestampCreated + "&Version=" + 'version;
        string signature = array:toBase64(check crypto:hmacSha256(stringToSign
            .toBytes(), (self.secretAccessKey).toBytes())).toLowerAscii();
        return signature;
    }

    private isolated function generateRequest(string payload, string timestamp, string signatureString, string action)
            returns http:Request|error {
        map<string> parameters = {};
        parameters["AWSAccessKeyId"] = self.accessKeyId;
        parameters["Version"] = VERSION_NUMBER;
        parameters["Signature"] = signatureString;
        parameters["SignatureVersion"] = "2";
        parameters["SignatureMethod"] = "HmacSHA256";
        parameters["Timestamp"] = timestamp;
        string parameterQuery = buildPayload(parameters);
        string requestParameters =  payload + "&" +parameterQuery;
        map<string> headers = {};    
        headers["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8"; 
        headers["Host"] = "sdb.amazonaws.com"; 
        string msgBody = requestParameters;
        http:Request request = new;  
        request.setTextPayload(msgBody);      
        foreach var [k,v] in headers.entries() {
            request.setHeader(k, v);
        }
        return request;
    }

    private isolated function generateQueryParameters(string payload, string timestamp, string signatureString)
            returns string|error {
        map<string> parameters = {};

        string parameterQuery = buildPayload(parameters);      
        return parameterQuery;
    }
}
