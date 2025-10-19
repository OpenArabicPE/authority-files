<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.0">
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* |node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:change[position() = 1]">
        <xsl:choose>
            <!-- check if the change element has been referenced -->
            <xsl:when test="ancestor::tei:TEI/descendant::node()/@change[matches(., concat('#', current()/@xml:id))]">
                <xsl:copy>
                    <xsl:apply-templates select="@* |node()"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>The change </xsl:text>
                    <xsl:value-of select="@xml:id"/>
                    <xsl:text> is not referenced in this file</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>