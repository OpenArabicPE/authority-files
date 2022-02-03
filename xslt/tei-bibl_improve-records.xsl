<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:bgn="http://bibliograph.net/" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:opf="http://www.idpf.org/2007/opf" xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:umbel="http://umbel.org/umbel#" xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- this stylesheet improves local bibliographies by adding an OpenArabicPE ID to records missing such an ID. In the future, it is planned to query OCLC for more details on individual titles. -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml" omit-xml-declaration="no"/>
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    <!-- variables for OpenArabicPE IDs -->
    <xsl:variable name="v_oape-id-count" select="count(//tei:monogr/tei:idno[@type = 'oape'])"/>
    <xsl:variable name="v_oape-id-highest" select="
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
                <!-- sorting can be much improved -->
                <!-- titles -->
                <xsl:sort order="ascending" select="tei:monogr[1]/tei:title[@xml:lang = 'ar'][1]"/>
                <xsl:sort order="ascending" select="tei:monogr[1]/tei:title[1]"/>
                <!-- locations -->
                <xsl:sort order="ascending" select="tei:monogr[1]/tei:imprint/tei:pubPlace[1]/tei:placeName[@ref][1]/@ref"/>
                <xsl:sort order="ascending" select="descendant::tei:placeName[1][parent::tei:pubPlace]"/>
                <!-- dates -->
                <xsl:sort order="ascending" select="tei:monogr[1]/tei:imprint/tei:date[@type = 'onset'][1]/@when"/>
                <xsl:sort order="ascending" select="tei:monogr[1]/tei:imprint/tei:date[1]/@when"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="tei:listBibl"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblStruct">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- add @subtype based on the Jaraid ID -->
            <xsl:variable name="v_subtype">
                <xsl:variable name="v_id" select="number(replace(descendant::tei:idno[@type = 'jaraid'][1], 't\dr(\d+)$', '$1'))"/>
                <xsl:choose>
                    <xsl:when test="870 &lt;= $v_id and $v_id &lt;= 1533">
                        <xsl:text>newspaper</xsl:text>
                    </xsl:when>
                     <xsl:when test="2035 &lt;= $v_id and $v_id &lt;= 2083">
                        <xsl:text>newspaper</xsl:text>
                    </xsl:when>
                    <xsl:when test="2349 &lt;= $v_id and $v_id &lt;= 3024">
                        <xsl:text>newspaper</xsl:text>
                    </xsl:when>
                    <xsl:when test="1534  &lt;= $v_id and $v_id &lt;= 2029">
                        <xsl:text>journal</xsl:text>
                    </xsl:when>
                    <xsl:when test="2084  &lt;= $v_id and $v_id &lt;= 2097">
                        <xsl:text>journal</xsl:text>
                    </xsl:when>
                    <xsl:when test="3025 &lt;= $v_id and $v_id &lt;= 3323">
                        <xsl:text>journal</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>NA</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="$v_subtype != 'NA' and not(@subtype)">
                <xsl:attribute name="subtype" select="$v_subtype"/>
            </xsl:if>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:monogr">
        <!--<xsl:message>
            <xsl:value-of select="$v_oape-id-highest"/>
        </xsl:message>
-->
        <xsl:copy>
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
        <!--<xsl:message>
            <xsl:value-of select="$p_oape-id"/>
        </xsl:message>-->
        <xsl:element name="idno">
            <xsl:attribute name="type" select="'oape'"/>
            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
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
                <xsl:attribute name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
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
