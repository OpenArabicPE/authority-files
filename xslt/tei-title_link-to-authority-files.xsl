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
    
    <!-- this stylesheet queries an external authority files for every <title> and attempts to provide links via the @ref attribute -->
    <!-- The now unnecessary code to updated the master file needs to be removed -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no" exclude-result-prefixes="#all"/>

    <xsl:include href="query-geonames.xsl"/>
    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master"
        select="'../data/tei/bibliography_OpenArabicPE-periodicals.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>
    
   <!-- identity transform -->
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
    
    <!-- function to retrieve a <biblStruct> from a local authority file -->
    <xsl:function name="oape:get-bibl-from-authority-file">
        <xsl:param name="p_idno"/>
        <xsl:variable name="v_authority">
            <xsl:choose>
                <xsl:when test="contains($p_idno, 'oape:bibl:')">
                    <xsl:text>oape</xsl:text>
                </xsl:when>
                <xsl:when test="contains($p_idno, 'OCLC:')">
                    <xsl:text>OCLC</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_idno">
            <xsl:choose>
                <xsl:when test="contains($p_idno, 'oape:bibl:')">
                    <xsl:value-of select="replace($p_idno, '.*oape:bibl:(\d+).*', '$1')"/>
                </xsl:when>
                <xsl:when test="contains($p_idno, 'OCLC:')">
                    <xsl:value-of select="replace($p_idno, '.*OCLC:(\d+).*', '$1')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!--<xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>oape:get-place-from-authority-file: $v_authority="</xsl:text><xsl:value-of select="$v_authority"/><xsl:text>" and $v_idno="</xsl:text><xsl:value-of select="$v_idno"/><xsl:text>"</xsl:text>
            </xsl:message>
        </xsl:if>-->
        <!-- check if the bibliography contains an entry for this ID, if so, retrieve the full <biblStruct>, otherwise return 'false()' -->
        <xsl:choose>
            <xsl:when test="$v_file-entities-master//tei:biblStruct[.//tei:idno[@type = $v_authority] = $v_idno]">
                <xsl:copy-of
            select="$v_file-entities-master//tei:biblStruct[.//tei:idno[@type = $v_authority] = $v_idno]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'false()'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- look for titles that have a @ref attribute -->
    <xsl:template match="tei:text//tei:title[@ref]" name="t_3">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_3: found a title with @ref </xsl:text>
                <xsl:value-of select="@ref"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="v_corresponding-bibl"
            select="oape:get-bibl-from-authority-file(@ref)"/>
        <xsl:variable name="v_ref">
            <xsl:choose>
                <!-- protect existing values of @ref for which there is no entry in the bibliography -->
                <xsl:when test="$v_corresponding-bibl = 'false()'">
                    <xsl:value-of select="@ref"/>
                </xsl:when>
                <xsl:when test="contains(@ref, 'oape:bibl:') or contains(@ref, 'oclc:')">
                    <!-- add references to IDs -->
                    <xsl:value-of
                        select="concat('oape:bibl:', $v_corresponding-bibl/descendant::tei:idno[@type = 'oape'][1])"/>
                    <xsl:if test="$v_corresponding-bibl/descendant::tei:idno[@type = 'OCLC']">
                        <xsl:text> </xsl:text>
                        <xsl:value-of
                            select="concat('oclc:', $v_corresponding-bibl/descendant::tei:idno[@type = 'OCLC'][1])"
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
                         <xsl:text>t_3: missing reference to either OCLC or local authority file will be added</xsl:text>
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
    <xsl:template match="tei:text//tei:title[not(@ref)]" name="t_2">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_2: found a title without @ref</xsl:text>
            </xsl:message>
        </xsl:if>
        <!-- normalize the spelling of the name in question -->
        <xsl:variable name="v_self" select="normalize-space(replace(., '([إ|أ|آ])', 'ا'))"/>
        <!-- version of the placeName without non-word characters -->
        <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>
        <!-- test if the flattened name is present in the authority file -->
        <xsl:choose>
            <xsl:when
                test="$v_file-entities-master//tei:biblStruct/tei:monogr/tei:title[replace(., '([إ|أ|آ])', 'ا') = $v_self]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_2: </xsl:text>
                        <xsl:value-of select="$v_self"/>
                        <xsl:text> is present in authority file and will be updated</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:variable name="v_corresponding-bibl"
                    select="$v_file-entities-master/descendant::tei:title[replace(., '([إ|أ|آ])', 'ا') = $v_self][1]/ancestor::tei:biblStruct[1]"/>
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
                            select="concat('oape:bibl:', $v_corresponding-bibl/descendant::tei:idno[@type = 'oape'][1])"/>
                        <xsl:if test="$v_corresponding-bibl/descendant::tei:idno[@type = 'OCLC']">
                            <xsl:text> </xsl:text>
                            <xsl:value-of
                                select="concat('oclc:', $v_corresponding-bibl/descendant::tei:idno[@type = 'OCLC'][1])"
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
                <xsl:text>) and to OCLC (WorldCat) IDs to </xsl:text><tei:gi>titles</tei:gi><xsl:text>s without such references based on  </xsl:text><tei:gi>biblStruct</tei:gi><xsl:text>s mentioned in the authority file (bibliography).</xsl:text>
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
