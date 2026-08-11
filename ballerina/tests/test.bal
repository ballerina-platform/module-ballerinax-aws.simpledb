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
import ballerinax/aws;

configurable string accessKeyId = os:getEnv("ACCESS_KEY_ID");
configurable string secretAccessKey = os:getEnv("SECRET_ACCESS_KEY");
configurable string sessionToken = os:getEnv("SESSION_TOKEN");
configurable string region = os:getEnv("REGION");

configurable boolean runLiveTests = os:getEnv("IS_LIVE_SERVER") == "true";

const string TEST_DOMAIN = "test";
const string TEST_ITEM = "test-item";
const string TEST_ATTRIBUTE_NAME = "colour";
const string TEST_ATTRIBUTE_VALUE = "blue";

Client amazonSimpleDBClient = test:mock(Client);

@test:BeforeGroups {value: ["live"]}
function initLiveClient() returns error? {
    if !runLiveTests {
        return;
    }
    ConnectionConfig config = {
        auth: sessionToken == "" ? {accessKeyId, secretAccessKey} : {accessKeyId, secretAccessKey, sessionToken},
        region: region == "" ? aws:US_EAST_1 : region
    };
    amazonSimpleDBClient = check new (config);
}

@test:Config {enable: runLiveTests, groups: ["live"]}
function testCreateDomain() returns error? {
    CreateDomainResponse|xml response = check amazonSimpleDBClient->createDomain(TEST_DOMAIN);
    assertForResponseErrors(response);
}

@test:Config {enable: runLiveTests, groups: ["live"], dependsOn: [testCreateDomain]}
function testListDomains() returns error? {
    ListDomainsResponse|xml response = check amazonSimpleDBClient->listDomains();
    assertForResponseErrors(response);
}

@test:Config {enable: runLiveTests, groups: ["live"], dependsOn: [testListDomains]}
function testGetDomainMetaData() returns error? {
    DomainMetaDataResponse|xml response = check amazonSimpleDBClient->getDomainMetaData(TEST_DOMAIN);
    assertForResponseErrors(response);
}

@test:Config {enable: runLiveTests, groups: ["live"], dependsOn: [testCreateDomain]}
function testPutAttributes() returns error? {
    PutAttributesResponse|xml response = check amazonSimpleDBClient->putAttributes(TEST_DOMAIN, TEST_ITEM,
            [{name: TEST_ATTRIBUTE_NAME, value: TEST_ATTRIBUTE_VALUE}]);
    assertForResponseErrors(response);
}

@test:Config {enable: runLiveTests, groups: ["live"], dependsOn: [testPutAttributes]}
function testGetAttributes() returns error? {
    GetAttributesResponse|xml response = check amazonSimpleDBClient->getAttributes(TEST_DOMAIN, TEST_ITEM, true);
    assertForResponseErrors(response);
    if response is GetAttributesResponse {
        string attributes = response.getAttributesResult.attributes;
        test:assertTrue(attributes.includes(TEST_ATTRIBUTE_NAME), attributes);
        test:assertTrue(attributes.includes(TEST_ATTRIBUTE_VALUE), attributes);
    }
}

@test:Config {enable: runLiveTests, groups: ["live"], dependsOn: [testPutAttributes]}
function testSelect() returns error? {
    string selectExpression = string `select ${TEST_ATTRIBUTE_NAME} from ${TEST_DOMAIN}`;
    SelectResponse|xml response = check amazonSimpleDBClient->'select(selectExpression, true);
    assertForResponseErrors(response);
}

@test:Config {enable: runLiveTests, groups: ["live"], dependsOn: [testGetAttributes, testSelect]}
function testDeleteAttributes() returns error? {
    DeleteAttributesResponse|xml response = check amazonSimpleDBClient->deleteAttributes(TEST_DOMAIN, TEST_ITEM,
            [{name: TEST_ATTRIBUTE_NAME, value: TEST_ATTRIBUTE_VALUE}]);
    assertForResponseErrors(response);
    GetAttributesResponse|xml readBack = check amazonSimpleDBClient->getAttributes(TEST_DOMAIN, TEST_ITEM, true);
    if readBack is GetAttributesResponse {
        test:assertFalse(readBack.getAttributesResult.attributes.includes(TEST_ATTRIBUTE_VALUE),
                readBack.getAttributesResult.attributes);
    }
}

@test:Config {enable: runLiveTests, groups: ["live"], dependsOn: [testDeleteAttributes, testGetDomainMetaData]}
function testDeleteDomain() returns error? {
    DeleteDomainResponse|xml response = check amazonSimpleDBClient->deleteDomain(TEST_DOMAIN);
    assertForResponseErrors(response);
}

function assertForResponseErrors(anydata response) {
    if response is xml {
        test:assertFalse((response/<Errors>/*).data() != "", msg = response.toBalString());
    }
}
