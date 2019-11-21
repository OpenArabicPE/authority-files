<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="no" exclude-result-prefixes="#all" omit-xml-declaration="no"/>
    
    <!-- parameters for string-replacements -->
    <xsl:param name="p_string-match" select="'([إ|أ|آ])'"/>
    <xsl:param name="p_string-replace" select="'ا'"/>
    <xsl:param name="p_string-harakat" select="'([ِ|ُ|ٓ|ٰ|ْ|ٌ|ٍ|ً|ّ|َ])'"/>
    
    <xsl:function name="oape:string-normalise-name">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_self" select="normalize-space(replace(oape:string-remove-harakat($p_input),$p_string-match,$p_string-replace))"/>
        <xsl:value-of select="replace($v_self, '\W', '')"/>
    </xsl:function>
    
    <xsl:function name="oape:string-remove-characters">
        <xsl:param name="p_input"/>
        <xsl:param name="p_string-match"/>
        <xsl:value-of select="normalize-space(replace($p_input,$p_string-match,''))"/>
    </xsl:function>
    
    <xsl:function name="oape:string-remove-harakat">
        <xsl:param name="p_input"/>
        <xsl:value-of select="oape:string-remove-characters($p_input,$p_string-harakat)"/>
    </xsl:function>
    
</xsl:stylesheet>