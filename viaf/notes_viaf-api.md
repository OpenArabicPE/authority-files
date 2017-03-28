---
title: "VIAF: use and access to API"
author: Till Grallert
date: 2017-03-23 10:59:09 +0100
---


- API: 
    + Search for authority data by keyword, local name, preferred name form, title, source, or control number of source records and retrieve authority records and relationships between authority records from different sources.
    + Retrieve summary information from authority records as well as relationships between records from different sources. 
    + Retrieve authority records in different formats from several national libraries.
- This API does not require authentication.
- VIAF data is available under the [Open Data Commons Attribution License (ODC-BY)](https://opendatacommons.org/licenses/by/). Please see [OCLC Data licenses & attribution](http://www.oclc.org/en/worldcat/data-strategy.html) for guidelines.

- links:
    + http://www.oclc.org/developer/develop/web-services/viaf.en.html

# VIAF API

The Base URL is `http://www.viaf.org`

## Authority cluster

API Resource & Methods | Description | Path | HTTP Method
-|-|-|- 
Identify | The Identify operation provides the Linked Data Uniform Resource Identifier for the entity described by the authority. | /viaf/102333412 | GET
Get Data | Returns Authority Cluster data in xml format based on the supplied VIAF Identifier. | /viaf/102333412/ | GET
Get Data In Format | Append a format specifier to the path. | /viaf/102333412/rdf.xml | GET
Translate LCCN ID | Translate a Library of Congress Control Number to a VIAF URI.  | /viaf/lccn/n79032879 | GET
Translate Source ID | Translate a SourceID (identifier for an original source record at a specific institution) to a VIAF URI.   | /viaf/sourceID/DNB%7c1034425390 | GET
SRU Search | Search for records where the authority includes the terms "Jane+Austen" and return RSS. | `/viaf/search?query=cql.any+=+"Jane Austen"&maximumRecords=5&httpAccept=application/json` or `application/xml` | GET
SRU Browse | Browse for LCCN "n2001-50284"  | `/viaf/search/viaf?scanClause=local.LCCN+exact+"n2001-50284"&responsePosition=10&maximumTerms=20` | GET
Auto Suggest | Suggest Authority Terms based on a text passed in a query. | /viaf/AutoSuggest?query=austen | GET



## Authority Source 
API Resource & Methods | Description | Path | HTTP Method
-|-|-|- 
Read | The Authority file that was contributed by the national library | /processed/BNF|12037720 | GET
SRU Search | Search Authority Source records by SRU indexes. | /processed/search/processed?query=local.personalName+all+"jane+austen" &recordSchema=info:srw/schema/1/briefmarcxml-v1.1&maximumRecords=5&httpAccept=text/xml |  GET
SRU Browse | Browse Authority Source records by SRU indexes. | /processed/search/processed?operation=scan&scanClause=local.personalName exact+"austen,+jane+"&responsePosition=10&maximumTerms=20 | GET

# VIA RDF

- rdf namespace in XML: `http://www.w3.org/1999/02/22-rdf-syntax-ns#`
- schema namespace in XML

## example

~~~{.xml}
<rdf:RDF xmlns:bgn="http://bibliograph.net/" xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:pto="http://www.productontology.org/id/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/" xmlns:umbel="http://umbel.org/umbel#">
    <rdf:Description rdf:about="http://viaf.org/viaf/299037057/">
        <rdf:type rdf:resource="http://xmlns.com/foaf/0.1/Document"/>
        <rdf:type rdf:resource="http://www.w3.org/2006/gen/ont#InformationResource"/>
        <void:inDataset rdf:resource="http://viaf.org/viaf/data" xmlns:void="http://rdfs.org/ns/void#"/>
        <foaf:primaryTopic rdf:resource="http://viaf.org/viaf/299037057" xmlns:foaf="http://xmlns.com/foaf/0.1/"/>
    </rdf:Description>
    <rdf:Description rdf:about="http://viaf.org/viaf/299037057">
        <dcterms:identifier xmlns:dcterms="http://purl.org/dc/terms/">299037057</dcterms:identifier>
        <rdf:type rdf:resource="http://schema.org/Person"/>
        <rdf:type rdf:resource="http://schema.org/Person"/>
        <rdf:type rdf:resource="http://schema.org/Person"/>
        <rdf:type rdf:resource="http://schema.org/Person"/>
        <rdf:type rdf:resource="http://schema.org/Person"/>
        <schema:birthDate>1878</schema:birthDate>
        <schema:deathDate>1947</schema:deathDate>
        <schema:name xml:lang="en-US">ʻAbd Allāh Mukhliṣ</schema:name>
        <rdfs:comment xml:lang="en" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">Warning: skos:prefLabels are not ensured against change!</rdfs:comment>
        <skos:prefLabel xml:lang="en-US" xmlns:skos="http://www.w3.org/2004/02/skos/core#">ʻAbd Allāh Mukhliṣ</skos:prefLabel>
        <schema:name xml:lang="en-US">ʻAbd Allāh Mukhliṣ</schema:name>
        <rdfs:comment xml:lang="en" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">Warning: skos:prefLabels are not ensured against change!</rdfs:comment>
        <skos:prefLabel xml:lang="en-US" xmlns:skos="http://www.w3.org/2004/02/skos/core#">ʻAbd Allāh Mukhliṣ</skos:prefLabel>
        <schema:name xml:lang="en-IL">ʻAbd Allāh Mukhliṣ</schema:name>
        <rdfs:comment xml:lang="en" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">Warning: skos:prefLabels are not ensured against change!</rdfs:comment>
        <skos:prefLabel xml:lang="en-IL" xmlns:skos="http://www.w3.org/2004/02/skos/core#">ʻAbd Allāh Mukhliṣ</skos:prefLabel>
        <schema:name xml:lang="en-IL">ʻAbd Allāh Mukhliṣ</schema:name>
        <rdfs:comment xml:lang="en" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">Warning: skos:prefLabels are not ensured against change!</rdfs:comment>
        <skos:prefLabel xml:lang="en-IL" xmlns:skos="http://www.w3.org/2004/02/skos/core#">ʻAbd Allāh Mukhliṣ</skos:prefLabel>
        <schema:name xml:lang="en">ʻAbd Allāh Mukhliṣ</schema:name>
        <schema:name xml:lang="en">ʻAbd Allāh Mukhliṣ</schema:name>
        <schema:name xml:lang="ar-IL">مخلص، عبد الله</schema:name>
        <rdfs:comment xml:lang="en" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">Warning: skos:prefLabels are not ensured against change!</rdfs:comment>
        <skos:prefLabel xml:lang="ar-IL" xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله</skos:prefLabel>
        <schema:name xml:lang="ar-IL">مخلص، عبد الله</schema:name>
        <rdfs:comment xml:lang="en" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">Warning: skos:prefLabels are not ensured against change!</rdfs:comment>
        <skos:prefLabel xml:lang="ar-IL" xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله</skos:prefLabel>
        <schema:name xml:lang="ar-LB">مخلص، عبد الله،</schema:name>
        <rdfs:comment xml:lang="en" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">Warning: skos:prefLabels are not ensured against change!</rdfs:comment>
        <skos:prefLabel xml:lang="ar-LB" xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله،</skos:prefLabel>
        <schema:name xml:lang="ar-LB">مخلص، عبد الله،</schema:name>
        <rdfs:comment xml:lang="en" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">Warning: skos:prefLabels are not ensured against change!</rdfs:comment>
        <skos:prefLabel xml:lang="ar-LB" xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله،</skos:prefLabel>
        <schema:alternateName>عبد الله مخلص</schema:alternateName>
        <schema:alternateName>عبد اللّه مخلص،</schema:alternateName>
        <schema:alternateName>مخلص، عبد الله</schema:alternateName>
        <schema:alternateName>مخلص، عبد الله</schema:alternateName>
        <schema:alternateName>مخلص، عبد الله بن محمد،</schema:alternateName>
        <schema:alternateName>مخلص، عبد الله بن محمد،</schema:alternateName>
        <schema:sameAs>
            <rdf:Description rdf:about="http://isni.org/isni/0000000403043110"/>
        </schema:sameAs>
        <schema:sameAs>
            <rdf:Description rdf:about="http://id.loc.gov/authorities/names/nr89003446"/>
        </schema:sameAs>
        <schema:gender rdf:resource="http://www.wikidata.org/entity/Q6581097"/>
    </rdf:Description>
    <rdf:Description rdf:about="http://viaf.org/viaf/sourceID/LC%7Cnr+89003446#skos:Concept">
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="http://viaf.org/authorityScheme/LC" xmlns:skos="http://www.w3.org/2004/02/skos/core#"/>
        <skos:prefLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">Mukhliṣ, ʻAbd Allāh 1878-1947</skos:prefLabel>
        <skos:altLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله</skos:altLabel>
        <foaf:focus rdf:resource="http://viaf.org/viaf/299037057" xmlns:foaf="http://xmlns.com/foaf/0.1/"/>
    </rdf:Description>
    <rdf:Description rdf:about="http://viaf.org/viaf/sourceID/NLI%7C000172833#skos:Concept">
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="http://viaf.org/authorityScheme/NLI" xmlns:skos="http://www.w3.org/2004/02/skos/core#"/>
        <skos:prefLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">Mukhliṣ, ʻAbd Allāh 1878-1947</skos:prefLabel>
        <skos:prefLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله</skos:prefLabel>
        <skos:altLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">عبد الله مخلص</skos:altLabel>
        <foaf:focus rdf:resource="http://viaf.org/viaf/299037057" xmlns:foaf="http://xmlns.com/foaf/0.1/"/>
    </rdf:Description>
    <rdf:Description rdf:about="http://viaf.org/viaf/sourceID/ISNI%7C0000000403043110#skos:Concept">
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="http://viaf.org/authorityScheme/ISNI" xmlns:skos="http://www.w3.org/2004/02/skos/core#"/>
        <skos:prefLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">Mukhliṣ, ʻAbd Allāh 1878-1947</skos:prefLabel>
        <skos:altLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">عبد الله مخلص</skos:altLabel>
        <skos:altLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">عبد اللّه مخلص، 1878-1947</skos:altLabel>
        <skos:altLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله</skos:altLabel>
        <skos:altLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله بن محمد، 1878-1947</skos:altLabel>
        <foaf:focus rdf:resource="http://viaf.org/viaf/299037057" xmlns:foaf="http://xmlns.com/foaf/0.1/"/>
    </rdf:Description>
    <rdf:Description rdf:about="http://viaf.org/viaf/sourceID/NLI%7C000172833#skos:Concept">
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="http://viaf.org/authorityScheme/NLI" xmlns:skos="http://www.w3.org/2004/02/skos/core#"/>
        <skos:prefLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">Mukhliṣ, ʻAbd Allāh 1878-1947</skos:prefLabel>
        <skos:prefLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله</skos:prefLabel>
        <skos:altLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">عبد الله مخلص</skos:altLabel>
        <foaf:focus rdf:resource="http://viaf.org/viaf/299037057" xmlns:foaf="http://xmlns.com/foaf/0.1/"/>
    </rdf:Description>
    <rdf:Description rdf:about="http://viaf.org/viaf/sourceID/LNL%7C7060#skos:Concept">
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="http://viaf.org/authorityScheme/LNL" xmlns:skos="http://www.w3.org/2004/02/skos/core#"/>
        <skos:prefLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله، 1878-1947</skos:prefLabel>
        <skos:altLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">عبد اللّه مخلص، 1878-1947</skos:altLabel>
        <skos:altLabel xmlns:skos="http://www.w3.org/2004/02/skos/core#">مخلص، عبد الله بن محمد، 1878-1947</skos:altLabel>
        <foaf:focus rdf:resource="http://viaf.org/viaf/299037057" xmlns:foaf="http://xmlns.com/foaf/0.1/"/>
    </rdf:Description>
</rdf:RDF>
~~~

## XPath to retrieve specific data

- dates of birth and death
    + `rdf:RDF/rdf:Description/schema:birthDate`
    + `rdf:RDF/rdf:Description/schema:deathDate`
    
# VIAF via SRU

- The query `/viaf/search?query=cql.any+=+"Jane Austen"&maximumRecords=5&httpAccept=application/xml` returns SRU XML
    + to query for VIAF IDs use: `https://viaf.org/viaf/search?query=local.viafID+any+"89743196"&httpAccept=application/xml`
    + to query for personal names only use: `https://viaf.org/viaf/search?query=local.personalNames+all+"Jane Austen"&httpAccept=application/xml`
    + additional options
        * `&sortKeys=holdingscount`
        * `&maximumRecords=5`
        * `&recordSchema=BriefVIAF`
- XML namespaces
    + SRU: `xmlns="http://www.loc.gov/zing/srw/"`, `xmlns:ns1="http://www.loc.gov/zing/srw/"`
        <!-- * I suggest using the following `xmlns:srw="http://www.loc.gov/zing/srw/"` -->
    + `xmlns:ns2="http://viaf.org/viaf/terms#"`


## XPath to retrieve specific data

- A note on namespaces: The namespace conventions are really odd. Every returned record gets a new namespace prefix (ns2, ns3, ns4 etc.) that all point to the same viaf namespace. I therefore suggest to use the following namespace declarations for any XPath query
    + SRU: `xmlns:srw="http://www.loc.gov/zing/srw/"`
    + VIAF: `xmlns:viaf="http://viaf.org/viaf/terms#"`

- VIAF ID
    + `srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster/viaf:viafID`
- type of entity
    + `srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster/viaf:nameType` can return the following values
        * "Personal"
- potential co-authors
    + `srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster/viaf:coauthors/viaf:data` retrieves references to names and ISNI numbers
- publishers the person has published with
    + `srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster/viaf:publishers/viaf:data` retrieves references to names and ISNI numbers
- birth and death dates
    + `srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster/viaf:birthDate` and `srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster/viaf:deathDate`
- published works
    + `srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster/viaf:titles/viaf:work` returns information on titles (`viaf:title`) and the source of this information (`viaf:sources`)
    
    ~~~{.}
    <ns2:sources>
        <ns2:s>NLI</ns2:s>
        <ns2:sid>NLI|000172833</ns2:sid>
    </ns2:sources>
    <ns2:title>الاشارة الى من نال الوزارة</ns2:title>
    ~~~