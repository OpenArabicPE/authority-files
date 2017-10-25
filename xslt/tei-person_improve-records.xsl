<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:html="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:opf="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:bgn="http://bibliograph.net/" xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:pto="http://www.productontology.org/id/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/" xmlns:umbel="http://umbel.org/umbel#"
    xmlns:xi="http://www.w3.org/2001/XInclude" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="2.0">
    
    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output method="xml" encoding="UTF-8" indent="yes" exclude-result-prefixes="#all" omit-xml-declaration="no"/>
    
    <xsl:include href="query-viaf.xsl"/>
    
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:param name="p_id-editor" select="'pers_TG'"/>
    <!-- toggle debugging messages -->
    <xsl:param name="p_verbose" select="false()"/>
    
    <xsl:template match="@* | node()" name="t_1">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_1: </xsl:text>
                <xsl:if test="ancestor-or-self::node()">
                    <xsl:value-of select="ancestor-or-self::node()/@xml:id"/>
                </xsl:if>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:listPerson" name="t_2">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_2: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:person">
                <!-- this sort should consider the Arabic "al-" -->
                <xsl:sort select="tei:persName[tei:surname][1]/tei:surname[1]"/>
                <xsl:sort select="tei:persName[1]"/>
                <xsl:sort select="tei:idno[@type='viaf'][1]" order="descending"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <!-- improve tei:person records with VIAF references -->
    <xsl:template match="tei:person[tei:persName[matches(@ref,'viaf:\d+')]] | tei:person[tei:idno[@type='viaf']!='']" name="t_3">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_3: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="v_viaf-id">
            <xsl:choose>
                <xsl:when test="tei:idno[@type='viaf']!=''">
                    <xsl:value-of select="tei:idno[@type='viaf']"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace(tei:persName[matches(@ref,'viaf:\d+')][1]/@ref,'viaf:(\d+)','$1')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <!--<xsl:call-template name="t_query-viaf-rdf">
                <xsl:with-param name="p_viaf-id" select="replace(tei:persName[matches(@ref,'viaf:\d+')][1]/@ref,'viaf:(\d+)','$1')"/>
            </xsl:call-template>-->
            <!-- check if basic data is already present -->
<!--            <xsl:if test="not(tei:birth and tei:death)">-->
                <!-- add missing fields -->
                <xsl:call-template name="t_query-viaf-sru">
                    <xsl:with-param name="p_output-mode" select="'tei'"/>
                    <xsl:with-param name="p_include-bibliograpy-in-output" select="false()"/>
                    <xsl:with-param name="p_search-term" select="$v_viaf-id"/>
                    <xsl:with-param name="p_input-type" select="'id'"/>
                </xsl:call-template>
                <!-- try to download the VIAF SRU file -->
                <xsl:call-template name="t_query-viaf-sru">
                    <xsl:with-param name="p_output-mode" select="'file'"/>
                    <xsl:with-param name="p_search-term" select="$v_viaf-id"/>
                    <xsl:with-param name="p_input-type" select="'id'"/>
                </xsl:call-template>
            <!--</xsl:if>-->
        </xsl:copy>
    </xsl:template>
    
    <!-- improve tei:person records without VIAF references -->
    <xsl:template match="tei:person" name="t_4">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_4: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <!-- check if basic data is already present -->
            <!--<xsl:if test="not(tei:birth and tei:death)">
                <!-\- add missing fields -\->
                <xsl:call-template name="t_query-viaf-sru">
                    <xsl:with-param name="p_output-mode" select="'tei'"/>
                    <xsl:with-param name="p_search-term" select="normalize-space(tei:persName[1])"/>
                    <xsl:with-param name="p_input-type" select="'persName'"/>
                </xsl:call-template>
                <!-\- try to download the VIAF SRU file -\->
                <xsl:call-template name="t_query-viaf-sru">
                    <xsl:with-param name="p_output-mode" select="'file'"/>
                    <xsl:with-param name="p_search-term" select="normalize-space(tei:persName[1])"/>
                    <xsl:with-param name="p_input-type" select="'persName'"/>
                </xsl:call-template>
            </xsl:if>-->
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:persName" name="t_5">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_5: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> copy existing persName</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
        <!-- add flattened persName string  -->
        <xsl:variable name="v_self">
            <xsl:value-of select="normalize-space(replace(.,'([إ|أ|آ])','ا'))"/>
        </xsl:variable>
        <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>
        <xsl:if test="not(parent::node()/tei:persName[@type='flattened'] = $v_name-flat)">
            <xsl:if test="$p_verbose=true()">
                <xsl:message>
                    <xsl:text>t_5: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> create flattened persName</xsl:text>
                </xsl:message>
            </xsl:if>
            <xsl:copy>
                <xsl:apply-templates select="@xml:lang"/>
                <xsl:attribute name="type" select="'flattened'"/>
                <!-- the flattened string should point back to its origin -->
                <xsl:attribute name="corresp" select="concat('#',@xml:id)"/>
                <xsl:value-of select="$v_name-flat"/>
                
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:persName[@type='flattened']" name="t_6">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_6: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="v_self" select="."/>
        <xsl:copy>
            <!-- check if it has a @corresp attribute -->
            <xsl:if test="not(@corresp)">
                <xsl:if test="$p_verbose=true()">
                    <xsl:message>
                        <xsl:text>t_6: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> no @corresp</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:attribute name="corresp" select="concat('#',parent::tei:person/tei:persName[replace(normalize-space(.),'\W','')=$v_self][1]/@xml:id)"/>
            </xsl:if>
            <xsl:apply-templates select="@* |node() "/>
        </xsl:copy>
    </xsl:template>
    
    <!-- decide whether or not to omit existing records -->
    <xsl:template match="tei:person/tei:idno | tei:person/tei:birth | tei:person/tei:death | tei:person/tei:listBibl" name="t_7">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_7: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
    </xsl:template>
    
    <!-- document the changes -->
    <xsl:template match="tei:revisionDesc" name="t_8">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="$p_id-editor"/>
                <xsl:text>Improved </xsl:text><tei:gi>person</tei:gi><xsl:text> nodes that had references to VIAF, by querying VIAF and adding  </xsl:text><tei:gi>birth</tei:gi><xsl:text>, </xsl:text><tei:gi>death</tei:gi><xsl:text>, and </xsl:text><tei:gi>idno</tei:gi><xsl:text>.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>