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
import ballerina/url;
import ballerinax/aws.auth;

# Builds the signed query string for an operation. SimpleDB is signed with AWS
# Signature Version 2 — it is the only signature version the service accepts —
# so the signature travels as a query parameter rather than in an
# `Authorization` header. The credentials are resolved (and, when temporary,
# refreshed) by the `aws.auth` credential provider on every call.
#
# + parameters - The operation parameters, already URL encoded
# + credentialProvider - Provider that resolves the signing credentials
# + host - The endpoint host to sign against
# + return - The signed query string, or an `error` if the credentials cannot be resolved or the request cannot be signed
isolated function generateQueryParameters(map<string> parameters, auth:CredentialProvider credentialProvider,
        string host) returns string|error {
    auth:Credentials|auth:CredentialResolutionError credentials = credentialProvider.getCredentials();
    if credentials is auth:CredentialResolutionError {
        return error GenerateRequestFailed(
                string `Error occurred while resolving the AWS credentials: ${credentials.message()}`, credentials);
    }
    map<string> sortedParameters = check updateAndSortParameters(parameters, credentials);
    string formattedParameters = check calculateStringToSignV2(sortedParameters, host);
    string signatureString = check sign(formattedParameters, credentials.secretAccessKey);
    sortedParameters["Signature"] = check urlEncode(signatureString);
    return buildPayload(sortedParameters);
}

# Generates the `Timestamp` parameter of a SigV2 request: the current moment as
# an ISO 8601 instant in UTC, at second precision.
#
# + return - The formatted timestamp
isolated function generateTimestamp() returns string {
    time:Utc currentTime = time:utcNow();
    return time:utcToString([currentTime[0], 0]);
}

isolated function generateRequest() returns http:Request {
    http:Request request = new;
    request.setHeader("Content-Type", "application/x-www-form-urlencoded; charset=utf-8");
    return request;
}

isolated function sendRequest(http:Client amazonSimpleDBClient, http:Request request, string query) returns xml|error {
    http:Response|error httpResponse = amazonSimpleDBClient->post(string `/?${query}`, request);
    if httpResponse is error {
        return error Error("Error occurred while invoking the REST API.", httpResponse);
    }
    return handleResponse(httpResponse);
}

# Adds the attributes to the query parameters, in the `Attribute.N.Name` and
# `Attribute.N.Value` form the SimpleDB query API expects, where `N` is the
# one-based position of the attribute. The values are encoded here because the
# parameters are signed in their encoded form.
#
# + parameters - Parameter map to add the attributes to
# + attributes - The attributes to add
# + return - The updated parameter map, or an `error` if an attribute cannot be encoded
isolated function setAttributes(map<string> parameters, Attribute[] attributes) returns map<string>|error {
    foreach int index in 0 ..< attributes.length() {
        Attribute attribute = attributes[index];
        string attributePrefix = string `Attribute.${index + 1}.`;
        parameters[attributePrefix + "Name"] = check urlEncode(attribute.name);
        parameters[attributePrefix + "Value"] = check urlEncode(attribute.value);
    }
    return parameters;
}

# Handles the HTTP response.
#
# + httpResponse - Http response or error
# + return - If successful returns `xml` response. Else returns error
isolated function handleResponse(http:Response httpResponse) returns xml|error {
    if httpResponse.statusCode == http:STATUS_NO_CONTENT {
        return error ResponseHandleFailed("No Content was sent with the response.");
    }
    var xmlResponse = httpResponse.getXmlPayload();
    return xmlResponse;
}

isolated function urlEncode(string rawValue) returns string|error {
    string encoded = check url:encode(rawValue, "UTF-8");
    encoded = re `\+`.replaceAll(encoded, "%20");
    encoded = re `\*`.replaceAll(encoded, "%2A");
    encoded = re `%7E`.replaceAll(encoded, "~");
    return encoded;
}

isolated function updateAndSortParameters(map<string> parameters, auth:Credentials credentials) returns map<string>|error {
    parameters["AWSAccessKeyId"] = check urlEncode(credentials.accessKeyId);
    string? sessionToken = credentials?.sessionToken;
    if sessionToken is string {
        parameters["SecurityToken"] = check urlEncode(sessionToken);
    }
    parameters["SignatureVersion"] = check urlEncode("2");
    parameters["Timestamp"] = check urlEncode(generateTimestamp());
    parameters["SignatureMethod"] = check urlEncode(HMAC_SHA_256);
    parameters["Version"] = check urlEncode(VERSION_NUMBER);
    return sortParameters(parameters);
}

isolated function calculateStringToSignV2(map<string> parameters, string host) returns string|error {
    map<string> sortedParameters = sortParameters(parameters);
    return string `POST${NEW_LINE}${host.toLowerAscii()}${NEW_LINE}/${NEW_LINE}${buildPayload(sortedParameters)}`;
}

isolated function buildPayload(map<string> parameters) returns string {
    string payload = EMPTY_STRING;
    int parameterNumber = 1;
    foreach var [key, value] in parameters.entries() {
        if parameterNumber > 1 {
            payload += "&";
        }
        payload += string `${key}=${value}`;
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
