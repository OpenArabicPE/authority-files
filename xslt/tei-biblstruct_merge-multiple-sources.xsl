<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"  
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:zot="https://zotero.org"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    
    <!-- the plan:
    - enrich an existing bibliography by adding information **to** a master file 
    - already existing entries shall be enriched with clearly marked information.
         + add a <biblStruct> child with the additional information
    - new entries can just be added from the external file. -->
    
     <xsl:param name="p_url-master"
        select="'../data/tei/bibliography_OpenArabicPE-periodicals.TEIP5.xml'"/>
    <xsl:variable name="v_file-master" select="doc($p_url-master)"/>
    <xsl:variable name="v_file-current" select="/"/>
    
    <xsl:param name="p_enrich-master" select="true()"/>
    
    <xsl:template match="/">
        <xsl:result-document href="_output/merge-multiple-sources.TEIP5.xml">
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
        </xsl:result-document>
    </xsl:template>
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="m_copy-from-source">
        <xsl:copy>
            <xsl:apply-templates select="@* "/>
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
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
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
                    <xsl:with-param name="p_source" select="if($p_enrich-master = true()) then($v_file-current) else($v_file-master)"/>
                    <xsl:with-param name="p_target" select="if($p_enrich-master = false()) then($v_file-current) else($v_file-master)"/>
                </xsl:call-template>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template name="t_add-biblstruct-from-master">
        <xsl:param name="p_target"/>
        <xsl:param name="p_source"/>
        <xsl:copy-of select="$p_source/descendant::tei:biblStruct[not(tei:monogr/tei:title = $p_target/descendant::tei:biblStruct/tei:monogr/tei:title)]"/>
    </xsl:template>
    
    <!-- update existing <biblStruct -->
    <xsl:template match="tei:biblStruct">
        <xsl:variable name="v_base" select="."/>
        <xsl:variable name="v_source" select="if($p_enrich-master = true()) then($v_file-current) else($v_file-master)"/>
        <xsl:variable name="v_additional-info">
            <!-- select a biblStruct in the external file that matches $v_base by title, editors etc. -->
            <xsl:choose>
                <!-- multiple matches -->
                <xsl:when test="count($v_source/descendant::tei:biblStruct[tei:monogr/tei:title = $v_base/tei:monogr/tei:title]) gt 1">
                    <!-- better message needed -->
                    <xsl:message terminate="no">
                        <xsl:text>more than one match in the external file</xsl:text>
                     </xsl:message>
                </xsl:when>
                <!-- single match -->
                <xsl:when test="count($v_source/descendant::tei:biblStruct[tei:monogr/tei:title = $v_base/tei:monogr/tei:title]) = 1">
                    <xsl:copy-of select="$v_source/descendant::tei:biblStruct[tei:monogr/tei:title = $v_base/tei:monogr/tei:title]"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!-- check if there is additional information available -->
        <xsl:choose>
            <xsl:when test="$v_additional-info != ''">
                <xsl:message>
                    <xsl:text>additional information available</xsl:text>
                </xsl:message>
                <!-- establish source and target for enrichment -->
                <xsl:variable name="v_target" select="if($p_enrich-master = false()) then($v_base) else($v_additional-info)"/>
                <xsl:variable name="v_source" select="if($p_enrich-master = true()) then($v_base) else($v_additional-info)"/>
                <xsl:variable name="v_combined">
                    <xsl:copy-of select="$v_source"/>
                    <xsl:copy-of select="$v_target"/>
                </xsl:variable>
                <xsl:variable name="v_target-monogr" select="$v_target/descendant-or-self::tei:biblStruct/tei:monogr"/>
                <xsl:variable name="v_source-monogr" select="$v_source/descendant-or-self::tei:biblStruct/tei:monogr"/>
                <xsl:copy>
                    <!-- combine attributes -->
                    <xsl:apply-templates select="$v_combined/descendant-or-self::tei:biblStruct/@*"/>
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
                        <xsl:apply-templates select="$v_source-monogr/tei:editor[not(. = $v_target-monogr/tei:editor)]" mode="m_copy-from-source"/>
                        <!-- textLang -->
                        <xsl:apply-templates select="$v_target-monogr/tei:textLang"/>
                        <xsl:apply-templates select="$v_source-monogr/tei:textLang[not(. = $v_target-monogr/tei:textLang)]" mode="m_copy-from-source"/>
                        <!-- imprint -->
                        <xsl:element name="imprint">
                            <xsl:apply-templates select="$v_combined/descendant-or-self::tei:biblStruct/tei:monogr/tei:imprint/@*"/>
                            <!-- date -->
                            <xsl:apply-templates select="$v_target-monogr/tei:imprint/tei:date"/>
                            <xsl:apply-templates select="$v_source-monogr/tei:imprint/tei:date[not(. = $v_target-monogr/tei:imprint/tei:date)]" mode="m_copy-from-source"/>
                            <!-- pubPlace -->
                            <xsl:apply-templates select="$v_target-monogr/tei:imprint/tei:pubPlace"/>
                            <xsl:apply-templates select="$v_source-monogr/tei:imprint/tei:pubPlace[not(. = $v_target-monogr/tei:imprint/tei:pubPlace)]" mode="m_copy-from-source"/>
                            <!-- publisher  -->
                            <xsl:apply-templates select="$v_target-monogr/tei:imprint/tei:publisher"/>
                            <xsl:apply-templates select="$v_source-monogr/tei:imprint/tei:publisher[not(. = $v_target-monogr/tei:imprint/tei:publisher)]" mode="m_copy-from-source"/>
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
                <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
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
                <ref target="{base-uri()}"><xsl:value-of select="base-uri()"/></ref>
                <xsl:text> using matching of titles.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    
</xsl:stylesheet>