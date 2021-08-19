<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" 
    xmlns:bgn="http://bibliograph.net/" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:genont="http://www.w3.org/2006/gen/ont#" 
    xmlns:oape="https://openarabicpe.github.io/ns" 
    xmlns:opf="http://www.idpf.org/2007/opf" 
    xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:re="http://oclcsrw.google.code/redirect" 
    xmlns:schema="http://schema.org/" 
    xmlns:srw="http://www.loc.gov/zing/srw/"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:umbel="http://umbel.org/umbel#" 
    xmlns:viaf="http://viaf.org/viaf/terms#" 
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xi="http://www.w3.org/2001/XInclude" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- this stylesheet queries an external authority files for every <title> and attempts to provide links via the @ref attribute -->
    <!-- note that some of the matching is based on location. Therefore, the placeName nodes in the source file should be linked to the gazetteer first -->
    <!-- The now unnecessary code to updated the master file needs to be removed -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml" omit-xml-declaration="no"/>
    
    <xsl:import href="functions.xsl"/>
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/">
        <!-- temporary debugging -->
        <!--<xsl:message>
            <xsl:value-of select="$v_bibliography"/>
        </xsl:message>-->
        <!-- test if the URL of the personography resolves to an actual file -->
        <xsl:if test="not(doc-available($p_url-bibliography))">
            <xsl:message terminate="yes">
                <xsl:text>The specified authority file has not been found at </xsl:text><xsl:value-of select="$p_url-bibliography"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:variable name="v_year-publication" select="if (/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct)
        then (oape:date-year-only(oape:query-biblstruct(/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct[1], 'date', '', '', '')))
       else(2020)"/>

    <xsl:template match="tei:title[ancestor::tei:text | ancestor::tei:standOff][@level = 'j'][not(@type = 'sub')]" priority="10">
        <xsl:copy-of select="oape:link-title-to-authority-file(., $p_local-authority, $v_bibliography)"/>
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
                <xsl:text>Added references to local authority file (</xsl:text>
                <tei:ref target="{$p_url-bibliography}" xml:lang="en">
                    <xsl:value-of select="$p_url-bibliography"/>
                </tei:ref>
                <xsl:text>) and to OCLC (WorldCat) IDs to </xsl:text>
                <tei:gi xml:lang="en">titles</tei:gi>
                <xsl:text>s without such references based on  </xsl:text>
                <tei:gi xml:lang="en">biblStruct</tei:gi>
                <xsl:text>s mentioned in the authority file (bibliography).</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
