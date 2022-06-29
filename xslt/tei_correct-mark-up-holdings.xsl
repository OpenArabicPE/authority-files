<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:zot="https://zotero.org" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:import href="functions.xsl"/>
    <!--  identity transform  -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:note[@type = 'holdings']">
        <listBibl>
            <xsl:apply-templates select="descendant::tei:item" mode="m_update"/>
        </listBibl>
    </xsl:template>
    <xsl:template match="node() | @*" mode="m_update">
        <xsl:copy>
            <xsl:apply-templates mode="m_update" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@change | @xml:id" mode="m_update"/>
    <!-- transform holding information to msDesc -->
    <xsl:template match="tei:item[not(descendant::tei:bibl)]" mode="m_update">
        <msDesc>
            <!-- @ana pointing to the main biblStruct -->
            <xsl:attribute name="ana" select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'id', '', '', $p_local-authority)"/>
            <!-- holding institution -->
            <msIdentifier>
                <xsl:apply-templates mode="m_update" select="tei:label/tei:placeName"/>
                <repository>
                    <xsl:apply-templates mode="m_update" select="tei:label/tei:orgName"/>
                </repository>
                <xsl:apply-templates mode="m_update" select="tei:idno | tei:ref"/>
            </msIdentifier>
            <xsl:variable name="v_text">
                <xsl:apply-templates mode="m_plain-text" select="text()"/>
            </xsl:variable>
            <xsl:if test="not(matches(normalize-space($v_text), '^\W$'))">
                <!--<xsl:message>
                    <xsl:value-of select="$v_text"/>
                </xsl:message>-->
                <msContents>
                    <msItem>
                        <bibl>
                            <!-- @ana pointing to the main biblStruct -->
                            <xsl:attribute name="ana" select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'id', '', '', $p_local-authority)"/>
                            <xsl:value-of select="normalize-space($v_text)"/>
                        </bibl>
                    </msItem>
                </msContents>
            </xsl:if>
        </msDesc>
    </xsl:template>
    <xsl:template match="tei:item[descendant::tei:bibl] | tei:ab[descendant::tei:bibl]" mode="m_update">
        <xsl:apply-templates select="descendant::tei:bibl" mode="m_update"/>
    </xsl:template>
    <xsl:template match="tei:bibl" mode="m_update">
        <msDesc>
            <!-- @ana pointing to the main biblStruct -->
            <xsl:attribute name="ana" select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'id', '', '', $p_local-authority)"/>
            <!-- holding institution -->
            <msIdentifier>
                <xsl:variable name="v_item" select="ancestor::tei:item[1]"/>
                <xsl:apply-templates mode="m_update" select="$v_item/tei:label/tei:placeName"/>
                <repository>
                    <xsl:apply-templates mode="m_update" select="$v_item/tei:label/tei:orgName"/>
                </repository>
                <xsl:apply-templates mode="m_update" select="tei:idno"/>
            </msIdentifier>
            <xsl:if test="tei:date | tei:biblScope">
                <msContents>
                    <msItem>
                        <bibl>
                            <!-- @ana pointing to the main biblStruct -->
                            <xsl:attribute name="ana" select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'id', '', '', $p_local-authority)"/>
                            <xsl:apply-templates mode="m_update" select="tei:date | tei:biblScope"/>
                        </bibl>
                    </msItem>
                </msContents>
            </xsl:if>
        </msDesc>
    </xsl:template>
    <xsl:template match="tei:idno[@type = 'classmark']" mode="m_update">
        <xsl:copy>
            <xsl:apply-templates mode="m_update" select="@*"/>
            <xsl:if test="matches(@source, 'hathi')">
                <xsl:attribute name="subtype" select="'US-miaahdl'"/>
            </xsl:if>
            <xsl:apply-templates mode="m_update" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:ref" mode="m_update">
        <idno type="url">
            <xsl:value-of select="@target"/>
        </idno>
    </xsl:template>
</xsl:stylesheet>
