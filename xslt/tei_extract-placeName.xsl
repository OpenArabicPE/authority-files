<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet  xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" 
    xmlns:opf="http://www.idpf.org/2007/opf" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:bgn="http://bibliograph.net/" 
    xmlns:genont="http://www.w3.org/2006/gen/ont#" 
    xmlns:pto="http://www.productontology.org/id/" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:re="http://oclcsrw.google.code/redirect" 
    xmlns:schema="http://schema.org/" 
    xmlns:umbel="http://umbel.org/umbel#"
    xmlns:srw="http://www.loc.gov/zing/srw/"
    xmlns:viaf="http://viaf.org/viaf/terms#"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    exclude-result-prefixes="#all" version="2.0">

    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no"
        exclude-result-prefixes="#all"/>
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"
        name="xml_indented" exclude-result-prefixes="#all"/>

    <xsl:include href="query-geonames.xsl"/>

    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master"
        select="'../tei/entities_master.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>

    <!-- parameter to select whether the master file should be updated  -->
    <xsl:param name="p_update-master" select="true()"/>
    <!-- parameter to select whether the source file should be updated  -->
    <xsl:param name="p_update-source" select="true()"/>
    <!-- toggle debugging messages -->
    <xsl:param name="p_verbose" select="true()"/>

    <!-- p_id-editor references the @xml:id of a responsible editor to be used for documentation of changes -->
    <xsl:param name="p_id-editor" select="'pers_TG'"/>

    <xsl:variable name="v_id-file"
        select="
            if (tei:TEI/@xml:id) then
                (tei:TEI/@xml:id)
            else
                ('_output')"/>
    <xsl:variable name="v_url-file"
        select="concat('../../', substring-after(base-uri(), 'OpenArabicPE/'))"/>


    <!-- This template replicates everything -->
    <xsl:template match="node() | @*" name="t_1">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_1: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
   
   <xsl:template match="/">
       <xsl:apply-templates/>
   </xsl:template>
    
    <xsl:template match="tei:listPlace//tei:placeName">
        <xsl:call-template name="t_query-geonames">
            <xsl:with-param name="p_input" select="normalize-space(.)"/>
            <xsl:with-param name="p_output-mode" select="'file'"/>
        </xsl:call-template>
    </xsl:template>
</xsl:stylesheet>
