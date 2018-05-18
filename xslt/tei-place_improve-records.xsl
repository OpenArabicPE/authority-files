<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:html="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:opf="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:bgn="http://bibliograph.net/" xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:pto="http://www.productontology.org/id/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/" xmlns:umbel="http://umbel.org/umbel#"
    xmlns:xi="http://www.w3.org/2001/XInclude" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="2.0">
    
    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute on a persName child.
    It DOES NOT try to find names on VIAF without an ID -->
    <xsl:output method="xml" encoding="UTF-8" indent="yes" exclude-result-prefixes="#all" omit-xml-declaration="no"/>
    
    <xsl:include href="query-geonames.xsl"/>
    
 
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    <!--<xsl:param name="p_id-editor" select="'pers_TG'"/>-->
    
    <xsl:variable name="v_sort-place-type" select="'&lt; region &lt; country &lt; state &lt; province &lt; district &lt; county &lt; town &lt; village &lt; quarter &lt; neighbourhood &lt; building'"/>
    
    <xsl:template match="@* | node()" name="t_1">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:listPlace" name="t_2">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_2: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:head"/>
            <xsl:apply-templates select="tei:place">
                <!-- this sort should use a private collation by @type from larger entities to smaller-->
                <xsl:sort select="@type" collation="http://saxon.sf.net/collation?rules={encode-for-uri($v_sort-place-type)}" order="ascending"/>
                <xsl:sort select="tei:placeName[@xml:lang='ar'][1]" order="ascending"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="tei:listPlace"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- improve tei:place records with GeoNames references -->
    <!-- tei:place[tei:placeName[matches(@ref,'geon:\d+')]] | tei:place[tei:idno[@type='geon']!=''] -->
    <xsl:template match="tei:place" name="t_3" priority="100">
        <xsl:variable name="v_geonames-search">
            <xsl:choose>
                <xsl:when test="tei:idno[@type='geon']!=''">
                    <xsl:value-of select="tei:idno[@type='geon']"/>
                </xsl:when>
                <xsl:when test="tei:placeName[matches(@ref,'geon:\d+')]">
                    <xsl:value-of select="replace(tei:placeName[matches(@ref,'geon:\d+')][1]/@ref,'geon:(\d+)','$1')"/>
                </xsl:when>
                <!-- check Arabic toponyms first -->
                <xsl:when test="tei:placeName[@xml:lang='ar']">
                    <xsl:copy-of select="tei:placeName[@xml:lang='ar'][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="tei:placeName[1]"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_3: query GeoNames for </xsl:text><xsl:value-of select="$v_geonames-search"/>
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
            <xsl:apply-templates select="@* | node()"/>
            <!--<xsl:call-template name="t_query-viaf-rdf">
                <xsl:with-param name="p_viaf-id" select="replace(tei:placeName[matches(@ref,'geon:\d+')][1]/@ref,'geon:(\d+)','$1')"/>
            </xsl:call-template>-->
            <!-- check if basic data is already present -->
            <!-- add missing fields -->
            <xsl:if test="not(tei:placeName[@xml:lang = 'ar'])">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'ar']"/>
            </xsl:if>
            <xsl:if test="not(tei:placeName[@xml:lang = 'en'])">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'en']"/>
            </xsl:if>
            <xsl:if test="not(tei:placeName[@xml:lang = 'fr'])">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'fr']"/>
            </xsl:if>
            <xsl:if test="not(tei:placeName[@xml:lang = 'de'])">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'de']"/>
            </xsl:if>
            <xsl:if test="not(tei:placeName[@xml:lang = 'tr'])">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:placeName[@xml:lang = 'tr']"/>
            </xsl:if>
            <xsl:if test="not(tei:location)">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:location"/>
            </xsl:if>
            <xsl:if test="not(tei:link)">
                <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:link"/>
            </xsl:if>
            <xsl:if test="not(tei:idno[@type='geon'])">
                 <xsl:copy-of select="$v_geonames-result-tei/descendant::tei:place[1]/tei:idno"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <!-- improve tei:place records without GeoNames references -->
    <xsl:template match="tei:place" name="t_4">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_4: no GeoName ID in original data for </xsl:text><xsl:value-of select="@xml:id"/><xsl:text>. Removed duplicare toponyms</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- check if it has duplicate child nodes -->
            <xsl:for-each-group select="tei:placeName" group-by=".">
                <xsl:apply-templates select="."/>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>
    
<!--    <xsl:template match="tei:placeName[@type='flattened']" priority="100"/>-->
    
   <!-- <xsl:template match="tei:placeName[ancestor::tei:settingDesc]" name="t_5">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_5: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> copy existing persName</xsl:text>
            </xsl:message>
        </xsl:if>
            <xsl:copy>
                <xsl:apply-templates select="@* | node()"/>
            </xsl:copy>
        <!-\- add flattened persName string if this is not already present  -\->
        <xsl:variable name="v_self">
            <xsl:value-of select="normalize-space(replace(.,'([إ|أ|آ])','ا'))"/>
        </xsl:variable>
        <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>
        <xsl:if test="not(parent::node()/tei:placeName[@type='flattened'] = $v_name-flat)">
            <xsl:if test="$p_verbose=true()">
                <xsl:message>
                    <xsl:text>t_5: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> create flattened persName</xsl:text>
                </xsl:message>
            </xsl:if>
            <xsl:copy>
                <xsl:apply-templates select="@xml:lang"/>
                <xsl:attribute name="type" select="'flattened'"/>
                <!-\- the flattened string should point back to its origin -\->
                <xsl:attribute name="corresp" select="concat('#',@xml:id)"/>
                <xsl:value-of select="$v_name-flat"/>
                
            </xsl:copy>
        </xsl:if>
    </xsl:template>-->
    
    <xsl:template match="tei:placeName[@type='flattened']" name="t_6">
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
                <xsl:attribute name="corresp" select="concat('#',parent::tei:place/tei:placeName[replace(normalize-space(.),'\W','')=$v_self][1]/@xml:id)"/>
            </xsl:if>
            <xsl:apply-templates select="@* |node() "/>
        </xsl:copy>
    </xsl:template>
    
    <!-- decide whether or not to omit existing records -->
    <!--<xsl:template match="tei:place/tei:idno | tei:place/tei:birth | tei:place/tei:death | tei:place/tei:listBibl" name="t_7">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_7: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
    </xsl:template>
    -->
    <!-- replicate everything except @xml:id -->
    <xsl:template match="@*[not(name() = 'xml:id')] | node()" mode="m_no-ids" name="t_10">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_10 master: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*[not(name() = 'xml:id')] | node()" mode="m_no-ids"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- document the changes -->
    <xsl:template match="tei:revisionDesc" name="t_8">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#',$p_id-editor)"/>
                <xsl:text>Improved </xsl:text><tei:gi>person</tei:gi><xsl:text> nodes that had references to VIAF, by querying VIAF and adding  </xsl:text><tei:gi>birth</tei:gi><xsl:text>, </xsl:text><tei:gi>death</tei:gi><xsl:text>, and </xsl:text><tei:gi>idno</tei:gi><xsl:text>.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>