<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.0">
    <xsl:output encoding="UTF-8" indent="yes" method="text" name="text" omit-xml-declaration="yes"/>
    
    <!-- this stylesheet converts tei:place nodes into Linked Places TSV v0.3 (https://github.com/LinkedPasts/linked-places-format/blob/master/tsv_0.3.md) -->
    
    <xsl:import href="functions.xsl"/>
    <xsl:param name="p_project-start" select="'1850'"/>
    
    <xsl:template match="/">
        <xsl:result-document format="text" href="{$v_url-base}/../csv/{$v_id-file}.lp.tsv">
            <!-- csv head -->
            <xsl:value-of select="$v_csv-head"/>
            <xsl:apply-templates select="/tei:TEI/tei:standOff/tei:listPlace/descendant::tei:place" mode="m_tei-to-lp-tsv"/>
             <xsl:variable name="v_toponyms">
                 <xsl:apply-templates select="/tei:TEI/tei:text/descendant::tei:placeName" mode="m_placename-to-place"/>
             </xsl:variable>
            <xsl:for-each-group select="$v_toponyms/descendant-or-self::tei:place" group-by=".">
                <xsl:sort select="tei:placeName[@xml:lang = 'ar'][1]"/>
                <xsl:sort select="tei:placeName[1]"/>
                <xsl:apply-templates select="." mode="m_tei-to-lp-tsv"/>
            </xsl:for-each-group>
        </xsl:result-document>
    </xsl:template>
   
    
     <xsl:variable name="v_csv-head">
        <xsl:value-of select="$v_beginning-of-line"/>
         <!-- required -->
         <xsl:text>id</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>title</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>title_source</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>start</xsl:text><xsl:value-of select="$v_seperator"/>
         <!-- encouraged -->
         <xsl:text>title_uri</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>ccodes</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>matches</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>variants</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>aat_types</xsl:text><xsl:value-of select="$v_seperator"/>
         <!-- optional -->
         <xsl:text>parent_name</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>parent_id</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>lon</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>lat</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>geowkt</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>geo_source</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>geo_id</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>end</xsl:text><xsl:value-of select="$v_seperator"/>
         <xsl:text>description</xsl:text>
         <xsl:value-of select="$v_end-of-line"/>
     </xsl:variable>
    <xsl:template match="tei:place" mode="m_tei-to-lp-tsv">
        <xsl:value-of select="$v_beginning-of-line"/>
        <!-- required -->
        <xsl:value-of select="oape:query-place(., 'id-local', '', $p_local-authority)"/><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="oape:query-place(., 'name', '', $p_local-authority)"/><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$p_local-authority"/><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$p_project-start"/><xsl:value-of select="$v_seperator"/>
        <!-- encouraged -->
        <xsl:value-of select="$v_url-file"/><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$v_seperator"/>
        <xsl:if test="not(oape:query-place(., 'id-geon', '', $p_local-authority) = 'NA')">
            <xsl:value-of select="concat('gn:',oape:query-place(., 'id-geon', '', $p_local-authority))"/>
        </xsl:if><xsl:value-of select="$v_seperator"/>
        <!-- variants:  -->
        <xsl:apply-templates select="tei:placeName" mode="m_alternate-names"/><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$v_seperator"/>
        <!-- optional -->
        <xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$v_seperator"/>
        <xsl:if test="not(oape:query-place(., 'long', '', $p_local-authority) = 'NA')">
            <xsl:value-of select="oape:query-place(., 'long', '', $p_local-authority)"/>
        </xsl:if><xsl:value-of select="$v_seperator"/>
        <xsl:if test="not(oape:query-place(., 'lat', '', $p_local-authority) = 'NA')">
            <xsl:value-of select="oape:query-place(., 'lat', '', $p_local-authority)"/>
        </xsl:if><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="$v_end-of-line"/>
    </xsl:template>
    <xsl:template match="tei:placeName" mode="m_alternate-names">
        <!-- variants: {name}@lang-script, semicolon-delimited. Karl Grossner clarified that the brackets should be omitted -->
        <!--<xsl:text>{</xsl:text>-->
        <xsl:value-of select="normalize-space(.)"/>
        <!--<xsl:text>}</xsl:text>-->
        <xsl:text>@</xsl:text><xsl:value-of select="@xml:lang"/>
        <xsl:if test="following-sibling::tei:placeName">
            <xsl:text>; </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tei:placeName" mode="m_placename-to-place">
        <xsl:variable name="v_place" select="oape:get-entity-from-authority-file(., $p_local-authority, $v_gazetteer)"/>
        <xsl:choose>
            <xsl:when test="$v_place = 'NA'">
                <xsl:element name="tei:place">
                    <xsl:copy-of select="."/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$v_place"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>