<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.wikidata.org/">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    
    <xsl:import href="parameters.xsl"/>
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
   
   <xsl:template match="tei:idno[@type = $p_local-authority]">
       <xsl:copy>
           <xsl:apply-templates select="@* |node()"/>
       </xsl:copy>
       <xsl:variable name="v_corresp-QID" select="$v_QIDs/descendant::tei:idno[@type = $p_acronym-wikidata][parent::node()/tei:idno[@type = $p_local-authority] = current()]"/>
       <xsl:if test="$v_corresp-QID != '' and not(parent::tei:monogr/tei:idno[@type = $p_acronym-wikidata] = $v_corresp-QID)">
           <xsl:copy>
               <xsl:attribute name="type" select="$p_acronym-wikidata"/>
               <xsl:value-of select="$v_corresp-QID"/>
           </xsl:copy>
       </xsl:if>
   </xsl:template>
    
    <!-- read data from file -->
    <xsl:variable name="v_QIDs" select="doc('../data/refine/openrefine_person-mapping-2024-03-27.TEIP5.xml')/descendant::tei:standOff"/>
    
</xsl:stylesheet>