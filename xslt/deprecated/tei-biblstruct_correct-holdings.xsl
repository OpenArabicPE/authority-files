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
    <xsl:template match="tei:label[matches(tei:orgName, '^[A-Z]{2}\-')]" priority="10">
        <xsl:variable name="v_orgName">
            <xsl:element name="orgName">
                <xsl:attribute name="ref" select="concat('isil:', tei:orgName)"/>
            </xsl:element>
        </xsl:variable>
        <xsl:variable name="v_org" select="oape:get-entity-from-authority-file($v_orgName/descendant-or-self::tei:orgName, $p_local-authority, $v_organizationography)"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <xsl:apply-templates select="$v_org/descendant::tei:placeName[1]" mode="m_identity-transform"/>
            <xsl:text>, </xsl:text>
             <xsl:apply-templates select="$v_org/descendant::tei:orgName[1]" mode="m_identity-transform"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:label[tei:orgName][not(tei:placeName)]">
        <xsl:variable name="v_org" select="oape:get-entity-from-authority-file(tei:orgName, $p_local-authority, $v_organizationography)"/>
        <xsl:variable name="v_location" select="oape:query-org($v_org, 'location-name', '', $p_local-authority)"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="$v_location != 'NA'">
            <xsl:element name="placeName">
                <xsl:value-of select="$v_location"/>
            </xsl:element>
                <xsl:text>, </xsl:text>
        </xsl:if>
            <xsl:apply-templates select="node()" mode="m_identity-transform"/>
        </xsl:copy>
    </xsl:template>
    <!-- rs: transform to orgName -->
    <xsl:template match="tei:rs[ancestor::tei:note[@type = 'holdings']]">
        <xsl:element name="orgName">
            <xsl:apply-templates select="@* | node()" mode="m_identity-transform"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:list[parent::tei:note[@type = 'comments']]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="xml:lang" select="'de'"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <!--<xsl:template match="tei:note[@type = 'holdings']/descendant::tei:ab[1]">
        <xsl:copy>
            <!-\- reproduce content -\->
             <xsl:apply-templates select="@* | node()" mode="m_identity-transform"/>
        </xsl:copy>
        <!-\- new content: bibl -\->
        <xsl:element name="ab">
            <xsl:element name="bibl">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'classmark'"/>
                    <xsl:attribute name="subtype" select="'AUB'"/>
                    <xsl:value-of select="ancestor::tei:biblStruct/descendant::tei:idno[@type = 'AUBNO']"/>
                </xsl:element>
                <xsl:apply-templates select="following-sibling::tei:ab/tei:ref" mode="m_ref-to-idno"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>-->
    <xsl:template match="tei:ref" mode="m_ref-to-idno">
        <xsl:element name="idno">
            <xsl:attribute name="type" select="'url'"/>
            <xsl:value-of select="@target"/>
        </xsl:element>
    </xsl:template>
    <!-- orgName with ref children -->
    <!--<xsl:template match="tei:orgName[ancestor::tei:note[@type = 'holdings']][tei:ref]" priority="10">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <xsl:apply-templates select="node()[not(self::tei:ref)]" mode="m_identity-transform"></xsl:apply-templates>
        </xsl:copy>
        <xsl:apply-templates select="tei:ref" mode="m_identity-transform"/>
    </xsl:template>-->
    <!-- orgName  with content split by ":"-->
    <!--<xsl:template match="tei:orgName[ancestor::tei:note[@type = 'holdings']][contains(., ':')]">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <xsl:value-of select="substring-before(., ':')"/>
        </xsl:copy>
        <xsl:value-of select="normalize-space(substring-after(., ':'))"/>
    </xsl:template>-->
</xsl:stylesheet>