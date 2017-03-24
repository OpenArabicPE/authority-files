<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:html="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:opf="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:bgn="http://bibliograph.net/" xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:pto="http://www.productontology.org/id/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/" xmlns:umbel="http://umbel.org/umbel#"
    xmlns:xi="http://www.w3.org/2001/XInclude" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs xd xi dc opf html" version="2.0">
    
    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output method="xml" encoding="UTF-8" indent="yes" exclude-result-prefixes="#all"/>
    
    <xsl:include href="query-viaf.xsl"/>
    
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:listPerson">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:person">
                <xsl:sort select="tei:persName[tei:surname][1]/tei:surname"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <!-- improve tei:person records -->
    <xsl:template match="tei:person[tei:persName[matches(@ref,'viaf:\d+')]]">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <!--<xsl:call-template name="t_query-viaf-rdf">
                <xsl:with-param name="p_viaf-id" select="replace(tei:persName[matches(@ref,'viaf:\d+')][1]/@ref,'viaf:(\d+)','$1')"/>
            </xsl:call-template>-->
            <xsl:call-template name="t_query-viaf-sru">
                <xsl:with-param name="p_output-mode" select="'file'"/>
                <xsl:with-param name="p_search-term" select="replace(tei:persName[matches(@ref,'viaf:\d+')][1]/@ref,'viaf:(\d+)','$1')"/>
                <xsl:with-param name="p_input-type" select="'id'"/>
               <!-- <xsl:with-param name="p_search-term">
                    <xsl:value-of select="normalize-space(tei:persName[1])"/>
                </xsl:with-param>
                <xsl:with-param name="p_input-type" select="'persName'"/>-->
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>
    
    <!-- omit existing records -->
    <xsl:template match="tei:person/tei:idno | tei:person/tei:birth | tei:person/tei:death"/>
</xsl:stylesheet>