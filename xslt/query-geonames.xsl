<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="2.0" xmlns:bgn="http://bibliograph.net/"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:genont="http://www.w3.org/2006/gen/ont#"
    xmlns:opf="http://www.idpf.org/2007/opf" xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/"
    xmlns:srw="http://www.loc.gov/zing/srw/" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:umbel="http://umbel.org/umbel#" xmlns:viaf="http://viaf.org/viaf/terms#"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!-- this stylesheet  tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="yes" method="xml"
        name="xml_indented" omit-xml-declaration="no"/>
    
    <xsl:include href="convert_geonames-to-tei_functions.xsl"/>
    <xsl:include href="../data/api-credentials/api-credentials.xsl"/>
    
    <!-- this param establishes the path to the folder holding individual authority files from GeoNames. The file path is relative to this stylesheet!  -->
    <xsl:param name="p_path-authority-files" select="'../data/geonames/'"/>
    <!-- trigger debugging: paramter is loaded from OpenArabicPE_parameters.xsl included in parent stylesheet  -->
<!--    <xsl:param name="p_verbose" select="true()"/>-->
    <!-- these variables are used to establish the language of any given string -->
    <!--    <xsl:variable name="v_string-transcribe-ijmes" select="'btḥḫjdrzsṣḍṭẓʿfqklmnhāūīwy0123456789'"/>
    <xsl:variable name="v_string-transcribe-arabic" select="'بتحخجدرزسصضطظعفقكلمنهاويوي٠١٢٣٤٥٦٧٨٩'"/>-->
    <xsl:template name="t_query-geonames">
        <!-- $p_input can be <tei:placeName> nodes or GeoNames IDs -->
        <xsl:param name="p_input"/>
        <xsl:param name="p_place-type"/>
        <!-- available values are 'tei', 'file', and 'csv' -->
        <xsl:param name="p_output-mode" select="'file'"/>
        <xsl:param name="p_csv-separator" select="';'"/>
        <xsl:param name="p_number-of-results" select="1"/>
        <!-- establish whether the input is a string or an integer -->
        <xsl:variable name="v_input-data-type">
            <xsl:analyze-string regex="\d+" select="$p_input">
                <xsl:matching-substring>
                    <xsl:text>int</xsl:text>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:text>string</xsl:text>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <!-- if the input is a geonamesId or points to such an ID using the @ref attribute, one should check for a local copy of the geonames XML file -->
        <xsl:variable name="v_geonames-id">
            <xsl:choose>
                <xsl:when test="$v_input-data-type = 'int'">
                    <xsl:value-of select="$p_input"/>
                </xsl:when>
                <xsl:when test="starts-with($p_input/@ref, 'geon:')">
                    <xsl:value-of select="substring-after($p_input/@ref, 'geon:')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'NA'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>value of $v_geonames-id: </xsl:text><xsl:value-of select="$v_geonames-id"/>
            </xsl:message>
        </xsl:if>
        <!-- check tei:place/@type and do not query GeoNames if it is 'building' or 'street' and if $v_input-data-type='string' -->
        <xsl:choose>
            <xsl:when test="not($p_place-type = ('building','street','neighbourhood','quarter') and $v_input-data-type = 'string')">
                <!-- either copy local file or retrieve results from geonames.org -->
        <xsl:variable name="v_xml-geonames">
            <xsl:choose>
                <!-- 1. $v_geonames-id contains an ID and local copy of GeoNames result file is available -->
                <xsl:when
                    test="$v_geonames-id != 'NA' and doc-available(concat($p_path-authority-files, 'geon_', $v_geonames-id, '.xml'))">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>
                            <xsl:text>Found local copy for </xsl:text>
                            <xsl:value-of select="$v_geonames-id"/>
                        </xsl:message>
                    </xsl:if>
                    <xsl:copy-of
                        select="document(concat($p_path-authority-files, 'geon_', $v_geonames-id, '.xml'))"
                    />
                </xsl:when>
                <!-- otherwise query geonames -->
                <xsl:otherwise>
                    <xsl:variable name="v_api-endpoint" select="'http://api.geonames.org/'"/>
                    <xsl:variable name="v_api-query-field">
                        <xsl:choose>
                            <xsl:when test="$v_input-data-type = 'string'">
                                <xsl:value-of
                                    select="concat('search?name=',translate($p_input,$vGeoNamesIjmes,$vGeoNamesDiac),'&amp;maxRows=',$p_number-of-results)"
                                />
                            </xsl:when>
                            <xsl:when test="$v_input-data-type = 'int'">
                                <xsl:value-of select="concat('get?geonameId=', $v_geonames-id)"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="v_api-options"
                        select="concat('&amp;style=FULL&amp;lang=en&amp;username=',$v_api-geonames_key)"/>
                    <xsl:variable name="v_api-call">
                        <xsl:value-of select="$v_api-endpoint"/>
                        <xsl:value-of select="$v_api-query-field"/>
                        <xsl:value-of select="$v_api-options"/>
                    </xsl:variable>
                    <xsl:copy-of select="document($v_api-call)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- if there is no ID, there is no search result and there need not be any output -->
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>The query for </xsl:text>
                <xsl:value-of select="$p_input"/>
                <xsl:text> returned the ID: </xsl:text>
                <xsl:value-of select="$v_xml-geonames/descendant-or-self::geoname[1]/geonameId"/>
            </xsl:message>
        </xsl:if>
        <!-- generate output -->
        <xsl:choose>
            <xsl:when test="not($v_xml-geonames/descendant-or-self::totalResultsCount = 0)">
            <xsl:choose>
                <xsl:when test="$p_output-mode = 'file'">
                    <!-- this is relative to the input XML  -->
                    <!-- check if the file already exists! -->
                    <xsl:if test="doc-available(concat('_output/geonames/geon_',$v_xml-geonames/descendant-or-self::geoname[1]/geonameId,'.xml'))">
                        <xsl:result-document
                        href="_output/geonames/geon_{$v_xml-geonames/descendant-or-self::geoname[1]/geonameId}.xml">
                        <xsl:copy-of select="$v_xml-geonames"/>
                    </xsl:result-document>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$p_output-mode = 'tei'">
                    <tei:listPlace>
                        <xsl:apply-templates mode="m_geon-to-tei" select="$v_xml-geonames/descendant-or-self::geoname"/>
                    </tei:listPlace>
                </xsl:when>
                <xsl:when test="$p_output-mode = 'csv'">
                    <xsl:value-of select="$v_xml-geonames/descendant-or-self::geoname[1]/geonameId"/>
                    <xsl:value-of select="$p_csv-separator"/>
                    <xsl:value-of select="$v_xml-geonames/descendant-or-self::geoname[1]/lat"/>
                    <xsl:value-of select="$p_csv-separator"/>
                    <xsl:value-of select="$v_xml-geonames/descendant-or-self::geoname[1]/lng"/>
                    <xsl:value-of select="$p_csv-separator"/>
                </xsl:when>
            </xsl:choose>
        </xsl:when>
            <!-- return error message if no results are found -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>No results for </xsl:text><xsl:value-of select="$p_input"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
            </xsl:when>
            <!-- return message that GeoNames was not queried -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>GeoNames was not queried for </xsl:text><xsl:value-of select="$p_input"/><xsl:text> because it is a building.</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
</xsl:stylesheet>
