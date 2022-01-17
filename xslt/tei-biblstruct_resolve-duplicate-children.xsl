<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:zot="https://zotero.org" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="no" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:include href="functions.xsl"/>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- remove duplicate elements -->
    <!--<xsl:template match="node()[ancestor::tei:biblStruct][current()/name() != ''][preceding-sibling::node()[name() =  current()/name()] = current()][preceding-sibling::node()[name() =  current()/name()]/@type= current()/@type]">
        <xsl:message>
            <xsl:value-of select="current()/name()"/>
            <xsl:text>; preceding @: </xsl:text><xsl:value-of select="preceding-sibling::node()[name() =  current()/name()]/@*"/>
            <xsl:text>; current @: </xsl:text><xsl:value-of select="current()/@*"/>
        </xsl:message>
    </xsl:template>-->
      <xsl:template match="tei:title[ancestor::tei:biblStruct/@type = 'periodical'][not(@level)]">
        <xsl:copy>
            <xsl:attribute name="level" select="'j'"/>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[ancestor::tei:biblStruct][preceding-sibling::tei:title = current()]"/>
    <xsl:template match="tei:date[ancestor::tei:biblStruct][preceding-sibling::tei:date = current()][preceding-sibling::tei:date[. = current()]/@type = current()/@type][preceding-sibling::tei:date[. = current()]/@when = current()/@when]"/>
    <xsl:template match="tei:idno[ancestor::tei:biblStruct][preceding-sibling::tei:idno = current()][preceding-sibling::tei:idno[. = current()]/@type = current()/@type]"/>
    <xsl:template match="tei:publisher[ancestor::tei:biblStruct][preceding-sibling::tei:publisher = current()]"/>
    <xsl:template match="tei:note[parent::tei:biblStruct][preceding-sibling::tei:note = current()]"/>
    
    
    
</xsl:stylesheet>