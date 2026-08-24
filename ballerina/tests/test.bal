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

import ballerina/os;
import ballerina/test;
import ballerina/uuid;
import ballerinax/aws;

// The operation tests run against the mock SimpleDB service by default, and
// against the real service when `IS_LIVE_SERVER` is set.
configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";

configurable string accessKeyId = isLiveServer ? os:getEnv("ACCESS_KEY_ID") : "test";
configurable string secretAccessKey = isLiveServer ? os:getEnv("SECRET_ACCESS_KEY") : "test";
configurable string sessionToken = isLiveServer ? os:getEnv("SESSION_TOKEN") : "";
configurable string region = os:getEnv("REGION");

final string testDomain = string `ballerina-simpledb-test-${uuid:createType4AsString()}`;

const string TEST_ITEM = "test-item";
const string TEST_ATTRIBUTE_NAME = "colour";
const string TEST_ATTRIBUTE_VALUE = "blue";

final Client amazonSimpleDBClient = check initClient();

isolated function initClient() returns Client|error {
    ConnectionConfig config = {
        auth: sessionToken == "" ? {accessKeyId, secretAccessKey} : {accessKeyId, secretAccessKey, sessionToken},
        region: region == "" ? aws:US_EAST_1 : region,
        endpoint: isLiveServer ? {} : {customEndpoint: mockServiceUrl}
    };
    return new (config);
}

@test:AfterSuite {alwaysRun: true}
function deleteTestDomain() returns error? {
    DeleteDomainResponse|xml response = check amazonSimpleDBClient->deleteDomain(testDomain);
    assertForResponseErrors(response);
}

@test:Config {}
function testCreateDomain() returns error? {
    CreateDomainResponse|xml response = check amazonSimpleDBClient->createDomain(testDomain);
    assertForResponseErrors(response);
}

@test:Config {dependsOn: [testCreateDomain]}
function testListDomains() returns error? {
    ListDomainsResponse|xml response = check amazonSimpleDBClient->listDomains();
    assertForResponseErrors(response);
    if response is ListDomainsResponse {
        test:assertTrue(response.listDomainsResult.domainNames.includes(testDomain),
                response.listDomainsResult.domainNames);
    }
}

@test:Config {dependsOn: [testListDomains]}
function testGetDomainMetaData() returns error? {
    DomainMetaDataResponse|xml response = check amazonSimpleDBClient->getDomainMetaData(testDomain);
    assertForResponseErrors(response);
}

@test:Config {dependsOn: [testCreateDomain]}
function testPutAttributes() returns error? {
    PutAttributesResponse|xml response = check amazonSimpleDBClient->putAttributes(testDomain, TEST_ITEM,
            [{name: TEST_ATTRIBUTE_NAME, value: TEST_ATTRIBUTE_VALUE}]);
    assertForResponseErrors(response);
}

@test:Config {dependsOn: [testPutAttributes]}
function testGetAttributes() returns error? {
    GetAttributesResponse|xml response = check amazonSimpleDBClient->getAttributes(testDomain, TEST_ITEM, true);
    assertForResponseErrors(response);
    if response is GetAttributesResponse {
        string attributes = response.getAttributesResult.attributes;
        test:assertTrue(attributes.includes(TEST_ATTRIBUTE_NAME), attributes);
        test:assertTrue(attributes.includes(TEST_ATTRIBUTE_VALUE), attributes);
    }
}

@test:Config {dependsOn: [testPutAttributes]}
function testSelect() returns error? {
    string quotedDomain = "`" + testDomain + "`";
    string selectExpression = string `select ${TEST_ATTRIBUTE_NAME} from ${quotedDomain}`;
    SelectResponse|xml response = check amazonSimpleDBClient->'select(selectExpression, true);
    assertForResponseErrors(response);
    if response is SelectResponse {
        test:assertTrue(response.selectResult.items.includes(TEST_ATTRIBUTE_VALUE), response.selectResult.items);
    }
}

@test:Config {dependsOn: [testGetAttributes, testSelect]}
function testDeleteAttributes() returns error? {
    DeleteAttributesResponse|xml response = check amazonSimpleDBClient->deleteAttributes(testDomain, TEST_ITEM,
            [{name: TEST_ATTRIBUTE_NAME, value: TEST_ATTRIBUTE_VALUE}]);
    assertForResponseErrors(response);
    GetAttributesResponse|xml readBack = check amazonSimpleDBClient->getAttributes(testDomain, TEST_ITEM, true);
    if readBack is GetAttributesResponse {
        test:assertFalse(readBack.getAttributesResult.attributes.includes(TEST_ATTRIBUTE_VALUE),
                readBack.getAttributesResult.attributes);
    }
}

@test:Config {dependsOn: [testDeleteAttributes, testGetDomainMetaData]}
function testDeleteDomain() returns error? {
    DeleteDomainResponse|xml response = check amazonSimpleDBClient->deleteDomain(testDomain);
    assertForResponseErrors(response);
}

@test:Config {dependsOn: [testDeleteDomain]}
function testOperationOnMissingDomain() returns error? {
    // The service reports an operation failure as an `Errors` document, which the
    // connector surfaces as raw `xml` rather than the mapped response record.
    DomainMetaDataResponse|xml response = check amazonSimpleDBClient->getDomainMetaData(
            string `ballerina-simpledb-absent-${uuid:createType4AsString()}`);
    test:assertTrue(response is xml, response.toBalString());
    if response is xml {
        test:assertEquals((response/<Errors>/<Error>/<Code>/*).toString(), "NoSuchDomain", response.toString());
    }
}

function assertForResponseErrors(anydata response) {
    if response is xml {
        test:assertFalse((response/<Errors>/*).data() != "", msg = response.toBalString());
    }
}
