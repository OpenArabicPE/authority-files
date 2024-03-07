---
title: "readme: OpenArabicPE/authority-files"
author: Till Grallert
date: 2024-02-02
lang: en
---

[![License: CC BY 4.0](https://img.shields.io/badge/license-CC_BY_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Maintenance](https://img.shields.io/badge/maintained%3F-yes-green.svg)](https://github.com/openarabicpe/authority-files/graphs/commit-activity)
![Commit activity](https://img.shields.io/github/commit-activity/m/openarabicpe/authority-files)
[![GitHub release](https://img.shields.io/github/release/openarabicpe/authority-files.svg?maxAge=2592000)](https://github.com/openarabicpe/authority-files/releases)
![GitHub commits since latest release (by date)](https://img.shields.io/github/commits-since/openarabicpe/authority-files/latest)

This repository holds the authority files for three research projects in Arab Periodical Studies and on the history of Arabic periodicals until roughly 1930: Project Jarāʾid, Open Arabic Periodical Editions, and Sihafa. The aim is to provide information on all titles, publishers, and places of publication relevant for this discursive sphere, including non-Arabic titles referenced within Arabic periodicals. As far as possible, I aim at linking local data to relevant external authority files, such as the *Virtual International Authority File* ([VIAF](https://viaf.org)), the [GeoNames](https://geonames.org) gazetteer or [Wikidata](https://wikidata.org/).

# locations and file names

* folder for all data: `data/`
    * `tei/`: main folder for authority data generated within OpenArabicPE
        - bibliography
        - personography
        - organizationography
        - gazetteer
    * `csv/`: folder for derivatives of the main `tei/` folder, serialised as CSV or TSV.
    * `geonames/`: this folder acts as a cache for linked data from [GeoNames](https://geonames.org) in order to minimise traffic. The file naming scheme in this folder is `geon_[ID].xml`
    * `viaf/`: this folder acts as a cache for linked data from [VIAF](https://viaf.org) in order to minimise traffic. The file naming scheme in this folder is `viaf_[ID].SRW.xml`.
* folder for tools: `xslt/`

# to do
## bibliography of periodicals

- [x] add all known collaborators to Suriye (oape:bibl:321)
- [ ] add sources as TEI/XML to the bibliography
    + some are encoded as `<ref type="pandoc">`
    + [@LaPresseMusulmane+1909, 106]
    + [@Campos+2008+TheVoiceOf, 245]
- [ ] wrap content in `<publisher source="oape:org:73">` originating from AUB in a `<orgName>` element
- [ ] The holding information from Jaraid needs to become more machine-actionable. See below for details.
    + example 1
        * we have: `<ref resp="#pAM" target="https://gpa.eastview.com/crl/mena/newspapers/msbh" xml:lang="und-Latn">online 1899-1900</ref>` 
        * we want: `<bibl><date type="onset">1899</date>-<date type="terminus">1900</date></bibl>`
- [ ] ambiguous matches for referenced periodicals
    + the problem concerns important journals with minor competitors of the same name
    + references do not include spatial information
    + I already added a lot of conditions but the problem persists, when we have only a title
    + idea: proximity
        + spatial
        + temporal: easier to check
- [ ] faulty historical matches
    + the result of past matching needs to be validated, especially for 
        * [x] *al-Muqtabas* 
        * [ ] *al-Manār*
    + check if the content of the `<title>` node matches the `@ref`.
    + example: `مجلة <title level="j" ref="oape:bibl:46" xml:lang="ar">العلم في القرن العشرين</title>`
- [ ] extract dates from holding data
    + dates in holding data can be used to improve our knowledge of publication histories. If a library has a copy and provides a publication date for this copy, assume that they catalogued it correctly, and add this dating information as `<date type="documented"/>` to the main entry's `<imprint/>`

## XSLT

- [ ] support full URLs in `@ref` in the XSLT linking entity names to authority files.
    + add param whether to output private URI scheme or full URLs
- [ ] `@type='noAddName'` is missing whitespace between name components in some cases
- XSLT for generating the mapping data needs to be improved (not very important to the workflow/tutorial)

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

- `tei-biblstruct_merge-multiple-sources.xsl`: Stylesheet to merge `<bibl>` and `<biblStruct>` from source files into the bibliography based on the `tei:title/@ref` values. 


XSLT to copy data from biblio-biographic dictionaries, such as Zirikli to the bibliography
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

1. [x] created original bibliography through gathering all `<biblStruct>` for periodicals from all OpenArabicPE editions, merging information from Project Jarāʾid, and library catalogues (ZDB, HathiTrust, AUB).
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

### to do

- integrate other encyclopaedic works on the Arabic press beyond dī Ṭarrāzī
    + namely al-Hasanī on Iraq

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
    + "periodical"
- values of `@subtype`
    + "journal": everything that is called *majalla* in Arabic
    + "newspaper": everything that is called *jarīda* in Arabic

- changes in editorship etc.: Many periodicals underwent various changes in editorship, title, frequency etc. these can be encoded as multiple `<monogr>` children of `<biblStruct>`. The sequence is already established by the structure of the XML and there is currently no need for explicit linking with `@next` and `@prev`.
- contributors
    + the main contributors are encoded as `<editor>`, which can carry a `@type` attribute
        * `@type`
            - "owner": The owner-cum-editor, commonly referred to as *ṣāḥib*.
            - "publisher": The publisher-cum-editor, commonly referred to as *munshiʾ*.
            - "editor": Implicitly assumed type of all editors, used for all of the following:
                + *mudīr masʾūl* (responsible director)
                + *raʾis al-taḥrīr* (editor-in-chief)
                + *mudīr al-taḥrīr* (managing editor)
                + *muḥarrir* (editor)
- dating: `<date>` can carry a `@type` attribute to differentiate different dating information
    + `@type`
        * untyped: this data pertains to the volume and issue numbers provided in `<biblScope>`
        * "onset": date of first publication
        * "terminus": date of last publication
        * "documented": date this periodical has been mentioned in another source
    + `@source`: pointing to a source for the different type of source

```xml
<biblStruct>
    <monogr>
        <!-- titles in Arabic and transcription -->
        <title corresp="sakhrit:jid:14" level="j" xml:lang="ar">لغة العرب</title>
        <title level="j" type="sub" xml:lang="ar">مجلة شهرية ادبية علمية تاريخية</title>
        <title level="j" xml:lang="ar-Latn-x-ijmes">Lughat al-ʿArab</title>
        <title level="j" type="sub" xml:lang="ar-Latn-x-ijmes">Majalla shahriyya adabiyya ʿilmiyya tārīkhiyya</title>
        <!-- identifiers -->
        <idno change="#d2e69" type="oape">1</idno>
        <idno type="jid" xml:lang="ar">14</idno>
        <idno type="OCLC">472450345</idno>
        <textLang mainLang="ar"/>
        <editor>
            <!-- persNames link back to the prosopography -->
            <!-- only one is needed. Additional names could be looked up automatically -->
            <persName ref="oape:pers:227 viaf:39370998" xml:lang="ar"> <roleName type="rank" xml:lang="ar">الأب</roleName> <forename xml:lang="ar">أنستاس</forename> <forename xml:lang="ar">ماري</forename> <surname xml:lang="ar"> <addName type="nisbah" xml:lang="ar">الكرملي</addName> </surname></persName>
            <persName xml:lang="ar-Latn-x-ijmes">al-Abb Anastās Mārī al-Karamlī</persName>
        </editor>
        <editor>
            <persName change="#d3e53" ref="oape:pers:396" xml:id="persName_195.d1e5884" xml:lang="ar"> <forename xml:id="forename_224.d1e5885" xml:lang="ar">كاظم</forename> <surname xml:id="surname_195.d1e5888" xml:lang="ar"> <addName type="nisbah">الدجيلي</addName> </surname> </persName>
        </editor>
        <imprint>
            <publisher/>
            <pubPlace>
                <!-- placeNames link back to the gazetteer -->
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
    <!-- various notes -->
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
```

### Holding information

One of the main purposes of Project Jarāʾid and my own efforts is to locate periodicals in collections in order to guide researchers to material and inform digitisation efforts.

#### schema

```xml
<note type="holdings"> 
    <list>
        <!-- each collection gets its own item -->
        <item source="https://projectjaraid.github.io"> 
            <!-- information on the collection is provided in the label -->
            <label> 
                <placeName ref="geon:2988507 oape:place:322">Paris</placeName>, 
                <orgName ref="jaraid:org:hBNF oape:org:12" xml:lang="und-Latn">BnF</orgName> 
            </label> 
        </item>
        <item source="https://projectjaraid.github.io"> 
            <!-- information on the collection is provided in the label -->
            <label> 
                <placeName ref="geon:2988507 oape:place:322">Paris</placeName>, 
                <orgName ref="jaraid:org:hIMA oape:org:36" xml:lang="und-Latn">IMA</orgName> 
            </label>
            <!-- information on the holdings is provided in a listBibl -->
            <listBibl source="">
                <!-- each item potentially gets its own bibl -->
                <bibl>
                    <!-- one could potentially provide a title element with a @ref attribute pointing to the authority file -->
                    <date type="onset" when="1878"/>
                    <date type="terminus" when="1910"/>
                    <idno type="URI" subtype="self">http://ima.bibalex.org/IMA/presentation/periodic/list.jsf?pid=05C0204A80C79A91F11989B6E0AA9D48"</idno>
                </bibl>
            </listBibl>
        </item>
    </list>
</note>
```

#### current encoding

```xml
<note type="holdings"> 
    <list>
        <!-- each collection gets its own item -->
        <item source="https://projectjaraid.github.io"> 
            <!-- information on the collection is provided in the label -->
            <label> 
                <placeName ref="geon:2988507 oape:place:322">Paris</placeName>, 
                <orgName ref="jaraid:org:hBNF oape:org:12" xml:lang="und-Latn">BnF</orgName> 
            </label> 
        </item>
        <!-- weird mix of encoding: originating from very early conversions of the Jaraid data -->
        <item source="https://projectjaraid.github.io">online at <ref target="http://www.archive.org" xml:lang="und-Latn">archive.org</ref>, reprint <placeName ref="geon:276781 jaraid:place:2 oape:place:26" xml:lang="und-Latn">Beirut</placeName> </item>
        <item source="https://projectjaraid.github.io">1920-23 online at <ref target="https://catalog.hathitrust.org/Record/010495186">Hathitrust</ref> </item>
        <item source="https://projectjaraid.github.io"> 
            <label> <orgName ref="oape:org:421">Sakhrit</orgName> </label>
            <listBibl source="https://projectjaraid.github.io">
                <bibl> 
                    <idno change="#d10e912" subtype="self" type="URI">http://archive.alsharekh.org/newmagazineYears.aspx?MID=107</idno>facsimiles and (limited) index,</bibl>
            </listBibl>
        </item>
        <item source="https://projectjaraid.github.io"> 
            <label> 
                <placeName ref="geon:250441 jaraid:place:73 oape:place:508">Amman</placeName>, 
                <orgName ref="jaraid:org:hDMW oape:org:28" xml:lang="und-Latn">DMW</orgName> 
            </label>: 1877-1930s (with gaps),
        </item>
        <!-- some structured information BUT room for improvement -->
        <item source="https://projectjaraid.github.io"> 
            <label> 
                <placeName ref="geon:281184 oape:place:6">Jerusalem</placeName>, 
                <orgName ref="jaraid:org:hNLI oape:org:60" resp="#pAM" xml:lang="und-Latn">NLoI</orgName> 
            </label>: 
            <listBibl source="https://projectjaraid.github.io">
                <bibl>: <idno type="url">https://jrayed.org/en/newspapers/annafir</idno>1911, 1920-1932 </bibl>
            </listBibl> 
        </item>
        <!-- ZDB data -->
        <item source="https://ld.zdb-services.de/resource/534650-2"> 
            <label> 
                <placeName ref="geon:2879139 oape:place:344" resp="#xslt">Leipzig</placeName>, 
                <orgName ref="oape:org:386" type="short">Leipzig DNB</orgName> 
            </label> 
            <listBibl> 
                <bibl> 
                    <idno source="http://ld.zdb-services.de/data/organisations/DE-101a.rdf" subtype="DE-101a" type="classmark">ZB 10293</idno> 
                </bibl> 
            </listBibl> 
        </item>
        <item source="https://ld.zdb-services.de/resource/534650-2"> 
            <label> 
                <placeName ref="geon:2911522 oape:place:342" resp="#xslt">Halle/Saale</placeName>, 
                <orgName ref="isil:DE-3-1 oape:org:268" type="short">Halle/S ZwB Vord. Orient</orgName> 
            </label> 
            <listBibl> 
                <bibl> 
                    <idno source="http://ld.zdb-services.de/data/organisations/DE-3-1.rdf" subtype="DE-3-1" type="classmark">D Ne 284</idno> 
                    <date type="onset" when="1923">1923</date> 
                </bibl> 
            </listBibl> 
        </item>
        <!-- AUB catalogue data -->
        <item source="oape:org:73"> 
            <label> 
                <placeName ref="geon:276781 jaraid:place:2 oape:place:26">Beirut</placeName>,  
                <orgName ref="jaraid:org:hAUB oape:org:73" xml:lang="en">AUB</orgName> 
            </label>
            <!-- unstructured bibliographic information that could/ has not been parsed (yet) --> 
            <ab source="oape:org:73" xml:lang="ar">في المكتبة: مج.1:ع.31(1923:كانون الثاني)</ab>
            <!-- failed attempt to add structured data --> 
            <listBibl>
                <bibl/> 
            </listBibl> 
        </item>
        <item source="oape:org:73"> 
            <label> 
                <placeName ref="geon:276781 jaraid:place:2 oape:place:26">Beirut</placeName>,  
                <orgName ref="jaraid:org:hAUB oape:org:73" xml:lang="en">AUB</orgName> 
            </label>: 
            <!-- unstructured information on holdings -->
            <ab source="oape:org:73" xml:lang="ar">في المكتبة :1902: نيسان -1912: كانون اول.</ab> 
            <!-- structured information, which should be updated with data from the above <ab> -->
            <listBibl>
                <bibl> 
                    <idno subtype="AUB" type="classmark">Mic-NA:000164</idno> 
                    <idno source="oape:org:73" type="url">https://libcat.aub.edu.lb/record=b1282668</idno> 
                </bibl> 
            </listBibl>
        </item>
        <!-- full holding records from HathiTrust -->
        <item source="https://catalog.hathitrust.org/Record/008882426"> 
            <!-- the @source attribute on all children is redundant and should be removed -->
            <label source="oape:org:417"> 
                <placeName ref="geon:5102922 oape:place:715" source="oape:org:417" xml:lang="en">Princeton</placeName>, 
                <orgName ref="isil:US-njp jaraid:org:hPUL oape:org:65" source="oape:org:417">Princeton University</orgName>
            </label>
            <!-- -->
            <listBibl source="oape:org:417"> 
                <bibl source="oape:org:417"> 
                    <idno source="oape:org:417" type="classmark">njp.32101007749128</idno> 
                    <idno source="oape:org:417" subtype="self" type="URI">https://hdl.handle.net/2027/njp.32101007749128</idno> 
                    <date source="oape:org:417" when="1886">1886</date> 
                    <biblScope from="2" source="oape:org:417" to="2" unit="volume">vol.2</biblScope> 
                </bibl>
            </listBibl>
        </item>
        <item source="https://catalog.hathitrust.org/Record/000060895"> 
            <label source="oape:org:417"> 
                <placeName ref="geon:4931972 oape:place:714" source="oape:org:417" xml:lang="en">Cambridge</placeName>, 
                <orgName change="#d10e82" ref="isil:US-hvd jaraid:org:hHARV oape:org:43" source="oape:org:417"
                  >Libraries of Harvard University</orgName> 
              </label> 
              <listBibl source="oape:org:417"> 
                <bibl source="oape:org:417"> 
                    <idno source="oape:org:417" type="classmark">hvd.32044014693741</idno> 
                    <idno source="oape:org:417" subtype="self" type="URI">https://hdl.handle.net/2027/hvd.32044014693741</idno> 
                    <date source="oape:org:417" when="1880">1880</date> 
                    <!-- such biblScope can clearly be improved -->
                    <biblScope source="oape:org:417">4:1-12 (1879-1880)</biblScope> 
                </bibl>
            </listBibl>
        </item>
    </list> 
</note>
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