<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.0">
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:particDesc">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- create a new list -->
            <xsl:element name="tei:listPerson">
                <!-- apply sort to add all descendant tei:person -->
                <xsl:apply-templates select="tei:listPerson/tei:person">
                    <xsl:sort select="descendant::tei:surname[1]"/>
                    <xsl:sort select="descendant::tei:forename[1]"/>
                    <xsl:sort select="descendant::tei:addName[@type='noAddName'][not(.='')][1]"/>
                    <xsl:sort select="descendant::tei:addName[@type='flattened'][1]"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <!-- remove empty nodes -->
    <xsl:template match="node()[.='']"/>
</xsl:stylesheet>