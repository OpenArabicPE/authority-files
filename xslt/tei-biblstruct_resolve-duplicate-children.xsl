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
    <xsl:template match="tei:note[@type = ('holdings', 'comments')][tei:list][following-sibling::tei:note[@type = current()/@type][tei:list]]">
        <xsl:variable name="v_items">
            <xsl:apply-templates select="tei:list/tei:item"/>
            <!-- add items from following siblings -->
            <xsl:apply-templates select="following-sibling::tei:note[@type = current()/@type]/tei:list/tei:item"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@type | @xml:lang"/>
            <xsl:element name="list">
                <xsl:apply-templates select="$v_items/descendant-or-self::tei:item">
                    <xsl:sort select="descendant-or-self::tei:item/tei:label/tei:placeName"/>
                    <xsl:sort select="descendant-or-self::tei:item/tei:label/tei:orgName"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:note[@type = ('holdings', 'comments')][tei:list][preceding-sibling::tei:note[@type = current()/@type][tei:list]]" priority="1"/>
    <xsl:template match="tei:item[not(@xml:lang)]">
        <xsl:copy>
            <xsl:choose>
                <xsl:when test="@source = '#zdb'">
                    <xsl:attribute name="xml:lang" select="'de'"/>
                </xsl:when>
                <xsl:when test="parent::tei:list/@xml:lang">
                    <xsl:copy-of select="parent::tei:list/@xml:lang"/>
                </xsl:when>
                <xsl:when test="ancestor::tei:note/@xml:lang">
                    <xsl:copy-of select="ancestor::tei:note/@xml:lang"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!--<xsl:template match="tei:item[not(@source)]">
        <xsl:copy>
            <xsl:copy select="ancestor::node()[@source][1]/@source"/>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>-->
    <!-- remove duplicate elements -->
    <!--    <xsl:template match="tei:note[ancestor::tei:biblStruct][preceding-sibling::tei:note = current()]"/>-->
    <!--<xsl:template match="node()[ancestor::tei:biblStruct][current()/name() != ''][preceding-sibling::node()[name() =  current()/name()] = current()][preceding-sibling::node()[name() =  current()/name()]/@type= current()/@type]">
        <xsl:message>
            <xsl:value-of select="current()/name()"/>
            <xsl:text>; preceding @: </xsl:text><xsl:value-of select="preceding-sibling::node()[name() =  current()/name()]/@*"/>
            <xsl:text>; current @: </xsl:text><xsl:value-of select="current()/@*"/>
        </xsl:message>
    </xsl:template>-->
    <!--<xsl:template match="tei:title[ancestor::tei:biblStruct/@type = 'periodical'][not(@level)]">
        <xsl:copy>
            <xsl:attribute name="level" select="'j'"/>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>-->
    <!--<xsl:template match="tei:title[ancestor::tei:biblStruct][preceding-sibling::tei:title = current()]"/>
    <xsl:template match="tei:date[ancestor::tei:biblStruct][preceding-sibling::tei:date = current()][preceding-sibling::tei:date[. = current()]/@type = current()/@type][preceding-sibling::tei:date[. = current()]/@when = current()/@when]"/>
    <xsl:template match="tei:idno[ancestor::tei:biblStruct][preceding-sibling::tei:idno = current()][preceding-sibling::tei:idno[. = current()]/@type = current()/@type]"/>
    <xsl:template match="tei:publisher[ancestor::tei:biblStruct][preceding-sibling::tei:publisher = current()]"/>
    -->
</xsl:stylesheet>
