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
    <!--<xsl:include href="functions.xsl"/>-->
    
       <!-- variables for local IDs (OpenArabicPE) -->
    <xsl:param name="p_local-authority" select="'oape'"/>
    
    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-gazetteer" select="'../data/tei/gazetteer_levant-phd.TEIP5.xml'"/>
<!--    <xsl:param name="p_url-master" select="'/BachUni/BachBibliothek/GitHub/ProjectJaraid/jaraid_source/authority-files/jaraid_authority-file.TEIP5.xml'"></xsl:param>-->
    <xsl:variable name="v_file-entities-master" select="doc($p_url-gazetteer)"/>

    <!-- parameter to select whether the source file should be updated  -->
    <xsl:param name="p_update-source" select="true()"/>

   <!-- Identity transformation -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:placeName" priority="10">
        <!-- flatened version of the persName without non-word characters -->
        <xsl:variable name="v_name-flat" select="oape:string-normalise-characters(string())"/>
        <!-- test if the flattened name is present in the authority file -->
        <xsl:variable name="v_corresponding-place">
            <xsl:choose>
                <!-- test if this node already points to an authority file -->
                <xsl:when test="@ref">
                    <xsl:copy-of select="oape:get-place-from-authority-file(@ref, $v_file-entities-master)"/>
                </xsl:when>
                <!-- test if the name is found in the authority file -->
                <xsl:when test="$v_file-entities-master//tei:place[tei:placeName = $v_name-flat]">
                    <xsl:copy-of select="$v_file-entities-master/descendant::tei:place[tei:placeName = $v_name-flat][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- one cannot use a boolean value if the default result is non-boolean -->
                    <xsl:value-of select="'false()'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- fallback: name is not found in the authority file -->
            <xsl:when test="$v_corresponding-place = 'false()'">
<!--                <xsl:if test="$p_verbose = true()">-->
                    <xsl:message>
                        <xsl:value-of select="normalize-space(.)"/>
                        <xsl:text> not found in authority file. Add </xsl:text>
                        <xsl:element name="tei:place">
                            <xsl:copy>
                                <xsl:if test="not(@xml:lang)">
                                    <xsl:attribute name="xml:lang" select="'ar'"/>
                                </xsl:if>
                                <xsl:apply-templates select="@* | node()" mode="m_identity-transform"/>
                            </xsl:copy>
                        </xsl:element>
                        <xsl:text> to the authority file.</xsl:text>
                    </xsl:message>
                <!--</xsl:if>-->
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:when>
            <!-- name is found in the authority file. it will be linked and potentially updated -->
            <xsl:otherwise>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:value-of select="normalize-space(.)"/>
                        <xsl:text> is present in authority file and will be updated</xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- get @xml:id of corresponding entry in authority file -->
<!--                <xsl:variable name="v_corresponding-xml-id" select="substring-after($v_corresponding-person//tei:persName[@type = 'flattened'][. = $v_name-flat][1]/@corresp, '#')"/>-->
                
                <!-- construct @ref pointing to the corresponding entry -->
                <xsl:variable name="v_ref">
                    <xsl:value-of
                        select="concat($p_local-authority, ':place:', $v_corresponding-place/descendant::tei:idno[@type = $p_local-authority][1])"/>
                    <xsl:if test="$v_corresponding-place/descendant::tei:idno[@type = 'geon']">
                        <xsl:text> </xsl:text>
                        <xsl:value-of
                            select="concat('geon:', $v_corresponding-place/descendant::tei:idno[@type = 'geon'][1])"
                        />
                    </xsl:if>
                </xsl:variable>   
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <!-- add references to IDs -->
                    <xsl:attribute name="ref" select="$v_ref"/>
                    <!-- document change -->
                    <xsl:if test="not(@ref = $v_ref)">
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
                    <!-- NOTE: one could try to add mark-up from $v_corresponding-person -->
                    <xsl:apply-templates/>
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
                <tei:ref target="{$p_url-gazetteer}">
                    <xsl:value-of select="$p_url-gazetteer"/>
                </tei:ref>
                <xsl:text>) and to GeoNames IDs to </xsl:text><tei:gi>placeName</tei:gi><xsl:text>s without such references based on  </xsl:text><tei:gi>place</tei:gi><xsl:text>s mentioned in the authority file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
