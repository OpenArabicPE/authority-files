<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:bgn="http://bibliograph.net/" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:opf="http://www.idpf.org/2007/opf" xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:umbel="http://umbel.org/umbel#"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    
    <!-- this stylesheet improves local bibliographies by adding an OpenArabicPE ID to records missing such an ID. In the future, it is planned to query OCLC for more details on individual titles. -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml"
        omit-xml-declaration="no"/>
<!--    <xsl:include href="query-geonames.xsl"/>-->
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    <!-- variables for OpenArabicPE IDs -->
    <xsl:variable name="v_oape-id-count" select="count(//tei:monogr/tei:idno[@type = 'oape'])"/>
    <xsl:variable name="v_oape-id-highest"
        select="
            if ($v_oape-id-count gt 0) then
                (max(//tei:monogr/tei:idno[@type = 'oape']))
            else
                (0)"/>
    <!-- identity transform -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- alphabetically sort children of <listBibl> by <title> -->
    <xsl:template match="tei:listBibl" name="t_2">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_2: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:head"/>
            <xsl:apply-templates select="tei:biblStruct">
                <xsl:sort order="ascending" select="tei:monogr/tei:title[@xml:lang = 'ar'][1]"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="tei:listBibl"/>
        </xsl:copy>
    </xsl:template>
    <!-- future plans improve tei:biblStruct records with OCLC references -->
    <!-- tei:place[tei:placeName[matches(@ref,'geon:\d+')]] | tei:place[tei:idno[@type='geon']!=''] -->
    <!--<xsl:template match="tei:biblStruct" name="t_3" priority="100">
        <xsl:variable name="v_worldcat-search">
            <xsl:choose>
                <xsl:when test="tei:monogr/tei:idno[@type = 'OCLC'] != ''">
                    <xsl:value-of select="tei:monogr/tei:idno[@type = 'OCLC']"/>
                </xsl:when>
                <xsl:when test="tei:monogr/tei:title[matches(@ref, 'OCLC:\d+')]">
                    <xsl:value-of
                        select="replace(tei:monogr/tei:title[matches(@ref, 'OCLC:\d+')][1]/@ref, 'OCLC:(\d+)', '$1')"
                    />
                </xsl:when>
                <!-\- check Arabic titles first -\->
                <xsl:when test="tei:monogr/tei:title[@xml:lang = 'ar']">
                    <xsl:copy-of select="tei:placeName[@xml:lang = 'ar'][1]"/>
                </xsl:when>
                <!-\- check Arabic titles in IJMES transcription second -\->
                <xsl:when test="tei:monogr/tei:title[@xml:lang = 'ar-Latn-x-ijmes']">
                    <xsl:copy-of select="tei:monogr/tei:title[@xml:lang = 'ar-Latn-x-ijmes'][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="tei:monogr/tei:title[1]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_3: query GeoNames for </xsl:text>
                <xsl:value-of select="$v_worldcat-search"/>
            </xsl:message>
        </xsl:if>
        <!-\- try to download the GeoNames XML file -\->
        <xsl:call-template name="t_query-geonames">
            <xsl:with-param name="p_output-mode" select="'file'"/>
            <xsl:with-param name="p_input" select="$v_geonames-search"/>
            <xsl:with-param name="p_place-type" select="@type"/>
            <xsl:with-param name="p_number-of-results" select="1"/>
        </xsl:call-template>
        <!-\- transform the result to TEI  -\->
        <xsl:variable name="v_geonames-result-tei">
            <xsl:call-template name="t_query-geonames">
                <xsl:with-param name="p_output-mode" select="'tei'"/>
                <xsl:with-param name="p_input" select="$v_geonames-search"/>
                <xsl:with-param name="p_place-type" select="@type"/>
                <xsl:with-param name="p_number-of-results" select="1"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-\- add @type if it is missing -\->
            <xsl:if test="not(@type) and $v_geonames-result-tei/descendant::tei:place[1]/@type">
                <xsl:attribute name="type"
                    select="$v_geonames-result-tei/descendant::tei:place[1]/@type"/>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
            <!-\-<xsl:call-template name="t_query-viaf-rdf">
                <xsl:with-param name="p_viaf-id" select="replace(tei:placeName[matches(@ref,'geon:\d+')][1]/@ref,'geon:(\d+)','$1')"/>
            </xsl:call-template>-\->
            <!-\- check if basic data is already present -\->
            <!-\- add missing fields -\->
            <xsl:if test="not(tei:placeName[@xml:lang = 'ar'])">
                <xsl:copy-of
                    select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'ar']"
                />
            </xsl:if>
            <xsl:if test="not(tei:placeName[@xml:lang = 'en'])">
                <xsl:copy-of
                    select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'en']"
                />
            </xsl:if>
            <xsl:if test="not(tei:placeName[@xml:lang = 'fr'])">
                <xsl:copy-of
                    select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'fr']"
                />
            </xsl:if>
            <xsl:if test="not(tei:placeName[@xml:lang = 'de'])">
                <xsl:copy-of
                    select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'de']"
                />
            </xsl:if>
            <xsl:if test="not(tei:placeName[@xml:lang = 'tr'])">
                <xsl:copy-of
                    select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'tr']"
                />
            </xsl:if>
            <xsl:if test="not(tei:location)">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:location"/>
            </xsl:if>
            <xsl:if test="not(tei:link)">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:link"/>
            </xsl:if>
            <!-\- GeoNames ID -\->
            <xsl:if test="not(tei:idno[@type = 'geon'])">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:idno"/>
            </xsl:if>
            <!-\- our own OpenArabicPE ID -\->
            <xsl:apply-templates mode="m_generate-id" select="."/>
        </xsl:copy>
    </xsl:template>-->
    <xsl:template match="tei:monogr">
        <!--<xsl:message>
            <xsl:value-of select="$v_oape-id-highest"/>
        </xsl:message>
-->        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:title"/>
            <!-- check for <idno> -->
            <xsl:choose>
                <xsl:when test="tei:idno">
                    <xsl:apply-templates select="tei:idno"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="t_generate-oape-id"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="child::node()[not(self::tei:title | self::tei:idno)]"/>
        </xsl:copy>
    </xsl:template>
    <!-- mode to generate OpenArabicPE IDs -->
    <xsl:template match="tei:monogr/tei:idno">
        <!-- for the first idno child check if the parent has an OpenArabicPE ID. If not, generate one -->
        <xsl:if test="not(preceding-sibling::tei:idno) and not(parent::tei:monogr/tei:idno[@type = 'oape'])">
            <xsl:call-template name="t_generate-oape-id"/>
        </xsl:if>
        <!-- reproduce content -->
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="t_generate-oape-id">
        <xsl:param name="p_oape-id" select="$v_oape-id-highest + count(preceding::tei:monogr[not(tei:idno[@type = 'oape'])]) + 1"/>
        <xsl:message>
            <xsl:value-of select="$p_oape-id"/>
        </xsl:message>
        <xsl:element name="idno">
                <xsl:attribute name="type" select="'oape'"/>
                <xsl:attribute name="change" select="concat('#',$p_id-change)"/>
                <!-- basis is the highest existing ID -->
                <!-- add preceding tei:place without OpenArabicPE ID -->
                <xsl:value-of select="$p_oape-id"/>
            </xsl:element>
    </xsl:template>
    
    <!-- document the changes -->
    <xsl:template match="tei:revisionDesc" name="t_8">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:text>Improved </xsl:text>
                <tei:gi>biblStruct</tei:gi>
                <xsl:text> nodes by adding a private ID scheme with </xsl:text>
                <tei:tag>idno type="oape"</tei:tag>
                <xsl:text>.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
