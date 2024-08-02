<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.wikidata.org/">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:import href="parameters.xsl"/>
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:title[@level = 'j'][following-sibling::tei:textLang[@mainLang = 'ota']][following-sibling::tei:imprint/tei:date[matches(.,'publication','i')]][not(following-sibling::tei:idno[@type = $p_acronym-wikidata])]">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
        <xsl:variable name="v_corresp-QID" select="if(matches(@ref, 'Q\d+')) then(replace(@ref,'^.*(Q\d+).*$','$1')) else($v_QIDs/descendant::tei:idno[@type = $p_acronym-wikidata][parent::node()/tei:title = current()])"/>
        <xsl:if test="$v_corresp-QID != '' and not(parent::node()/tei:idno[@type = $p_acronym-wikidata] = $v_corresp-QID)">
            <xsl:element name="idno">
                <xsl:attribute name="type" select="$p_acronym-wikidata"/>
                <xsl:value-of select="$v_corresp-QID"/>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:idno[@type = $p_local-authority]">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
        <xsl:variable name="v_corresp-QID" select="$v_QIDs/descendant::tei:idno[@type = $p_acronym-wikidata][parent::node()/tei:idno[@type = $p_local-authority] = current()]"/>
        <xsl:if test="$v_corresp-QID != '' and not(parent::node()/tei:idno[@type = $p_acronym-wikidata] = $v_corresp-QID)">
            <xsl:copy>
                <xsl:attribute name="type" select="$p_acronym-wikidata"/>
                <xsl:value-of select="$v_corresp-QID"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:org">
        <xsl:variable name="v_corresp-QID" select="$v_QIDs/descendant::tei:idno[@type = $p_acronym-wikidata][parent::tei:org/tei:orgName = current()/tei:orgName]"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:orgName"/>
            <xsl:apply-templates select="tei:idno"/>
            <xsl:if test="$v_corresp-QID != '' and not(parent::node()/tei:idno[@type = $p_acronym-wikidata] = $v_corresp-QID)">
                <xsl:copy-of select="$v_corresp-QID"/>
            </xsl:if>
            <xsl:apply-templates select="tei:location"/>
            <xsl:apply-templates select="tei:note"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:place">
        <xsl:variable name="v_corresp-QID" select="$v_QIDs/descendant::tei:idno[@type = $p_acronym-wikidata][parent::tei:place/tei:placeName = current()/tei:placeName]"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:placeName"/>
            <xsl:apply-templates select="tei:location"/>
            <xsl:apply-templates select="tei:idno"/>
            <xsl:if test="$v_corresp-QID != '' and not(parent::node()/tei:idno[@type = $p_acronym-wikidata] = $v_corresp-QID)">
                <xsl:copy-of select="$v_corresp-QID"/>
            </xsl:if>
            <xsl:apply-templates select="tei:note"/>
        </xsl:copy>
    </xsl:template>
    <!-- read data from file -->
    <xsl:variable name="v_QIDs" select="doc('../data/OpenRefine/mappings/baykal_bibl-mapping-2024-08-02.TEIP5.xml')/descendant::tei:standOff"/>
</xsl:stylesheet>
