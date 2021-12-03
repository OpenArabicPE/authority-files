<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="2.0" xmlns:bgn="http://bibliograph.net/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:genont="http://www.w3.org/2006/gen/ont#"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:opf="http://www.idpf.org/2007/opf" xmlns:pto="http://www.productontology.org/id/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/" xmlns:srw="http://www.loc.gov/zing/srw/" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:umbel="http://umbel.org/umbel#" xmlns:viaf="http://viaf.org/viaf/terms#" xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- PROBLEM: in some instance this stylesheet produces empty <placeName> nodes in the source file upon adding GeoNames references to them -->
    <!-- this stylesheet queries an external authority files for every <placeName> and attempts to provide links via the @ref attribute -->
    <!-- The now unnecessary code to updated the master file needs to be removed -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml" omit-xml-declaration="no"/>
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="yes" method="xml" name="xml_indented" omit-xml-declaration="no"/>
    <xsl:include href="functions.xsl"/>
    <!-- Identity transformation -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/">
        <!-- temporary debugging -->
        <!-- test if the URL of the personography resolves to an actual file -->
        <xsl:if test="not(doc-available($p_url-organizationography))">
            <xsl:message terminate="yes">
                <xsl:text>The specified authority file has not been found.</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:orgName" priority="30">
        <xsl:variable name="v_self-linked" select="oape:link-orgname-to-authority-file(., $p_local-authority, $v_organizationography)"/>
        <xsl:choose>
            <!-- test if a match was found in the authority file -->
            <xsl:when test="$v_self-linked/@ref">
                <xsl:copy-of select="$v_self-linked"/>
            </xsl:when>
            <!-- fall back -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Add the following organization to the authority file: </xsl:text>
                    <xsl:element name="org">
                        <xsl:apply-templates mode="m_copy-from-source" select="."/>
                    </xsl:element>
                </xsl:message>
                <!-- fallback replicate original input -->
                <xsl:apply-templates mode="m_identity-transform" select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- document the changes to source file -->
    <xsl:template match="tei:revisionDesc" name="t_9">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_9 source: document changes</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Added references to local authority file (</xsl:text>
                <tei:ref target="{$p_url-organizationography}">
                    <xsl:value-of select="$p_url-organizationography"/>
                </tei:ref>
                <xsl:text>)  to </xsl:text>
                <tei:gi>orgName</tei:gi>
                <xsl:text>s without such references based on  </xsl:text>
                <tei:gi>org</tei:gi>
                <xsl:text>s mentioned in the authority file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
