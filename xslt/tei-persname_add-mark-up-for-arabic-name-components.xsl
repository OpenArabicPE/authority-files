<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" 
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" 
    xmlns:xi="http://www.w3.org/2001/XInclude" 
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="3.0">
    
    <xsl:output method="xml" encoding="UTF-8" indent="no" exclude-result-prefixes="#all" omit-xml-declaration="no"/>

    <xsl:include href="functions.xsl"/>
    <!-- identify the author of the change by means of a @xml:id -->
    <!-- toggle debugging messages -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>

    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- remove
        - persName @type="flattened"
        - persName @type="noAddName"
    -->
    <xsl:template match="tei:persName[@type = ('flattened', 'noAddName')]"/>
    <!-- remove persName/@change -->
    <xsl:template match="tei:persName/@change | tei:idno/@change"/>
    
    <!-- add mark-up to direct text children of persName -->
    <xsl:template match="tei:persName[not(@type = ('flattened', 'noAddName'))]/text() | tei:forename/text() | tei:surname/text()">
        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
    </xsl:template>
    
    <!-- document the changes -->
    <xsl:template match="tei:revisionDesc" name="t_8">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#',$p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Improved </xsl:text><tei:gi>persName</tei:gi><xsl:text>, </xsl:text><tei:gi>surname</tei:gi><xsl:text> and </xsl:text><tei:gi>forename</tei:gi><xsl:text> nodes by automatically marking up Arabic name components, such as nasab, nisba, khitab, kunya.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    </xsl:stylesheet>