<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- this stylesheet goes through the target file and tries to pull-in information from the source file (the TEI XML this XSLT is run on) -->
    <!-- workflow
        - collect a list of all biblStruct in the source based on their IDs
        - go over every biblStruct in the target
            + if its ID is in the list,
                - enrich
            + if the its ID is not in the list
                - identity transform
        - add all biblStruct from the source without ID to the target
    -->
    <!-- achievements
        - a file can be merged into itself without creating additional redundant descendants of any biblStruct!
    -->
    <!-- BUGs
        - this stylesheet failes on biblStruct in the target file with multiple monogr children
            - these multiple monogr children are all merged into one ...
            - therefore such biblStruct are not included in the merging process
       - sorting of idno
           - the content is alphanumeric but pure numbers should be sorted as such, i.e. 90 before 100
      - pubPlaces without placeName/@ref are omitted
      - some publishers go missing
    -->
    <!-- NOTE 
        - that all biblStruct in the target file must have a local <idno> 
        - to which extent are <item>s in <notes> merged or not?
        - should Arabic strings  be normalised before matching?
    -->
    <xsl:import href="functions.xsl"/>
    <xsl:param name="p_include-bibl" select="false()"/>
    <!-- define the target -->
    <xsl:variable name="v_bibliography-target">
        <xsl:choose>
            <xsl:when test="$p_debug = true()">
                <xsl:copy-of select="doc('../data/test-data/test_bibliography-merge_target.TEIP5.xml')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$v_bibliography"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- re-define $p_id-change -->
    <xsl:param name="p_id-change" select="generate-id($v_bibliography-target/descendant::tei:revisionDesc[1]/tei:change[last()])"/>
    <xsl:template match="/">
        <xsl:if test="$p_debug = true()">
            <xsl:message terminate="no">
                <xsl:value-of select="$p_id-change"/>
            </xsl:message>
            <xsl:message>
                <xsl:text>The source file contains bibliographic data for the following IDs: </xsl:text>
                <xsl:value-of select="$v_bibls-source-ids"/>
            </xsl:message>
        </xsl:if>
        <!-- BUG?! Currently, this template cannot NOT MERGE existing monogr children of the target -->
        <!-- this effects almost 30 biblStruct  in our main bibliography -->
        <xsl:if test="$v_bibliography-target//tei:standOff//tei:biblStruct[count(tei:monogr) > 1]">
            <xsl:message>
                <xsl:text>WARNING: The target contains </xsl:text>
                <xsl:value-of select="count($v_bibliography-target//tei:standOff//tei:biblStruct[count(tei:monogr) > 1])"/>
                <xsl:text> biblStruct with multiple monogr children</xsl:text>
            </xsl:message>
        </xsl:if>
        <!-- report the number of bibls in the source -->
        <xsl:result-document href="_output/bibl_merged/{$p_file-bibliography}">
            <xsl:apply-templates mode="m_merge" select="$v_bibliography-target"/>
        </xsl:result-document>
    </xsl:template>
    <!-- identity transform -->
    <xsl:template match="node() | @*" mode="m_merge">
        <xsl:copy>
            <xsl:apply-templates mode="m_merge" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- find all <bibl>s in current file and convert them to <biblStruct> -->
    <xsl:variable name="v_bibls-source">
        <!-- find all <bibl>s in current file and compile them if necessary -->
        <!-- convert <bibl>s to <biblStruct> -->
        <xsl:if test="$p_include-bibl = true()">
            <xsl:variable name="v_bibl">
                <xsl:for-each select="/descendant::tei:bibl[ancestor::tei:standOff or ancestor::tei:text]">
                    <xsl:choose>
                        <xsl:when test="@next">
                            <xsl:copy-of select="oape:compile-next-prev(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>
            <xsl:apply-templates mode="m_bibl-to-biblStruct" select="$v_bibl/descendant-or-self::tei:bibl"/>
        </xsl:if>
        <!-- find all <biblStruct> in the curent file and add @change, @source -->
        <!-- limit to periodicals! -->
        <xsl:apply-templates mode="m_copy-from-source" select="/descendant::tei:biblStruct[ancestor::tei:standOff or ancestor::tei:text][tei:monogr/tei:title/@level = 'j']">
            <!-- <xsl:apply-templates mode="m_copy-from-source" select="/descendant::tei:biblStruct[tei:monogr/tei:title/@ref[. != 'NA']][ancestor::tei:standOff or ancestor::tei:text]"> -->
            <!-- 5 seems a good choice to reduce the polution of notes with documentary attributes -->
            <xsl:with-param name="p_depth-of-documentation" select="5"/>
        </xsl:apply-templates>
    </xsl:variable>
    <!-- variable holding a comma-separated list of IDs -->
    <xsl:variable name="v_bibls-source-ids">
        <xsl:apply-templates mode="m_bibl-to-id" select="$v_bibls-source/tei:biblStruct"/>
    </xsl:variable>
    <xsl:template match="tei:biblStruct" mode="m_bibl-to-id">
        <!-- always look IDs up in the authority file, to make sure that biblStruct are correctly grouped! -->
        <xsl:choose>
            <!-- linked through idno: still better to look them up! -->
            <xsl:when test="tei:monogr/tei:idno[@type = $p_local-authority]">
                <xsl:variable name="v_title-temp">
                    <tei:title ref="{concat($p_local-authority, ':bibl:',tei:monogr/tei:idno[@type = $p_local-authority][1])}"/>
                </xsl:variable>
                <!--                <xsl:value-of select="oape:query-biblstruct(., 'id', '', $v_gazetteer, $p_local-authority)"/>-->
                <xsl:value-of select="oape:query-bibliography($v_title-temp/tei:title, $v_bibliography, '', $p_local-authority, 'id', '')"/>
            </xsl:when>
            <xsl:when test="tei:monogr/tei:idno[@type = $p_acronym-wikidata]">
                <xsl:variable name="v_title-temp">
                    <tei:title ref="{concat($p_acronym-wikidata, ':',tei:monogr/tei:idno[@type = $p_acronym-wikidata][1])}"/>
                </xsl:variable>
                <xsl:value-of select="oape:query-bibliography($v_title-temp/tei:title, $v_bibliography, '', $p_local-authority, 'id', '')"/>
            </xsl:when>
            <!-- linked through @ref -->
            <xsl:when test="tei:monogr/tei:title/@ref != 'NA'">
                <xsl:value-of select="oape:query-bibliography(tei:monogr/tei:title[@ref != 'NA'][1], $v_bibliography, '', $p_local-authority, 'id', '')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>INFO: found biblStruct not linked to the authority file</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="node() | @*" mode="m_copy-from-source">
        <xsl:param name="p_depth-of-documentation" select="1"/>
        <!-- source information -->
        <xsl:variable name="v_source">
            <xsl:variable name="v_base-uri" select="base-uri()"/>
            <xsl:variable name="v_bibl-source" select="ancestor-or-self::node()[local-name() = ('bibl', 'biblStruct')]/@source"/>
            <xsl:variable name="v_bibl-id" select="ancestor-or-self::node()[local-name() = ('bibl', 'biblStruct')]/@xml:id"/>
            <!-- if the there is already a source on the node, replicate it -->
            <xsl:choose>
                <xsl:when test="@source != ''">
                    <xsl:value-of select="@source"/>
                </xsl:when>
                <xsl:when test="$v_bibl-source != ''">
                    <xsl:value-of select="$v_bibl-source"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($v_base-uri, '#', $v_bibl-id)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates mode="m_copy-from-source" select="@*"/>
            <xsl:if test="$p_depth-of-documentation > 0">
                <!-- document change -->
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                <!-- document source of additional information -->
                <xsl:attribute name="source" select="$v_source"/>
            </xsl:if>
            <!-- content -->
            <xsl:apply-templates mode="m_copy-from-source" select="node()">
                <xsl:with-param name="p_depth-of-documentation" select="$p_depth-of-documentation - 1"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title" mode="m_copy-from-source">
        <!-- reproduce in full -->
        <!-- source information -->
        <xsl:variable name="v_source">
            <xsl:variable name="v_base-uri" select="base-uri()"/>
            <xsl:variable name="v_bibl-source" select="ancestor-or-self::node()[local-name() = ('bibl', 'biblStruct')]/@source"/>
            <xsl:variable name="v_bibl-id" select="ancestor-or-self::node()[local-name() = ('bibl', 'biblStruct')]/@xml:id"/>
            <!-- if the there is already a source on the node, replicate it -->
            <xsl:choose>
                <xsl:when test="@source != ''">
                    <xsl:value-of select="@source"/>
                </xsl:when>
                <xsl:when test="$v_bibl-source != ''">
                    <xsl:value-of select="$v_bibl-source"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($v_base-uri, '#', $v_bibl-id)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates mode="m_copy-from-source" select="@*"/>
            <!-- document change -->
            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            <!-- document source of additional information -->
            <xsl:attribute name="source" select="$v_source"/>
            <!-- content -->
            <xsl:apply-templates mode="m_identity-transform" select="node()"/>
        </xsl:copy>
        <!-- add idnos if title has @ref attribute -->
        <xsl:if test="@ref">
            <xsl:for-each select="tokenize(@ref, '\s+')">
                <xsl:variable name="v_authority">
                    <xsl:choose>
                        <xsl:when test="contains(., 'oclc:')">
                            <xsl:text>OCLC</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains(., 'jaraid:')">
                            <xsl:text>jaraid</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains(., 'oape:')">
                            <xsl:text>oape</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'NA'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="v_local-uri-scheme" select="concat($v_authority, ':bibl:')"/>
                <xsl:variable name="v_idno">
                    <xsl:choose>
                        <xsl:when test="contains(., 'oclc:')">
                            <xsl:value-of select="replace(., '.*oclc:(\d+).*', '$1')"/>
                        </xsl:when>
                        <xsl:when test="contains(., $v_local-uri-scheme)">
                            <!-- local IDs in Project Jaraid are not nummeric for biblStructs -->
                            <xsl:value-of select="replace(., concat('.*', $v_local-uri-scheme, '(\w+).*'), '$1')"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:if test="$v_authority != 'NA'">
                    <idno type="{$v_authority}">
                        <xsl:value-of select="$v_idno"/>
                    </idno>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <!-- do not copy certain attributes from one file to another -->
    <xsl:template match="@xml:id | @change | @next | @prev" mode="m_copy-from-source"/>
    <!-- update existing <biblStruct -->
    <!-- this is run on the target file -->
    <xsl:template match="tei:biblStruct[ancestor::tei:standOff]" mode="m_merge" priority="11">
        <xsl:variable name="v_target" select="."/>
        <xsl:variable name="v_id-target" select="oape:query-biblstruct($v_target, 'id', '', $v_gazetteer, $p_local-authority)"/>
        <xsl:if test="$p_debug = true()">
            <xsl:message>
                <xsl:text>INFO: checking if the source contains information on the ID "</xsl:text>
                <xsl:value-of select="$v_id-target"/>
                <xsl:text>"</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:choose>
            <!-- BUG?! Currently, this template cannot NOT MERGE existing monogr children of the target -->
            <!-- this effects almost 30 biblStruct  in our main bibliography -->
            <xsl:when test="count(tei:monogr) > 1">
                <xsl:message>
                    <xsl:text>WARNING: The target "</xsl:text>
                    <xsl:value-of select="$v_id-target"/>
                    <xsl:text>" has multiple monogr children and will be retained as is</xsl:text>
                </xsl:message>
                <xsl:apply-templates mode="m_identity-transform" select="."/>
            </xsl:when>
            <!-- check if the target is also mentioned in the source file -->
            <xsl:when test="matches($v_bibls-source-ids, concat($v_id-target, '(,|$)'))">
                <!-- get the source: this should only every return a single biblStruct -->
                <!-- BUT  the source file could hold multiple biblStruct nodes pointing to the same biblStruct in the target -->
                <xsl:variable name="v_source">
                    <xsl:for-each
                        select="$v_bibls-source/descendant-or-self::tei:biblStruct[tei:monogr/tei:title/@ref != 'NA' or tei:monogr/tei:idno[@type = ($p_local-authority, $p_acronym-wikidata)]]">
                        <!-- this function call is computationally expensive as it is invoked every time a match has been found in the source file -->
                        <!--                        <xsl:variable name="v_id-source" select="oape:query-bibliography(tei:monogr/tei:title[@ref != 'NA'][1], $v_bibliography, '', $p_local-authority, 'id', '')"/>-->
                        <xsl:variable name="v_id-source">
                            <xsl:choose>
                                <!-- linked through idno: still better to look them up! -->
                                <xsl:when test="tei:monogr/tei:idno[@type = $p_local-authority]">
                                    <xsl:variable name="v_title-temp">
                                        <tei:title ref="{concat($p_local-authority, ':bibl:',tei:monogr/tei:idno[@type = $p_local-authority][1])}"/>
                                    </xsl:variable>
                                    <!--                <xsl:value-of select="oape:query-biblstruct(., 'id', '', $v_gazetteer, $p_local-authority)"/>-->
                                    <xsl:value-of select="oape:query-bibliography($v_title-temp/tei:title, $v_bibliography, '', $p_local-authority, 'id', '')"/>
                                </xsl:when>
                                <xsl:when test="tei:monogr/tei:idno[@type = $p_acronym-wikidata]">
                                    <xsl:variable name="v_title-temp">
                                        <tei:title ref="{concat($p_acronym-wikidata, ':',tei:monogr/tei:idno[@type = $p_acronym-wikidata][1])}"/>
                                    </xsl:variable>
                                    <xsl:value-of select="oape:query-bibliography($v_title-temp/tei:title, $v_bibliography, '', $p_local-authority, 'id', '')"/>
                                </xsl:when>
                                <!-- linked through @ref -->
                                <xsl:when test="tei:monogr/tei:title/@ref != 'NA'">
                                    <xsl:value-of select="oape:query-bibliography(tei:monogr/tei:title[@ref != 'NA'][1], $v_bibliography, '', $p_local-authority, 'id', '')"/>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <!-- match based on IDs -->
                        <xsl:if test="$v_id-source = $v_id-target">
                            <xsl:apply-templates mode="m_identity-transform" select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                <!--<xsl:variable name="v_source-compiled">
                    <xsl:call-template name="t_merge-biblstructs">
                        <xsl:with-param name="p_biblstructs" select="$v_source"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:apply-templates select="oape:merge-2-biblStruct($v_source-compiled/tei:biblStruct, $v_target)" mode="m_post-process"/>-->
                <xsl:variable name="v_target-source-compiled">
                    <xsl:copy-of select="$v_target"/>
                    <xsl:copy-of select="$v_source"/>
                </xsl:variable>
                <xsl:copy-of select="oape:merge-biblStructs($v_target-source-compiled)"/>
                <xsl:message terminate="no">
                    <xsl:text>SUCCESS: The target was updated with data for "</xsl:text>
                    <xsl:value-of select="$v_id-target"/>
                    <xsl:text>" from the source</xsl:text>
                </xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>WARNING: no additional information found for </xsl:text>
                        <xsl:value-of select="$v_id-target"/>
                    </xsl:message>
                </xsl:if>
                <xsl:apply-templates mode="m_identity-transform" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:function name="oape:merge-biblStructs">
        <!-- assume a sorted input of multiple biblstructs -->
        <xsl:param name="p_biblstructs" as="node()"/>
        <xsl:variable name="v_count" select="count($p_biblstructs/descendant-or-self::tei:biblStruct)"/>
        <!--        <xsl:if test="$p_debug = true()">-->
        <xsl:message>
            <xsl:text>INFO: There are </xsl:text>
            <xsl:value-of select="$v_count"/>
            <xsl:text> biblStruct to be merged</xsl:text>
        </xsl:message>
        <!--</xsl:if>-->
        <xsl:choose>
            <xsl:when test="$v_count = 1">
                <xsl:copy-of select="$p_biblstructs"/>
            </xsl:when>
            <xsl:when test="$v_count = 2">
                <xsl:apply-templates mode="m_post-process" select="oape:merge-2-biblStruct($p_biblstructs/descendant-or-self::tei:biblStruct[2], $p_biblstructs/descendant-or-self::tei:biblStruct[1])"
                />
            </xsl:when>
            <xsl:when test="$v_count > 2">
                <!-- merge the first two  -->
                <xsl:variable name="v_merged">
                    <xsl:apply-templates mode="m_post-process"
                        select="oape:merge-2-biblStruct($p_biblstructs/descendant-or-self::tei:biblStruct[2], $p_biblstructs/descendant-or-self::tei:biblStruct[1])"/>
                </xsl:variable>
                <!-- combine the merged and the remaining biblStructs -->
                <xsl:variable name="v_remaining">
                    <xsl:copy-of select="$v_merged"/>
                    <xsl:copy-of select="$p_biblstructs/descendant-or-self::tei:biblStruct[position() > 2]"/>
                </xsl:variable>
                <!-- call this template again -->
                <xsl:copy-of select="oape:merge-biblStructs($v_remaining)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="node() | @*" mode="m_post-process">
        <xsl:copy>
            <xsl:apply-templates mode="m_post-process" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- remove attributes in post processing -->
    <xsl:template match="tei:idno[@type = ($p_local-authority, $p_acronym-wikidata)]/@source | tei:imprint/@source | tei:monogr/@source | tei:note/@source | node()[@xml:lang][empty(.)]/@xml:lang"
        mode="m_post-process" priority="10"/>
    <xsl:template match="@source[parent::node()/@source]" priority="9"/>
    <!-- try and unify overboarding source information -->
    <xsl:template mode="m_post-process" match="@source">
        <xsl:attribute name="source">
            <xsl:for-each select="tokenize(., '\s+')">
                <xsl:sort select="."/>
                <xsl:value-of select="."/>
                <xsl:if test="position() != last()">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="tei:title/text()" mode="m_post-process">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    <xsl:function name="oape:merge-2-biblStruct">
        <xsl:param as="node()" name="p_source"/>
        <xsl:param as="node()" name="p_target"/>
        <!-- combine source and target -->
        <xsl:variable name="v_combined-monogr">
            <xsl:copy-of select="$p_target/tei:monogr/element()"/>
            <xsl:copy-of select="$p_source/tei:monogr/element()"/>
        </xsl:variable>
        <xsl:variable name="v_combined-imprint">
            <xsl:copy-of select="$v_combined-monogr/tei:imprint/element()"/>
        </xsl:variable>
        <xsl:variable name="v_combined-note">
            <xsl:copy-of select="$p_target/tei:note"/>
            <xsl:copy-of select="$p_source/tei:note"/>
        </xsl:variable>
        <xsl:copy select="$p_target">
            <!-- merge attributes -->
            <xsl:copy-of select="oape:merge-attributes($p_source, $p_target)"/>
            <!-- analytic -->
            <!-- monogr -->
            <xsl:copy select="$p_target/tei:monogr[1]">
                <!-- merge attributes -->
                <xsl:copy-of select="oape:merge-attributes($p_source/tei:monogr, $p_target/tei:monogr)"/>
                <!-- title -->
                <xsl:for-each-group group-by="normalize-space(.)" select="$v_combined-monogr/tei:title">
                    <xsl:sort select="current-group()[1]/@type"/>
                    <xsl:sort select="current-grouping-key()"/>
                    <xsl:call-template name="t_merge-groups">
                        <xsl:with-param name="p_current-group" select="current-group()"/>
                        <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                    </xsl:call-template>
                </xsl:for-each-group>
                <!-- <xsl:merge>
                    <xsl:merge-source name="target" select="$p_target/tei:monogr/tei:idno" sort-before-merge="yes">
                        <xsl:merge-key select="@type" order="ascending"/>
                        <xsl:merge-key select="normalize-space(.)" order="ascending"/>
                    </xsl:merge-source>
                    <xsl:merge-source name="source" select="$p_source/tei:monogr/tei:idno" sort-before-merge="yes">
                        <xsl:merge-key select="@type" order="ascending"/>
                        <xsl:merge-key select="normalize-space(.)" order="ascending"/>
                    </xsl:merge-source>
                    <xsl:merge-action>
                        <xsl:sequence select="current-merge-group()"/>
                        <!-\-<xsl:choose>
                            <!-\\- unique values in target -\\->
                            <xsl:when test="empty(current-merge-group('source'))">
                                <xsl:copy-of select="current-merge-group('target')"/>
                            </xsl:when>
                            <!-\\- unique values in source -\\->
                            <xsl:when test="empty(current-merge-group('target'))">
                                <xsl:copy-of select="current-merge-group('source')"/>
                            </xsl:when>
                            <!-\\- merge values -\\->
                            <xsl:otherwise>
                                <xsl:sequence select="current-merge-group()"/>
                            </xsl:otherwise>
                        </xsl:choose>-\->
                    </xsl:merge-action>
                </xsl:merge>-->
                <!-- idno -->
                <xsl:for-each-group group-by="@type" select="$v_combined-monogr/tei:idno">
                    <xsl:sort select="current-grouping-key()"/>
                    <xsl:call-template name="t_merge-groups-by-text">
                        <xsl:with-param name="p_current-group" select="current-group()"/>
                    </xsl:call-template>
                </xsl:for-each-group>
                <!-- textLang -->
                <xsl:for-each-group group-by="@mainLang" select="$v_combined-monogr/tei:textLang">
                    <xsl:sort select="current-grouping-key()"/>
                    <xsl:call-template name="t_merge-groups">
                        <xsl:with-param name="p_current-group" select="current-group()"/>
                        <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                        <xsl:with-param name="p_grouping-key-is-attribute-value" select="true()"/>
                    </xsl:call-template>
                </xsl:for-each-group>
                <!-- editors -->
                <xsl:for-each-group group-by="element()/@ref" select="$v_combined-monogr/tei:editor[element()/@ref]">
                    <xsl:call-template name="t_merge-groups">
                        <xsl:with-param name="p_current-group" select="current-group()"/>
                        <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                        <!-- cover persName children -->
                        <!-- note: persNames might have a lot of mark-up that will thus be omitted -->
                        <xsl:with-param name="p_depth-of-merging" select="4"/>
                    </xsl:call-template>
                </xsl:for-each-group>
                <xsl:for-each-group group-by="element()" select="$v_combined-monogr/tei:editor[not(element()/@ref)]">
                    <xsl:call-template name="t_merge-groups">
                        <xsl:with-param name="p_current-group" select="current-group()"/>
                        <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                        <!-- cover persName children -->
                        <!-- note: persNames might have a lot of mark-up that will thus be omitted -->
                        <xsl:with-param name="p_depth-of-merging" select="4"/>
                    </xsl:call-template>
                </xsl:for-each-group>
                <!-- respStmt -->
                <xsl:for-each-group group-by="tei:resp" select="$v_combined-monogr/tei:respStmt">
                    <xsl:call-template name="t_merge-groups">
                        <xsl:with-param name="p_current-group" select="current-group()"/>
                        <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                        <xsl:with-param name="p_depth-of-merging" select="2"/>
                    </xsl:call-template>
                </xsl:for-each-group>
                <!-- imprint -->
                <xsl:copy select="$v_combined-monogr/tei:imprint[1]">
                    <xsl:copy-of select="oape:merge-attributes($p_source/tei:monogr/tei:imprint, $p_target/tei:monogr/tei:imprint)"/>
                    <!-- pubPlace -->
                    <xsl:for-each-group group-by="tei:placeName/@ref" select="$v_combined-imprint/tei:pubPlace[element()/@ref]">
                        <xsl:call-template name="t_merge-groups">
                            <xsl:with-param name="p_current-group" select="current-group()"/>
                            <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                            <!-- cover placeName children -->
                            <xsl:with-param name="p_depth-of-merging" select="1"/>
                        </xsl:call-template>
                    </xsl:for-each-group>
                    <xsl:for-each-group group-by="element()" select="$v_combined-imprint/tei:pubPlace[not(element()/@ref)]">
                        <xsl:call-template name="t_merge-groups">
                            <xsl:with-param name="p_current-group" select="current-group()"/>
                            <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                            <!-- cover placeName children -->
                            <xsl:with-param name="p_depth-of-merging" select="1"/>
                        </xsl:call-template>
                    </xsl:for-each-group>
                    <!-- publisher -->
                    <xsl:for-each-group group-by="element()/@ref" select="$v_combined-imprint/tei:publisher[element()/@ref]">
                        <xsl:call-template name="t_merge-groups">
                            <xsl:with-param name="p_current-group" select="current-group()"/>
                            <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                            <!-- cover orgName children -->
                            <xsl:with-param name="p_depth-of-merging" select="4"/>
                        </xsl:call-template>
                    </xsl:for-each-group>
                    <xsl:for-each-group group-by="element()" select="$v_combined-imprint/tei:publisher[not(element()/@ref)]">
                        <xsl:call-template name="t_merge-groups">
                            <xsl:with-param name="p_current-group" select="current-group()"/>
                            <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                            <!-- cover orgName children -->
                            <xsl:with-param name="p_depth-of-merging" select="4"/>
                        </xsl:call-template>
                    </xsl:for-each-group>
                    <!-- date -->
                    <!-- NOTE: there are 200+ dates without @type in the target -->
                    <xsl:for-each-group group-by="@type" select="$v_combined-imprint/tei:date[@type]">
                        <xsl:sort select="current-group()[@when][1]/@when"/>
                        <xsl:sort select="current-grouping-key()"/>
                        <xsl:call-template name="t_merge-groups-attr.datable">
                            <xsl:with-param name="p_current-group" select="current-group()"/>
                        </xsl:call-template>
                    </xsl:for-each-group>
                    <!-- fall-back: reproduce all untyped dates -->
                    <xsl:apply-templates mode="m_identity-transform" select="$v_combined-imprint/tei:date[not(@type)]"/>
                </xsl:copy>
                <!-- biblScope -->
                <xsl:for-each-group group-by="@unit" select="$v_combined-monogr/tei:biblScope">
                    <xsl:sort select="current-grouping-key()"/>
                    <!-- this will delete all biblScope without both attributes -->
                    <xsl:for-each-group group-by="." select="current-group()[(@from, @to)]">
                        <xsl:call-template name="t_merge-groups-attr_from-to">
                            <xsl:with-param name="p_current-group" select="current-group()"/>
                        </xsl:call-template>
                    </xsl:for-each-group>
                </xsl:for-each-group>
            </xsl:copy>
            <!-- note -->
            <xsl:for-each-group group-by="@type" select="$v_combined-note/tei:note">
                <xsl:sort select="current-grouping-key()"/>
                <xsl:variable name="v_combined-list">
                    <xsl:copy-of select="current-group()/tei:list"/>
                </xsl:variable>
                <xsl:variable name="v_combined-direct-text">
                    <xsl:value-of select="current-group()/text()"/>
                </xsl:variable>
                <xsl:copy select="current-group()[1]">
                    <xsl:copy-of select="oape:merge-attributes(current-group()[1], current-group()[2])"/>
                    <!-- deal with lists -->
                    <xsl:copy select="$v_combined-list/tei:list[1]">
                        <!-- I do not current want to check whether some items should be merged -->
                        <xsl:apply-templates mode="m_identity-transform" select="$v_combined-list/tei:list/tei:item">
                            <!-- sort by location, institution, label -->
                            <xsl:sort select="tei:label/tei:orgName"/>
                            <xsl:sort select="tei:label/tei:placeName"/>
                            <xsl:sort select="tei:label"/>
                        </xsl:apply-templates>
                        <!--<xsl:for-each-group group-by="tei:label" select="$v_combined-list/tei:list/tei:item">
                            <xsl:call-template name="t_merge-groups">
                                <xsl:with-param name="p_current-group" select="current-group()"/>
                                <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                                <xsl:with-param name="p_depth-of-merging" select="0"/>
                            </xsl:call-template>
                        </xsl:for-each-group>-->
                    </xsl:copy>
                    <!-- other children -->
                    <xsl:apply-templates mode="m_identity-transform" select="current-group()/element()[not(self::tei:list)]"/>
                    <!-- this seemingly doesn't work -->
                    <xsl:if test="normalize-space($v_combined-direct-text) != ''">
                        <xsl:element name="ab">
                            <xsl:value-of select="normalize-space($v_combined-direct-text)"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:copy>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:function>
    <xsl:template name="t_merge-groups">
        <xsl:param name="p_current-group"/>
        <xsl:param name="p_current-grouping-key"/>
        <xsl:param name="p_grouping-key-is-attribute-value" select="false()"/>
        <!-- the default depth of merging is  1, which allows for merging of persName, placeName, and orgName children -->
        <xsl:param name="p_depth-of-merging" select="1"/>
        <xsl:copy select="$p_current-group[1]">
            <xsl:choose>
                <xsl:when test="count($p_current-group) > 1">
                    <xsl:copy-of select="oape:merge-attributes($p_current-group[1], $p_current-group[2])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$p_current-group[1]/@*"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <!-- run merging only on the first level of child elements -->
                <xsl:when test="$p_depth-of-merging > 0 and $p_current-group/node()">
                    <!-- this seems to work sufficiently well for persName, placeName, and orgName children -->
                    <!-- PROBLEM: some persName contain a lot of mark-up -->
                    <xsl:for-each-group group-by="." select="$p_current-group/node()">
                        <xsl:call-template name="t_merge-groups">
                            <xsl:with-param name="p_current-group" select="current-group()"/>
                            <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
                            <xsl:with-param name="p_grouping-key-is-attribute-value" select="false()"/>
                            <!-- decrease the depth of merging with increasing progress -->
                            <xsl:with-param name="p_depth-of-merging" select="$p_depth-of-merging - 1"/>
                        </xsl:call-template>
                    </xsl:for-each-group>
                </xsl:when>
                <!-- suppress content when the input had none -->
                <xsl:when test="$p_grouping-key-is-attribute-value = true()"/>
                <xsl:otherwise>
                    <xsl:copy-of select="$p_current-grouping-key"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <xsl:template name="t_merge-groups-by-text">
        <xsl:param name="p_current-group"/>
        <xsl:for-each-group group-by="normalize-space(.)" select="$p_current-group">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:call-template name="t_merge-groups">
                <xsl:with-param name="p_current-group" select="current-group()"/>
                <xsl:with-param name="p_current-grouping-key" select="current-grouping-key()"/>
            </xsl:call-template>
        </xsl:for-each-group>
    </xsl:template>
    <xsl:template name="t_merge-groups-attr.datable">
        <xsl:param name="p_current-group"/>
        <!-- @when -->
        <xsl:for-each-group group-by="@when" select="$p_current-group[@when]">
            <xsl:sort select="current-grouping-key()"/>
            <!-- do not merge dates from different dating systems -->
            <!-- this removes all dates wich do not carry the @when-custom attribute -->
            <xsl:for-each-group group-by="@when-custom" select="current-group()[@when-custom]">
                <xsl:call-template name="t_merge-groups-by-text">
                    <xsl:with-param name="p_current-group" select="current-group()"/>
                </xsl:call-template>
            </xsl:for-each-group>
            <xsl:for-each-group group-by="." select="current-group()[not(@when-custom)]">
                <xsl:call-template name="t_merge-groups-by-text">
                    <xsl:with-param name="p_current-group" select="current-group()"/>
                </xsl:call-template>
            </xsl:for-each-group>
        </xsl:for-each-group>
        <!-- @notAfter and @notBefore can occur independtly from each other, but are not allowed if @when, @from or @to are present -->
        <xsl:for-each-group group-by="@notAfter" select="$p_current-group[@notAfter][@notBefore]">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:for-each-group group-by="@notBefore" select="current-group()">
                <xsl:call-template name="t_merge-groups-by-text">
                    <xsl:with-param name="p_current-group" select="current-group()"/>
                </xsl:call-template>
            </xsl:for-each-group>
        </xsl:for-each-group>
        <xsl:for-each-group group-by="@notAfter" select="$p_current-group[@notAfter][not(@notBefore)]">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:call-template name="t_merge-groups-by-text">
                <xsl:with-param name="p_current-group" select="current-group()"/>
            </xsl:call-template>
        </xsl:for-each-group>
        <xsl:for-each-group group-by="@notBefore" select="$p_current-group[not(@notAfter)][@notBefore]">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:call-template name="t_merge-groups-by-text">
                <xsl:with-param name="p_current-group" select="current-group()"/>
            </xsl:call-template>
        </xsl:for-each-group>
        <!-- @from and @to can occur independtly from each other, but are not allowed if @when, @notBefore or @notAfter are present -->
        <xsl:for-each-group group-by="." select="$p_current-group[(@from, @to)]">
            <xsl:call-template name="t_merge-groups-attr_from-to">
                <xsl:with-param name="p_current-group" select="current-group()"/>
            </xsl:call-template>
        </xsl:for-each-group>
    </xsl:template>
    <xsl:template name="t_merge-groups-attr_from-to">
        <xsl:param name="p_current-group"/>
        <xsl:for-each-group group-by="@from" select="$p_current-group[@from][@to]">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:for-each-group group-by="@to" select="current-group()">
                <xsl:call-template name="t_merge-groups-by-text">
                    <xsl:with-param name="p_current-group" select="current-group()"/>
                </xsl:call-template>
            </xsl:for-each-group>
        </xsl:for-each-group>
        <xsl:for-each-group group-by="@from" select="$p_current-group[@from][not(@to)]">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:call-template name="t_merge-groups-by-text">
                <xsl:with-param name="p_current-group" select="current-group()"/>
            </xsl:call-template>
        </xsl:for-each-group>
        <xsl:for-each-group group-by="@to" select="$p_current-group[not(@from)][@to]">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:call-template name="t_merge-groups-by-text">
                <xsl:with-param name="p_current-group" select="current-group()"/>
            </xsl:call-template>
        </xsl:for-each-group>
    </xsl:template>
    <xsl:function name="oape:merge-attributes">
        <xsl:param name="p_source"/>
        <xsl:param name="p_target"/>
        <!-- list all attributes -->
        <xsl:variable name="v_source-attr">
            <xsl:for-each select="$p_source/@*">
                <xsl:value-of select="name()"/>
                <xsl:if test="not(position() = last())">
                    <xsl:value-of select="$v_comma"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="v_target-attr">
            <xsl:for-each select="$p_target/@*">
                <xsl:value-of select="name()"/>
                <xsl:if test="not(position() = last())">
                    <xsl:value-of select="$v_comma"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <!-- copy unique attributes -->
        <xsl:for-each select="$p_source/@*[not(contains($v_target-attr, name()))]">
            <xsl:apply-templates mode="m_merge" select="."/>
        </xsl:for-each>
        <xsl:for-each select="$p_target/@*[not(contains($v_source-attr, name()))]">
            <xsl:apply-templates mode="m_merge" select="."/>
        </xsl:for-each>
        <!-- merge attributes present on both source and target -->
        <xsl:for-each select="$p_target/@*[contains($v_source-attr, name())]">
            <xsl:variable name="v_name" select="name()"/>
            <xsl:variable name="v_source-value" select="$p_source/@*[name() = $v_name]"/>
            <xsl:attribute name="{$v_name}">
                <!-- copy value of target -->
                <xsl:value-of select="."/>
                <xsl:if test="not(. = $v_source-value)">
                    <xsl:value-of select="concat(' ', $v_source-value)"/>
                </xsl:if>
            </xsl:attribute>
        </xsl:for-each>
    </xsl:function>
    <!-- omit attributes:
        - @xml:lang on some nodes that should not have any textual content 
    -->
    <xsl:template match="@change | tei:title/@ref | tei:biblStruct/@xml:lang | tei:monogr/@xml:lang | tei:imprint/@xml:lang" mode="m_merge"/>
    <!-- add <biblStruct> from source not currently available in the target -->
    <xsl:template match="tei:standOff" mode="m_merge">
        <xsl:message>
            <xsl:text>INFO: The source contains </xsl:text>
            <xsl:value-of select="count($v_bibls-source/tei:biblStruct)"/>
            <xsl:text> IDs to be merged into the target</xsl:text>
        </xsl:message>
        <xsl:copy>
            <!-- reproduce and update bibls found in the source  -->
            <xsl:apply-templates mode="m_merge" select="@* | node()"/>
            <!-- add bibls NOT found in the source -->
            <xsl:element name="listBibl">
                <xsl:element name="head">
                    <xsl:text>Entries from </xsl:text>
                    <xsl:value-of select="$v_name-file"/>
                </xsl:element>
                <!--                <xsl:apply-templates mode="m_copy-from-source" select="$v_bibls-source/descendant-or-self::tei:biblStruct[not(tei:monogr/tei:title/@ref)]"/>-->
                <!-- this condition will leas to many false positives -->
                <xsl:apply-templates mode="m_copy-from-source"
                    select="$v_bibls-source/descendant-or-self::tei:biblStruct[tei:monogr/tei:title[@ref = 'NA'][not(parent::tei:monogr/tei:title/@ref != 'NA')]]"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <!-- document the changes -->
    <xsl:template match="tei:revisionDesc" mode="m_merge">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:element name="change">
                <xsl:attribute name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:text>Merged bibliographic information from "</xsl:text>
                <xsl:element name="ref">
                    <xsl:attribute name="target" select="$v_url-file"/>
                    <xsl:value-of select="$v_name-file"/>
                </xsl:element>
                <xsl:text>" into this file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates mode="m_identity-transform" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- PLAYGROUND -->
    <xsl:function name="oape:merge-nodes-2">
        <xsl:param as="node()" name="p_source"/>
        <xsl:param as="node()" name="p_target"/>
        <!-- check if source and target are the same element -->
        <xsl:variable name="v_source-name" select="$p_source/local-name()"/>
        <xsl:variable name="v_target-name" select="$p_target/local-name()"/>
        <xsl:variable name="v_input-names-matches" select="
                if ($v_source-name = $v_target-name) then
                    (true())
                else
                    (false())"/>
        <!-- when should source and target be merged? -->
        <xsl:choose>
            <!-- fundamental condition: same element name -->
            <xsl:when test="$v_input-names-matches = true()">
                <!-- 1. condition: similar textual content -->
                <!-- 2. condition: decisive attributes -->
                <!-- the combination of these conditions depends on the element name -->
                <!-- these decisions have been moved into the selection of child elements to be merged -->
                <xsl:variable name="v_merge" select="true()"> </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$v_merge = true()">
                        <xsl:copy select="$p_source">
                            <!-- merge attributes -->
                            <xsl:copy-of select="oape:merge-attributes($p_source, $p_target)"/>
                            <!-- list all elements -->
                            <xsl:variable name="v_source-nodes">
                                <xsl:for-each select="$p_source/element()">
                                    <xsl:value-of select="local-name()"/>
                                    <xsl:if test="not(position() = last())">
                                        <xsl:value-of select="$v_comma"/>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:variable name="v_target-nodes">
                                <xsl:for-each select="$p_target/element()">
                                    <xsl:value-of select="local-name()"/>
                                    <xsl:if test="not(position() = last())">
                                        <xsl:value-of select="$v_comma"/>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:variable>
                            <!-- copy unique nodes with unique element names -->
                            <!-- PROBLEM: this changes the order of child elements -->
                            <xsl:for-each select="$p_source/element()[not(contains($v_target-nodes, local-name()))]">
                                <xsl:apply-templates mode="m_identity-transform" select="."/>
                            </xsl:for-each>
                            <xsl:for-each select="$p_target/element()[not(contains($v_source-nodes, local-name()))]">
                                <xsl:apply-templates mode="m_identity-transform" select="."/>
                            </xsl:for-each>
                            <!-- The folllowing needs more work!!! -->
                            <!-- merge elements present on both source and target -->
                            <xsl:for-each select="$p_target/element()[contains($v_source-nodes, local-name())]">
                                <xsl:variable name="v_target" select="."/>
                                <!-- NOTE: this is a place holder, as it only looks at the first child element of the source with a given name -->
                                <xsl:for-each select="$p_source/element()[local-name() = $v_target/local-name()]">
                                    <xsl:variable name="v_source" select="."/>
                                    <xsl:variable name="v_source-text">
                                        <xsl:value-of select="$v_source/text()"/>
                                    </xsl:variable>
                                    <xsl:variable name="v_target-text">
                                        <xsl:value-of select="$v_target/text()"/>
                                    </xsl:variable>
                                    <xsl:variable name="v_input-text-matches" select="
                                            if (normalize-space($v_source-text) = normalize-space($v_target-text)) then
                                                (true())
                                            else
                                                (false())"/>
                                    <xsl:variable name="v_merge">
                                        <xsl:choose>
                                            <!-- element names that prevent merging -->
                                            <xsl:when test="$v_source/local-name() = 'note'">
                                                <xsl:copy-of select="false()"/>
                                            </xsl:when>
                                            <!-- attributes that prevent merging -->
                                            <xsl:when test="$v_source/@type != $v_target/@type">
                                                <xsl:message>
                                                    <xsl:value-of select="$v_source/local-name()"/>
                                                    <xsl:text>: The @type attribute values on source (</xsl:text>
                                                    <xsl:value-of select="$v_source/@type"/>
                                                    <xsl:text>) and target (</xsl:text>
                                                    <xsl:value-of select="$v_target/@type"/>
                                                    <xsl:text>) do not match</xsl:text>
                                                </xsl:message>
                                                <xsl:copy-of select="false()"/>
                                            </xsl:when>
                                            <xsl:when test="$v_source/@level != $v_target/@level">
                                                <xsl:message>
                                                    <xsl:value-of select="$v_source/local-name()"/>
                                                    <xsl:text>: The @level attribute values on source (</xsl:text>
                                                    <xsl:value-of select="$v_source/@level"/>
                                                    <xsl:text>) and target (</xsl:text>
                                                    <xsl:value-of select="$v_target/@level"/>
                                                    <xsl:text>) do not match</xsl:text>
                                                </xsl:message>
                                                <xsl:copy-of select="false()"/>
                                            </xsl:when>
                                            <!-- content that prevents merging -->
                                            <xsl:when test="$v_input-text-matches = false()">
                                                <xsl:message>
                                                    <xsl:value-of select="$v_source/local-name()"/>
                                                    <xsl:text>: The text() of source and target do not match</xsl:text>
                                                </xsl:message>
                                                <xsl:copy-of select="false()"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:copy-of select="true()"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    <xsl:choose>
                                        <!-- children shall be merged -->
                                        <xsl:when test="$v_merge = true()">
                                            <xsl:copy-of select="oape:merge-nodes-2($v_source, $v_target)"/>
                                        </xsl:when>
                                        <xsl:when test="$v_merge = false()">
                                            <!-- if we copy both the source and the target information here, we create tens of unnecessary duplicates -->
                                            <!--<xsl:apply-templates select="$v_target" mode="m_identity-transform"/>
                                                <xsl:apply-templates select="$v_source" mode="m_identity-transform"/>--> </xsl:when>
                                    </xsl:choose>
                                </xsl:for-each>
                            </xsl:for-each>
                            <!-- reproduce the textual content -->
                            <xsl:value-of select="$p_target/text()"/>
                        </xsl:copy>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:text>WARNING: Source and target could not be merged.</xsl:text>
                        </xsl:message>
                        <xsl:apply-templates mode="m_identity-transform" select="$p_source"/>
                        <xsl:apply-templates mode="m_identity-transform" select="$p_target"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>WARNING: Source and target do not have the same name.</xsl:text>
                </xsl:message>
                <xsl:apply-templates mode="m_identity-transform" select="$p_source"/>
                <xsl:apply-templates mode="m_identity-transform" select="$p_target"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>
