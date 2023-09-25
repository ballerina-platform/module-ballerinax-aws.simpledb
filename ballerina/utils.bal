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
import ballerina/jballerina.java;
import ballerina/lang.array;
import ballerina/http;
import ballerina/time;
import ballerina/url;

isolated function generateQueryParameters(map<string> parameters, string accessKeyId, string secretAccessKey) returns string|error {
    map<string> sortedParameters = check updateAndSortParameters(parameters, accessKeyId);
    string formattedParameters = check calculateStringToSignV2(sortedParameters);
    string signatureString = check sign(formattedParameters, secretAccessKey);
    sortedParameters[SIGNATURE] = check urlEncode(signatureString);
    return buildPayload(sortedParameters);
}

isolated function generateTimestamp() returns string|error {
    [int, decimal] & readonly currentTime = time:utcNow();
    string amzDate = check utcToString(currentTime, ISO8601_FORMAT);
    return amzDate;
}

isolated function generateRequest() returns http:Request {
    http:Request request = new;
    request.setHeader(CONTENT_TYPE, SDB_CONTENT_TYPE);
    return request;
}

isolated function sendRequest(http:Client amazonSimpleDBClient, http:Request|error request, string query) returns @tainted xml|error {
    if request is http:Request {
        http:Response|error httpResponse = amazonSimpleDBClient->post("/?" + query, request);
        return handleResponse(httpResponse);
    } else {
        return error(REQUEST_ERROR);
    }
}

isolated function validateCredentials(string accessKeyId, string secretAccessKey) returns error? {
    if accessKeyId == EMPTY_STRING || secretAccessKey == EMPTY_STRING {
        return error(EMPTY_CREDENTIALS);
    }
    return;
}

isolated function utcToString(time:Utc utc, string pattern) returns string|error {
    [int, decimal] [epochSeconds, lastSecondFraction] = utc;
    int nanoAdjustments = (<int>lastSecondFraction * 1000000000);
    var instant = ofEpochSecond(epochSeconds, nanoAdjustments);
    var zoneId = getZoneId(java:fromString(Z));
    var zonedDateTime = atZone(instant, zoneId);
    var dateTimeFormatter = ofPattern(java:fromString(pattern));
    handle formatString = format(zonedDateTime, dateTimeFormatter);
    return formatString.toBalString();
}

# Set attributes to a map of string to add as query parameters.
#
# + parameters - Parameter map
# + attributes - Attribute to convert to a map of string
# + return - If successful returns `map<string>` response. Else returns error
isolated function setAttributes(map<string> parameters, Attribute attributes) returns map<string> {
    int attributeNumber = 1;
    map<anydata> attributeMap = <map<anydata>>attributes;
    foreach var [key, value] in attributeMap.entries() {
        string attributeName = getAttributeName(key);
        parameters[ATTRIBUTE + FULL_STOP + attributeNumber.toString() + FULL_STOP + NAME] = attributeName.toString();
        parameters[ATTRIBUTE + FULL_STOP + attributeNumber.toString() + FULL_STOP + VALUE] = value.toString();
        attributeNumber = attributeNumber + 1;
    }
    return parameters;
}

# Handles the HTTP response.
#
# + httpResponse - Http response or error
# + return - If successful returns `xml` response. Else returns error
isolated function handleResponse(http:Response|error httpResponse) returns @untainted xml|error {
    if httpResponse is http:Response {
        if httpResponse.statusCode == http:STATUS_NO_CONTENT {
            return error ResponseHandleFailed(NO_CONTENT_SET_WITH_RESPONSE_MSG);
        }
        var xmlResponse = httpResponse.getXmlPayload();
        return xmlResponse;
    } else {
        return error(ERROR_OCCURRED_WHILE_INVOKING_REST_API_MSG, httpResponse);
    }
}

isolated function getAttributeName(string attribute) returns string {
    string firstLetter = attribute.substring(0, 1);
    string otherLetters = attribute.substring(1);
    string upperCaseFirstLetter = firstLetter.toUpperAscii();
    string attributeName = upperCaseFirstLetter + otherLetters;
    return attributeName;
}

isolated function urlEncode(string rawValue) returns string|error {
    string encoded = check url:encode(rawValue, UTF_8);
    encoded = re `\+`.replaceAll(encoded, "%20");
    encoded = re `\*`.replaceAll(encoded, "%2A");
    encoded = re `%7E`.replaceAll(encoded, "~");
    return encoded;
}

isolated function updateAndSortParameters(map<string> parameters, string accessKeyId) returns map<string>|error {
    parameters[ACCESS_KEY] = check urlEncode(accessKeyId);
    parameters[SIGNATURE_VERSION] = check urlEncode(TWO);
    parameters[TIME_STAMP] = check urlEncode(check generateTimestamp());
    parameters[SIGNATURE_METHOD] = check urlEncode(HMAC_SHA_256);
    parameters[VERSION] = check urlEncode(VERSION_NUMBER);
    return sortParameters(parameters);
}

isolated function calculateStringToSignV2(map<string> parameters) returns string|error {
    map<string> sortedParameters = sortParameters(parameters);
    string stringToSign = EMPTY_STRING;
    stringToSign += POST + NEW_LINE;
    stringToSign += AMAZON_AWS_HOST + NEW_LINE;
    stringToSign += ENDPOINT + NEW_LINE;
    stringToSign += buildPayload(sortedParameters);
    return stringToSign;
}

isolated function buildPayload(map<string> parameters) returns string {
    string payload = EMPTY_STRING;
    int parameterNumber = 1;
    foreach var [key, value] in parameters.entries() {
        if parameterNumber > 1 {
            payload += AMBERSAND;
        }
        payload += key + EQUAL + value;
        parameterNumber += 1;
    }
    return payload;
}

isolated function sortParameters(map<string> parameters) returns map<string> {
    string[] keys = parameters.keys();
    keys = keys.sort();
    map<string> sortedParameters = {};
    foreach var key in keys {
        string? value = parameters[key];
        sortedParameters[key] = value is string ? value : EMPTY_STRING;
    }
    return sortedParameters;
}

isolated function sign(string data, string secretKey) returns string|error {
    return array:toBase64(check crypto:hmacSha256(data.toBytes(), secretKey.toBytes()));
}
