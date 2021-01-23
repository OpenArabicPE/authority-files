<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
    xmlns:oape="https://openarabicpe.github.io/ns" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" name="xml" omit-xml-declaration="no"/>
    <xsl:output encoding="UTF-8" indent="yes" method="text" name="text" omit-xml-declaration="yes"/>
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>This stylesheet produces nodes and edges tables for unimodal networks between people, connected by publications. Input are biblStruct nodes. Output are CSV files.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <!-- import functions -->
<!--    <xsl:include href="../../convert_tei-to-bibliographic-data/xslt/convert_tei-to-csv_functions.xsl"/>-->
    <xsl:include href="functions.xsl"/>
    
    <xsl:variable name="v_csv-head_persons">
        <xsl:value-of select="$v_quot"/>
            <xsl:text>name</xsl:text><xsl:value-of select="$v_seperator"/>
            <!-- names not strictly needed -->
            <xsl:text>id.viaf</xsl:text><xsl:value-of select="$v_seperator"/>
            <xsl:text>id.wiki</xsl:text><xsl:value-of select="$v_seperator"/>
            <xsl:value-of select="concat('id.', $p_local-authority)"/>
        <xsl:value-of select="$v_quot"/><xsl:value-of select="$v_new-line"/>
    </xsl:variable>
    <xsl:variable name="v_csv-head_places">
        <xsl:value-of select="$v_quot"/>
            <xsl:text>name</xsl:text><xsl:value-of select="$v_seperator"/>
            <!-- names not strictly needed -->
            <xsl:text>id.geon</xsl:text><xsl:value-of select="$v_seperator"/>
            <xsl:text>id.wiki</xsl:text><xsl:value-of select="$v_seperator"/>
            <xsl:value-of select="concat('id.', $p_local-authority)"/>
        <xsl:value-of select="$v_quot"/><xsl:value-of select="$v_new-line"/>
    </xsl:variable>
    
    <xsl:template match="/">
        <!-- persons -->
        <xsl:result-document href="{$v_base-directory}refine/{$v_id-file}_persons.csv" method="text">
            <xsl:value-of select="$v_csv-head_persons"/>
            <xsl:apply-templates select="descendant::tei:standOff/descendant::tei:person | descendant::tei:teiHeader/tei:profileDesc/tei:particDesc/descendant::tei:person" mode="m_openrefine"/>
        </xsl:result-document>
        <xsl:result-document href="{$v_base-directory}refine/{$v_id-file}_places.csv" method="text">
            <xsl:value-of select="$v_csv-head_places"/>
            <xsl:apply-templates select="descendant::tei:standOff/descendant::tei:place | descendant::tei:teiHeader/tei:profileDesc/tei:settingDesc/descendant::tei:place" mode="m_openrefine"/>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="tei:person" mode="m_openrefine">
        <xsl:value-of select="$v_quot"/>
        <!-- name -->
        <xsl:value-of select="oape:query-person(., 'name', 'ar', '')"/><xsl:value-of select="$v_seperator"/>
        <!-- IDs -->
        <xsl:value-of select="oape:query-person(., 'id-viaf', '', '')"/><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="oape:query-person(., 'id-wiki', '', '')"/><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="oape:query-person(., 'id-local', '', $p_local-authority)"/>
        <!-- end of line -->
        <xsl:value-of select="$v_quot"/><xsl:value-of select="$v_new-line"/>
    </xsl:template>
     <xsl:template match="tei:place" mode="m_openrefine">
        <xsl:value-of select="$v_quot"/>
        <!-- name -->
        <xsl:value-of select="oape:query-place(., 'name', 'ar', '')"/><xsl:value-of select="$v_seperator"/>
        <!-- IDs -->
        <xsl:value-of select="oape:query-place(., 'id-geon', '', '')"/><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="oape:query-person(., 'id-wiki', '', '')"/><xsl:value-of select="$v_seperator"/>
        <xsl:value-of select="oape:query-person(., 'id-local', '', $p_local-authority)"/>
        <!-- end of line -->
        <xsl:value-of select="$v_quot"/><xsl:value-of select="$v_new-line"/>
    </xsl:template>
</xsl:stylesheet>