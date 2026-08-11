// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerinax/aws;
import ballerinax/aws.auth;

const string TEST_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE";
const string TEST_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";
const string TEST_SESSION_TOKEN = "FQoDYXdzEXAMPLETOKEN123";
const string TEST_HOST = "sdb.us-west-2.amazonaws.com";

// The canonical string to sign, and the resulting signature, for a fixed
// parameter set. Cross-checked against an independent SigV2 implementation.
const string EXPECTED_STRING_TO_SIGN = "POST\n" + TEST_HOST + "\n/\n" +
    "AWSAccessKeyId=AKIAIOSFODNN7EXAMPLE&Action=CreateDomain&DomainName=test&SignatureMethod=HmacSHA256" +
    "&SignatureVersion=2&Timestamp=2026-08-10T08%3A37%3A49Z&Version=2009-04-15";
const string EXPECTED_SIGNATURE = "51khLjJ+gT6fGrLunxH973qcBGkhfGTiEAM+fiJx2OA=";

@test:Config {}
function testStringToSignAndSignature() returns error? {
    map<string> parameters = {
        "Action": "CreateDomain",
        "AWSAccessKeyId": TEST_ACCESS_KEY_ID,
        "DomainName": "test",
        "SignatureMethod": HMAC_SHA_256,
        "SignatureVersion": "2",
        "Timestamp": check urlEncode("2026-08-10T08:37:49Z"),
        "Version": "2009-04-15"
    };
    string stringToSign = check calculateStringToSignV2(parameters, TEST_HOST);
    test:assertEquals(stringToSign, EXPECTED_STRING_TO_SIGN);
    test:assertEquals(check sign(stringToSign, TEST_SECRET_ACCESS_KEY), EXPECTED_SIGNATURE);
}

@test:Config {}
function testStringToSignUsesResolvedHost() returns error? {
    string stringToSign = check calculateStringToSignV2({"Action": "ListDomains"}, "SDB.amazonaws.com");
    // The host is signed in lower case, and is whatever the endpoint resolved to.
    test:assertTrue(stringToSign.startsWith("POST\nsdb.amazonaws.com\n/\n"), stringToSign);
}

@test:Config {}
function testSignedQueryWithStaticCredentials() returns error? {
    auth:CredentialProvider provider = check new ({
        accessKeyId: TEST_ACCESS_KEY_ID,
        secretAccessKey: TEST_SECRET_ACCESS_KEY
    });
    string query = check generateQueryParameters({[ACTION]: "CreateDomain"}, provider, TEST_HOST);
    test:assertTrue(query.includes(string `AWSAccessKeyId=${TEST_ACCESS_KEY_ID}`), query);
    test:assertTrue(query.includes("SignatureVersion=2"), query);
    test:assertTrue(query.includes("SignatureMethod=HmacSHA256"), query);
    test:assertTrue(query.includes("Version=2009-04-15"), query);
    test:assertTrue(query.includes("Signature="), query);
    // Long-lived credentials carry no session token.
    test:assertFalse(query.includes("SecurityToken"), query);
}

@test:Config {}
function testSignedQueryWithTemporaryCredentials() returns error? {
    auth:CredentialProvider provider = check new ({
        accessKeyId: TEST_ACCESS_KEY_ID,
        secretAccessKey: TEST_SECRET_ACCESS_KEY,
        sessionToken: TEST_SESSION_TOKEN
    });
    string query = check generateQueryParameters({[ACTION]: "CreateDomain"}, provider, TEST_HOST);
    test:assertTrue(query.includes(string `SecurityToken=${TEST_SESSION_TOKEN}`), query);
    // The token has to be signed along with the rest, so it sorts into the
    // signed parameters rather than being appended after the signature.
    int? tokenIndex = query.indexOf("SecurityToken");
    int? signatureIndex = query.indexOf("&Signature=");
    test:assertTrue(tokenIndex is int && signatureIndex is int && tokenIndex < signatureIndex, query);
}

@test:Config {}
function testAttributeParameters() returns error? {
    map<string> parameters = check setAttributes({}, [{name: "colour/shade", value: "dark blue"}]);
    // The attribute's own name and value, not the record's field names.
    test:assertEquals(parameters["Attribute.1.Name"], "colour%2Fshade");
    test:assertEquals(parameters["Attribute.1.Value"], "dark%20blue");
    test:assertEquals(parameters.length(), 2);
}

@test:Config {}
function testMultipleAttributeParameters() returns error? {
    map<string> parameters = check setAttributes({}, [
        {name: "colour", value: "blue"},
        {name: "size", value: "large"},
        {name: "note", value: "on sale"}
    ]);
    // `Attribute.N` is one-based and follows the array order.
    test:assertEquals(parameters["Attribute.1.Name"], "colour");
    test:assertEquals(parameters["Attribute.1.Value"], "blue");
    test:assertEquals(parameters["Attribute.2.Name"], "size");
    test:assertEquals(parameters["Attribute.2.Value"], "large");
    test:assertEquals(parameters["Attribute.3.Name"], "note");
    test:assertEquals(parameters["Attribute.3.Value"], "on%20sale");
    test:assertEquals(parameters.length(), 6);
}

@test:Config {}
function testNoAttributeParameters() returns error? {
    // An empty array adds nothing, which is how `deleteAttributes` asks SimpleDB
    // to delete the whole item.
    map<string> parameters = check setAttributes({[ACTION]: "DeleteAttributes"}, []);
    test:assertEquals(parameters.length(), 1);
}

@test:Config {}
function testAttributeIsSigned() returns error? {
    auth:CredentialProvider provider = check new ({
        accessKeyId: TEST_ACCESS_KEY_ID,
        secretAccessKey: TEST_SECRET_ACCESS_KEY
    });
    map<string> parameters = check setAttributes({[ACTION]: "PutAttributes"}, [{name: "colour", value: "blue"}]);
    string query = check generateQueryParameters(parameters, provider, TEST_HOST);
    // The attribute parameters sort ahead of the signature, so they are covered by it.
    int? attributeIndex = query.indexOf("Attribute.1.Name=colour");
    int? signatureIndex = query.indexOf("&Signature=");
    test:assertTrue(attributeIndex is int && signatureIndex is int && attributeIndex < signatureIndex, query);
}

@test:Config {}
function testEndpointResolution() {
    // SimpleDB's us-east-1 endpoint is the legacy region-less host.
    test:assertEquals(aws:resolveEndpointHost(SERVICE_NAME, aws:US_EAST_1), "sdb.amazonaws.com");
    test:assertEquals(aws:resolveEndpointHost(SERVICE_NAME, aws:US_WEST_2), TEST_HOST);
    test:assertEquals(aws:resolveEndpoint(SERVICE_NAME, aws:EU_WEST_1), "https://sdb.eu-west-1.amazonaws.com");
}

@test:Config {}
function testTransportFailureIsModuleError() returns error? {
    // An unroutable host, so the request fails in transport rather than at AWS.
    Client simpleDb = check new ({
        auth: {accessKeyId: TEST_ACCESS_KEY_ID, secretAccessKey: TEST_SECRET_ACCESS_KEY},
        region: aws:US_EAST_1,
        endpoint: {customEndpoint: "http://localhost:1"},
        timeout: 5
    });
    CreateDomainResponse|xml|error response = simpleDb->createDomain("test");
    // The transport failure has to be matchable as the module's own error type,
    // and it has to keep the underlying failure as its cause.
    test:assertTrue(response is Error, (response is error ? response.toString() : "not an error"));
    if response is Error {
        test:assertEquals(response.message(), "Error occurred while invoking the REST API.");
        test:assertTrue(response.cause() is error, "cause was dropped");
    }
}
