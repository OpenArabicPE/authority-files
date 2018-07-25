<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.0">
    
    <xsl:output method="text" encoding="UTF-8"/>
    
    <xsl:param name="p_separator" select="','"/>
    <xsl:param name="p_separator-escape" select="';'"/>
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="descendant::tei:settingDesc"/>
    </xsl:template>
    
    <xsl:template match="tei:settingDesc">
        <xsl:text>schema:Place</xsl:text><xsl:value-of select="$p_separator"/>
        <xsl:text>schema:latitude</xsl:text><xsl:value-of select="$p_separator"/>
        <xsl:text>schema:longitude</xsl:text><xsl:value-of select="$p_separator"/>
        <xsl:text>schema:language</xsl:text><xsl:value-of select="$p_separator"/>
        <xsl:text>schema:identifier</xsl:text><xsl:value-of select="$v_new-line"/>
        <xsl:for-each-group select="descendant::tei:placeName[parent::tei:place/tei:location/tei:geo]" group-by="normalize-space(string())">
            <xsl:sort select="current-grouping-key()" order="ascending"/>
            <xsl:value-of select="current-grouping-key()"/><xsl:value-of select="$p_separator"/>
            <xsl:value-of select="tokenize(parent::tei:place/tei:location/tei:geo,',')[1]"/><xsl:value-of select="$p_separator"/>
            <xsl:value-of select="normalize-space(tokenize(parent::tei:place/tei:location/tei:geo,',')[2])"/><xsl:value-of select="$p_separator"/>
            <xsl:value-of select="parent::tei:place/tei:placeName[string() = current-grouping-key()][@xml:lang][1]/@xml:lang"/><xsl:value-of select="$p_separator"/>
            <xsl:value-of select="if(parent::tei:place/tei:idno[@type='geon']) then(concat('https://www.geonames.org/',parent::tei:place/tei:idno[@type='geon'])) else()"/><xsl:value-of select="$v_new-line"/>
        </xsl:for-each-group>
    </xsl:template>
    
</xsl:stylesheet>