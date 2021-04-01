<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- this stylesheet tries to remove automatically generated mark-up -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml" omit-xml-declaration="no"/>
    
    <xsl:template match="/">
        <xsl:copy>
<!--            <xsl:apply-templates select="descendant::tei:listPerson"/>-->
            <xsl:apply-templates select="descendant::tei:listPlace"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tei:person">
        <!-- if any persName points to oape, ignore it -->
        <xsl:choose>
            <xsl:when test="tei:persName/@ref[matches(., 'oape:pers:\d+')]"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:place">
        <!-- if any persName points to oape, ignore it -->
        <xsl:choose>
            <xsl:when test="tei:placeName/@ref[matches(., 'oape:place:\d+')]"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>