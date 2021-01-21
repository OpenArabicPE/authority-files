<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:bgn="http://bibliograph.net/" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:opf="http://www.idpf.org/2007/opf" xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:umbel="http://umbel.org/umbel#"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" method="xml"
        omit-xml-declaration="no"/>
    
    <xsl:include href="functions.xsl"/>

      <!-- variables for local IDs (OpenArabicPE) -->
    <xsl:param name="p_local-authority" select="'oape'"/>
    <xsl:variable name="v_local-id-count" select="count(//tei:place/tei:idno[@type = $p_local-authority])"/>
    <xsl:variable name="v_local-id-highest"
        select="
            if ($v_local-id-count gt 0) then
                (max(//tei:place/tei:idno[@type = $p_local-authority]))
            else
                (0)"/>
    <xsl:variable name="v_sort-place-type"
        select="'&lt; region &lt; country &lt; state &lt; province &lt; district &lt; county &lt; town &lt; village &lt; quarter &lt; neighbourhood &lt; building'"/>
    <xsl:template match="@* | node()" name="t_1">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="/">
        <xsl:result-document
            href="{concat('_output/place_improved/',tokenize(base-uri(),'/')[last()])}">
            <xsl:copy>
                <xsl:apply-templates/>
            </xsl:copy>
        </xsl:result-document>
    </xsl:template>
    <xsl:template match="tei:listPlace" name="t_2">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:head"/>
            <xsl:apply-templates select="tei:place">
                <!-- this sort should use a private collation by @type from larger entities to smaller-->
                <xsl:sort
                    collation="http://saxon.sf.net/collation?rules={encode-for-uri($v_sort-place-type)}"
                    order="ascending" select="@type"/>
                <xsl:sort order="ascending" select="tei:placeName[@xml:lang = 'ar'][1]"/>
                 <xsl:sort order="ascending" select="tei:placeName[@xml:lang = 'ar-Latn-x-ijmes'][1]"/>
                <xsl:sort order="ascending" select="tei:placeName[@xml:lang = 'en'][1]"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="tei:listPlace"/>
        </xsl:copy>
    </xsl:template>
    <!-- improve tei:place records with GeoNames references -->
    <!-- tei:place[tei:placeName[matches(@ref,'geon:\d+')]] | tei:place[tei:idno[@type='geon']!=''] -->
    <xsl:template match="tei:place" name="t_3" priority="100">
        <xsl:variable name="v_geonames-search">
            <xsl:choose>
                <xsl:when test="oape:query-place(.,'id-geon', '', '') != 'NA'">
                    <xsl:value-of select="oape:query-place(.,'id-geon', '', '')"/>
                </xsl:when>
                <xsl:when test="oape:query-place(., 'name', 'en', '') != ''">
                    <xsl:value-of select="oape:query-place(., 'name', 'en', '')"/>
                </xsl:when>
                <xsl:when test="oape:query-place(., 'name', 'ar', '') != ''">
                    <xsl:value-of select="oape:query-place(., 'name', 'ar', '')"/>
                </xsl:when>
                <!-- this fallback is not necessary as the function oape:query-place returns the same -->
                <xsl:otherwise>
                    <xsl:copy-of select="tei:placeName[1]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
         <!-- ID -->
        <xsl:variable name="v_id">
            <xsl:choose>
                <xsl:when test="oape:query-place(.,'id-local', '', $p_local-authority) = 'NA'">
                    <xsl:value-of select="$v_local-id-highest + count(preceding::tei:place[not(tei:idno[@type=$p_local-authority])]) + 1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="oape:query-place(.,'id-local', '', $p_local-authority)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_xml-id" select="concat('place_',$v_id)"/>
        <!-- test if the place has a toponym -->
        <xsl:if test="$v_geonames-search = ''">
            <xsl:message terminate="yes">
                <xsl:text>The place (</xsl:text><xsl:value-of select="$v_id"/><xsl:text>)  has no placeName child.</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_3: query GeoNames for: </xsl:text><xsl:value-of select="$v_geonames-search"/>
            </xsl:message>
        </xsl:if>
        <!-- try to download the GeoNames XML file -->
        <xsl:call-template name="t_query-geonames">
            <xsl:with-param name="p_output-mode" select="'file'"/>
            <xsl:with-param name="p_input" select="$v_geonames-search"/>
            <xsl:with-param name="p_place-type" select="@type"/>
            <xsl:with-param name="p_number-of-results" select="1"/>
        </xsl:call-template>
        <!-- transform the result to TEI  -->
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
            <!-- new @xml:id  -->
            <xsl:attribute name="xml:id" select="$v_xml-id"/>
            <!-- add @type if it is missing -->
            <xsl:if test="not(@type) and $v_geonames-result-tei/descendant::tei:place[1]/@type">
                <xsl:attribute name="type"
                    select="$v_geonames-result-tei/descendant::tei:place[1]/@type"/>
            </xsl:if>
            <!-- the content model specifies that <idno> must be the last child -->
            <xsl:apply-templates select="tei:placeName"/>
            <!-- check if basic data is already present -->
            <!-- add missing fields -->
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
            <!-- location -->
            <xsl:apply-templates select="tei:location"/>
            <xsl:if test="not(tei:location)">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:location"/>
            </xsl:if>
            <xsl:apply-templates select="tei:link"/>
            <xsl:if test="not(tei:link)">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:link"/>
            </xsl:if>
            <!-- IDs -->
            <xsl:apply-templates select="tei:idno"/>
            <!-- GeoNames ID -->
            <xsl:if test="not(tei:idno[@type = 'geon'])">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:idno"/>
            </xsl:if>
            <!-- our own OpenArabicPE ID -->
            <xsl:if test="not(tei:idno[@type=$p_local-authority])">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="$p_local-authority"/>
                    <xsl:value-of select="$v_id"/>
                </xsl:element>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <!-- document the changes -->
    <xsl:template match="tei:revisionDesc" name="t_8">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Improved </xsl:text>
                <tei:gi>place</tei:gi>
                <xsl:text> nodes with GeoNames data, querying GeoNames for IDs (if already available) and toponyms, and adding alternative names, IDs, and geo-coded locations.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
