<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="2.0">
    
    
   <!-- stylesheet to correct the mark-up of my gazeteers -->
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>
    
    <!-- identiy transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:place">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
        <xsl:apply-templates select="tei:placeName, tei:location"/>
        <xsl:if test="@xml:id">
            <xsl:element name="tei:idno">
                    <xsl:choose>
                        <xsl:when test="starts-with(@xml:id, 'lgn')">
                            <xsl:attribute name="type" select="$p_acronym-geonames"/>
                            <xsl:analyze-string select="@xml:id" regex="lgn(\d+)p*$">
                                <xsl:matching-substring>
                                    <xsl:value-of select="regex-group(1)"/>
                                </xsl:matching-substring>
                            </xsl:analyze-string>
                        </xsl:when>
                        <xsl:when test="starts-with(@xml:id, 'lwm')">
                            <xsl:attribute name="type" select="'wikimapia'"/>
                            <xsl:value-of select="substring-after(@xml:id, 'lwm')"/>
                        </xsl:when>
                    </xsl:choose>
            </xsl:element>
        </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:placeName">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- try to establish the source of this information -->
            <xsl:if test="@type = 'alt'">
                <xsl:choose>
                    <xsl:when test="starts-with(parent::tei:place/@xml:id, 'lgn')">
                        <xsl:attribute name="source" select="'#org_geon'"/>
                    </xsl:when>
                    <xsl:when test="starts-with(parent::tei:place/@xml:id, 'lwm')"/>
                    <xsl:otherwise>
                        <xsl:attribute name="source" select="'#pers_TG'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:value-of select="normalize-space(.)"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>