<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:bgn="http://bibliograph.net/" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:genont="http://www.w3.org/2006/gen/ont#" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:opf="http://www.idpf.org/2007/opf"
    xmlns:pto="http://www.productontology.org/id/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:umbel="http://umbel.org/umbel#" xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- This stylesheet takes a TEI personography as input. It resorts the persons by names, queries VIAF for additional information (based on VIAF IDs already present in the personography), and adds normalized versions of names for each person. -->
    <!-- Note 1: It DOES NOT try to find names on VIAF without an ID -->
    <!-- PROBLEM: 
        - nested listPerson are deleted
        - successive listPerson are deleted
    -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml" omit-xml-declaration="no"/>
    <xsl:include href="functions.xsl"/>
    <!-- variables for local IDs (OpenArabicPE) -->
    <xsl:variable name="v_local-id-count" select="count(//tei:person/tei:idno[@type = $p_local-authority])"/>
    <xsl:variable name="v_local-id-highest" select="
            if ($v_local-id-count gt 0) then
                (max(//tei:person/tei:idno[@type = $p_local-authority]))
            else
                (0)"/>
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- resort the contents of listPerson by surname, forename -->
    <xsl:template match="tei:listPerson" name="t_2">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates mode="m_identity-transform" select="tei:head"/>
            <xsl:apply-templates mode="m_improve" select="tei:person">
                <!-- this sort should consider the Arabic "al-" -->
                <xsl:sort select="descendant::tei:surname[1]"/>
                <xsl:sort select="descendant::tei:addName[@type = 'nisbah'][1]"/>
                <xsl:sort select="descendant::tei:forename[1]"/>
                <xsl:sort select="descendant::tei:addName[@type = 'noAddName'][not(. = '')][1]"/>
                <xsl:sort select="descendant::tei:addName[@type = 'flattened'][1]"/>
                <xsl:sort select="tei:persName[1]"/>
                <xsl:sort order="ascending" select="tei:idno[@type = 'VIAF'][1]"/>
            </xsl:apply-templates>
            <!-- listPerson -->
            <xsl:apply-templates select="tei:listPerson"/>
            <!-- other children? -->
            <xsl:apply-templates mode="m_identity-transform" select="node()[not(local-name() = ('head', 'person', 'listPerson'))]"/>
        </xsl:copy>
    </xsl:template>
    <!--<!-\- improve tei:person records with VIAF references -\->
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
                <!-\- try to download the VIAF SRU file -\->
                <xsl:call-template name="t_query-viaf-sru">
                    <xsl:with-param name="p_output-mode" select="'file'"/>
                    <xsl:with-param name="p_search-term" select="$v_viaf-id"/>
                    <xsl:with-param name="p_input-type" select="'id'"/>
                </xsl:call-template>
            <!-\- transform results into TEI -\->
            <xsl:variable name="v_viaf-result-tei">
                <xsl:call-template name="t_query-viaf-sru">
                    <xsl:with-param name="p_output-mode" select="'tei'"/>
                    <!-\- chose whether to included bibliographic data. Default is 'false()' as this inflates the resulting file and can be retrieved on demand at a later stage -\->
                    <xsl:with-param name="p_include-bibliograpy-in-output" select="false()"/>
                    <xsl:with-param name="p_search-term" select="$v_viaf-id"/>
                    <xsl:with-param name="p_input-type" select="'id'"/>
                </xsl:call-template>
            </xsl:variable>
            <!-\- replicate existing data -\->
            <xsl:apply-templates select="@* | node()"/>
            <!-\- add missing fields -\->
            <!-\- VIAF ID -\->
            <xsl:if test="not(tei:idno[@type='VIAF'])">
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:idno[@type='VIAF']" mode="m_documentation"/>
            </xsl:if>
            <xsl:if test="not(tei:idno[@type='wiki'])">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message><xsl:text>This person has no Wikidata ID</xsl:text></xsl:message>
                </xsl:if>
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:idno[@type='wiki']" mode="m_documentation"/>
            </xsl:if>
            <!-\- our own OpenArabicPE ID -\->
            <xsl:apply-templates select="." mode="m_generate-id"/>
            <!-\- birth -\->
            <xsl:if test="not(tei:birth)">
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:birth" mode="m_documentation"/>
            </xsl:if>
            <!-\- death -\->
            <xsl:if test="not(tei:death)">
                <xsl:apply-templates select="$v_viaf-result-tei/descendant::tei:person/tei:death" mode="m_documentation"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>-->
    <!-- improve tei:person records without VIAF references -->
    <xsl:template match="tei:person" mode="m_improve" priority="10">
        <!-- ID -->
        <xsl:variable name="v_id">
            <xsl:choose>
                <xsl:when test="oape:query-person(., 'id-local', '', $p_local-authority) = 'NA'">
                    <xsl:value-of select="$v_local-id-highest + count(preceding::tei:person[not(tei:idno[@type = $p_local-authority])]) + 1"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="oape:query-person(., 'id-local', '', $p_local-authority)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_xml-id" select="concat('person_', $v_id)"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- new @xml:id  -->
            <xsl:attribute name="xml:id" select="$v_xml-id"/>
            <!-- persName -->
            <!-- replicate all untyped persNames and remove all typed persNames -->
            <xsl:for-each-group group-by="." select="tei:persName[not(@type)]">
                <!--                <xsl:apply-templates select="."/>-->
                <xsl:variable name="v_xml-id-persName" select="concat('persName_', $v_id, '.', position())"/>
                <xsl:variable name="v_self">
                    <xsl:copy>
                        <xsl:apply-templates select="@*[not(name() = 'ref')]"/>
                        <!-- new @xml:id -->
                        <xsl:attribute name="xml:id" select="$v_xml-id-persName"/>
                        <xsl:apply-templates select="node()"/>
                    </xsl:copy>
                </xsl:variable>
                <!-- reproduce content -->
                <xsl:copy-of select="$v_self"/>
                <!-- add flattened persName string  -->
                <xsl:variable name="v_flat" select="oape:name-flattened($v_self, concat($v_xml-id-persName, '.1'), '')"/>
                <!-- prevent duplicates: 
                    - apart from single-word names there should be no untyped duplicates  of $v_flat -->
                <xsl:choose>
                    <!-- problem: as all untyped persNames are removed, this will prevent proper output -->
                    <xsl:when test="preceding-sibling::tei:persName[not(@type)][oape:name-flattened(., '', '') = $v_flat]"/>
                    <xsl:otherwise>
                        <xsl:copy-of select="$v_flat"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:variable name="v_no-addName" select="oape:name-remove-addnames($v_self, concat($v_xml-id-persName, '.2'), '')"/>
                <!-- prevent duplicates of noAddName -->
                <xsl:choose>
                    <xsl:when test="parent::tei:person/tei:persName[not(@type)] = $v_no-addName">
                        <!--<xsl:message><xsl:value-of select="concat('&quot;', $v_no-addName, '&quot; is already present')"/></xsl:message>--> </xsl:when>
                    <!-- as I am stripping out roleNames, the additional names shoule not be triggered without roleNames being present -->
                    <xsl:when test="not(descendant::tei:roleName) and not(tei:nameLink)"/>
                    <xsl:when test="$v_no-addName != ''">
                        <xsl:variable name="v_no-addName-flat" select="oape:name-flattened($v_no-addName, concat($v_xml-id-persName, '.3'), '')"/>
                        <xsl:copy-of select="$v_no-addName"/>
                        <xsl:copy-of select="$v_no-addName-flat"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each-group>
            <!-- replicate all existing children other than persName -->
            <xsl:apply-templates select="node()[not(self::tei:persName)]"/>
            <!-- add data -->
            <!-- our own ID -->
            <xsl:if test="not(tei:idno[@type = $p_local-authority])">
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="$p_local-authority"/>
                    <xsl:value-of select="$v_id"/>
                </xsl:element>
            </xsl:if>
            <!-- other IDs linked through a @ref attribute on a persName child-->
            <xsl:if test="tei:persName/@ref">
                <xsl:for-each-group group-by="." select="tei:persName/@ref/tokenize(., ' ')">
                    <xsl:if test="not(matches(current-grouping-key(), concat($p_local-authority, '|viaf')))">
                        <xsl:element name="idno">
                            <xsl:attribute name="type" select="'unknown'"/>
                            <xsl:value-of select="current-grouping-key()"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:for-each-group>
            </xsl:if>
            <!-- test for occupation -->
            <!-- note that this is extremely expensive to compute -->
            <xsl:if test="not(tei:occupation)">
                <!-- test each periodical -->
                <!-- the XPath selector assumes that all persons in the bibliography have been linked to the personography -->
                <xsl:for-each select="$v_bibliography//tei:biblStruct[@type = 'periodical'][descendant::tei:persName[contains(@ref, concat($p_local-authority, ':pers:', $v_id))]]">
                    <xsl:variable name="v_bibl" select="."/>
                    <!-- test each mentioned person -->
                    <xsl:for-each select="tei:monogr//node()[tei:persName[@ref]]/tei:persName[@ref][1]">
                        <!-- get local id -->
                        <xsl:variable name="v_id-temp" select="oape:query-personography(., $v_personography, $p_local-authority, 'id-local', '')"/>
                        <!-- if the IDs are the same, we can write a new occupation note -->
                        <xsl:if test="$v_id = $v_id-temp">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found person </xsl:text>
                                    <xsl:value-of select="$v_id"/>
                                    <xsl:text> in the bibliography. Creating a new occupation node.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:element name="occupation">
                                <xsl:attribute name="resp" select="'#xslt'"/>
                                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                                <xsl:attribute name="xml:lang" select="'en'"/>
                                <xsl:text>Editor of </xsl:text>
                                <xsl:copy-of select="oape:query-biblstruct($v_bibl, 'title-tei', 'ar', '', $p_local-authority)"/>
                            </xsl:element>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:if>
            <!-- VIAF data -->
            <xsl:if test="oape:query-person(., 'id-viaf', '', '') != 'NA'">
                <xsl:variable name="v_viaf-id" select="oape:query-person(., 'id-viaf', '', '')"/>
                <!-- debugging -->
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>Found VIAF ID: </xsl:text>
                        <xsl:value-of select="$v_viaf-id"/>
                    </xsl:message>
                </xsl:if>
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
                <xsl:variable name="v_viaf-person" select="$v_viaf-result-tei/descendant::tei:person"/>
                <!-- VIAF ID -->
                <xsl:if test="not(tei:idno[@type = 'VIAF'])">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>
                            <xsl:text>This person has no VIAF ID</xsl:text>
                        </xsl:message>
                    </xsl:if>
                    <xsl:apply-templates mode="m_documentation" select="$v_viaf-result-tei/descendant::tei:person/tei:idno[@type = 'VIAF']"/>
                    <!--                <xsl:value-of select="$v_viaf-id"/>-->
                </xsl:if>
                <!-- Wikidata ID -->
                <xsl:if test="not(tei:idno[@type = $p_acronym-wikidata])">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>
                            <xsl:text>This person has no Wikidata ID</xsl:text>
                        </xsl:message>
                    </xsl:if>
                    <xsl:apply-templates mode="m_documentation" select="$v_viaf-person/tei:idno[@type = $p_acronym-wikidata]"/>
                </xsl:if>
                <!-- birth -->
                <xsl:if test="not(tei:birth)">
                    <xsl:apply-templates mode="m_documentation" select="$v_viaf-person/tei:birth"/>
                </xsl:if>
                <!-- death -->
                <xsl:if test="not(tei:death)">
                    <xsl:apply-templates mode="m_documentation" select="$v_viaf-person/tei:death"/>
                </xsl:if>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    <!-- remove empty nodes -->
    <xsl:template match="node()[. = '']" priority="20"/>
    <!-- document the changes -->
    <xsl:template match="tei:revisionDesc">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Improved </xsl:text>
                <tei:gi>person</tei:gi>
                <xsl:text> nodes with </xsl:text>
                <tei:tag>persName type="noAddName"</tei:tag>
                <xsl:text> and </xsl:text>
                <tei:tag>persName type="flattened"</tei:tag>
                <xsl:text> children and by querying VIAF for those with VIAF IDs, adding </xsl:text>
                <tei:gi>birth</tei:gi>
                <xsl:text>, </xsl:text>
                <tei:gi>death</tei:gi>
                <xsl:text>, and </xsl:text>
                <tei:gi>idno</tei:gi>
                <xsl:text>.</xsl:text>
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
