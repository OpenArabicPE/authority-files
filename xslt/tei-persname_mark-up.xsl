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
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="2.0">
    
    <!-- PROBLEM: in some instance this stylesheet produces empty <persName> nodes in the source file upon adding VIAF references to them -->

    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no" name="xml"
        exclude-result-prefixes="#all"/>
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"
        name="xml_indented" exclude-result-prefixes="#all"/>

    <xsl:include href="query-viaf.xsl"/>
    
    <!-- p_id-editor references the @xml:id of a responsible editor to be used for documentation of changes -->
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>

    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master" select="'../data/tei/personography_OpenArabicPE.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>

    <!-- parameter to select whether the source file should be updated  -->
    <xsl:param name="p_update-source" select="true()"/>

    <xsl:variable name="v_id-file"
        select="
            if (tei:TEI/@xml:id) then
                (tei:TEI/@xml:id)
            else
                ('_output')"/>
    <xsl:variable name="v_url-file"
        select="concat('../../', substring-after(base-uri(), 'OpenArabicPE/'))"/>


    <!-- This template replicates everything -->
    <xsl:template match="node() | @*" mode="m_replicate" name="t_1">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_1: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="node() | @*" mode="m_mark-up-source" name="t_2">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_2: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_mark-up-source"/>
        </xsl:copy>
    </xsl:template>
    <!-- replicate everything except @xml:id -->
    <xsl:template match="node() | @*[not(name() = 'xml:id')]" mode="m_no-ids" name="t_10">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_10 master: </xsl:text>
                <xsl:value-of select="."/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*[not(name() = 'xml:id')] | node()" mode="m_no-ids"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id" mode="m_no-ids"/>
    <xsl:template match="text()" mode="m_no-ids">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <!-- run on root -->
    <xsl:template match="/" name="t_3">
        <!-- updated the source files with data from the authority file -->
            <xsl:if test="$p_verbose = true()">
                <xsl:message>
                    <xsl:text>t_3 source: add mark-up</xsl:text>
                </xsl:message>
            </xsl:if>
            <xsl:copy>
                <xsl:apply-templates mode="m_mark-up-source"/>
            </xsl:copy>
    </xsl:template>

    <!-- variable to collect all persNames found in file this transformation is run on in a list containing tei:person with tei:persName and tei:idno children -->
    <xsl:variable name="v_persons-source">
        <xsl:element name="tei:listPerson">
            <xsl:for-each-group
                select="tei:TEI/tei:text/descendant::tei:persName[not(tei:persName)]" group-by="normalize-space(.)">
                <xsl:sort select="tei:surname[1]"/>
                <xsl:sort select="tei:forename[1]"/>
                <xsl:sort select="current-grouping-key()"/>
                <!-- some variables -->
                <xsl:variable name="v_self">
                    <xsl:value-of select="normalize-space(replace(.,'([إ|أ|آ])','ا'))"/>
                </xsl:variable>
                <xsl:variable name="v_viaf-id"
                    select="replace(tokenize(@ref, ' ')[matches(., 'viaf:\d+')][1], 'viaf:(\d+)', '$1')"/>
                <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>
                <!-- construct nodes -->
                <xsl:element name="tei:person">
                    <!-- copy the persName -->
                    <xsl:copy>
                        <xsl:apply-templates select="@* | node()" mode="m_no-ids"/>
                    </xsl:copy>
                    <!-- construct a flattened string -->
                    <xsl:element name="tei:persName">
                        <xsl:attribute name="type" select="'flattened'"/>
                        <xsl:value-of select="$v_name-flat"/>
                    </xsl:element>
                    <!-- construct name without titles, honorary addresses etc. -->
                    <xsl:if test="child::tei:addName | child::tei:roleName">
                        <xsl:element name="tei:persName">
                            <xsl:attribute name="type" select="'noAddName'"/>
                            <xsl:apply-templates select="child::node()[not(self::tei:addName)][not(self::tei:roleName)]" mode="m_no-ids"/>
                        </xsl:element>
                    </xsl:if>
                    <!-- construct the idno child -->
                    <xsl:if test="./@ref">
                        <!-- <xsl:variable name="v_viaf-id" select="replace(tokenize(@ref,' ')[matches(.,'viaf:\d+')][1],'viaf:(\d+)','$1')"/>-->
                        <xsl:element name="tei:idno">
                            <xsl:attribute name="type" select="'viaf'"/>
                            <xsl:value-of select="$v_viaf-id"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:element>
    </xsl:variable>

    <!-- mode m_mark-up-source will at some point provide automatic addition of information from $v_file-entities-master to a TEI file  -->
    <xsl:template match="tei:persName" mode="m_mark-up-source" name="t_4">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_4 source: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <!-- normalize the spelling of the name in question -->
        <xsl:variable name="v_self" select="normalize-space(replace(.,'([إ|أ|آ])','ا'))"/>
        <!-- version of the persName without non-word characters -->
        <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>
        <!-- check if the persName carries a VIAF ID and extract it -->
        <xsl:variable name="v_viaf-id"
            select="replace(tokenize(@ref, ' ')[matches(., 'viaf:\d+')][1], 'viaf:(\d+)', '$1')"/>
        
        <!-- check if a reference to VIAF can be provided based on the master file -->
        <xsl:choose>
            <!-- 1. test if a name has a @ref attribute pointing to VIAF and an entry for the VIAF ID is already present in the master file. In this case nothing should be changed apart from adding mark-up to the components of persName -->
            <xsl:when
                test="$v_viaf-id and $v_file-entities-master//tei:person[tei:idno[@type = 'viaf'] = $v_viaf-id]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_4 source #1: VIAF ID for </xsl:text>
                        <xsl:value-of select="$v_self"/>
                        <xsl:text> is present in master file</xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- attempt to supply mark-up of the name's components based on the master file -->
                <xsl:copy>
                    <!-- replicate attributes -->
                    <xsl:apply-templates select="@*" mode="m_replicate"/>
                    <xsl:choose>
                        <!-- test if the persName already has children. If not try to add some based on the persName without non-word characters and the authority file -->
                        <xsl:when test="not(child::node()[namespace::tei])">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>t_4 source #3: </xsl:text>
                                    <xsl:value-of select="$v_self"/>
                                    <xsl:text> contains no mark-up and will be updated.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <!-- get @corresp of corresponding flat persName in the master file -->
                            <xsl:variable name="v_corresp-xml-id"
                                select="substring-after($v_file-entities-master//tei:persName[@type = 'flattened'][. = $v_name-flat]/@corresp, '#')"/>
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>t_4 source #5: the xml:id of the corresponding persName in $v_file-entities-master is </xsl:text>
                                    <xsl:value-of select="$v_corresp-xml-id"/>
                                </xsl:message>
                            </xsl:if>
                            <!-- document change -->
                    <xsl:choose>
                        <xsl:when test="not(@change)">
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="m_documentation" select="@change"/>
                        </xsl:otherwise>
                    </xsl:choose>
                            <xsl:apply-templates
                                select="$v_file-entities-master//tei:persName[@xml:id = $v_corresp-xml-id]/node()"
                                mode="m_no-ids"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="node()" mode="m_replicate"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:copy>
            </xsl:when>
            <!-- 2. test if the text string is present in the master file. If so, mark-up and pointers can be supplied by the master file -->
            <xsl:when
                test="$v_file-entities-master//tei:person[tei:idno[@type = 'viaf']][tei:persName[@type = 'flattened'] = $v_name-flat]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_4 source #2: </xsl:text>
                        <xsl:value-of select="$v_self"/>
                        <xsl:text> is present in master file but has no VIAF ID and was updated</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="m_replicate"/>
                    <xsl:attribute name="ref"
                        select="concat('viaf:', $v_file-entities-master//tei:person[tei:persName[@type = 'flattened'] = $v_name-flat]/tei:idno[@type = 'viaf'])"/>
                    <!-- document change -->
                    <xsl:choose>
                        <xsl:when test="not(@change)">
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="m_documentation" select="@change"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- it would also be possible to supply mark-up of the name's components based on the master file -->
                    <xsl:choose>
                        <xsl:when test="not(child::node()[namespace::tei])">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>t_4 source #4: </xsl:text>
                                    <xsl:value-of select="$v_self"/>
                                    <xsl:text> contains no mark-up and was updated.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <!-- get @corresp of corresponding flat persName in the master file -->
                            <xsl:variable name="v_corresp-xml-id"
                                select="substring-after($v_file-entities-master//tei:persName[@type = 'flattened'][. = $v_name-flat]/@corresp, '#')"/>
                            <xsl:apply-templates
                                select="$v_file-entities-master//tei:persName[@xml:id = $v_corresp-xml-id]/node()"
                                mode="m_no-ids"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="node()" mode="m_replicate"/>
                        </xsl:otherwise>
                    </xsl:choose>
<!--                    <xsl:apply-templates select="node()" mode="m_replicate"/>-->
                </xsl:copy>
            </xsl:when>
            <!-- test if a name has a @ref attribute pointing to VIAF  -->
            <!--<xsl:when test="$v_viaf-id">
                    <xsl:if test="$p_verbose=true()">
                        <xsl:message><xsl:text>t_4 source #3:</xsl:text><xsl:value-of select="$v_self"/><xsl:text> has a VIAF ID but is not present in master file</xsl:text></xsl:message>
                    </xsl:if>
                    <xsl:copy>
                        <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
                    </xsl:copy>
                </xsl:when>-->
            <!-- name has no reference to VIAF and is not present in the master file -->
            <xsl:otherwise>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_4 source #4: </xsl:text>
                        <xsl:value-of select="$v_self"/>
                        <xsl:message> not found in master file.</xsl:message>
                    </xsl:message>
                </xsl:if>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
   

   
    <!-- document the changes to source file -->
    <xsl:template match="tei:revisionDesc" mode="m_mark-up-source" name="t_9">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_9 source: document changes</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_replicate"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Added references to VIAF IDs to </xsl:text><tei:gi>persName</tei:gi><xsl:text>s without such references based on  </xsl:text><tei:gi>person</tei:gi><xsl:text>s mentioned in </xsl:text><tei:ref target="{$p_url-master}"><xsl:value-of select="$p_url-master"/></tei:ref><xsl:text> but not previously present in this master file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()" mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
    <!-- document changes on changed elements by means of the @change attribute linking to the @xml:id of the <tei:change> element -->
    <xsl:template match="@change" mode="m_documentation">
        <xsl:attribute name="change">
            <xsl:value-of select="concat(., ' #', $p_id-change)"/>
        </xsl:attribute>
    </xsl:template>
</xsl:stylesheet>
