<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"    
    xmlns:tei="http://www.tei-c.org/ns/1.0"
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
    
    <!-- p_id-editor references the @xml:id of a responsible editor to be used for documentation of changes -->
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    
    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master" select="'../data/tei/personography_OpenArabicPE.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>
    
    <!-- This template replicates everything -->
    <xsl:template match="node() | @*" mode="m_mark-up-source" name="t_2">
        <!--<xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_2: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>-->
        <xsl:copy>
            <xsl:apply-templates mode="m_mark-up-source" select="@* | node()"/>
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
    <xsl:template match="@xml:id | @xml:change" mode="m_copy-from-authority-file" priority="100"/>
    <!--<xsl:template match="text()" mode="m_copy-from-authority-file">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>-->
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
   
    <!-- mode m_mark-up-source will at some point provide automatic addition of information from $v_file-entities-master to a TEI file  -->
    <xsl:template match="tei:persName" mode="m_mark-up-source" name="t_4">
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_4 source: </xsl:text>
                <xsl:value-of select="@xml:id"/>
            </xsl:message>
        </xsl:if>
        <!-- normalize the spelling of the name in question -->
        <xsl:variable name="v_self" select="normalize-space(replace(., '([إ|أ|آ])', 'ا'))"/>
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
                        <xsl:text> is present in the authority file</xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- attempt to supply mark-up of the name's components based on the master file -->
                <xsl:copy>
                    <!-- replicate attributes -->
                    <xsl:apply-templates mode="m_mark-up-source" select="@*"/>
                    <xsl:choose>
                        <!-- test if the persName already has children. If not try to add some based on the persName without non-word characters and the authority file -->
                        <xsl:when test="not(child::node()[namespace::tei])">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>t_4 source #3: </xsl:text>
                                    <xsl:value-of select="$v_self"/>
                                    <xsl:text> contains no mark-up and should be updated.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <!-- check if the flattened persName is present -->
                            <xsl:choose>
                                <xsl:when
                                    test="$v_file-entities-master//tei:persName[@type = 'flattened'] = $v_name-flat">
                                    <xsl:if test="$p_verbose = true()">
                                        <xsl:message>
                                            <xsl:text>t_4 source #4: </xsl:text>
                                            <xsl:value-of select="$v_name-flat"/>
                                            <xsl:text> is present in the authority file</xsl:text>
                                        </xsl:message>
                                    </xsl:if>
                                    <!-- get @corresp of corresponding flat persName in the master file -->
                                    <xsl:variable name="v_corresp-xml-id"
                                        select="substring-after($v_file-entities-master//tei:persName[@type = 'flattened'][. = $v_name-flat]/@corresp, '#')"/>
                                    <xsl:if test="$p_verbose = true()">
                                        <xsl:message>
                                            <xsl:text>t_4 source #5: the xml:id of the corresponding persName in the authority file is </xsl:text>
                                            <xsl:value-of select="$v_corresp-xml-id"/>
                                        </xsl:message>
                                    </xsl:if>
                                    <!-- document change -->
                                    <xsl:choose>
                                        <xsl:when test="not(@change)">
                                            <xsl:attribute name="change"
                                                select="concat('#', $p_id-change)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:apply-templates mode="m_documentation"
                                                select="@change"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:apply-templates mode="m_copy-from-authority-file"
                                        select="$v_file-entities-master//tei:persName[@xml:id = $v_corresp-xml-id]/node()"
                                    />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:if test="$p_verbose = true()">
                                        <xsl:message>
                                            <xsl:text>t_4 source #4: </xsl:text>
                                            <xsl:value-of select="$v_name-flat"/>
                                            <xsl:text> is not present in the authority file. The content of </xsl:text>
                                            <xsl:value-of select="@xml:id"/>
                                            <xsl:text> has not been updated.</xsl:text>
                                        </xsl:message>
                                    </xsl:if>
                                    <xsl:apply-templates mode="m_mark-up-source" select="node()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="m_mark-up-source" select="node()"/>
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
                    <xsl:apply-templates mode="m_mark-up-source" select="@*"/>
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
                            <xsl:apply-templates mode="m_copy-from-authority-file"
                                select="$v_file-entities-master//tei:persName[@xml:id = $v_corresp-xml-id]/node()"
                            />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="m_mark-up-source" select="node()"/>
                        </xsl:otherwise>
                    </xsl:choose>
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
                    <xsl:apply-templates mode="m_mark-up-source" select="@* | node()"/>
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
            <xsl:apply-templates mode="m_mark-up-source" select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Added references to VIAF IDs to </xsl:text>
                <tei:gi>persName</tei:gi>
                <xsl:text>s without such references based on  </xsl:text>
                <tei:gi>person</tei:gi>
                <xsl:text>s mentioned in </xsl:text>
                <tei:ref target="{$p_url-master}">
                    <xsl:value-of select="$p_url-master"/>
                </tei:ref>
                <xsl:text> but not previously present in this master file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates mode="m_mark-up-source" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- document changes on changed elements by means of the @change attribute linking to the @xml:id of the <tei:change> element -->
    <xsl:template match="@change" mode="m_documentation">
        <xsl:attribute name="change">
            <xsl:value-of select="concat(., ' #', $p_id-change)"/>
        </xsl:attribute>
    </xsl:template>
</xsl:stylesheet>
