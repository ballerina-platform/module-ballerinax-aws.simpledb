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

// A mock of the Amazon SimpleDB query API, so the operation tests can run
// without an AWS account. It speaks the same wire protocol as the service:
// the operation and its parameters arrive as a signed query string on a POST,
// and the reply is a namespaced XML document.
import ballerina/http;
import ballerina/lang.regexp;
import ballerina/time;

const MOCK_SERVICE_PORT = 9090;

// The endpoint the tests point the client at, through `endpoint.customEndpoint`.
final string mockServiceUrl = string `http://localhost:${MOCK_SERVICE_PORT}`;

// The credentials the mock accepts. The tests sign with these, and the mock
// re-derives the signature with them to check the request was signed correctly.
const MOCK_ACCESS_KEY_ID = "test";
const MOCK_SECRET_ACCESS_KEY = "test";

// The host the connector resolves the mock endpoint to, and therefore the host
// that ends up in the string to sign.
final string mockServiceHost = string `localhost:${MOCK_SERVICE_PORT}`;

const SDB_NAMESPACE = "http://sdb.amazonaws.com/doc/2009-04-15/";
const MOCK_REQUEST_ID = "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d";
const MOCK_BOX_USAGE = "0.0000219907";
const BACK_QUOTE = "`";

// The parameters SimpleDB requires on every signed request.
final readonly & string[] REQUIRED_PARAMETERS =
    ["AWSAccessKeyId", "Signature", "SignatureVersion", "SignatureMethod", "Timestamp", "Version"];

// domain name -> item name -> attribute name -> values. SimpleDB attributes are
// multi-valued, and `PutAttributes` appends rather than replaces, so the values
// are held as a list.
isolated map<map<map<string[]>>> domains = {};

service on new http:Listener(MOCK_SERVICE_PORT) {

    isolated resource function post .(http:Request request) returns xml|http:BadRequest|error {
        map<string> parameters = queryParameters(request);
        http:BadRequest? invalidRequest = check validateSignedRequest(parameters);
        if invalidRequest is http:BadRequest {
            return invalidRequest;
        }
        match parameters["Action"] {
            "CreateDomain" => {
                return createDomain(parameters);
            }
            "DeleteDomain" => {
                return deleteDomain(parameters);
            }
            "ListDomains" => {
                return listDomains();
            }
            "DomainMetadata" => {
                return domainMetadata(parameters);
            }
            "PutAttributes" => {
                return putAttributes(parameters);
            }
            "GetAttributes" => {
                return getAttributes(parameters);
            }
            "DeleteAttributes" => {
                return deleteAttributes(parameters);
            }
            "Select" => {
                return 'select(parameters);
            }
        }
        return awsError("InvalidAction", string `The action ${parameters["Action"] ?: ""} is not valid for this web service.`);
    }
}

// ===== Operations =====

isolated function createDomain(map<string> parameters) returns xml|http:BadRequest|error {
    string|http:BadRequest domainName = requiredDomainName(parameters);
    if domainName is http:BadRequest {
        return domainName;
    }
    lock {
        // `CreateDomain` is idempotent; re-creating an existing domain is a no-op.
        if !domains.hasKey(domainName) {
            domains[domainName] = {};
        }
    }
    return response("CreateDomainResponse", "");
}

isolated function deleteDomain(map<string> parameters) returns xml|http:BadRequest|error {
    string|http:BadRequest domainName = requiredDomainName(parameters);
    if domainName is http:BadRequest {
        return domainName;
    }
    lock {
        // `DeleteDomain` on a domain that is not there succeeds, as the service does.
        _ = domains.removeIfHasKey(domainName);
    }
    return response("DeleteDomainResponse", "");
}

isolated function listDomains() returns xml|error {
    string[] domainNames;
    lock {
        domainNames = domains.keys().clone();
    }
    string result = "";
    foreach string domainName in domainNames.sort() {
        result += string `<DomainName>${escape(domainName)}</DomainName>`;
    }
    return response("ListDomainsResponse", string `<ListDomainsResult>${result}</ListDomainsResult>`);
}

isolated function domainMetadata(map<string> parameters) returns xml|http:BadRequest|error {
    string|http:BadRequest domainName = requiredDomainName(parameters);
    if domainName is http:BadRequest {
        return domainName;
    }
    map<map<string[]>>? items;
    lock {
        items = domains[domainName].clone();
    }
    if items is () {
        return noSuchDomain();
    }

    int itemCount = items.length();
    int itemNamesSizeBytes = 0;
    int attributeValueCount = 0;
    int attributeValuesSizeBytes = 0;
    int attributeNamesSizeBytes = 0;
    map<()> attributeNames = {};
    foreach [string, map<string[]>] [itemName, attributes] in items.entries() {
        itemNamesSizeBytes += itemName.toBytes().length();
        foreach [string, string[]] [name, values] in attributes.entries() {
            if !attributeNames.hasKey(name) {
                attributeNames[name] = ();
                attributeNamesSizeBytes += name.toBytes().length();
            }
            attributeValueCount += values.length();
            foreach string value in values {
                attributeValuesSizeBytes += value.toBytes().length();
            }
        }
    }
    string result = string `<DomainMetadataResult>` +
        string `<ItemCount>${itemCount}</ItemCount>` +
        string `<ItemNamesSizeBytes>${itemNamesSizeBytes}</ItemNamesSizeBytes>` +
        string `<AttributeNameCount>${attributeNames.length()}</AttributeNameCount>` +
        string `<AttributeNamesSizeBytes>${attributeNamesSizeBytes}</AttributeNamesSizeBytes>` +
        string `<AttributeValueCount>${attributeValueCount}</AttributeValueCount>` +
        string `<AttributeValuesSizeBytes>${attributeValuesSizeBytes}</AttributeValuesSizeBytes>` +
        string `<Timestamp>${time:utcNow()[0]}</Timestamp>` +
        string `</DomainMetadataResult>`;
    return response("DomainMetadataResponse", result);
}

isolated function putAttributes(map<string> parameters) returns xml|http:BadRequest|error {
    string|http:BadRequest domainName = requiredDomainName(parameters);
    if domainName is http:BadRequest {
        return domainName;
    }
    string? itemName = parameters["ItemName"];
    if itemName is () {
        return awsError("MissingParameter", "The request must contain the parameter ItemName.");
    }
    [string, string][] attributes = attributeParameters(parameters);
    lock {
        if !domains.hasKey(domainName) {
            return noSuchDomain();
        }
        map<map<string[]>> items = domains.get(domainName);
        map<string[]> item = items[itemName] ?: {};
        foreach [string, string] [name, value] in attributes.clone() {
            string[] values = item[name] ?: [];
            // The value is added to the attribute rather than replacing what is
            // already there, which is what `PutAttributes` does without `Replace`.
            if values.indexOf(value) is () {
                values.push(value);
            }
            item[name] = values;
        }
        items[itemName] = item;
    }
    return response("PutAttributesResponse", "");
}

isolated function getAttributes(map<string> parameters) returns xml|http:BadRequest|error {
    string|http:BadRequest domainName = requiredDomainName(parameters);
    if domainName is http:BadRequest {
        return domainName;
    }
    string? itemName = parameters["ItemName"];
    if itemName is () {
        return awsError("MissingParameter", "The request must contain the parameter ItemName.");
    }
    map<string[]>? item;
    lock {
        map<map<string[]>>? items = domains[domainName];
        if items is () {
            return noSuchDomain();
        }
        item = items[itemName].clone();
    }
    // Reading an item that is not there is not an error; the result is empty.
    string result = item is () ? "" : attributeElements(item);
    return response("GetAttributesResponse", string `<GetAttributesResult>${result}</GetAttributesResult>`);
}

isolated function deleteAttributes(map<string> parameters) returns xml|http:BadRequest|error {
    string|http:BadRequest domainName = requiredDomainName(parameters);
    if domainName is http:BadRequest {
        return domainName;
    }
    string? itemName = parameters["ItemName"];
    if itemName is () {
        return awsError("MissingParameter", "The request must contain the parameter ItemName.");
    }
    [string, string][] attributes = attributeParameters(parameters);
    lock {
        map<map<string[]>>? items = domains[domainName];
        if items is () {
            return noSuchDomain();
        }
        map<string[]>? item = items[itemName];
        if item is map<string[]> {
            if attributes.length() == 0 {
                // No attributes named means the whole item goes.
                _ = items.removeIfHasKey(itemName);
            } else {
                foreach [string, string] [name, value] in attributes.clone() {
                    string[]? values = item[name];
                    if values is string[] {
                        string[] remaining = from string existing in values
                            where existing != value
                            select existing;
                        if remaining.length() == 0 {
                            _ = item.removeIfHasKey(name);
                        } else {
                            item[name] = remaining;
                        }
                    }
                }
                if item.length() == 0 {
                    _ = items.removeIfHasKey(itemName);
                }
            }
        }
    }
    return response("DeleteAttributesResponse", "");
}

isolated function 'select(map<string> parameters) returns xml|http:BadRequest|error {
    string? selectExpression = parameters["SelectExpression"];
    if selectExpression is () {
        return awsError("MissingParameter", "The request must contain the parameter SelectExpression.");
    }
    // Only the shape the connector's tests use is understood:
    // `select <attributes> from <domain> [where ...]`.
    [string[], string]|error parsed = parseSelectExpression(selectExpression);
    if parsed is error {
        return awsError("InvalidQueryExpression", "The specified query expression syntax is not valid.");
    }
    [string[], string] [selected, domainName] = parsed;

    map<map<string[]>>? items;
    lock {
        items = domains[domainName].clone();
    }
    if items is () {
        return noSuchDomain();
    }
    string result = "";
    foreach [string, map<string[]>] [itemName, attributes] in items.entries() {
        map<string[]> projected = selected.length() == 0 ? attributes :
            map from [string, string[]] [name, values] in attributes.entries()
                where selected.indexOf(name) !is ()
                select [name, values];
        if projected.length() == 0 {
            continue;
        }
        result += string `<Item><Name>${escape(itemName)}</Name>${attributeElements(projected)}</Item>`;
    }
    return response("SelectResponse", string `<SelectResult>${result}</SelectResult>`);
}

// ===== Helpers =====

// `select <a, b | *> from `domain`` — the domain may be back-quoted, as the
// connector's own tests quote it.
isolated function parseSelectExpression(string expression) returns [string[], string]|error {
    string:RegExp selectPattern = re `(?i:^\s*select\s+(.+?)\s+from\s+(\S+)(\s+.*)?$)`;
    regexp:Groups? groups = selectPattern.findGroups(expression);
    if groups is () || groups.length() < 3 {
        return error("unparseable select expression");
    }
    regexp:Span? attributeSpan = groups[1];
    regexp:Span? domainSpan = groups[2];
    if attributeSpan is () || domainSpan is () {
        return error("unparseable select expression");
    }
    string attributeList = attributeSpan.substring().trim();
    string[] selected = attributeList == "*" ? []
        : from string attribute in re `,`.split(attributeList)
            select attribute.trim();
    string domainName = domainSpan.substring().trim();
    // The domain may be back-quoted, as the connector's own tests quote it.
    if domainName.startsWith(BACK_QUOTE) && domainName.endsWith(BACK_QUOTE) && domainName.length() > 1 {
        domainName = domainName.substring(1, domainName.length() - 1);
    }
    return [selected, domainName];
}

isolated function attributeElements(map<string[]> attributes) returns string {
    string elements = "";
    foreach [string, string[]] [name, values] in attributes.entries() {
        foreach string value in values {
            elements += string `<Attribute><Name>${escape(name)}</Name><Value>${escape(value)}</Value></Attribute>`;
        }
    }
    return elements;
}

// Reads the `Attribute.N.Name`/`Attribute.N.Value` pairs off the query, in the
// one-based order the connector writes them.
isolated function attributeParameters(map<string> parameters) returns [string, string][] {
    [string, string][] attributes = [];
    int index = 1;
    while true {
        string? name = parameters[string `Attribute.${index}.Name`];
        string? value = parameters[string `Attribute.${index}.Value`];
        if name is () || value is () {
            break;
        }
        attributes.push([name, value]);
        index += 1;
    }
    return attributes;
}

isolated function queryParameters(http:Request request) returns map<string> {
    map<string> parameters = {};
    foreach [string, string[]] [key, values] in request.getQueryParams().entries() {
        parameters[key] = values.length() > 0 ? values[0] : "";
    }
    return parameters;
}

// The service rejects a request that is not signed, or is signed the wrong way,
// before it looks at the operation at all.
isolated function validateSignedRequest(map<string> parameters) returns http:BadRequest|error? {
    foreach string required in REQUIRED_PARAMETERS {
        if !parameters.hasKey(required) {
            return awsError("MissingParameter", string `The request must contain the parameter ${required}.`);
        }
    }
    if parameters["SignatureVersion"] != "2" {
        return awsError("InvalidParameterValue", "Value found in SignatureVersion is not valid.");
    }
    if parameters["SignatureMethod"] != "HmacSHA256" {
        return awsError("InvalidParameterValue", "Value found in SignatureMethod is not valid.");
    }
    if parameters["Version"] != "2009-04-15" {
        return awsError("NoSuchVersion", "The requested version does not exist.");
    }
    if !parameters.hasKey("Action") {
        return awsError("MissingParameter", "The request must contain the parameter Action.");
    }
    if parameters["AWSAccessKeyId"] != MOCK_ACCESS_KEY_ID {
        return awsError("InvalidClientTokenId", "The AWS Access Key Id you provided does not exist in our records.");
    }
    return validateSignature(parameters);
}

// Re-derives the signature over everything the request actually carried, and
// rejects the request when it does not match what arrived.
isolated function validateSignature(map<string> parameters) returns http:BadRequest|error? {
    // The query parameters arrive decoded, and are signed in their encoded form.
    map<string> signedParameters = {};
    foreach [string, string] [key, value] in parameters.entries() {
        if key != "Signature" {
            signedParameters[key] = check urlEncode(value);
        }
    }
    string stringToSign = check calculateStringToSignV2(signedParameters, mockServiceHost);
    if parameters["Signature"] != check sign(stringToSign, MOCK_SECRET_ACCESS_KEY) {
        return awsError("SignatureDoesNotMatch",
                "The request signature we calculated does not match the signature you provided.");
    }
    return;
}

isolated function requiredDomainName(map<string> parameters) returns string|http:BadRequest {
    string? domainName = parameters["DomainName"];
    if domainName is () {
        return awsError("MissingParameter", "The request must contain the parameter DomainName.");
    }
    return domainName;
}

isolated function response(string element, string result) returns xml|error {
    string payload = string `<${element} xmlns="${SDB_NAMESPACE}">${result}` +
        string `<ResponseMetadata><RequestId>${MOCK_REQUEST_ID}</RequestId>` +
        string `<BoxUsage>${MOCK_BOX_USAGE}</BoxUsage></ResponseMetadata></${element}>`;
    return xml:fromString(payload);
}

isolated function noSuchDomain() returns http:BadRequest {
    return awsError("NoSuchDomain", "The specified domain does not exist.");
}

// SimpleDB reports operation failures as a 400 carrying an `Errors` document,
// which the connector surfaces as raw `xml`.
isolated function awsError(string code, string message) returns http:BadRequest {
    xml|error payload = xml:fromString(string `<Response><Errors><Error>` +
        string `<Code>${escape(code)}</Code><Message>${escape(message)}</Message>` +
        string `<BoxUsage>${MOCK_BOX_USAGE}</BoxUsage></Error></Errors>` +
        string `<RequestID>${MOCK_REQUEST_ID}</RequestID></Response>`);
    return {body: payload is xml ? payload : xml `<Response/>`, mediaType: "text/xml"};
}

isolated function escape(string value) returns string {
    string escaped = re `&`.replaceAll(value, "&amp;");
    escaped = re `<`.replaceAll(escaped, "&lt;");
    return re `>`.replaceAll(escaped, "&gt;");
}
