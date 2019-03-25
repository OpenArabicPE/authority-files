<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet  
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
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
    
    <!-- PROBLEM: in some instance this stylesheet produces empty <placeName> nodes in the source file upon adding GeoNames references to them -->
    
    <!-- this stylesheet queries an external authority files for every <placeName> and attempts to provide links via the @ref attribute -->
    <!-- The now unnecessary code to updated the master file needs to be removed -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no"
        exclude-result-prefixes="#all"/>
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes" name="xml_indented" exclude-result-prefixes="#all"/>

    <xsl:include href="query-geonames.xsl"/>


    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master"
        select="'../data/tei/gazetteer_levant-phd.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>

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
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- replicate everything except @xml:id and @xml:change -->
    <xsl:template match="node() | @*" mode="m_copy-from-authority-file" name="t_10">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_10 master: </xsl:text>
                <xsl:value-of select="."/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates mode="m_copy-from-authority-file" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_copy-from-authority-file" priority="100"/>

    <!-- variable to collect all placeName found in file this transformation is run on in a list containing tei:place with tei:placeName and tei:idno children -->
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
    
    <xsl:function name="oape:get-place-from-authority-file">
        <xsl:param name="p_idno"/>
        <xsl:variable name="v_authority">
            <xsl:choose>
                <xsl:when test="contains($p_idno, 'oape:place:')">
                    <xsl:text>oape</xsl:text>
                </xsl:when>
                <xsl:when test="contains($p_idno, 'geon:')">
                    <xsl:text>geon</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_idno">
            <xsl:choose>
                <xsl:when test="contains($p_idno, 'oape:place:')">
                    <xsl:value-of select="replace($p_idno, '.*oape:place:(\d+).*', '$1')"/>
                </xsl:when>
                <xsl:when test="contains($p_idno, 'geon:')">
                    <xsl:value-of select="replace($p_idno, '.*geon:(\d+).*', '$1')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!--<xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>oape:get-place-from-authority-file: $v_authority="</xsl:text><xsl:value-of select="$v_authority"/><xsl:text>" and $v_idno="</xsl:text><xsl:value-of select="$v_idno"/><xsl:text>"</xsl:text>
            </xsl:message>
        </xsl:if>-->
        <xsl:copy-of
            select="$v_file-entities-master//tei:place[tei:idno[@type = $v_authority] = $v_idno]"/>
    </xsl:function>
    <!-- get OpenArabicPE ID from authority file with an @xml:id -->
    <xsl:function name="oape:get-id-for-place">
        <xsl:param name="p_xml-id"/>
        <xsl:param name="p_authority"/>
        <xsl:value-of
            select="$v_file-entities-master//tei:lace[tei:placeName[@xml:id = $p_xml-id]]/tei:idno[@type = $p_authority]"
        />
    </xsl:function>
    <!-- look for placeNames that have a @ref attribute -->
    <xsl:template match="tei:placeName[@ref]" name="t_3">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_3: found a placeName with @ref </xsl:text>
                <xsl:value-of select="@ref"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="v_corresponding-place"
            select="oape:get-place-from-authority-file(@ref)"/>
        <xsl:variable name="v_ref">
            <xsl:choose>
                <xsl:when test="contains(@ref, 'oape:place:') or contains(@ref, 'geon:')">
                    <!-- add references to IDs -->
                    <xsl:value-of
                        select="concat('oape:place:', $v_corresponding-place/descendant::tei:idno[@type = 'oape'][1])"/>
                    <xsl:if test="$v_corresponding-place/descendant::tei:idno[@type = 'geon']">
                        <xsl:text> </xsl:text>
                        <xsl:value-of
                            select="concat('geon:', $v_corresponding-place/descendant::tei:idno[@type = 'geon'][1])"
                        />
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@ref"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_3: @ref </xsl:text>
                <xsl:value-of select="$v_ref"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:if test="@ref != $v_ref">
                 <xsl:if test="$p_verbose = true()">
                     <xsl:message>
                         <xsl:text>t_3: missing reference to either GeoNames or local authority file will be added</xsl:text>
                     </xsl:message>
                 </xsl:if>
                <xsl:attribute name="ref" select="$v_ref"/>
                <!-- document change -->
                <xsl:choose>
                    <xsl:when test="not(@change)">
                        <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="m_documentation" select="@change"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <!-- replicate content -->
            <xsl:apply-templates select="node()"></xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <!-- lock for placeName that have no @ref attribute -->
    <xsl:template match="tei:placeName[not(@ref)]" name="t_2">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_2: found a placeName without @ref</xsl:text>
            </xsl:message>
        </xsl:if>
        <!-- normalize the spelling of the name in question -->
        <xsl:variable name="v_self" select="normalize-space(replace(., '([إ|أ|آ])', 'ا'))"/>
        <!-- version of the placeName without non-word characters -->
        <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>
        <!-- test if the flattened name is present in the authority file -->
        <xsl:choose>
            <xsl:when
                test="$v_file-entities-master//tei:place/tei:placeName[replace(., '([إ|أ|آ])', 'ا') = $v_self]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_2: </xsl:text>
                        <xsl:value-of select="$v_self"/>
                        <xsl:text> is present in authority file and will be updated</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:variable name="v_corresponding-place"
                    select="$v_file-entities-master/descendant::tei:placeName[replace(., '([إ|أ|آ])', 'ا') = $v_self][1]/parent::tei:place"/>
                <!--<xsl:variable name="v_corresponding-xml-id"
                    select="substring-after($v_corresponding-place/descendant::tei:placeName[replace(., '([إ|أ|آ])', 'ا') = $v_self][1]/@corresp, '#')"/>-->
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <!-- document change -->
                    <xsl:choose>
                        <xsl:when test="not(@change)">
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="m_documentation" select="@change"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- add references to IDs -->
                    <xsl:attribute name="ref">
                        <xsl:value-of
                            select="concat('oape:place:', $v_corresponding-place/descendant::tei:idno[@type = 'oape'][1])"/>
                        <xsl:if test="$v_corresponding-place/descendant::tei:idno[@type = 'geon']">
                            <xsl:text> </xsl:text>
                            <xsl:value-of
                                select="concat('geon:', $v_corresponding-place/descendant::tei:idno[@type = 'geon'][1])"
                            />
                        </xsl:if>
                    </xsl:attribute>
                    <!-- replicate content -->
                    <!-- NOTE: one could try to add mark-up from $v_corresponding-place -->
                    <xsl:apply-templates select="node()"/>
                </xsl:copy>
            </xsl:when>
            <!-- fallback -->
            <xsl:otherwise>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_2: </xsl:text>
                        <xsl:value-of select="$v_self"/>
                        <xsl:message> not found in authority file.</xsl:message>
                    </xsl:message>
                </xsl:if>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- document the changes to source file -->
    <xsl:template match="tei:revisionDesc" name="t_9">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_9 source: document changes</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                 <xsl:text>Added references to local authority file (</xsl:text>
                <tei:ref target="{$p_url-master}">
                    <xsl:value-of select="$p_url-master"/>
                </tei:ref>
                <xsl:text>) and to GeoNames IDs to </xsl:text><tei:gi>placeName</tei:gi><xsl:text>s without such references based on  </xsl:text><tei:gi>place</tei:gi><xsl:text>s mentioned in the authority file.</xsl:text>
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
