---
title: "readme: OpenArabicPE/authority-files"
author: Till Grallert
date: 2019-01-30
---

# locations and file names

+ main repository: `OpenArabicPE/authority-files/`
    * folder for all data: `data/`
        * `tei/`: main folder for authority data generated within OpenArabicPE
        * `geonames/`: this folder acts as a cache for linked data from [GeoNames](https://geonames.org) in order to minimise traffic. The file naming scheme in this folder is `geon_[ID].xml`
        * `viaf/`: this folder acts as a cache for linked data from [VIAF](https://viaf.org) in order to minimise traffic. The file naming scheme in this folder is `viaf_[ID].SRW.xml`.
    * folder for tools: `xslt/`

# stylesheets
## Persons

1. `tei-person_improve-records.xsl`: This stylesheet is meant to be run on authority files containing `<tei:person>` elements with at least one `<tei:persName>` child and will try to enrich the data.
    - additional data:
        + `<tei:persName type="flattened">`
        + `<tei:persName type="noAddName">`
        + `<tei:birth>`: this element is populated using data from VIAF
        + `<tei:death>`: this element is populated using data from VIAF
        + `<tei:idno type="viaf">`
        + `<tei:idno type="oape">`: nummerical ID for the OpenArabicPE project
    <!-- - output: the output is save at `./_output/person_improved` -->
2. `tei-persname_mark-up.xsl`: this stylesheet will run on any TEI XML file as input and try to add information from an authority file  to `<tei:persName>` nodes. Everything else is replicated as is. The matching is done via `@ref` and the string value of the name. If a match is found in the authority file, the stylesheet will add a `@ref` with multiple valued pointing to the `<tei:idno>`s of the authority using custom URL schemes (`viaf:`, `oape:pers:`). If the input `<tei:persName>` contains no other TEI mark-up, the stylesheet will use the mark-up found in the authority file.
3. `tei_extract-persname.xsl`: This stylesheet has a twofold purpose. First, it enriches all `<tei:persName>` elements in an input file with `@ref` attributes (if available) using an external authority file. Second, it adds all names not yet available in the external authority file to that file
    - input: any TEI XML file
    - output:
        1. a copy of the input with additional information added to already existing `<tei:persName>` elements
        2. an updated copy of the authority file

## Places

## helpers, functions

1. `query-viaf.xsl`: this stylesheet provides templates to query VIAF using SRU or RDF APIs. In both cases input can be either a VIAF ID or a literal string. Output options are TEI XML and VIAF SRU XML.
2. `query-geonames.xsl`: this stylesheet provides templates to query VIAF using SRU or RDF APIs. In both cases input can be either a GeoNames ID or a literal string. Output options are TEI XML, GeoNames XML or CSV.
3. `convert_viaf-to-tei-functions.xsl`



# Workflow named entities: persons

1. Query all TEI files for `persName`
    + check if information is already present in a **local** authority file
    + check if it already has a reference to VIAF
2. Query VIAF through SRU using
    + VIAF ID or
    + name
3. Save VIAF results as individual copy.
    + naming scheme: `viaf_id.SRW.xml`
    + licence: VIAF data is available under the [Open Data Commons Attribution License (ODC-BY)](https://opendatacommons.org/licenses/by/).

# TEI mark-up

```xml
<person xml:id="">
    <!-- more than one persName in any language -->
    <persName xml:lang="ar"></persName>
    <!-- birth and death can be retrieved from VIAF -->
    <birth resp="viaf" when=""></birth>
    <death>Executed in <placeName>Damascus</placeName></death>
    <!-- potential children -->
    <idno type="viaf"></idno>
    <idno type="oape"></idno>
    <event when="" notBefore="" notAfter=""></event>
    <education from="" to=""><orgName>Maktab ʿAnbar</orgName></education>
    <state from="" to="">Member of the <orgName>Arab Academy of Sciences</orgName></state>
</person>
```

# Notes and ideas

Only a fraction of the persons mentioned in early Arabic periodicals can be found in existing authority files. Many of them could be found in the various biographical dictionaries covering this period and one should think a way of referencing these works in a standardised form. (Some dictionaries number the biographies, but not all of them do and it is unclear whether such numbers are stable between editions)

I have currently access to digital versions of

- Khayr al-Dīn Ziriklī
- Yūsuf Ilyān Sarkīs