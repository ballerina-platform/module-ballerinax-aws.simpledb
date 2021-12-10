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

configurable string accessKeyId = os:getEnv("ACCESS_KEY");
configurable string secretAccessKey = os:getEnv("SECRET_ACCESS_KEY");
configurable string region = os:getEnv("REGION");

AwsCredentials awsCredentials = {
    accessKeyId: accessKeyId,
    secretAccessKey: secretAccessKey
};

ConnectionConfig config = {
    credentials: awsCredentials
};

Client amazonSimpleDBClient = check new(config);

@test:Config{}
function testCreateDomain() {
    CreateDomainResponse|error response = amazonSimpleDBClient->createDomain("test");
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config{}
function testListDomains() {
    ListDomainsResponse|error response = amazonSimpleDBClient->listDomains();
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config{}
function testGetDomainMetaData() {
    DomainMetaDataResponse|error response = amazonSimpleDBClient->getDomainMetaData("test");
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config{}
function testSelect() {
    string selectExpression = "select output_list from test"; 
    SelectResponse|error response = amazonSimpleDBClient->'select(selectExpression, true);
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config{}
function testDeleteDomain() {
    DeleteDomainResponse|error response = amazonSimpleDBClient->deleteDomain("test");
    if (response is error) {
        test:assertFail(response.toString());
    }
}

@test:Config{}
function testGetAttributes() {
    GetAttributesResponse|error response = amazonSimpleDBClient->getAttributes("test", "output_list", true);
    if (response is error) {
        test:assertFail(response.toString());
    }
}
