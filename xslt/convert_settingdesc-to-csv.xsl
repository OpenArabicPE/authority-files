<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.0">
    
    <xsl:output method="text" encoding="UTF-8"/>
    
    <xsl:param name="p_separator" select="';'"/>
    <xsl:param name="p_separator-escape" select="','"/>
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="descendant::tei:settingDesc"/>
    </xsl:template>
    
    <xsl:template match="tei:settingDesc">
        <xsl:text>location</xsl:text><xsl:value-of select="$p_separator"/>
        <xsl:text>lat</xsl:text><xsl:value-of select="$p_separator"/>
        <xsl:text>long</xsl:text><xsl:value-of select="$v_new-line"/>
        <xsl:for-each-group select="descendant::tei:placeName[following-sibling::tei:location/tei:geo]" group-by="normalize-space(string())">
            <xsl:sort select="current-grouping-key()" order="ascending"/>
            <xsl:value-of select="current-grouping-key()"/><xsl:value-of select="$p_separator"/>
            <xsl:value-of select="tokenize(following-sibling::tei:location/tei:geo,',')[1]"/><xsl:value-of select="$p_separator"/>
            <xsl:value-of select="normalize-space(tokenize(following-sibling::tei:location/tei:geo,',')[2])"/><xsl:value-of select="$v_new-line"/>
        </xsl:for-each-group>
    </xsl:template>
    
</xsl:stylesheet>