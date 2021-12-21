<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:pj="https://projectjaraid.github.io/ns"
    xmlns:oape="https://openarabicpe.github.io/ns" 
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs pj"
    version="3.0">
    
    <xsl:include href="/BachUni/BachBibliothek/GitHub/OpenArabicPE/tools/xslt/functions_arabic-transcription.xsl"/>
    <xsl:include href="functions.xsl"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node()[ancestor::tei:biblStruct][@xml:lang=('ar-Latn-x-ijmes', 'ar-Latn-x-dmg')]">
        <!-- decomposed utf-8 -->
        <xsl:variable name="v_self-latin" select="normalize-unicode(., 'NFKC')"/>
        <xsl:variable name="v_self-arabic">
            <xsl:value-of select="oape:string-transliterate-arabic_latin-to-arabic($v_self-latin)"/>
        </xsl:variable>
        <!-- reproduce content -->
<!--        <xsl:apply-templates select="." mode="m_identity-transform"/>-->
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <xsl:value-of select="$v_self-latin"/>
        </xsl:copy>
        <!-- check if there is a sibling with the same content in Arabic script -->
        <xsl:choose>
            <xsl:when test="parent::node()/node()[name() = current()/name()][text() = $v_self-arabic]">
                <xsl:message>
                    <xsl:value-of select="$v_self-arabic"/>
                    <xsl:text> is already present</xsl:text>
                </xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <!-- add arabic script -->
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            <xsl:attribute name="resp" select="'#xslt'"/>
            <xsl:attribute name="xml:lang" select="'ar'"/>
            <xsl:value-of select="normalize-space($v_self-arabic)"/>
        </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- generate documentation of change -->
    <xsl:template match="tei:revisionDesc">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="change">
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="$p_id-editor"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:text>Automatically translated IJMES/DMG transcriptions into Arabic script</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>