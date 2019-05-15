<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:opf="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:bgn="http://bibliograph.net/" xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:pto="http://www.productontology.org/id/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/" xmlns:umbel="http://umbel.org/umbel#"
    xmlns:xi="http://www.w3.org/2001/XInclude" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- This stylesheet takes a TEI personography as input. It resorts the persons by names, queries VIAF for additional information (based on VIAF IDs already present in the personography), and adds normalized versions of names for each person. -->
    <!-- Note 1: It DOES NOT try to find names on VIAF without an ID -->
    <!-- Note 2: all <persName>s in the personography must have an @xml:id prior to running this stylesheet -->
    <xsl:output method="xml" encoding="UTF-8" indent="no" exclude-result-prefixes="#all" omit-xml-declaration="no"/>
    
    <xsl:include href="query-viaf.xsl"/>
    <!-- identify the author of the change by means of a @xml:id -->
    <!-- toggle debugging messages -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    
    <!-- variables for OpenArabicPE IDs -->
    <xsl:variable name="v_oape-id-count" select="count(//tei:person/tei:idno[@type='oape'])"/>
    <xsl:variable name="v_oape-id-highest" select="if($v_oape-id-count gt 0) then(max(//tei:person/tei:idno[@type='oape'])) else(0)"/>
    <!-- parameters for string-replacements -->
    <xsl:param name="p_string-match" select="'([إ|أ|آ])'"/>
    <xsl:param name="p_string-replace" select="'ا'"/>
    
    <xsl:template match="node() | @*" name="t_1">
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
                <xsl:sort select="descendant::tei:surname[1]"/>
                    <xsl:sort select="descendant::tei:forename[1]"/>
                    <xsl:sort select="descendant::tei:addName[@type='noAddName'][not(.='')][1]"/>
                    <xsl:sort select="descendant::tei:addName[@type='flattened'][1]"/>
                <xsl:sort select="tei:persName[1]"/>
                <xsl:sort select="tei:idno[@type='VIAF'][1]" order="ascending"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <!-- improve tei:person records with VIAF references -->
    <xsl:template match="tei:person[tei:persName[matches(@ref,'viaf:\d+')]] | tei:person[tei:idno[@type='VIAF']!='']" name="t_3">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_3: </xsl:text><xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="v_viaf-id">
            <xsl:choose>
                <xsl:when test="tei:idno[@type='VIAF']!=''">
                    <xsl:value-of select="tei:idno[@type='VIAF']"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace(tei:persName[matches(@ref,'viaf:\d+')][1]/@ref,'viaf:(\d+)','$1')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy>
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
                    <!-- chose whether to included bibliographic data. Default is 'false()' as this inflates the resulting file and can be retrieved on demand at a later stage -->
                    <xsl:with-param name="p_include-bibliograpy-in-output" select="false()"/>
                    <xsl:with-param name="p_search-term" select="$v_viaf-id"/>
                    <xsl:with-param name="p_input-type" select="'id'"/>
                </xsl:call-template>
            </xsl:variable>
            <!-- replicate existing data -->
            <xsl:apply-templates select="@* | node()"/>
            <!-- add missing fields -->
            <!-- VIAF ID -->
            <xsl:if test="not(tei:idno[@type='VIAF'])">
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:idno[@type='VIAF']" mode="m_documentation"/>
            </xsl:if>
            <xsl:if test="not(tei:idno[@type='wiki'])">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message><xsl:text>This person has no Wikidata ID</xsl:text></xsl:message>
                </xsl:if>
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:idno[@type='wiki']" mode="m_documentation"/>
            </xsl:if>
            <!-- our own OpenArabicPE ID -->
            <xsl:apply-templates select="." mode="m_generate-id"/>
            <!-- birth -->
            <xsl:if test="not(tei:birth)">
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:birth" mode="m_documentation"/>
            </xsl:if>
            <!-- death -->
            <xsl:if test="not(tei:death)">
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:death" mode="m_documentation"/>
            </xsl:if>
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
            <!--<xsl:for-each-group select="tei:persName" group-by=".">
                <xsl:apply-templates select="."/>
            </xsl:for-each-group>-->
            <!-- replicate all existing children -->
            <xsl:apply-templates select="node()"/>
             <!-- our own OpenArabicPE ID -->
            <xsl:apply-templates select="." mode="m_generate-id"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- mode to generate OpenArabicPE IDs -->
    <xsl:template match="tei:person" mode="m_generate-id">
        <xsl:if test="not(tei:idno[@type='oape'])">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'oape'"/>
                    <!-- basis is the highest existing ID -->
                    <!-- add preceding tei:person without OpenArabicPE ID -->
                    <xsl:value-of select="$v_oape-id-highest + count(preceding::tei:person[not(tei:idno[@type='oape'])]) + 1"/>
                </xsl:element>
            </xsl:if>
    </xsl:template>
    
    
    <xsl:template match="tei:person/tei:persName" name="t_5">
        <xsl:if test="$p_verbose=true()">
            <xsl:message>
                <xsl:text>t_5: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> copy existing persName</xsl:text>
            </xsl:message>
        </xsl:if>
            <xsl:copy>
                <xsl:apply-templates select="@* | node()"/>
            </xsl:copy>
        <!-- add flattened persName string if this is not already present  -->
        <!--<xsl:variable name="v_self">
            <xsl:value-of select="normalize-space(replace(string(),'([إ|أ|آ])','ا'))"/>
        </xsl:variable>
        <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>-->
        <xsl:variable name="v_name-flat">
            <xsl:call-template name="t_normalise-name">
                <xsl:with-param name="p_input" select="string()"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="not($v_name-flat='') and not(parent::tei:person/tei:persName[@type='flattened'] = $v_name-flat)">
            <xsl:if test="$p_verbose=true()">
                <xsl:message>
                    <xsl:text>t_5: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> create flattened persName</xsl:text>
                </xsl:message>
            </xsl:if>
            <xsl:element name="persName">
                <xsl:apply-templates select="@xml:lang"/>
                <xsl:attribute name="type" select="'flattened'"/>
                <!-- the flattened string should point back to its origin -->
                <xsl:if test="@xml:id">
                    <xsl:attribute name="corresp" select="concat('#',@xml:id)"/>
                </xsl:if>
                <!-- document change -->
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                <xsl:value-of select="$v_name-flat"/>
            </xsl:element>
        </xsl:if>
        <!-- add persName without any titles, honorary addresses etc. -->
        <!-- test if there are <addName> children -->
        <xsl:if test="tei:surname and tei:forename and (tei:addName | tei:roleName | tei:nameLink | tei:genName)">
            <xsl:if test="$p_verbose=true()">
                <xsl:message>
                    <xsl:text>t_5: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> create persName without titles</xsl:text>
                </xsl:message>
            </xsl:if>
            <xsl:variable name="v_no-addname">
                <xsl:copy>
                    <xsl:apply-templates select="@xml:lang"/>
                    <xsl:attribute name="type" select="'noAddName'"/>
                    <!-- document change -->
                    <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                    <xsl:apply-templates select="tei:surname | tei:forename" mode="m_no-ids"/>
                </xsl:copy>
            </xsl:variable>
            <xsl:choose>
                <!-- if there is already a child similar to the noAddName variant, this should not added to the output -->
                <xsl:when test="parent::node()/tei:persName = $v_no-addname">
                    <!--                    <xsl:message><xsl:value-of select="$v_no-addname"/> is already present</xsl:message>-->
                </xsl:when>
<!--                <xsl:when test="parent::node()/tei:persName[@type='flattened']=replace(normalize-space(replace($v_no-addname,'([إ|أ|آ])','ا')), '\W', '')"/>-->
                
                <xsl:otherwise>
<!--                    <xsl:message><xsl:value-of select="$v_no-addname"/> is not present</xsl:message>-->
                    <xsl:copy-of select="$v_no-addname"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- fix flattened persNames without @corresp attribute -->
    <xsl:template match="tei:persName[@type='flattened'][not(@corresp)]" name="t_6">
         <xsl:if test="$p_verbose=true()">
                    <xsl:message>
                        <xsl:text>t_6: </xsl:text><xsl:value-of select="@xml:id"/><xsl:text> no @corresp</xsl:text>
                    </xsl:message>
                </xsl:if>
        <xsl:variable name="v_self" select="."/>
        <xsl:copy>
            <!-- add @corresp -->
                <xsl:attribute name="corresp" select="concat('#',parent::tei:person/tei:persName[not(@type='flattened')][replace(normalize-space(replace(string(),$p_string-match,$p_string-replace)),'\W','')=$v_self][1]/@xml:id)"/>
                <!-- document change -->
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            <xsl:apply-templates select="@* |node() "/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="t_normalise-name">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_self" select="normalize-space(replace($p_input,$p_string-match,$p_string-replace))"/>
        <xsl:value-of select="replace($v_self, '\W', '')"/>
    </xsl:template>
    
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
    
    <!-- remove empty nodes -->
    <xsl:template match="node()[.='']"/>
    
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
        <xsl:attribute name="change" select="concat(., ' #', $p_id-change)"/>
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
</xsl:stylesheet>