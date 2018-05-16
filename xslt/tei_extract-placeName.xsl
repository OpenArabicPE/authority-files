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
    
    <!-- PROBLEM: in some instance this stylesheet produces empty <persName> nodes in the source file upon adding GeoNames references to them -->

    <!-- this stylesheet extracts all <placeName> elements from a TEI XML file and groups them into a <listPlace> element.  -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no" name="xml"
        exclude-result-prefixes="#all"/>
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"
        name="xml_indented" exclude-result-prefixes="#all"/>

    <xsl:include href="query-geonames.xsl"/>
    
    <!-- p_id-editor references the @xml:id of a responsible editor to be used for documentation of changes -->
    <!-- identify the author of the change by means of a @xml:id -->
        <xsl:param name="p_id-editor" select="'pers_TG'"/>
    <xsl:param name="p_id-change" select="'testId'"/>
<!--    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>-->

    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master"
        select="'../data/tei/gazetteer_levant-phd.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>

    <!-- parameter to select whether the master file should be updated  -->
    <xsl:param name="p_update-master" select="true()"/>
    <!-- parameter to select whether the source file should be updated  -->
    <xsl:param name="p_update-source" select="true()"/>
    <!-- toggle debugging messages: this is toggled through the parameter file -->
<!--    <xsl:param name="p_verbose" select="false()"/>-->

    

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
        <xsl:if test="$p_update-source = true()">
            <xsl:if test="$p_verbose = true()">
                <xsl:message>
                    <xsl:text>t_3 source: add mark-up</xsl:text>
                </xsl:message>
            </xsl:if>
            <xsl:copy>
                <xsl:apply-templates mode="m_mark-up-source"/>
            </xsl:copy>
        </xsl:if>
        <xsl:if test="$p_update-master = true()">
            <xsl:if test="$p_verbose = true()">
                <xsl:message>
                    <xsl:text>t_3 master: update entities</xsl:text>
                </xsl:message>
            </xsl:if>
            <xsl:result-document href="../tei/{$v_id-file}/gazetteer.TEIP5.xml"
                format="xml_indented">
                <xsl:apply-templates select="$v_file-entities-master" mode="m_replicate"/>
            </xsl:result-document>
        </xsl:if>
    </xsl:template>

    <!-- variable to collect all persNames found in file this transformation is run on in a list containing tei:place with tei:placeName and tei:idno children -->
    <xsl:variable name="v_places-source">
        <xsl:element name="tei:list">
            <xsl:for-each-group
                select="tei:TEI/tei:text/descendant::tei:placeName" group-by="normalize-space(.)">
                <xsl:sort select="current-grouping-key()"/>
                <!-- some variables -->
                <xsl:variable name="v_self">
                    <xsl:value-of select="normalize-space(replace(.,'([إ|أ|آ])','ا'))"/>
                </xsl:variable>
                <xsl:variable name="v_geonames-id"
                    select="replace(tokenize(@ref, ' ')[matches(., 'geon:\d+')][1], 'geon:(\d+)', '$1')"/>
                <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>
                <!-- construct nodes -->
                <xsl:element name="tei:place">
                    <xsl:copy>
                        <xsl:apply-templates select="@* | node()" mode="m_no-ids"/>
                    </xsl:copy>
                    <!-- construct a flattened string -->
                    <!--<xsl:element name="tei:placeName">
                        <xsl:attribute name="type" select="'flattened'"/>
                        <xsl:value-of select="$v_name-flat"/>
                    </xsl:element>-->
                    <!-- construct the idno child -->
                    <xsl:if test="./@ref">
                        <xsl:element name="tei:idno">
                            <xsl:attribute name="type" select="'geon'"/>
                            <xsl:value-of select="$v_geonames-id"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:element>
    </xsl:variable>

    <!-- mode m_mark-up-source will at some point provide automatic addition of information from $v_file-entities-master to a TEI file  -->
    <xsl:template match="tei:placeName" mode="m_mark-up-source" name="t_4">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_4 source: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="v_self">
            <xsl:value-of select="normalize-space(replace(.,'([إ|أ|آ])','ا'))"/>
        </xsl:variable>
        <xsl:variable name="v_geonames-id"
            select="replace(tokenize(@ref, ' ')[matches(., 'geon:\d+')][1], 'geon:(\d+)', '$1')"/>
        <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>
        <!-- check if a reference to GeoNames can be provided based on the master file -->
        <xsl:choose>
            <!-- 1. test if a name has a @ref attribute pointing to GeoNames and an entry for the GeoNames ID is already present in the master file. In this case nothing should be changed apart from adding mark-up to the components of persName -->
            <xsl:when
                test="$v_geonames-id and $v_file-entities-master//tei:place[tei:idno[@type = 'geon'] = $v_geonames-id]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_4 source #1: GeoNames ID for </xsl:text>
                        <xsl:value-of select="$v_self"/>
                        <xsl:text> is present in master file</xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- attempt to supply mark-up of the name's components based on the master file -->
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="m_replicate"/>
                    <xsl:apply-templates select="node()" mode="m_replicate"/>
                </xsl:copy>
            </xsl:when>
            <!-- 2. test if the text string is present in the master file. If so, mark-up and pointers can be supplied by the master file -->
            <xsl:when
                test="$v_file-entities-master//tei:place[tei:idno[@type = 'geon']!=''][tei:placeName = $v_self]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_4 source #2: </xsl:text>
                        <xsl:value-of select="$v_self"/>
                        <xsl:text> is present in master file but has no GeoNames ID and was updated</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:copy>
                    <xsl:apply-templates select="@*" mode="m_replicate"/>
                    <xsl:attribute name="ref"
                        select="concat('geon:', $v_file-entities-master//tei:place[tei:idno[@type = 'geon']!=''][tei:placeName = $v_self]/tei:idno[@type = 'geon'])"/>
                    <!-- document change -->
                    <xsl:choose>
                        <xsl:when test="not(@change)">
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="m_documentation" select="@change"/>
                        </xsl:otherwise>
                    </xsl:choose>
                            <xsl:apply-templates select="node()" mode="m_replicate"/>
                </xsl:copy>
            </xsl:when>
            <!-- test if a name has a @ref attribute pointing to GeoNames  -->
            <!--<xsl:when test="$v_viaf-id">
                    <xsl:if test="$p_verbose=true()">
                        <xsl:message><xsl:text>t_4 source #3:</xsl:text><xsl:value-of select="$v_self"/><xsl:text> has a GeoNames ID but is not present in master file</xsl:text></xsl:message>
                    </xsl:if>
                    <xsl:copy>
                        <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
                    </xsl:copy>
                </xsl:when>-->
            <!-- name has no reference to GeoNames and is not present in the master file -->
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

    <!-- ammend master file with entities found in the current TEI file -->
    <xsl:template match="tei:settingDesc" mode="m_replicate" name="t_5">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_5 master: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
            <!-- build a listPlace with places present in the source file but missing from the master -->
            <xsl:element name="tei:listPlace">
                <xsl:attribute name="corresp" select="$v_url-file"/>
                <xsl:apply-templates select="$v_places-source/descendant-or-self::tei:place"
                    mode="m_settingDesc"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <!-- m_settingDesc is exclusively run on a tei:place children of a variable that contain tei:placeName and tei:idno children.
    This generates only new entries -->
    <xsl:template match="tei:place" mode="m_settingDesc" name="t_6">
        <xsl:variable name="v_name" select="tei:placeName"/>
        <xsl:variable name="v_geonames-id" select="tei:idno[@type = 'geon']"/>
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_6 master: </xsl:text>
                <xsl:value-of select="$v_name"/>
            </xsl:message>
        </xsl:if>
<!--        <xsl:variable name="v_name-flat" select="tei:placeName[@type = 'flattened']"/>-->
        <!-- generate new tei:place elements for all names not in the master file -->
        <xsl:choose>
            <!-- test if a name has a @ref attribute pointing to GeoNames and an entry for the GeoNames ID is already present in the master file -->
            <xsl:when
                test="tei:idno[@type = 'geon'] and $v_file-entities-master//tei:place[tei:idno[@type = 'geon'] = $v_geonames-id]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_6 master #1: </xsl:text><xsl:value-of select="$v_name"/><xsl:text> has a GeoNames ID that is already present in the master file.</xsl:text>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <!-- test if the text string is present in the master file: it would be necessary to normalise the content of placeName in some way -->
            <xsl:when
                test="$v_file-entities-master//tei:place[tei:placeName = $v_name]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_6 master #2: </xsl:text><xsl:value-of select="$v_name"/><xsl:text> is present in the master file.</xsl:text>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <!-- name is not present in the master file and should be copied as is -->
            <xsl:otherwise>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_6 master #3: </xsl:text>
                        <xsl:value-of select="$v_name"/>
                        <xsl:message> was added to the master file.</xsl:message>
                    </xsl:message>
                </xsl:if>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- existing tei:place in the master file should updated with new information if available -->
    <xsl:template match="tei:place" mode="m_replicate" name="t_7">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_7 master: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="v_name" select="tei:placeName"/>
<!--        <xsl:variable name="v_name-flat" select="tei:placeName[@type = 'flattened']"/>-->
        <xsl:copy>
            <!-- update or  replicate tei:place elements in the master file -->
            <xsl:choose>
                <!-- test if a person has no GeoNames ID and if a person with the same name is present in $v_places-source with GeoNames ID -->
                <xsl:when
                    test="not(tei:idno[@type = 'geon']) and $v_places-source/descendant-or-self::tei:place[tei:placeName = $v_name][tei:idno[@type = 'geon']]">
                   <xsl:if test="$p_verbose = true()">
                       <xsl:message>
                           <xsl:text>master #1: GeoNames ID was added from source to </xsl:text>
                           <xsl:value-of select="tei:placeName[1]"/>
                       </xsl:message>
                   </xsl:if>
                    <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
                    <!-- add idno -->
                    <xsl:copy-of
                        select="$v_places-source/descendant-or-self::tei:place[tei:placeName = $v_name]/tei:idno[@type = 'geon']"
                    />
                </xsl:when>
                <!-- potentially test if there is an additional spelling in $v_places-source not precent in the entity master -->
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <!--<xsl:template match="tei:placeName/text() | tei:surname/text() | tei:forename/text() | tei:addName/text()" mode="m_replicate">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>-->
    <!-- omit xml:id from output -->
    <xsl:template
        match="tei:list//tei:placeName/@xml:id | tei:list//tei:surname/@xml:id | tei:list//tei:forename/@xml:id | tei:list//tei:addName/@xml:id"
        mode="m_replicate"/>
    <!--<xsl:template match="tei:placeName//tei:pb | tei:placeName//tei:lb | tei:placeName//tei:note"
        mode="m_replicate">
        <xsl:text> </xsl:text>
    </xsl:template>-->

    <!-- document the changes to master file -->
    <xsl:template match="tei:revisionDesc" mode="m_replicate" name="t_8">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_8 master: document changes</xsl:text>
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
                <xsl:text>Added </xsl:text><tei:gi>listPlace</tei:gi><xsl:text> with </xsl:text><tei:gi>place</tei:gi><xsl:text>s mentioned in </xsl:text><tei:ref target="{$v_url-file}"><xsl:value-of select="$v_url-file"/></tei:ref><xsl:text> but not previously present in this master file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()" mode="m_replicate"/>
        </xsl:copy>
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
                <xsl:text>Added references to GeoNames IDs to </xsl:text><tei:gi>placeName</tei:gi><xsl:text>s without such references based on  </xsl:text><tei:gi>place</tei:gi><xsl:text>s mentioned in </xsl:text><tei:ref target="{$p_url-master}"><xsl:value-of select="$p_url-master"/></tei:ref><xsl:text> but not previously present in this master file.</xsl:text>
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
