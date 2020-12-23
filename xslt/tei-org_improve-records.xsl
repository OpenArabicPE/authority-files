<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:bgn="http://bibliograph.net/" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:opf="http://www.idpf.org/2007/opf" xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:umbel="http://umbel.org/umbel#"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute on a persName child.
    It DOES NOT try to find names on VIAF without an ID -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="yes" method="xml"
        omit-xml-declaration="no"/>
    
    <xsl:include href="query-geonames.xsl"/>

      <!-- variables for local IDs (OpenArabicPE) -->
    <xsl:param name="p_local-authority" select="'oape'"/>
    <xsl:variable name="v_local-id-count" select="count(//tei:org/tei:idno[@type = $p_local-authority])"/>
    <xsl:variable name="v_local-id-highest"
        select="
            if ($v_local-id-count gt 0) then
                (max(//tei:place/tei:idno[@type = $p_local-authority]))
            else
                (0)"/>
    <xsl:template match="@* | node()" name="t_1">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!--<xsl:template match="/">
        <xsl:result-document
            href="{concat('_output/org_improved/',tokenize(base-uri(),'/')[last()])}">
            <xsl:copy>
                <xsl:apply-templates/>
            </xsl:copy>
        </xsl:result-document>
    </xsl:template>-->
    <xsl:template match="tei:listOrg" name="t_2">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_2: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:head"/>
            <xsl:apply-templates select="tei:org">
                <xsl:sort order="ascending" select="if(starts-with(tei:orgName[@xml:lang = 'ar'][1],'ال')) then(substring-after(tei:orgName[@xml:lang = 'ar'][1],'ال')) else(tei:orgName[@xml:lang = 'ar'][1])"/>
                 <xsl:sort order="ascending" select="tei:orgName[@xml:lang = 'ar-Latn-x-ijmes'][1]"/>
                <xsl:sort order="ascending" select="tei:orgName[@xml:lang = 'en'][1]"/>
                <xsl:sort order="ascending" select="tei:orgName[1]"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="tei:listOrg"/>
        </xsl:copy>
    </xsl:template>
    <!-- improve tei:place records with GeoNames references -->
    <!-- tei:place[tei:placeName[matches(@ref,'geon:\d+')]] | tei:place[tei:idno[@type='geon']!=''] -->
    <xsl:template match="tei:org" name="t_3" priority="100">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- the content model specifies that <idno> must be the last child -->
            <xsl:apply-templates select="tei:orgName"/>
            <!-- IDs -->
            <xsl:apply-templates select="tei:idno"/>
            <!-- our own ID -->
            <xsl:apply-templates mode="m_generate-id" select="."/>
        </xsl:copy>
    </xsl:template>
    <!-- mode to generate OpenArabicPE IDs -->
    <xsl:template match="tei:org" mode="m_generate-id">
        <xsl:if test="not(tei:idno[@type = $p_local-authority])">
            <xsl:element name="idno">
                <xsl:attribute name="type" select="$p_local-authority"/>
                <!-- basis is the highest existing ID -->
                <!-- add preceding tei:place without OpenArabicPE ID -->
                <xsl:value-of
                    select="$v_local-id-highest + count(preceding::tei:org[not(tei:idno[@type = $p_local-authority])]) + 1"
                />
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- decide whether or not to omit existing records -->
    <!--<xsl:template match="tei:place/tei:idno | tei:place/tei:birth | tei:place/tei:death | tei:place/tei:listBibl" name="t_7">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_7: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
    </xsl:template>
    -->
 
    <!-- document the changes -->
    <xsl:template match="tei:revisionDesc" name="t_8">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Improved </xsl:text>
                <tei:gi>org</tei:gi>
                <xsl:text> nodes by adding IDs.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
