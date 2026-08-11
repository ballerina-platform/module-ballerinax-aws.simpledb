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
import ballerina/uuid;
import ballerinax/aws.simpledb;

configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;
configurable string region = "us-east-1";

public function main() returns error? {
    simpledb:Client simpleDb = check new ({
        auth: {accessKeyId, secretAccessKey},
        region: region
    });

    // Each run works in a domain of its own, so the example never reads or
    // deletes a domain that already exists in the account.
    string domainName = string `inventory-${uuid:createType4AsString()}`;

    simpledb:CreateDomainResponse|xml created = check simpleDb->createDomain(domainName);
    if created is xml {
        return error(string `Failed to create the domain: ${created.toString()}`);
    }
    io:println(string `Created the domain '${domainName}'.`);

    // A newly created domain holds no items, so the counts start at zero.
    simpledb:DomainMetaDataResponse|xml metadata = check simpleDb->getDomainMetaData(domainName);
    if metadata is xml {
        return error(string `Failed to read the domain metadata: ${metadata.toString()}`);
    }
    simpledb:DomainMetadataResult result = metadata.domainMetadataResult;
    io:println(string `Items: ${result.itemCount}, attributes: ${result.attributeNameCount}`);

    simpledb:ListDomainsResponse|xml domains = check simpleDb->listDomains();
    if domains is xml {
        return error(string `Failed to list the domains: ${domains.toString()}`);
    }
    io:println("Domains in this account: ", domains.listDomainsResult.domainNames);

    // Clean up only the domain this run created; deleting a domain removes every
    // item it holds.
    simpledb:DeleteDomainResponse|xml deleted = check simpleDb->deleteDomain(domainName);
    if deleted is xml {
        return error(string `Failed to delete the domain: ${deleted.toString()}`);
    }
    io:println(string `Deleted the domain '${domainName}'.`);
}
