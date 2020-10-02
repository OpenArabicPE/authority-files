<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"  
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:zot="https://zotero.org"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="no" omit-xml-declaration="no" version="1.0"/>
    
    <!-- the plan:
    - enrich an existing bibliography by adding information **to** a master file 
    - already existing entries shall be enriched with clearly marked information.
         + add a <biblStruct> child with the additional information
    - new entries can just be added from the external file. -->
    
    <!-- problems:
    - <ref> children are ignored
     -->
    
    <xsl:include href="functions.xsl"/>
    
     <xsl:param name="p_url-master"
        select="'../data/tei/bibliography_OpenArabicPE-periodicals.TEIP5.xml'"/>
    <xsl:variable name="v_file-master" select="doc($p_url-master)"/>
    <xsl:variable name="v_file-current" select="/"/>
    
    <xsl:param name="p_enrich-master" select="true()"/>
    <!-- find all <bibl>s in current file and convert them to <biblStruct> -->
    <xsl:variable name="v_bibls-in-file-current">
        <!-- find all <bibl>s in current file and compile them if necessary -->
        <xsl:variable name="v_bibl">
            <xsl:for-each select="$v_file-current/descendant::tei:text/descendant::tei:bibl">
                 <xsl:copy-of select="oape:compile-next-prev(.)"/>
            </xsl:for-each>
        </xsl:variable>
        <!-- convert <bibl>s to <biblStruct> -->
        <xsl:variable name="v_biblStruct">
            <xsl:apply-templates select="$v_bibl/descendant-or-self::tei:bibl" mode="m_bibl-to-biblStruct"/>
            <!-- find all <biblStruct> in the curent file -->
            <xsl:apply-templates select="$v_file-current/descendant::tei:text/descendant::tei:biblStruct" mode="m_copy-from-source"/>
        </xsl:variable>
        <xsl:copy-of select="$v_biblStruct"/>
    </xsl:variable>
    
    <xsl:template match="/">
<!--        <xsl:result-document href="_output/merge-multiple-sources.TEIP5.xml">-->
            <xsl:choose>
                <xsl:when test="$p_enrich-master = true()">
                    <xsl:message>
                        <xsl:text>enriching master file</xsl:text>
                    </xsl:message>
                    <xsl:copy>
                        <xsl:apply-templates select="$v_file-master/tei:TEI"/>
                    </xsl:copy>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>enriching current file</xsl:text>
                    </xsl:message>
                    <xsl:copy>
                        <xsl:apply-templates/>
                    </xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        <!--</xsl:result-document>-->
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
            <xsl:variable name="v_base-uri" select="if($p_enrich-master = true()) then(base-uri($v_file-current)) else(base-uri($v_file-master))"/>
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
            <xsl:apply-templates select="@* " mode="m_copy-from-source"/>
            <!-- document change -->
            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            <!-- document source of additional information -->
             <xsl:attribute name="source" select="$v_source"/>
            <!-- content -->
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- do not copy certain attributes from one file to another -->
    <xsl:template match="@xml:id | @change | @next | @prev" mode="m_copy-from-source"/>
    
    <xsl:template match="@xml:id | @change">
        <xsl:choose>
            <xsl:when test="$p_enrich-master = true() and ( base-uri(.) = base-uri($v_file-master))">
                <xsl:copy/>
            </xsl:when>
            <xsl:when test="$p_enrich-master = true() and ( base-uri(.) = base-uri($v_file-current))"/>
        </xsl:choose>
    </xsl:template>
    
    <!-- add <biblStruct> from source not currently available in the target -->
    <xsl:template match="tei:body">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <xsl:element name="div">
                <xsl:attribute name="type" select="'section'"/>
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                <xsl:call-template name="t_add-biblstruct-from-master">
                    <!-- when the master file shall be enriched then the source is the current file and the target is the master file -->
                    <xsl:with-param name="p_source" select="if($p_enrich-master = true()) then($v_bibls-in-file-current) else($v_file-master/descendant::tei:text)"/>
                    <xsl:with-param name="p_target" select="if($p_enrich-master = false()) then($v_bibls-in-file-current) else($v_file-master/descendant::tei:text)"/>
                </xsl:call-template>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template name="t_add-biblstruct-from-master">
        <xsl:param name="p_target"/>
        <xsl:param name="p_source"/>
        <xsl:copy-of select="$p_source/descendant::tei:biblStruct[tei:monogr/tei:title[@level='j']][not(tei:monogr/tei:title = $p_target/descendant::tei:biblStruct/tei:monogr/tei:title)]"/>
<!--        <xsl:apply-templates select="$p_source/descendant-or-self::tei:bibl[not(tei:title = $p_target/descendant::tei:biblStruct/tei:monogr/tei:title)]" mode="m_copy-from-source"/>-->
    </xsl:template>
    
    <!-- update existing <biblStruct -->
    <xsl:template match="tei:biblStruct[ancestor::tei:text]">
        <xsl:variable name="v_base" select="."/>
        <xsl:variable name="v_file-source" select="if($p_enrich-master = true()) then($v_bibls-in-file-current) else($v_file-master)"/>
        <!--  -->
        <xsl:variable name="v_title" select="$v_base/tei:monogr/tei:title[1]"/>
        <xsl:variable name="v_level" select="$v_title/@level"/>
        <xsl:variable name="v_type" select="$v_base/@type"/>
         <xsl:variable name="v_subtype" select="$v_base/@subtype"/>
         <xsl:variable name="v_frequency" select="$v_base/@oape:frequency"/>
        <xsl:variable name="v_additional-info">
            <!-- select a biblStruct in the external file that matches $v_base by title, editors etc. -->
            <xsl:choose>
                <!-- multiple matches -->
                <xsl:when test="$v_file-source/descendant::tei:biblStruct[tei:monogr/tei:title/oape:string-normalise-characters(.) = $v_base/tei:monogr/tei:title/oape:string-normalise-characters(.)][@type = $v_type][@subtype = $v_subtype]">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>
                            <xsl:text>match(es) in the external file based on title, @type, @subtype</xsl:text>
                        </xsl:message>
                    </xsl:if>
                    <xsl:copy-of select="$v_file-source/descendant::tei:biblStruct[tei:monogr/tei:title/oape:string-normalise-characters(.) = $v_base/tei:monogr/tei:title/oape:string-normalise-characters(.)][@type = $v_type][@subtype = $v_subtype]"/>
                </xsl:when>
                <!-- single matches -->
                <xsl:when test="count($v_file-source/descendant::tei:biblStruct[tei:monogr/tei:title/oape:string-normalise-characters(.) = $v_base/tei:monogr/tei:title/oape:string-normalise-characters(.)]) = 1">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>
                            <xsl:text>one match in the external file for </xsl:text><xsl:value-of select="descendant::tei:title[1]"/>
                        </xsl:message>
                    </xsl:if>
                    <xsl:copy-of select="$v_file-source/descendant::tei:biblStruct[tei:monogr/tei:title/oape:string-normalise-characters(.) = $v_base/tei:monogr/tei:title/oape:string-normalise-characters(.)]"/>
                </xsl:when>
                <!-- multiple matches -->
                <xsl:when test="count($v_file-source/descendant::tei:biblStruct[tei:monogr/tei:title/oape:string-normalise-characters(.) = $v_base/tei:monogr/tei:title/oape:string-normalise-characters(.)]) gt 1">
                    <!-- better message needed -->
                    <xsl:message terminate="no">
                        <xsl:text>more than one match in the external file for </xsl:text><xsl:value-of select="descendant::tei:title[1]"/><xsl:text>. Will proceed without updating.</xsl:text>
                     </xsl:message>
                </xsl:when>
                <!--<xsl:when test="count($v_file-source/descendant-or-self::tei:bibl[tei:title = $v_base/tei:monogr/tei:title]) gt 1">
                    <!-\- better message needed -\->
                    <xsl:message terminate="no">
                        <xsl:text>more than one match in the external file</xsl:text>
                     </xsl:message>
                </xsl:when>-->
                 <!--<xsl:when test="count($v_file-source/descendant-or-self::tei:bibl[tei:title = $v_base/tei:monogr/tei:title]) = 1">
                     <xsl:if test="$p_verbose = true()">
                        <xsl:message>
                            <xsl:text>one match in the external file</xsl:text>
                        </xsl:message>
                    </xsl:if>
                    <xsl:copy-of select="$v_file-source/descendant-or-self::tei:bibl[tei:title = $v_base/tei:monogr/tei:title]"/>
                </xsl:when>-->
            </xsl:choose>
        </xsl:variable>
        <!-- check if there is additional information available -->
        <xsl:choose>
            <xsl:when test="$v_additional-info != ''">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>additional information available for </xsl:text><xsl:value-of select="descendant::tei:title[1]"/>
                    </xsl:message>
                </xsl:if>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:copy-of select="$v_additional-info"/>
                    </xsl:message>
                </xsl:if>
                <!-- establish source and target for enrichment -->
                <!-- if running on the master file, the source should be the current file and the target should be the master -->
                <xsl:variable name="v_source" select="if($p_enrich-master = false()) then($v_base) else($v_additional-info)"/>
                <xsl:variable name="v_target" select="if($p_enrich-master = true()) then($v_base) else($v_additional-info)"/>
                <xsl:variable name="v_combined">
                    <xsl:copy-of select="$v_source"/>
                    <xsl:copy-of select="$v_target"/>
                </xsl:variable>
                <xsl:variable name="v_target-monogr" select="$v_target/descendant-or-self::tei:biblStruct/tei:monogr"/>
                <xsl:variable name="v_source-monogr" select="if($v_source/descendant-or-self::tei:biblStruct/tei:monogr) then($v_source/descendant-or-self::tei:biblStruct/tei:monogr) else($v_source/descendant-or-self::tei:bibl)"/>
                <!-- IDs of editors -->
                        <xsl:variable name="v_id-editors-target">
                            <xsl:variable name="v_temp">
                                <xsl:value-of select="$v_target-monogr/tei:editor/tei:persName/@ref"/>
                            </xsl:variable>
                            <xsl:for-each-group select="tokenize($v_temp, ' ')" group-by=".">
                                <xsl:value-of select="concat(., ',')"/>
                            </xsl:for-each-group>
                        </xsl:variable>
                <!-- IDs of places -->
                        <xsl:variable name="v_id-place-target">
                            <xsl:variable name="v_temp">
                                <xsl:value-of select="$v_target-monogr/tei:imprint/tei:pubPlace/tei:placeName/@ref"/>
                            </xsl:variable>
                            <xsl:for-each-group select="tokenize($v_temp, ' ')" group-by=".">
                                <xsl:value-of select="concat(., ',')"/>
                            </xsl:for-each-group>
                        </xsl:variable>
                <xsl:copy>
                    <!-- combine attributes -->
<!--                    <xsl:apply-templates select="$v_combined/descendant-or-self::tei:biblStruct/@*"/>-->
                    <xsl:apply-templates select="$v_source/descendant-or-self::tei:biblStruct/@*" mode="m_copy-from-source"/>
                    <xsl:apply-templates select="$v_source/descendant-or-self::tei:bibl/@*" mode="m_copy-from-source"/>
                    <xsl:apply-templates select="$v_target/@*"/>
                    <!-- monogr -->
                    <xsl:element name="monogr">
                        <!-- combine attributes -->
                        <xsl:apply-templates select="$v_combined/descendant-or-self::tei:biblStruct/tei:monogr/@*"/>
                        <!-- reproduce target titles -->
                        <xsl:apply-templates select="$v_target-monogr/tei:title"/>
                        <!-- add source titles missing from the target -->
                        <xsl:apply-templates select="$v_source-monogr/tei:title[not(. = $v_target-monogr/tei:title)]" mode="m_copy-from-source"/>
                        <!-- idno -->
                        <xsl:apply-templates select="$v_target-monogr/tei:idno"/>
                        <xsl:apply-templates select="$v_source-monogr/tei:idno[not(. = $v_target-monogr/tei:idno)]" mode="m_copy-from-source"/>
                        <!-- editors etc. -->
                        <xsl:apply-templates select="$v_target-monogr/tei:editor"/>
                        <!-- try matching persons through their IDs first -->
                        <!--              debugging-->
                    <xsl:message>
                        <!--<xsl:text>editors in source (ID): </xsl:text><xsl:value-of select="$v_id-editors-source"/><xsl:text>; </xsl:text>-->
                        <xsl:text>editors in target (ID): </xsl:text><xsl:value-of select="$v_id-editors-target"/>
                    </xsl:message>
                <!-- end debugging-->
                        <xsl:for-each select="$v_source-monogr/tei:editor">
                            <xsl:choose>
                                <!-- test if it references authority files -->
                                <xsl:when test="tei:persName/@ref">
                                    <!-- test if the value of the @ref attributes are part of the target -->
                                    <xsl:choose>
                                        <xsl:when test="contains($v_id-editors-target, tokenize(tei:persName/@ref, ' ')[1])">
                                            <xsl:if test="$p_verbose = true()">
                                            <xsl:message>
                                                <xsl:text>editor (ID) found in target</xsl:text>
                                            </xsl:message>
                                            </xsl:if>
                                        </xsl:when>
                                        <xsl:when test="contains($v_id-editors-target, tokenize(tei:persName/@ref, ' ')[2])">
                                            <xsl:if test="$p_verbose = true()">
                                            <xsl:message>
                                                <xsl:text>editor (ID) found in target</xsl:text>
                                            </xsl:message>
                                            </xsl:if>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:apply-templates select="." mode="m_copy-from-source"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <!-- test if the string itself is present -->
                                <xsl:when test=". = $v_target-monogr/tei:editor"/>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="." mode="m_copy-from-source"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                        <!--<xsl:apply-templates select="$v_source-monogr/tei:editor[not(. = $v_target-monogr/tei:editor)]" mode="m_copy-from-source">/-->
                        <!-- textLang -->
                        <xsl:apply-templates select="$v_target-monogr/tei:textLang"/>
                        <xsl:apply-templates select="$v_source-monogr/tei:textLang[not(. = $v_target-monogr/tei:textLang)]" mode="m_copy-from-source"/>
                        <!-- imprint -->
                        <xsl:element name="imprint">
                            <xsl:apply-templates select="$v_combined/descendant-or-self::tei:biblStruct/tei:monogr/tei:imprint/@*"/>
                            <!-- date -->
                            <xsl:apply-templates select="$v_target-monogr/tei:imprint/tei:date"/>
                            <xsl:apply-templates select="$v_source-monogr/descendant::tei:date[not(. = $v_target-monogr/tei:imprint/tei:date)]" mode="m_copy-from-source"/>
                            <!-- pubPlace -->
                            <xsl:apply-templates select="$v_target-monogr/tei:imprint/tei:pubPlace"/>
                            <!-- try matching places through their IDs first -->
                            <xsl:for-each select="$v_source-monogr/tei:imprint/tei:pubPlace">
                            <xsl:choose>
                                <!-- test if it references authority files -->
                                <xsl:when test="tei:placeName/@ref">
                                    <!-- test if the value of the @ref attributes are part of the target -->
                                    <xsl:choose>
                                        <xsl:when test="contains($v_id-place-target, tokenize(tei:placeName/@ref, ' ')[1])">
                                            <xsl:if test="$p_verbose = true()">
                                                <xsl:message>
                                                <xsl:text>pubPlace (ID) found in target</xsl:text>
                                            </xsl:message>
                                            </xsl:if>
                                        </xsl:when>
                                        <xsl:when test="contains($v_id-place-target, tokenize(tei:placeName/@ref, ' ')[2])">
                                            <xsl:if test="$p_verbose = true()">
                                                <xsl:message>
                                                <xsl:text>pubPlace (ID) found in target</xsl:text>
                                            </xsl:message>
                                            </xsl:if>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:apply-templates select="." mode="m_copy-from-source"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <!-- test if the string itself is present -->
                                <xsl:when test=". = $v_target-monogr/tei:imprint/tei:pubPlace"/>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="." mode="m_copy-from-source"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
<!--                            <xsl:apply-templates select="$v_source-monogr/descendant::tei:pubPlace[not(. = $v_target-monogr/tei:imprint/tei:pubPlace)]" mode="m_copy-from-source"/>-->
                            <!-- publisher  -->
                            <xsl:apply-templates select="$v_target-monogr/tei:imprint/tei:publisher"/>
                            <xsl:apply-templates select="$v_source-monogr/descendant::tei:publisher[not(. = $v_target-monogr/tei:imprint/tei:publisher)]" mode="m_copy-from-source"/>
                        </xsl:element>
                        <!-- biblScope -->
                        <xsl:apply-templates select="$v_target-monogr/tei:biblScope"/>
                        <xsl:apply-templates select="$v_source-monogr/tei:biblScope[not(. = $v_target-monogr/tei:biblScope)]" mode="m_copy-from-source"/>
                    </xsl:element>
                    <!-- notes -->
                    <xsl:apply-templates select="$v_combined/descendant-or-self::tei:biblStruct/tei:note"/>
                </xsl:copy>
            </xsl:when>
            <!-- fallback: replicate input -->
            <xsl:otherwise>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>no additional information for </xsl:text><xsl:value-of select="descendant::tei:title[1]"/>
                    </xsl:message>
                </xsl:if>
                <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- convert <bibl> to <biblStruct> -->
    <xsl:template match="tei:bibl" mode="m_bibl-to-biblStruct">
        <xsl:variable name="v_source">
             <xsl:choose>
                    <xsl:when test="@source">
                        <xsl:value-of select="concat(@source, if($p_enrich-master = true()) then(base-uri($v_file-current)) else(base-uri($v_file-master)), '#', @xml:id)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat(if($p_enrich-master = true()) then(base-uri($v_file-current)) else(base-uri($v_file-master)), '#', @xml:id)"/>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>
        <biblStruct change="#{$p_id-change}">
            <xsl:apply-templates select="@*" mode="m_copy-from-source"/>
            <!-- document source of information -->
             <xsl:attribute name="source" select="$v_source"/>
            <xsl:if test="tei:title[@level  = 'a']">
                <analytic>
                    <xsl:apply-templates select="tei:title[@level  = 'a']"/>
                    <xsl:apply-templates select="tei:author" mode="m_copy-from-source"/>
                </analytic>
            </xsl:if>
            <monogr>
                <xsl:apply-templates select="tei:title[@level  != 'a']"/>
                <xsl:apply-templates select="tei:idno"/>
                <xsl:choose>
                    <xsl:when test="tei:textLang">
                        <xsl:apply-templates select="tei:textLang" mode="m_copy-from-source"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <textLang>
                    <xsl:attribute name="mainLang">
                        <xsl:choose>
                            <xsl:when test="tei:title[@level  != 'a']/@xml:lang">
                                <xsl:value-of select="tei:title[@level  != 'a'][@xml:lang][1]/@xml:lang"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>ar</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                </textLang>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="tei:title[@level  != 'a']">
                    <xsl:apply-templates select="tei:author" mode="m_copy-from-source"/>
                </xsl:if>
                <xsl:apply-templates select="tei:editor" mode="m_copy-from-source"/>
                <imprint>
                    <xsl:apply-templates select="tei:date" mode="m_copy-from-source"/>
                    <xsl:apply-templates select="tei:pubPlace" mode="m_copy-from-source"/>
                    <xsl:apply-templates select="tei:publisher" mode="m_copy-from-source"/>
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
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:text>Enriched all </xsl:text>
                <gi>biblStruct</gi>
                <xsl:text> with information from file </xsl:text>
                <ref target="{base-uri($v_file-current)}"><xsl:value-of select="base-uri($v_file-current)"/></ref>
                <xsl:text> using matching of titles.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>