<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:zot="https://zotero.org" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="no" method="xml" omit-xml-declaration="no" version="1.0"/>
    <!-- the plan:
    - enrich an existing bibliography by adding information **to** a master file 
    - already existing entries shall be enriched with clearly marked information.
         + add a <biblStruct> child with the additional information
    - new entries can just be added from the external file. -->
    <!-- problems:
    - <ref> children are ignored
     -->
    <xsl:include href="functions.xsl"/>
    <!-- find all <bibl>s in current file and convert them to <biblStruct> -->
    <xsl:variable name="v_bibls-in-file-current">
        <!-- find all <bibl>s in current file and compile them if necessary -->
        <xsl:variable name="v_bibl">
            <xsl:for-each select="/descendant::tei:bibl">
                <xsl:copy-of select="oape:compile-next-prev(.)"/>
            </xsl:for-each>
        </xsl:variable>
        <!-- convert <bibl>s to <biblStruct> -->
        <xsl:variable name="v_biblStruct">
            <xsl:apply-templates mode="m_bibl-to-biblStruct" select="$v_bibl/descendant-or-self::tei:bibl"/>
            <!-- find all <biblStruct> in the curent file -->
            <xsl:apply-templates mode="m_copy-from-source" select="/descendant::tei:biblStruct"/>
        </xsl:variable>
        <xsl:copy-of select="$v_biblStruct"/>
    </xsl:variable>
    <xsl:template match="/">
        <xsl:message>
            <xsl:text>enriching authority file (main bibliography)</xsl:text>
        </xsl:message>
        <xsl:copy>
            <xsl:apply-templates select="$v_bibliography/*"/>
        </xsl:copy>
    </xsl:template>
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="node() | @*" mode="m_copy-from-source">
        <!-- source information -->
        <xsl:variable name="v_source">
            <xsl:variable name="v_base-uri" select="base-uri()"/>
            <xsl:variable name="v_bibl-source" select="ancestor-or-self::node()[name() = ('bibl', 'biblStruct')]/@source"/>
            <xsl:variable name="v_bibl-id" select="ancestor-or-self::node()[name() = ('bibl', 'biblStruct')]/@xml:id"/>
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
            <xsl:apply-templates mode="m_copy-from-source" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title" mode="m_copy-from-source">
        <!-- reproduce in full -->
        <!-- source information -->
        <xsl:variable name="v_source">
            <xsl:variable name="v_base-uri" select="base-uri()"/>
            <xsl:variable name="v_bibl-source" select="ancestor-or-self::node()[name() = ('bibl', 'biblStruct')]/@source"/>
            <xsl:variable name="v_bibl-id" select="ancestor-or-self::node()[name() = ('bibl', 'biblStruct')]/@xml:id"/>
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
                <xsl:if  test="$v_authority != 'NA'">
                    <idno type="{$v_authority}">
                    <xsl:value-of select="$v_idno"/>
                </idno>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    <!-- do not copy certain attributes from one file to another -->
    <xsl:template match="@xml:id | @change | @next | @prev" mode="m_copy-from-source"/>
    <!-- add <biblStruct> from source not currently available in the target -->
    <xsl:template match="tei:body">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <xsl:element name="div">
                <xsl:attribute name="type" select="'section'"/>
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                <xsl:call-template name="t_add-biblstruct-from-master">
                    <!-- when the master file shall be enriched then the source is the current file and the target is the master file -->
                    <xsl:with-param name="p_source" select="$v_bibls-in-file-current"/>
                </xsl:call-template>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template name="t_add-biblstruct-from-master">
        <xsl:param name="p_source"/>
        <!-- as I am matching all references with the proper idno children, I must add all others to the back of this file -->
        <xsl:copy-of select="$p_source/descendant-or-self::tei:biblStruct[not(tei:idno/@type = $p_local-authority)]"/>
    </xsl:template>
    <!-- update existing <biblStruct -->
    <!-- plan: 
        1. check if any of the biblStructs in the current file already point to the authority file. In this case there is no further matching needed. 
            - The pointers are a result of running tei-title_link-to-authority-files.xsl. It should be mandatory to run this stylesheet first.
        2. copy all un-matched bibls from the current file to the authority file
            - any effort to imporve the matching algorithms should be spend on tei-title_link-to-authority-files.xsl
    -->
    <xsl:template match="tei:biblStruct[ancestor::tei:text]" priority="10">
        <xsl:variable name="v_target" select="."/>
        <xsl:variable name="v_source">
            <xsl:for-each select="tei:monogr/tei:idno[@type = $p_local-authority]">
                <xsl:variable name="v_idno" select="."/>
                <!--<xsl:message terminate="yes">
                    <xsl:copy-of select="$v_bibls-in-file-current"/>
                </xsl:message>-->
                <xsl:choose>
                    <!-- the first condition is commonly true -->
                    <xsl:when test="$v_idno = $v_bibls-in-file-current/descendant::tei:idno[@type = $p_local-authority]">
                        <xsl:message terminate="no">
                            <xsl:text>Found a match for &lt;idno type="</xsl:text>
                            <xsl:value-of select="$p_local-authority"/>
                            <xsl:text>"></xsl:text>
                            <xsl:value-of select="$v_idno"/>
                            <xsl:text>&lt;/idno></xsl:text>
                        </xsl:message>
                        <xsl:apply-templates mode="m_identity-transform" select="$v_bibls-in-file-current/tei:biblStruct[tei:monogr/tei:idno = $v_idno]"/>
                    </xsl:when>
                    <xsl:when test="$v_bibls-in-file-current/descendant::tei:title/@ref[matches(., concat($p_local-authority, ':bibl:', $v_idno, '[\W|$]'))]">
                        <xsl:message terminate="no">
                            <xsl:text>Found a match for </xsl:text>
                            <xsl:value-of select="concat($p_local-authority, ':bibl:', $v_idno)"/>
                        </xsl:message>
                        <xsl:apply-templates mode="m_identity-transform"
                            select="$v_bibls-in-file-current/tei:biblStruct[descendant::tei:title/@ref[matches(., concat($p_local-authority, ':bibl:', $v_idno, '[\W|$]'))]]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$v_source = 'NA'">
                <xsl:message>
                    <xsl:text>no additional information found for </xsl:text>
                    <xsl:value-of select="$v_target/tei:monogr/tei:title[1]"/>
                </xsl:message>
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@* | node()"/>
                </xsl:copy>
            </xsl:when>
            <!-- the source potentially contains additional data -->
            <xsl:otherwise>
                <!-- number of matches -->
                <xsl:message>
                    <xsl:text>Found </xsl:text>
                    <xsl:value-of select="count($v_source/descendant-or-self::tei:biblStruct)"/>
                    <xsl:text> match(es) for </xsl:text>
                    <xsl:value-of select="$v_target/tei:monogr/tei:title[1]"/>
                </xsl:message>
                <xsl:variable name="v_target-monogr" select="$v_target/tei:monogr"/>
                <xsl:variable name="v_source-monogr"
                    select="
                        if ($v_source/descendant-or-self::tei:biblStruct/tei:monogr) then
                            ($v_source/descendant-or-self::tei:biblStruct/tei:monogr)
                        else
                            ($v_source/descendant-or-self::tei:bibl)"/>
                <xsl:copy>
                    <!-- combine attributes -->
                    <xsl:apply-templates mode="m_copy-from-source" select="$v_source/descendant-or-self::tei:biblStruct/@*"/>
                    <xsl:apply-templates mode="m_copy-from-source" select="$v_target/@*"/>
                    <xsl:attribute name="change">
                        <xsl:choose>
                            <xsl:when test="@change">
                                <xsl:value-of select="concat(@change, ' #', $p_id-change)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('#', $p_id-change)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <!-- combined @source attribute -->
                    <xsl:attribute name="source">
                        <xsl:if test="@source">
                            <xsl:value-of select="concat(@source, ' ')"/>
                        </xsl:if>
                        <xsl:for-each select="$v_source/descendant-or-self::tei:biblStruct/@source">
                            <xsl:value-of select="."/>
                            <xsl:if test="position() != last()">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:attribute>
                    <!-- merged content -->
                    <!-- monogr -->
                    <xsl:copy select="$v_target/tei:monogr">
                        <!--                        <xsl:apply-templates mode="m_identity-transform" select="$v_source-monogr/@*"/>-->
                        <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/@*"/>
                        <!-- titles -->
                        <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:title"/>
                        <xsl:apply-templates mode="m_identity-transform" select="$v_source-monogr/tei:title[not(normalize-space(.) = $v_target-monogr/tei:title/normalize-space(.))]"/>
                        <!-- IDs -->
                        <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:idno"/>
                        <xsl:apply-templates mode="m_identity-transform" select="$v_source-monogr/tei:idno[not(normalize-space(.) = $v_target-monogr/tei:idno/normalize-space(.))]"/>
                        <!-- textLang -->
                        <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:textLang"/>
                        <xsl:apply-templates mode="m_identity-transform" select="$v_source-monogr/tei:textLang[not(. = $v_target-monogr/tei:textLang)]"/>
                        <!-- contributors -->
                        <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:author"/>
                        <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:editor"/>
                        <!-- IDs of editors -->
                        <xsl:variable name="v_id-editors-target">
                            <xsl:for-each select="$v_target-monogr/tei:editor">
                                <xsl:value-of select="oape:query-personography(tei:persName[@ref][1], $v_personography, $p_local-authority, 'id', '')"/>
                                <xsl:text>,</xsl:text>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:for-each select="$v_source-monogr/tei:editor">
                            <xsl:variable name="v_id" select="oape:query-personography(tei:persName[@ref][1], $v_personography, $p_local-authority, 'id', '')"/>
                            <!-- check if this ID is already present in the target -->
                            <xsl:if test="not(matches($v_id-editors-target, concat($v_id, '[\W|$]')))">
                                <xsl:message>
                                    <xsl:text>Found additional editor with ID </xsl:text>
                                    <xsl:value-of select="$v_id"/>
                                </xsl:message>
                                <xsl:apply-templates mode="m_identity-transform" select="."/>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:respStmt"/>
                        <!-- imprint -->
                        <xsl:copy select="$v_target-monogr/tei:imprint">
                            <xsl:apply-templates select="$v_target-monogr/tei:imprint/@*"/>
                            <!-- date -->
                            <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:imprint/tei:date"/>
                            <xsl:apply-templates mode="m_identity-transform" select="$v_source-monogr/tei:imprint/tei:date[not(. = $v_target-monogr/tei:imprint/tei:date)]"/>
                            <!-- location -->
                            <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:imprint/tei:pubPlace"/>
                            <!-- IDs of places -->
                            <xsl:variable name="v_id-place-target">
                                <xsl:for-each select="$v_target-monogr/tei:imprint/tei:pubPlace[tei:placeName/@ref]">
                                    <xsl:value-of select="oape:query-gazetteer(tei:placeName[@ref][1], $v_gazetteer, $p_local-authority, 'id', '')"/>
                                    <xsl:text>,</xsl:text>
                                </xsl:for-each>
                            </xsl:variable>
                            <xsl:for-each select="$v_source-monogr/tei:imprint/tei:pubPlace[tei:placeName/@ref]">
                                <xsl:variable name="v_id" select="oape:query-gazetteer(tei:placeName[@ref][1], $v_gazetteer, $p_local-authority, 'id', '')"/>
                                <!-- check if this ID is already present in the target -->
                                <xsl:if test="not(matches($v_id-place-target, concat($v_id, '[\W|$]')))">
                                    <xsl:message>
                                        <xsl:text>Found additional Location with ID </xsl:text>
                                        <xsl:value-of select="$v_id"/>
                                    </xsl:message>
                                    <xsl:apply-templates mode="m_identity-transform" select="."/>
                                </xsl:if>
                            </xsl:for-each>
                            <!-- publisher -->
                            <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:imprint/tei:publisher"/>
                            <xsl:apply-templates mode="m_identity-transform" select="$v_source-monogr/tei:imprint/tei:publisher[not(normalize-space(.) = $v_target-monogr/tei:imprint/tei:publisher/normalize-space(.))]"/>
                        </xsl:copy>
                        <xsl:apply-templates mode="m_identity-transform" select="$v_target-monogr/tei:biblScope"/>
                    </xsl:copy>
                    <!-- notes -->
                    <xsl:apply-templates mode="m_identity-transform" select="$v_target/tei:note"/>
                    <xsl:apply-templates mode="m_identity-transform" select="$v_source/descendant::tei:note"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- convert <bibl> to <biblStruct> -->
    <xsl:template match="tei:bibl" mode="m_bibl-to-biblStruct" priority="10">
        <xsl:variable name="v_source">
            <xsl:choose>
                <xsl:when test="@source">
                    <xsl:value-of select="concat(@source, ' ', base-uri(), '#', @xml:id)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(base-uri(), '#', @xml:id)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <biblStruct change="#{$p_id-change}">
            <xsl:apply-templates mode="m_copy-from-source" select="@*"/>
            <!-- document source of information -->
            <xsl:attribute name="source" select="$v_source"/>
            <xsl:if test="tei:title[@level = 'a']">
                <analytic>
                    <xsl:apply-templates select="tei:title[@level = 'a']"/>
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:author"/>
                </analytic>
            </xsl:if>
            <monogr>
                <xsl:apply-templates select="tei:title[@level != 'a']"/>
                <xsl:apply-templates select="tei:idno"/>
                <xsl:for-each select="tokenize(tei:title/@ref, '\s+')">
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
                    <idno type="{$v_authority}">
                        <xsl:value-of select="$v_idno"/>
                    </idno>
                </xsl:for-each>
                <xsl:choose>
                    <xsl:when test="tei:textLang">
                        <xsl:apply-templates mode="m_copy-from-source" select="tei:textLang"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <textLang>
                            <xsl:attribute name="mainLang">
                                <xsl:choose>
                                    <xsl:when test="tei:title[@level != 'a']/@xml:lang">
                                        <xsl:value-of select="tei:title[@level != 'a'][@xml:lang][1]/@xml:lang"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>ar</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </textLang>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="tei:title[@level != 'a']">
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:author"/>
                </xsl:if>
                <xsl:apply-templates mode="m_copy-from-source" select="tei:editor"/>
                <imprint>
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:date"/>
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:pubPlace"/>
                    <xsl:apply-templates mode="m_copy-from-source" select="tei:publisher"/>
                </imprint>
                <xsl:apply-templates select="tei:biblScope"/>
            </monogr>
        </biblStruct>
    </xsl:template>
    <!-- document the changes -->
    <xsl:template match="tei:revisionDesc">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="change">
                <xsl:attribute name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:text>Enriched all </xsl:text>
                <gi>biblStruct</gi>
                <xsl:text> with information from file </xsl:text>
                <ref target="{base-uri()}">
                    <xsl:value-of select="base-uri()"/>
                </ref>
                <xsl:text> using matching of titles.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
