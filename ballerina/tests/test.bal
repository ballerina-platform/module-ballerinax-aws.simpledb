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

import ballerina/test;
import ballerina/os;

configurable string accessKeyId = os:getEnv("ACCESS_KEY_ID");
configurable string secretAccessKey = os:getEnv("SECRET_ACCESS_KEY");
configurable string region = os:getEnv("REGION");

AwsCredentials awsCredentials = {
    accessKeyId: accessKeyId,
    secretAccessKey: secretAccessKey
};

ConnectionConfig config = {
    awsCredentials: awsCredentials
};

Client amazonSimpleDBClient = check new (config);

@test:Config {}
function testCreateDomain() returns error? {
    CreateDomainResponse|xml response = check amazonSimpleDBClient->createDomain("test");
    assertForResponseErrors(response);
}

@test:Config {dependsOn: [testCreateDomain]}
function testListDomains() returns error? {
    ListDomainsResponse|xml response = check amazonSimpleDBClient->listDomains();
    assertForResponseErrors(response);
}

@test:Config {dependsOn: [testListDomains]}
function testGetDomainMetaData() returns error? {
    DomainMetaDataResponse|xml response = check amazonSimpleDBClient->getDomainMetaData("test");
    assertForResponseErrors(response);
}

@test:Config {dependsOn: [testGetDomainMetaData]}
function testSelect() returns error? {
    string selectExpression = "select output_list from test";
    SelectResponse|xml response = check amazonSimpleDBClient->'select(selectExpression, true);
    assertForResponseErrors(response);
}  

@test:Config {dependsOn: [testGetAttributes]}
function testDeleteDomain() returns error? {
    DeleteDomainResponse|xml response = check amazonSimpleDBClient->deleteDomain("test");
    assertForResponseErrors(response);
}

@test:Config {dependsOn: [testSelect]}
function testGetAttributes() returns error? {
    GetAttributesResponse|xml response = check amazonSimpleDBClient->getAttributes("test", "output_list", true);
    assertForResponseErrors(response);
}

function assertForResponseErrors(anydata response) {
    if response is xml {
        test:assertFalse((response/<Errors>/*).data() != "", msg = response.toBalString());
    }
}
