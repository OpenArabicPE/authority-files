<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs tei"
    version="3.0">
    
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="yes" method="xml" name="xml"
        omit-xml-declaration="no"/>
    
    <!-- identify the author of the change by means of a @xml:id -->
    <!--    <xsl:param name="p_id-editor" select="'pers_TG'"/>-->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:listBibl" mode="m_unique-titles">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:head"/>
            <xsl:apply-templates select="tei:bibl[not(tei:title[@level = 'j'])]"/>
            <xsl:for-each-group select="tei:bibl[tei:title[@level = 'j']]" group-by="tei:title[@level = 'j']">
                <xsl:sort select="current-grouping-key()"/>
                <xsl:copy>
                    <xsl:attribute name="change" select="concat('#',$p_id-change)"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/">
        <xsl:apply-templates select="descendant::tei:text" mode="m_extract-titles"/>
    </xsl:template>
    
    <xsl:template match="tei:text" mode="m_extract-titles">
        <xsl:element name="listBibl">
        <xsl:for-each-group select="descendant::tei:title[@level = 'j']" group-by=".">    
                <xsl:element name="bibl">
                    <xsl:copy>
                <xsl:apply-templates/>
            </xsl:copy>
                </xsl:element>
        </xsl:for-each-group>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>