// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
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

import ballerina/io;
import ballerinax/aws.simpledb;

configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;
configurable string region = "us-east-1";

const string DOMAIN_NAME = "products";

public function main() returns error? {
    simpledb:Client simpleDb = check new ({
        auth: {accessKeyId, secretAccessKey},
        region: region
    });

    _ = check simpleDb->createDomain(DOMAIN_NAME);

    // Items are schemaless: each one carries only the attributes it is given, and
    // the item is created by the first `putAttributes` call that names it.
    simpledb:PutAttributesResponse|xml stored =
        check simpleDb->putAttributes(DOMAIN_NAME, "sku-1024", {name: "colour", value: "blue"});
    if stored is xml {
        return error(string `Failed to store the attribute: ${stored.toString()}`);
    }
    io:println("Stored the colour of 'sku-1024'.");

    // A consistent read reflects every write that completed before it, which a
    // read immediately after a write needs.
    simpledb:GetAttributesResponse|xml attributes =
        check simpleDb->getAttributes(DOMAIN_NAME, "sku-1024", true);
    if attributes is xml {
        return error(string `Failed to read the attributes: ${attributes.toString()}`);
    }
    io:println("Attributes of 'sku-1024': ", attributes.getAttributesResult.attributes);

    // Every attribute value is indexed on write, so it can be queried without
    // declaring an index. String literals in a select expression are single quoted.
    string selectExpression = string `select * from ${DOMAIN_NAME} where colour = 'blue'`;
    simpledb:SelectResponse|xml matches = check simpleDb->'select(selectExpression, true);
    if matches is xml {
        return error(string `Failed to run the select expression: ${matches.toString()}`);
    }
    io:println("Blue products: ", matches.selectResult.items);

    simpledb:DeleteAttributesResponse|xml removed =
        check simpleDb->deleteAttributes(DOMAIN_NAME, "sku-1024", {name: "colour", value: "blue"});
    if removed is xml {
        return error(string `Failed to delete the attribute: ${removed.toString()}`);
    }
    io:println("Removed the colour of 'sku-1024'.");
}
