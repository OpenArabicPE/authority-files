<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- PROBLEM: in some instance this stylesheet produces empty <persName> nodes in the source file upon adding VIAF references to them -->
    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml"
        omit-xml-declaration="no"/>
    <xsl:include href="functions.xsl"/>
    <!-- p_id-editor references the @xml:id of a responsible editor to be used for documentation of changes -->
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master" select="'../data/tei/personography_OpenArabicPE.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>
    <xsl:param name="p_add-mark-up-to-input" select="true()"/>
    
    <!-- idendity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:persName">
        <!-- flatened version of the persName without non-word characters -->
        <xsl:variable name="v_name-flat" select="oape:string-normalise-name(string())"/>
        <!-- test if the flattened name is present in the authority file -->
        <xsl:variable name="v_corresponding-person">
            <xsl:choose>
                <!-- test if this node already points to an authority file -->
                <xsl:when test="@ref">
                    <xsl:copy-of select="oape:get-person-from-authority-file(@ref)"/>
                </xsl:when>
                <!-- test if the name is found in the authority file -->
                <xsl:when test="$v_file-entities-master//tei:person[tei:persName[@type = 'flattened'] = $v_name-flat]">
                    <xsl:copy-of select="$v_file-entities-master/descendant::tei:person[tei:persName[@type = 'flattened'] = $v_name-flat][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- one cannot use a boolean value if the default result is non-boolean -->
                    <xsl:value-of select="'false()'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <!-- fallback: name is not found in the authority file -->
            <xsl:when test="$v_corresponding-person = 'false()'">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_2: </xsl:text>
                        <xsl:value-of select="normalize-space(.)"/>
                        <xsl:message> not found in authority file.</xsl:message>
                    </xsl:message>
                </xsl:if>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:when>
            <!-- name is found in the authority file. it will be linked and potentially updated -->
            <xsl:otherwise>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_2: </xsl:text>
                        <xsl:value-of select="normalize-space(.)"/>
                        <xsl:text> is present in authority file and will be updated</xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- get @xml:id of corresponding entry in authority file -->
                <xsl:variable name="v_corresponding-xml-id" select="substring-after($v_corresponding-person//tei:persName[@type = 'flattened'][. = $v_name-flat][1]/@corresp, '#')">
                    <!--<xsl:choose>
                <!-\- test if there is a corresponding entry in the authority file -\->
                        <xsl:when test="$v_corresponding-person != false()">
                            <xsl:value-of"/>
                        </xsl:when>
                    </xsl:choose>-->
                </xsl:variable>
                <!-- construct @ref pointing to the corresponding entry -->
                <xsl:variable name="v_ref">
                    <xsl:value-of
                        select="concat('oape:pers:', $v_corresponding-person/descendant::tei:idno[@type = 'oape'][1])"/>
                    <xsl:if test="$v_corresponding-person/descendant::tei:idno[@type = 'VIAF']">
                        <xsl:text> </xsl:text>
                        <xsl:value-of
                            select="concat('viaf:', $v_corresponding-person/descendant::tei:idno[@type = 'VIAF'][1])"
                        />
                    </xsl:if>
                </xsl:variable>   
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <!-- add references to IDs -->
                    <xsl:attribute name="ref" select="$v_ref"/>
                    <!-- document change -->
                    <xsl:if test="not(@ref = $v_ref) or not(node() = $v_corresponding-person/descendant-or-self::tei:persName[@xml:id = $v_corresponding-xml-id]/node())">
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
                    <xsl:choose>
                        <xsl:when test="$p_add-mark-up-to-input = false()">
                            <xsl:apply-templates select="node()"/>
                        </xsl:when>
                        <!-- test if the persName already has children. If not try to add some based on the persName without non-word characters and the authority file -->
                        <xsl:when test="not(child::node()[namespace::tei])">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>t_2: </xsl:text>
                                    <xsl:value-of select="normalize-space(.)"/>
                                    <xsl:text> contains no mark-up which will be updated from the authority file</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:choose>
                                <xsl:when
                                    test="$v_corresponding-person/descendant-or-self::tei:persName[@xml:id = $v_corresponding-xml-id]/node()">
                                    <!-- this assumes there will be marked-up content in the authority file for this content, which is not necessarily the case. -->
                                    <xsl:apply-templates mode="m_copy-from-authority-file"
                                        select="$v_corresponding-person/descendant-or-self::tei:persName[@xml:id = $v_corresponding-xml-id]/node()"
                                    />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- this function queries a local authority file with an OpenArabicPE or VIAF ID and returns a <tei:person> -->
    <xsl:function name="oape:get-person-from-authority-file">
        <xsl:param name="p_idno"/>
        <xsl:variable name="v_authority">
            <xsl:choose>
                <xsl:when test="contains($p_idno, 'oape:pers:')">
                    <xsl:text>oape</xsl:text>
                </xsl:when>
                <xsl:when test="contains($p_idno, 'viaf:')">
                    <xsl:text>VIAF</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_idno">
            <xsl:choose>
                <xsl:when test="contains($p_idno, 'oape:pers:')">
                    <xsl:value-of select="replace($p_idno, '.*oape:pers:(\d+).*', '$1')"/>
                </xsl:when>
                <xsl:when test="contains($p_idno, 'viaf:')">
                    <xsl:value-of select="replace($p_idno, '.*viaf:(\d+).*', '$1')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!--<xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>oape:get-person-from-authority-file: $v_authority="</xsl:text><xsl:value-of select="$v_authority"/><xsl:text>" and $v_idno="</xsl:text><xsl:value-of select="$v_idno"/><xsl:text>"</xsl:text>
            </xsl:message>
        </xsl:if>-->
        <xsl:copy-of
            select="$v_file-entities-master//tei:person[tei:idno[@type = $v_authority] = $v_idno]"/>
    </xsl:function>
    <!-- get OpenArabicPE ID from authority file with an @xml:id -->
    <xsl:function name="oape:get-id-for-person">
        <xsl:param name="p_xml-id"/>
        <xsl:param name="p_authority"/>
        <xsl:value-of
            select="$v_file-entities-master//tei:person[tei:persName[@xml:id = $p_xml-id]]/tei:idno[@type = $p_authority]"
        />
    </xsl:function>
    
    <!-- copy from authority file should not include @xml:id and @change -->
    <xsl:template match="node() | @*" mode="m_copy-from-authority-file">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_copy-from-authority-file"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_copy-from-authority-file"/>
    
    <!-- document the changes to source file -->
    <xsl:template match="tei:revisionDesc">
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
                <xsl:text>) and VIAF to </xsl:text>
                <tei:gi>persName</tei:gi>
                <xsl:text>s without such references based on </xsl:text>
                <tei:gi>person</tei:gi>
                <xsl:text>s in the local authority file. If the source </xsl:text>
                <tei:gi>persName</tei:gi>
                <xsl:text> did not contain any further TEI mark-up, this has been added from the local authority file.</xsl:text>
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
