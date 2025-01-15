<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
   <!-- this stylesheet calls mode m_post-process on all nodes -->
    <xsl:import href="functions.xsl"/>
    <xsl:template match="/">
        <xsl:apply-templates select="/" mode="m_post-process"/>
    </xsl:template>
<!--    <xsl:template match="tei:biblStruct/tei:analytic" mode="m_post-process" priority="8"/>-->
<!--    <xsl:template match="tei:biblStruct[not(tei:monogr/tei:title[@level = 'j'])]" mode="m_post-process"/>-->
    <xsl:template match="tei:biblStruct[not(@source)][parent::node()/@source]" mode="m_post-process">
        <xsl:copy>
            <xsl:copy-of select="parent::node()/@source"/>
            <xsl:apply-templates select="@* | node()" mode="m_post-process"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>