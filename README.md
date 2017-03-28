---
title: "readme: OpenArabicPE/authority-files"
author: Till Grallert
date: 2017-03-28 12:55:59 +0200
---

# locations and file names

+ main folder/repository: `OpenArabicPE/authority-files/`
    * sub-folder for tools: `xslt/`
    * sub-folder for viaf data: `viaf/`; this folder will act as a cache for linked data in order to minimise traffic.
    * sub-folder for TEI files: `tei/`
+ copies of SRU results from VIAF queries: `viaf_id.SRW.xml`


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