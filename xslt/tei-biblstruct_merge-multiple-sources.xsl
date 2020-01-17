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
    
     <xsl:param name="p_url-master"
        select="'../data/tei/bibliography_OpenArabicPE-periodicals.TEIP5.xml'"/>
    <xsl:variable name="v_file-master" select="doc($p_url-master)"/>
    
    <xsl:param name="p_enrich-master" select="false()"/>
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:biblStruct">
        <xsl:variable name="v_base" select="."/>
        <xsl:variable name="v_additional-info">
            <!-- select a biblStruct in the external file that matches $v_base by title, editors etc. -->
            <xsl:choose>
                <xsl:when test="$v_file-master/descendant::tei:biblStruct[tei:monogr/tei:title = $v_base/tei:monogr/tei:title][1]">
                    <xsl:copy-of select="$v_file-master/descendant::tei:biblStruct[tei:monogr/tei:title = $v_base/tei:monogr/tei:title]"/>
                </xsl:when>
                <xsl:when test="$v_file-master/descendant::tei:biblStruct[tei:monogr/tei:title = $v_base/tei:monogr/tei:title][count(.) gt 1]">
                    <xsl:message>
                    <xsl:text>more than one match in the external file</xsl:text>
                </xsl:message>
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
            </xsl:when>
            <!-- fallback: replicate input -->
            <xsl:otherwise>
                <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
</xsl:stylesheet>