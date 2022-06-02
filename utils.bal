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

import ballerina/jballerina.java;
import ballerina/http;
import ballerina/time;

isolated function buildPayload(map<string> parameters) returns string {
    string payload = EMPTY_STRING;
    int parameterNumber = 1;
    foreach var [key, value] in parameters.entries() {
        if (parameterNumber > 1) {
            payload = payload + AMBERSAND;
        }
        payload = payload + key + EQUAL + value;
        parameterNumber = parameterNumber + 1;
    }
    return payload;
}

isolated function sendRequest(http:Client amazonSimpleDBClient, http:Request|error request, string queryParameters) returns @tainted xml|error {
    if (request is http:Request) {
        http:Response|error httpResponse = amazonSimpleDBClient->post("/", request);
        xml|error response = handleResponse(httpResponse);
        return response;
    } else {
        return error(REQUEST_ERROR);
    }
}

isolated function validateCredentials(string accessKeyId, string secretAccessKey) returns error? {
    if ((accessKeyId == "") || (secretAccessKey == "")) {
        return error(EMPTY_CREDENTIALS);
    }
    return;
}

isolated function utcToString(time:Utc utc, string pattern) returns string|error {
    [int, decimal] [epochSeconds, lastSecondFraction] = utc;
    int nanoAdjustments = (<int>lastSecondFraction * 1000000000);
    var instant = ofEpochSecond(epochSeconds, nanoAdjustments);
    var zoneId = getZoneId(java:fromString("UTC+05:30"));
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
        parameters["Attribute." + attributeNumber.toString() + ".Name"] = attributeName.toString();
        parameters["Attribute." + attributeNumber.toString() + ".Value"] = value.toString();
        attributeNumber = attributeNumber + 1;
    }
    return parameters;
}

# Handles the HTTP response.
#
# + httpResponse - Http response or error
# + return - If successful returns `xml` response. Else returns error
isolated function handleResponse(http:Response|http:PayloadType|error httpResponse) returns @untainted xml|error {
    if (httpResponse is http:Response) {
        if (httpResponse.statusCode == http:STATUS_NO_CONTENT) {
            return error ResponseHandleFailed(NO_CONTENT_SET_WITH_RESPONSE_MSG);
        }
        var xmlResponse = httpResponse.getXmlPayload();
        return xmlResponse;
        // if (xmlResponse is xml) {
        //     if (httpResponse.statusCode == http:STATUS_OK) {
        //         return xmlResponse;
        //     } else {
        //         xmlns "http://sdb.amazonaws.com/doc/2009-04-15/" as ns;
        //         string xmlResponseErrorCode = httpResponse.statusCode.toString();
        //         string responseErrorMessage = (xmlResponse/<ns:'error>/<ns:message>/*).toString();
        //         string errorMsg = "status code" + ":" + xmlResponseErrorCode + 
        //             ";" + " " + "message" + ":" + " " + 
        //             responseErrorMessage;
        //         return error(errorMsg);
        //     }
        // } else {
        //     return error(RESPONSE_PAYLOAD_IS_NOT_XML_MSG);
        // }
    } else if (httpResponse is http:PayloadType) {
        return error(UNREACHABLE_STATE);
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
