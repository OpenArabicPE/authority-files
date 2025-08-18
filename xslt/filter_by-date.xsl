<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>
    <xsl:import href="functions.xsl"/>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:param name="p_terminus" select="'1930'"/>
    <xsl:template match="tei:biblStruct">
        <xsl:variable name="v_onset" select="oape:query-biblstruct(., 'year-onset','', '', $p_local-authority)"/>
        <!-- get earliest publication date -->
        <xsl:choose>
            <!-- when published after threshold: discard -->
            <xsl:when test="($v_onset != 'NA') and ($v_onset >= $p_terminus)">
                <xsl:message>
                    <xsl:value-of select="$v_onset"/><xsl:text> is after the threshold date.</xsl:text>
                </xsl:message>
            </xsl:when>
            <xsl:when test="$v_onset = 'NA'">
                <xsl:message>
                    <xsl:text>In the NLoI data, all non-machine-readible dates are after the threshold date</xsl:text>
                </xsl:message>
            </xsl:when>
            <!-- else retain -->
            <xsl:otherwise>
                <xsl:copy>
                     <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- delete biblStruct without explicit onset date -->
    <xsl:template match="tei:biblStruct[not(descendant::tei:date[@type = 'onset'])]" mode="m_off"/>
</xsl:stylesheet>