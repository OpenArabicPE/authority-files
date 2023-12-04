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
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/">
<!--        <xsl:apply-templates select="descendant::tei:text" mode="m_extract-titles"/>-->
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
   <!-- <xsl:template match="node()[tei:listBibl/tei:bibl]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-\- books -\->
            <xsl:element name="listBibl">
                <xsl:element name="head">
                    <xsl:text>books</xsl:text>
                </xsl:element>
                    <xsl:apply-templates select="descendant::tei:bibl[tei:title[@level = 'm']][not(tei:title[@level = 'a'])]"/>
            </xsl:element>
            <!-\- book chapters -\->
            <xsl:element name="listBibl">
                <xsl:element name="head">
                    <xsl:text>book chapters</xsl:text>
                </xsl:element>
                    <xsl:apply-templates select="descendant::tei:bibl[tei:title[@level = 'm']][tei:title[@level = 'a']]"/>
            </xsl:element>
            <!-\- periodicals -\->
            <xsl:element name="listBibl">
                <xsl:element name="head">
                    <xsl:text>periodicals</xsl:text>
                </xsl:element>
                    <xsl:apply-templates select="descendant::tei:bibl[tei:title[@level = 'j']][not(tei:title[@level = 'a'])]"/>
            </xsl:element>
            <!-\- periodical articles -\->
            <xsl:element name="listBibl">
                <xsl:element name="head">
                    <xsl:text>periodical articles</xsl:text>
                </xsl:element>
                    <xsl:apply-templates select="descendant::tei:bibl[tei:title[@level = 'j']][tei:title[@level = 'a']]"/>
            </xsl:element>
            <!-\- unclassified -\->
            <xsl:element name="listBibl">
                <xsl:element name="head">
                    <xsl:text>unclassified</xsl:text>
                </xsl:element>
                    <xsl:apply-templates select="descendant::tei:bibl[tei:title[@level != ('m','j')]]"/>
            </xsl:element>
        </xsl:copy>
        
    </xsl:template>-->
    
    <xsl:template match="tei:listBibl">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:head"/>
            <xsl:apply-templates select="tei:bibl[not(tei:title[@level = 'j'])]"/>
            <xsl:for-each-group select="tei:bibl[tei:title[@level = 'j']]" group-by="tei:title[@level = 'j']">
                <xsl:sort select="current-grouping-key()"/>
                <xsl:copy>
                    <xsl:attribute name="change">
                        <xsl:choose>
                            <xsl:when test="@change">
                                <xsl:value-of select="concat(@change, ' #',$p_id-change)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat('#',$p_id-change)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:text" mode="m_extract-titles">
        <xsl:element name="listBibl">
        <xsl:for-each-group select="descendant::tei:title[@level = 'j']" group-by=".">    
                <xsl:element name="bibl">
                    <xsl:copy>
                <xsl:apply-templates select="@* | node()"/>
            </xsl:copy>
                </xsl:element>
        </xsl:for-each-group>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>