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
    
    <!-- this stylesheet  tries to query external authority files if they are linked through the @ref attribute -->
    
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes" name="xml_indented" exclude-result-prefixes="#all"/>
    
    <!-- the file path is relative to this stylesheet!  -->
    <xsl:param name="p_viaf-file-path" select="'../geonames/'"/>
    <!-- these variables are used to establish the language of any given string -->
<!--    <xsl:variable name="v_string-transcribe-ijmes" select="'btḥḫjdrzsṣḍṭẓʿfqklmnhāūīwy0123456789'"/>
    <xsl:variable name="v_string-transcribe-arabic" select="'بتحخجدرزسصضطظعفقكلمنهاويوي٠١٢٣٤٥٦٧٨٩'"/>-->
   
    <xsl:variable name="vGeoNamesDiac" select="'’‘áḨḨḩŞşŢţz̧'"/>
    <xsl:variable name="vGeoNamesIjmes" select="'ʾʿāḤḤḥṢṣṬṭẓ'"/>
    
    <xsl:template name="t_query-geonames">
        <xsl:param name="p_input"/>
        <!-- available values are 'tei', 'file', and 'csv' -->
        <xsl:param name="p_output-mode" select="'file'"/>
        <xsl:param name="p_csv-separator" select="';'"/>
        <xsl:variable name="v_api-url" select="'http://api.geonames.org/search?name='"/>
        <xsl:variable name="v_api-options"
            select="'&amp;maxRows=1&amp;style=FULL&amp;lang=en&amp;username=tardigradae'"/>
        <xsl:variable name="vDocName">
            <xsl:value-of select="$v_api-url"/>
            <xsl:value-of select="translate($p_input,$vGeoNamesIjmes,$vGeoNamesDiac)"/>
            <xsl:value-of select="$v_api-options"/>
        </xsl:variable>
        <xsl:variable name="v_xml-geonames" select="document($vDocName)"/>
        <xsl:variable name="v_id-geonames" select="document($vDocName)/geonames/geoname[1]/geonameId"/>
        <!-- if there is no ID, there is no search result and there need not be any output -->
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:value-of select="$p_input"/><xsl:text> returned the ID: </xsl:text><xsl:value-of select="$v_id-geonames"/>
            </xsl:message>
        </xsl:if>
        <xsl:if test="$v_id-geonames!=''">
            <xsl:choose>
                <xsl:when test="$p_output-mode ='file'">
                    <xsl:result-document href="{$p_viaf-file-path}/geon_{$v_id-geonames}.xml">
                        <xsl:copy-of select="$v_xml-geonames"/>
                    </xsl:result-document>
                </xsl:when>
                <xsl:when test="$p_output-mode = 'tei'">
                    <xsl:apply-templates select="$v_xml-geonames/geonames/geoname[1]/geonameId" mode="m_geon-to-tei"/>
                    <xsl:apply-templates select="$v_xml-geonames/geonames/geoname[1]/lat" mode="m_geon-to-tei"/>
                </xsl:when>
                <xsl:when test="$p_output-mode = 'csv'">
                    <xsl:value-of select="$v_xml-geonames/geonames/geoname[1]/geonameId"/><xsl:value-of select="$p_csv-separator"/>
                    <xsl:value-of select="$v_xml-geonames/geonames/geoname[1]/lat"/><xsl:value-of select="$p_csv-separator"/>
                    <xsl:value-of select="$v_xml-geonames/geonames/geoname[1]/lng"/><xsl:value-of select="$p_csv-separator"/>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="geonameId" mode="m_geon-to-tei">
        <tei:idno type="geon">
            <xsl:value-of select="."/>
        </tei:idno>
    </xsl:template>
    
    <xsl:template match="lat" mode="m_geon-to-tei">
        <tei:location>
            <tei:geo>
                <xsl:value-of select="."/>
                <xsl:text>, </xsl:text>
                <xsl:value-of select=" following-sibling::lng"/>
            </tei:geo>
        </tei:location>
    </xsl:template>
</xsl:stylesheet>