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
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <listBibl>
                <xsl:apply-templates mode="m_update" select="descendant::tei:item"/>
            </listBibl>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="node() | @*" mode="m_update">
        <xsl:copy>
            <xsl:apply-templates mode="m_update" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@change | @xml:id" mode="m_update"/>
    <!-- transform holding information to msDesc -->
    <xsl:template match="tei:item" mode="m_update">
        <msDesc>
            <!-- @ana pointing to the main biblStruct -->
            <xsl:attribute name="ana" select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'id', '', '', $p_local-authority)"/>
            <!-- holding institution -->
            <msIdentifier>
                <xsl:apply-templates mode="m_update" select="tei:label/tei:placeName"/>
                <institution>
                    <xsl:apply-templates mode="m_update" select="tei:label/tei:orgName"/>
                </institution>
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
                    <xsl:if test="not(descendant::tei:bibl)">
                        <msItem>
                            <bibl>
                                <!-- @ana pointing to the main biblStruct -->
                                <xsl:attribute name="ana" select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'id', '', '', $p_local-authority)"/>
                                <xsl:value-of select="normalize-space($v_text)"/>
                            </bibl>
                        </msItem>
                    </xsl:if>
                    <!-- group descendant bibls by classmark -->
                    <xsl:for-each-group group-by="tei:idno[@type = 'classmark']" select="descendant::tei:bibl[tei:idno[@type = 'classmark']]">
                        <msItem>
                            <xsl:apply-templates mode="m_update" select="current-group()"/>
                        </msItem>
                    </xsl:for-each-group>
                    <xsl:for-each select="descendant::tei:bibl[not(tei:idno[@type = 'classmark'])]">
                        <msItem>
                            <xsl:apply-templates mode="m_update" select="."/>
                        </msItem>
                    </xsl:for-each>
                </msContents>
            </xsl:if>
        </msDesc>
    </xsl:template>
    <!--<xsl:template match="tei:item[descendant::tei:bibl] | tei:ab[descendant::tei:bibl]" mode="m_update">
        <xsl:apply-templates mode="m_update" select="descendant::tei:bibl[not(tei:idno[@type = 'classmark'])]"/>
    </xsl:template>-->
    <xsl:template match="tei:bibl" mode="m_update">
        <!--<xsl:if test="tei:date | tei:biblScope">-->
        <!--<msContents>
                    <msItem>-->
        <!-- reproduce the bibl -->
        <xsl:copy>
            <!-- @ana pointing to the main biblStruct -->
            <xsl:attribute name="ana" select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'id', '', '', $p_local-authority)"/>
            <!--                            <xsl:apply-templates mode="m_update" select="tei:date | tei:biblScope"/>-->
            <xsl:apply-templates mode="m_update" select="node()"/>
        </xsl:copy>
        <!--</msItem>
                </msContents>-->
        <!--</xsl:if>-->
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
    <!-- document the changes to source file -->
    <xsl:template match="tei:revisionDesc">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Changed the encoding of holding information from a list with bibls to msDesc.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
