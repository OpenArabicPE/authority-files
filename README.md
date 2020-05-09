---
title: "readme: OpenArabicPE/authority-files"
author: Till Grallert
date: 2020-04-06
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

## bibliography

- conversion between `<tei:biblStruct>` and `<mods:mods>` (including particularities of Zotero generated MODS)
    + IDs?
        * Zotero IDs are not included in the MODS output
    + Problems:
- XSLT to enrich Zotero-exports (file: `zotero_export-DRU8DnvU.xml`) with pre-exisiting data
    + based on matching:
        * title
        * editors
    + pre-existing data: copy everything except data edited in ZOtero
- XSLT to copy data from biblio-biographic dictionaries, such as Zirikli to the bibliography
    + based on matching:
        * title
        * IDs
    + Output should be wrapped as

    ```xml
    <note>
        <!-- information about and links to the source -->
        <note type="bibliographic"><ref target="pointer-to-source"><bibl>bibliographic reference for the source</bibl></ref></note>
        <!-- the source -->
        <quote></quote>
    </note>
    ```



# Workflows
## named entities: persons

1. Query all TEI files for `persName`
    + check if information is already present in a **local** authority file
    + check if it already has a reference to VIAF
2. Query VIAF through SRU using
    + VIAF ID or
    + name
3. Save VIAF results as individual copy.
    + naming scheme: `viaf_id.SRW.xml`
    + licence: VIAF data is available under the [Open Data Commons Attribution License (ODC-BY)](https://opendatacommons.org/licenses/by/).

## bibliography of periodicals

1. create original bibliography either manually or through gathering all `<biblStruct>` for periodicals from all OpenArabicPE editions.
2. enrich bibliography
    - the most urgently needed information are all potential contributors to be then tested with stylometry
    - automatically with information found in full text editions of Zirikli and Sarkīs
        + add full-text of dī Ṭarrāzī, which is organized in biographies
        + I make use of the `@source` attribute to keep record of the source for a piece of information
            * usually these are file URLs for full-text editions
            * but I will also use `sente:UUID` to reference other sources of information
            + in either case bibliographic information can be automatically retrieved (locally only)
    - manually
        + in order to manage limited resources, the order of importance for which periodicals we look at is established by the number of references to a title in our corpus (found, for example, in `oape_stats-referenced-periodicals.csv`)

# references to authority files

URI schemes used across the entire project

- VIAF:
    + ID pattern: `\d+`
    - mark-up: `viaf:ID`, `<idno type="viaf">ID</idno>`
    - resolves to: `https://viaf.org/ID`
- GeoNames:
    + ID pattern: `\d+`
    + mark-up: `geon:ID`, `<idno type="geon">ID</idno>`
- Wikidata:
    + ID pattern: `Q\d+`
    + mark-up: `wiki:ID`
    + resolves to: https://www.wikidata.org/wiki/
- local authority: OpenArabicPE
    + ID pattern: `\d+`
    + persons: (`oape:pers:`, `<idno type="oape">`)
- local authority: Sente (my reference manager)
    + ID pattern: UUID
    + mark-up: `sente:UUID`
    + since I have exported everything as individual XML files this information is not locked in, even though I am not currently sharing it on the internet

# TEI mark-up
## prosopography

```xml
<listPerson>
    <person xml:id="">
        <!-- more than one persName in any language -->
        <persName xml:lang="ar"></persName>
        <!-- birth and death can be retrieved from VIAF -->
        <birth resp="viaf" when=""></birth>
        <death>Executed in <placeName>Damascus</placeName></death>
        <!-- identifiers -->
        <idno type="viaf"></idno>
        <idno type="oape"></idno>
        <!-- potential children, these should all have some source information -->
        <event when="" notBefore="" notAfter=""></event>
        <education from="" to=""><orgName>Maktab ʿAnbar</orgName></education>
        <state from="" to="">Member of the <orgName>Arab Academy of Sciences</orgName></state>
    </person>
    <person>
        <!-- -->
    </person>
</listPerson>
```
## gazetteer

```xml
<listPlace>
    <head><!-- some short title --></head>
    <place type="town">
        <!-- more than one placeName in any language, can be retrieved from GeoNames -->
        <placeName source="#org_geon" type="alt" xml:lang="ar">النبطية</placeName>
        <placeName xml:lang="ar-Latn-x-ijmes">al-Nabaṭiyya</placeName>
        <placeName xml:lang="en">Nabatiye</placeName>
        <!-- location can be retrieved from GeoNames -->
        <location source="#org_geon">
            <geo>33.37717, 35.48383</geo>
        </location>
        <!-- identifiers -->
        <idno type="geon">7870014</idno>
        <idno type="oape">7</idno>
        <!-- potential children, these should all have some source information -->
    </place>
</listPlace>
```

## bibliography

Each publication is encoded as a `<biblStruct>` with a type attribute (even though the type could be guessed from the internal structure of the `<biblStruct>` and the values of `@level` on `<title>`). On the other hand, there is no way to distinguish between newspapers and journals/magazines based on the structure alone.

- values of `@type`:
    + "book"
    + "journal": everything that is called *majalla* in Arabic
    + "newspaper": everything that is called *jarīda* in Arabic

```xml
<!-- many periodicals underwent various changes in editorship, title, frequency etc. and should,
    therefore, be wrapped in a <listBibl>.  -->
<!-- the sequence is recorded explicitly by means of @next and @prev attributes  -->
<listBibl xml:lang="ar">
    <biblStruct xml:lang="ar">
        <monogr xml:lang="ar">
            <!-- titles in Arabic and transcription -->
            <title corresp="sakhrit:jid:14" level="j" xml:lang="ar">لغة العرب</title>
            <title level="j" type="sub" xml:lang="ar">مجلة شهرية ادبية علمية تاريخية</title>
            <title corresp="sakhrit:jid:14" level="j" xml:lang="ar-Latn-x-ijmes">Lughat al-ʿArab</title>
            <title level="j" type="sub" xml:lang="ar-Latn-x-ijmes">Majalla shahriyya adabiyya ʿilmiyya tārīkhiyya</title>
            <!-- identifiers -->
            <idno change="#d2e69" type="oape">1</idno>
            <idno type="jid" xml:lang="ar">14</idno>
            <idno type="OCLC">472450345</idno>
            <textLang mainLang="ar"/>
            <editor xml:lang="ar">
                <!-- persNames link back to the prosopography -->
                <!-- only one is needed. Additional names could be looked up automatically -->
                <persName ref="oape:pers:227 viaf:39370998" xml:lang="ar"> <roleName type="rank" xml:lang="ar">الأب</roleName> <forename xml:lang="ar">أنستاس</forename> <forename xml:lang="ar">ماري</forename> <surname xml:lang="ar"> <addName type="nisbah" xml:lang="ar">الكرملي</addName> </surname></persName>
                <persName xml:lang="ar-Latn-x-ijmes">al-Abb Anastās Mārī al-Karamlī</persName>
            </editor>
            <editor xml:lang="ar">
                <persName change="#d3e53" ref="oape:pers:396" xml:id="persName_195.d1e5884" xml:lang="ar"> <forename xml:id="forename_224.d1e5885" xml:lang="ar">كاظم</forename> <surname xml:id="surname_195.d1e5888" xml:lang="ar"> <addName type="nisbah">الدجيلي</addName> </surname> </persName>
            </editor>
            <imprint xml:lang="ar">
                <publisher/>
                <pubPlace xml:lang="ar">
                    <!-- persNames link back to the prosopography -->
                    <!-- only one is needed. Additional toponyms could be looked up automatically -->
                    <placeName change="#d5e42" ref="oape:place:216 geon:98182" xml:lang="ar">بغداد</placeName>
                    <placeName change="#d5e42"
                    ref="oape:place:216 geon:98182" xml:lang="ar-Latn-x-ijmes">Baghdād</placeName>
                    <placeName change="#d5e42" ref="oape:place:216 geon:98182" xml:lang="en">Baghdad</placeName>
                </pubPlace>
                <date datingMethod="#cal_islamic" when="1911-06-30" when-custom="1329-07-01"/>
            </imprint>
            <biblScope from="1" to="1" unit="volume"/>
            <biblScope from="1" to="1" unit="issue"/>
            <!-- <biblScope from="505" unit="page">505</biblScope>-->
        </monogr>
        <!-- $p_weekdays-published contains a comma-separated list of weekdays in English -->
        <note type="param" n="p_weekdays-published">Tuesday, Friday</note>
        <!--  $p_step sets incremental steps for the input to be iterated upon. Values are:
            - daily: this includes any publication cycle that is at least weekly
            - fortnightly:
            - monthly: -->
        <note type="param" n="p_step">daily</note>
        <!-- the two above parameters have been converted to the following  -->
        <note type="tagList">
            <list>
                <item>frequency_monthly</item>
                <item>days_monday</item>
            </list>
        </note>
    </biblStruct>
</listBibl>
```

## encoding the source of bits of information
### `@source`

Almost all elements can carry the global `@source` attribute (att.global.source). It "specifies the source from which some aspect of this element is drawn" and holds "1–∞ occurrences of teidata.pointer separated by whitespace". "the location may be provided using any form of URI, for example an absolute URI, a relative URI, or private scheme URI that is expanded to an absolute URI as documented in a prefixDef." ([TEI guidelines](https://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.global.source.html))

`teidata.pointer` is defined as `xsd:anyURI`

### `@resp`

The global `@resp` adheres to the same content model as `@source` but "indicates the agency responsible for the intervention or interpretation, for example an editor or transcriber."

# Notes and ideas

Only a fraction of the persons mentioned in early Arabic periodicals can be found in existing authority files. Many of them could be found in the various biographical dictionaries covering this period and one should think a way of referencing these works in a standardised form. (Some dictionaries number the biographies, but not all of them do and it is unclear whether such numbers are stable between editions)

I have currently access to digital versions of

- Khayr al-Dīn Ziriklī
- Yūsuf Ilyān Sarkīs