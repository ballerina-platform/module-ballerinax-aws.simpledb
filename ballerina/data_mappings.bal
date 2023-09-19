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


xmlns "http://sdb.amazonaws.com/doc/2009-04-15/" as namespace;

isolated function xmlToCreatedDomain(xml response) returns CreateDomainResponse|xml|error {
    xml responseMeta = response/<namespace:ResponseMetadata>;
    if (responseMeta.toString() != EMPTY_STRING) {
        ResponseMetadata responseMetadata = {
            requestId: (responseMeta/<namespace:RequestId>/*).toString(),
            boxUsage: (responseMeta/<namespace:BoxUsage>/*).toString()
        };
        CreateDomainResponse createDomainResponse = {
            responseMetadata : responseMetadata 
        };
        return createDomainResponse;
    } else {
        return response;
    }
}

isolated function xmlToDomainMetaData(xml response) returns DomainMetaDataResponse|xml|error {
    xml domainMetadata = response/<namespace:DomainMetadataResult>;
    xml responseMeta = response/<namespace:ResponseMetadata>;
    if (responseMeta.toString() != EMPTY_STRING) {
        DomainMetadataResult domainMetadataResult = {
            itemCount : (domainMetadata/<namespace:ItemCount>/*).toString(),
            itemNamesSizeBytes : (domainMetadata/<namespace:ItemNamesSizeBytes>/*).toString(),
            attributeNameCount : (domainMetadata/<namespace:AttributeNameCount>/*).toString(),
            attributeNamesSizeBytes : (domainMetadata/<namespace:AttributeNamesSizeBytes>/*).toString(),
            attributeValueCount : (domainMetadata/<namespace:AttributeValueCount>/*).toString(),
            attributeValuesSizeBytes : (domainMetadata/<namespace:AttributeValuesSizeBytes>/*).toString(),
            timestamp : (domainMetadata/<namespace:Timestamp>/*).toString()
        };
        ResponseMetadata responseMetadata = {
            requestId: (responseMeta/<namespace:RequestId>/*).toString(),
            boxUsage: (responseMeta/<namespace:BoxUsage>/*).toString()
        };
        DomainMetaDataResponse domainMetaDataResponse = {
            domainMetadataResult : domainMetadataResult,
            responseMetadata : responseMetadata 
        };
        return domainMetaDataResponse;
    } else {
        return response;
    }
}

isolated function xmlToSelectResponse(xml response) returns SelectResponse|xml|error {
    xml selectdResult = response/<namespace:SelectResult>;
    xml responseMeta = response/<namespace:ResponseMetadata>;
    if (responseMeta.toString() != EMPTY_STRING) {
        SelectResult selectResult = {
            items : (selectdResult/<namespace:Item>/*).toString()
        };        
        ResponseMetadata responseMetadata = {
            requestId: (responseMeta/<namespace:RequestId>/*).toString(),
            boxUsage: (responseMeta/<namespace:BoxUsage>/*).toString()
        };
        SelectResponse selectResponse = {
            selectResult : selectResult,
            responseMetadata : responseMetadata 
        };
        return selectResponse;
    } else {
        return response;
    }
}

isolated function xmlToGetAttributesResponse(xml response) returns GetAttributesResponse|xml|error {
    xml getAttributeResult = response/<namespace:GetAttributesResult>;
    xml responseMeta = response/<namespace:ResponseMetadata>;
    if (responseMeta.toString() != EMPTY_STRING) {
        GetAttributesResult getAttributesResult = {
            attributes : (getAttributeResult/<namespace:Attribute>/*).toString()
        };        
        ResponseMetadata responseMetadata = {
            requestId: (responseMeta/<namespace:RequestId>/*).toString(),
            boxUsage: (responseMeta/<namespace:BoxUsage>/*).toString()
        };
        GetAttributesResponse getAttributesResponse = {
            getAttributesResult : getAttributesResult,
            responseMetadata : responseMetadata 
        };
        return getAttributesResponse;
    } else {
        return response;
    }
}

isolated function xmlToPutAttributesResponse(xml response) returns PutAttributesResponse|xml|error {
    xml responseMeta = response/<namespace:ResponseMetadata>;
    if (responseMeta.toString() != EMPTY_STRING) {
        ResponseMetadata responseMetadata = {
            requestId: (responseMeta/<namespace:RequestId>/*).toString(),
            boxUsage: (responseMeta/<namespace:BoxUsage>/*).toString()
        };
        PutAttributesResponse putAttributesResponse = {
            responseMetadata : responseMetadata 
        };
        return putAttributesResponse;
    } else {
        return response;
    }
}

isolated function xmlToDeleteAttributesResponse(xml response) returns DeleteAttributesResponse|xml|error {
    xml responseMeta = response/<namespace:ResponseMetadata>;
    if (responseMeta.toString() != EMPTY_STRING) {
        ResponseMetadata responseMetadata = {
            requestId: (responseMeta/<namespace:RequestId>/*).toString(),
            boxUsage: (responseMeta/<namespace:BoxUsage>/*).toString()
        };
        DeleteAttributesResponse deleteAttributesResponse = {
            responseMetadata : responseMetadata 
        };
        return deleteAttributesResponse;
    } else {
        return response;
    }
}

isolated function xmlToDeletedDomain(xml response) returns DeleteDomainResponse|xml|error {
    xml responseMeta = response/<namespace:ResponseMetadata>;
    if (responseMeta.toString() != EMPTY_STRING) {
        ResponseMetadata responseMetadata = {
            requestId: (responseMeta/<namespace:RequestId>/*).toString(),
            boxUsage: (responseMeta/<namespace:BoxUsage>/*).toString()
        };
        DeleteDomainResponse deleteDomainResponse = {
            responseMetadata : responseMetadata 
        };
        return deleteDomainResponse;
    } else {
        return response;
    }
}

isolated function xmlToListsDomain(xml response) returns ListDomainsResponse|xml|error {
    xml listDomainResult = response/<namespace:ListDomainsResult>;
    xml responseMeta = response/<namespace:ResponseMetadata>;
    if (responseMeta.toString() != EMPTY_STRING) {
        ListDomainsResult listDomainsResult = {
            domainNames : (listDomainResult/<namespace:DomainName>/*).toString(),
            nextToken : (listDomainResult/<namespace:NextToken>/*).toString()
        };        
        ResponseMetadata responseMetadata = {
            requestId: (responseMeta/<namespace:RequestId>/*).toString(),
            boxUsage: (responseMeta/<namespace:BoxUsage>/*).toString()
        };
        ListDomainsResponse listDomainsResponse = {
            listDomainsResult : listDomainsResult,
            responseMetadata : responseMetadata 
        };
        return listDomainsResponse;
    } else {
        return response;
    }
}
