<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet  
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" 
    xmlns:opf="http://www.idpf.org/2007/opf" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:bgn="http://bibliograph.net/" 
    xmlns:genont="http://www.w3.org/2006/gen/ont#" 
    xmlns:pto="http://www.productontology.org/id/" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:re="http://oclcsrw.google.code/redirect" 
    xmlns:schema="http://schema.org/" 
    xmlns:umbel="http://umbel.org/umbel#"
    xmlns:srw="http://www.loc.gov/zing/srw/"
    xmlns:viaf="http://viaf.org/viaf/terms#"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="2.0">
    
    <!-- PROBLEM: in some instance this stylesheet produces empty <placeName> nodes in the source file upon adding GeoNames references to them -->
    <!-- necessary improvements:
        - disambiguation: There is a very small number of ambiguous Arabic toponyms, such as al-Jazāʾir for the country and the city. These should alsways point to the town
    -->
    
    <!-- this stylesheet queries an external authority files for every <placeName> and attempts to provide links via the @ref attribute -->
    <!-- The now unnecessary code to updated the master file needs to be removed -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no"
        exclude-result-prefixes="#all"/>
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes" name="xml_indented" exclude-result-prefixes="#all"/>

<!--    <xsl:include href="query-geonames.xsl"/>-->
    <xsl:include href="functions.xsl"/>

   <!-- Identity transformation -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/">
        <!-- temporary debugging -->
        <!--<xsl:message>
            <xsl:value-of select="$p_local-authority"/><xsl:text>, </xsl:text>
            <xsl:value-of select="$p_url-personography"/><xsl:text>, </xsl:text>
            <xsl:value-of select="$p_add-mark-up-to-input"/><xsl:text>, </xsl:text>
        </xsl:message>-->
        <!-- test if the URL of the personography resolves to an actual file -->
        <xsl:if test="not(doc-available($p_url-gazetteer))">
            <xsl:message terminate="yes">
                <xsl:text>The specified authority file has not been found.</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:placeName" priority="30">
        <xsl:variable name="v_self-linked" select="oape:link-placename-to-authority-file(., $p_local-authority, $v_gazetteer)"/>
        <xsl:choose>
            <!-- test if a match was found in the authority file -->
            <xsl:when test="$v_self-linked/@ref">
                <xsl:copy-of select="$v_self-linked"/>
            </xsl:when>
            <!-- fall back -->
            <xsl:otherwise>
                <!-- add mark-up to the input name -->
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>No match found in the authority file "</xsl:text><xsl:value-of select="$p_url-personography"/><xsl:text>". </xsl:text>
                    </xsl:message>
                </xsl:if>
                
                    <!-- fallback replicate original input -->
                   
                        <xsl:copy>
                            <xsl:apply-templates select="@* | node()" mode="m_identity-transform"/>
                        </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    
    
    <!-- document the changes to source file -->
    <xsl:template match="tei:revisionDesc" name="t_9">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                 <xsl:text>Added references to local authority file (</xsl:text>
                <tei:ref target="{$p_url-gazetteer}">
                    <xsl:value-of select="$p_url-gazetteer"/>
                </tei:ref>
                <xsl:text>) and to GeoNames IDs to </xsl:text><tei:gi>placeName</tei:gi><xsl:text>s without such references based on  </xsl:text><tei:gi>place</tei:gi><xsl:text>s mentioned in the authority file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
