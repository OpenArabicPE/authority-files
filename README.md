---
title: "readme: OpenArabicPE/authority-files"
author: Till Grallert
date: 2017-10-25 16:21:32 +0300
---

# locations and file names

+ main folder/repository: `OpenArabicPE/authority-files/`
    * sub-folder for tools: `xslt/`
    * sub-folder for viaf data: `viaf/`; this folder will act as a cache for linked data in order to minimise traffic.
    * sub-folder for TEI files: `tei/`
+ copies of SRU results from VIAF queries: `viaf_id.SRW.xml`

# stylesheets

1. `query-viaf.xsl`: this stylesheet provides templates to query VIAF using SRU or RDF APIs. In both cases input can be either a VIAF ID or a literal string. Output options are TEI XML and VIAF SRU XML.
2. `tei-person_improve-records.xsl`: This stylesheet is meant to be run on authority files containing `<tei:person>` elements with at least one `<tei:persName>` child and will try to enrich the data.
    - additional data:
        + `<tei:persName type="flattened">`
        + `<tei:persName type="noAddName">`
        + `<tei:birth>`: this element is populated using data from VIAF
        + `<tei:death>`: this element is populated using data from VIAF
        + `<tei:idno type="viaf">`
3. `tei_extract-persname.xsl`: This stylesheet has a twofold purpose. First, it enriches all `<tei:persName>` elements in an input file with `@ref` attributes (if available) using an external authority file. Second, it adds all names not yet available in the external authority file to that file
    - input: any TEI XML file
    - output:
        1. a copy of the input with additional information added to already existing `<tei:persName>` elements
        2. an updated copy of the authority file


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

~~~{.xml}
<person xml:id="">
    <!-- more than one persName in any language -->
    <persName xml:lang="ar"></persName>
    <!-- birth and death can be retrieved from VIAF -->
    <birth></birth>
    <death></death>
    <!-- potential children -->
    <idno type="viaf"></idno>
    <event when="" notBefore="" notAfter=""></event>
</person>
~~~

# Notes and ideas

Only a fraction of the persons mentioned in early Arabic periodicals can be found in existing authority files. Many of them could be found in the various biographical dictionaries covering this period and one should think a way of referencing these works in a standardised form. (Some dictionaries number the biographies, but not all of them do and it is unclear whether such numbers are stable between editions)