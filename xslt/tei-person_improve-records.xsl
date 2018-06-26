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
    
    <xsl:include href="query-viaf.xsl"/>
    <!-- identify the author of the change by means of a @xml:id -->
    <!-- toggle debugging messages -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    
    <xsl:template match="node() | @*" name="t_1">
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
            <!--<xsl:call-template name="t_query-viaf-rdf">
                <xsl:with-param name="p_viaf-id" select="replace(tei:persName[matches(@ref,'viaf:\d+')][1]/@ref,'viaf:(\d+)','$1')"/>
            </xsl:call-template>-->
                <!-- try to download the VIAF SRU file -->
                <xsl:call-template name="t_query-viaf-sru">
                    <xsl:with-param name="p_output-mode" select="'file'"/>
                    <xsl:with-param name="p_search-term" select="$v_viaf-id"/>
                    <xsl:with-param name="p_input-type" select="'id'"/>
                </xsl:call-template>
            <!-- transform results into TEI -->
            <xsl:variable name="v_viaf-result-tei">
                <xsl:call-template name="t_query-viaf-sru">
                    <xsl:with-param name="p_output-mode" select="'tei'"/>
                    <xsl:with-param name="p_include-bibliograpy-in-output" select="false()"/>
                    <xsl:with-param name="p_search-term" select="$v_viaf-id"/>
                    <xsl:with-param name="p_input-type" select="'id'"/>
                </xsl:call-template>
            </xsl:variable>
            <!-- replicate existing fields -->
            <xsl:apply-templates select="@* | node()"/>
            <!-- add missing fields -->
            <xsl:if test="not(tei:idno[@type='viaf'])">
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:idno[@type='viaf']" mode="m_documentation"/>
            </xsl:if>
            <xsl:if test="not(tei:birth)">
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:birth" mode="m_documentation"/>
            </xsl:if>
            <xsl:if test="not(tei:death)">
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:death" mode="m_documentation"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node()" mode="m_documentation">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="not(@change)">
                    <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="m_documentation" select="@change"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates/>
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
            <xsl:apply-templates select="@*"/>
            <!-- check if it has duplicate child nodes -->
            <xsl:for-each-group select="tei:persName" group-by=".">
                <xsl:apply-templates select="."/>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>
    
<!--    <xsl:template match="tei:persName[@type='flattened']" priority="100"/>-->
    
    <xsl:template match="tei:persName" name="t_5">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_5: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> copy existing persName</xsl:text>
            </xsl:message>
        </xsl:if>
            <xsl:copy>
                <xsl:apply-templates select="@* | node()"/>
            </xsl:copy>
        <!-- add flattened persName string if this is not already present  -->
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
        <!-- add persName without any titles, honorary addresses etc. -->
        <xsl:if test="child::tei:addName">
            <xsl:if test="$p_verbose=true()">
                <xsl:message>
                    <xsl:text>t_5: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> create persName without titles</xsl:text>
                </xsl:message>
            </xsl:if>
            <xsl:variable name="v_no-addname">
                <xsl:copy>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:attribute name="type" select="'noAddName'"/>
                    <xsl:apply-templates select="child::node()[not(self::tei:addName)]" mode="m_no-ids"/>
                </xsl:copy>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="parent::node()/tei:persName[@type='flattened']=replace(normalize-space(replace($v_no-addname,'([إ|أ|آ])','ا')), '\W', '')">
<!--                    <xsl:message><xsl:value-of select="$v_no-addname"/> is already present</xsl:message>-->
                </xsl:when>
                <xsl:otherwise>
<!--                    <xsl:message><xsl:value-of select="$v_no-addname"/> is not present</xsl:message>-->
                    <xsl:copy-of select="$v_no-addname"/>
                </xsl:otherwise>
            </xsl:choose>
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
    <!--<xsl:template match="tei:person/tei:idno | tei:person/tei:birth | tei:person/tei:death | tei:person/tei:listBibl" name="t_7">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_7: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
    </xsl:template>-->
    
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
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Improved </xsl:text><tei:gi>person</tei:gi><xsl:text> nodes that had references to VIAF, by querying VIAF and adding  </xsl:text><tei:gi>birth</tei:gi><xsl:text>, </xsl:text><tei:gi>death</tei:gi><xsl:text>, and </xsl:text><tei:gi>idno</tei:gi><xsl:text>.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- document changes on changed elements by means of the @change attribute linking to the @xml:id of the <tei:change> element -->
    <xsl:template match="@change" mode="m_documentation">
        <xsl:attribute name="change">
            <xsl:value-of select="concat(., ' #', $p_id-change)"/>
        </xsl:attribute>
    </xsl:template>
</xsl:stylesheet>