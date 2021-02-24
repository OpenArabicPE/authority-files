<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" 
    xmlns:bgn="http://bibliograph.net/" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:genont="http://www.w3.org/2006/gen/ont#" 
    xmlns:oape="https://openarabicpe.github.io/ns" 
    xmlns:opf="http://www.idpf.org/2007/opf" 
    xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:re="http://oclcsrw.google.code/redirect" 
    xmlns:schema="http://schema.org/" 
    xmlns:srw="http://www.loc.gov/zing/srw/"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:umbel="http://umbel.org/umbel#" 
    xmlns:viaf="http://viaf.org/viaf/terms#" 
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xi="http://www.w3.org/2001/XInclude" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- this stylesheet queries an external authority files for every <title> and attempts to provide links via the @ref attribute -->
    <!-- The now unnecessary code to updated the master file needs to be removed -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml" omit-xml-declaration="no"/>
    
    <xsl:include href="functions.xsl"/>
    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <!--<xsl:param name="p_url-master" select="'../data/tei/bibliography_OpenArabicPE-periodicals.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>-->
    <xsl:param name="p_update-existing-refs" select="false()"/>
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
    <xsl:template match="tei:title[ancestor::tei:text][@level = 'j'][not(@type = 'sub')]" priority="10">
        <xsl:copy-of select="oape:link-title-to-authority-file(., $v_bibliography)"/>
    </xsl:template>
    <xsl:function name="oape:link-title-to-authority-file">
        <xsl:param name="p_title"/>
        <xsl:param name="p_authority-file"/>
        <!-- flatened version of the persName without non-word characters and without any harakat -->
        <xsl:variable name="v_name-flat" select="oape:string-normalise-characters(string($p_title))"/>
        <xsl:variable name="v_level" select="$p_title/@level"/>
        <xsl:variable name="v_bibl"
            select="
                if ($p_title/ancestor::tei:bibl) then
                    (oape:compile-next-prev($p_title/ancestor::tei:bibl))
                else
                    ()"/>
        <xsl:variable name="v_type"
            select="
                if ($v_bibl/descendant-or-self::tei:bibl/@type) then
                    ($v_bibl/descendant-or-self::tei:bibl/@type)
                else
                    ()"/>
        <xsl:variable name="v_subtype"
            select="
                if ($v_bibl/descendant-or-self::tei:bibl/@subtype) then
                    ($v_bibl/descendant-or-self::tei:bibl/@subtype)
                else
                    ()"/>
        <xsl:variable name="v_frequency"
            select="
                if ($v_bibl/descendant-or-self::tei:bibl/@oape:frequency) then
                    ($v_bibl/descendant-or-self::tei:bibl/@oape:frequency)
                else
                    ()"/>
        <!-- get the publication date of the TEI document in order to establish whether a title could have been mentioned -->
        <xsl:variable name="v_date-publication" select="$p_title/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct[1]/tei:monogr/tei:imprint/tei:date[1]"/>
        <!-- get the place of publication -->
        <xsl:variable name="v_place-publication" select="$v_bibl/descendant-or-self::tei:bibl/tei:pubPlace/tei:placeName[1]"/>
        <!-- test if the flattened name is present in the authority file -->
        <xsl:variable name="v_corresponding-bibl">
            <xsl:choose>
                <!-- test if this node already points to an authority file -->
                <!-- since these @refs can be faulty, one should probably add a param -->
                <xsl:when test="$p_title/@ref and ($p_update-existing-refs = false())">
                    <xsl:copy-of select="oape:get-entity-from-authority-file($p_title, $p_local-authority, $v_bibliography)"/>
<!--                    <xsl:copy-of select="oape:get-bibl-from-authority-file($p_title/@ref, $p_authority-file)"/>-->
                </xsl:when>
                <!-- test if the name is found in the authority file -->
                <xsl:when test="$v_bibliography/descendant::tei:biblStruct/tei:monogr/tei:title[@level = $v_level][oape:string-normalise-characters(.) = $v_name-flat]">
                    <xsl:variable name="v_matches" select="$v_bibliography/descendant::tei:biblStruct[descendant::tei:title[@level = $v_level][oape:string-normalise-characters(.) = $v_name-flat]]"/>
                    <xsl:choose>
                        <!-- a single match -->
                        <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct) = 1">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for </xsl:text>
                                    <xsl:value-of select="$p_title"/>
                                    <xsl:text> in the authority file.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:copy-of select="$v_matches/descendant-or-self::tei:biblStruct"/>
                        </xsl:when>
                        <!-- multiple matches: add matching criteria -->
                        <xsl:otherwise>
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found multiple matches for </xsl:text>
                                    <xsl:value-of select="$p_title"/>
                                    <xsl:text> in the authority file. Trying to match further search criteria.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <!-- try to use further match criteria -->
                            <xsl:choose>
                                <!-- this should start with @type and @subtype criteria -->
                                <!-- more than one match based on @type and @subtype -->
                                <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype]) gt 1">
                                    <xsl:variable name="v_matches" select="$v_matches/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype]"/>
                                    <!-- add additional match criteria -->
                                    <xsl:choose>
                                        <!-- location -->
                                        <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[tei:monogr/tei:imprint/tei:pubPlace/tei:placeName = $v_place-publication]) = 1">
                                            <xsl:if test="$p_verbose = true()">
                                                <xsl:message>
                                                    <xsl:text>Found a single match based on publication place.</xsl:text>
                                                </xsl:message>
                                            </xsl:if>
                                            <xsl:copy-of select="$v_matches/descendant-or-self::tei:biblStruct[tei:monogr/tei:imprint/tei:pubPlace/tei:placeName = $v_place-publication]"/>
                                        </xsl:when>
                                        <!-- date -->
                                        <!-- the comparison of dates should be based on the year only, since the data type for att.dated is not xs:date -->
                                        <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[descendant::tei:date/@when lt $v_date-publication/@when]) = 1">
                                            <xsl:if test="$p_verbose = true()">
                                                <xsl:message>
                                                    <xsl:text>Found a single match based on publication date.</xsl:text>
                                                </xsl:message>
                                            </xsl:if>
                                            <xsl:copy-of select="$v_matches/descendant-or-self::tei:biblStruct[descendant::tei:date/@when lt $v_date-publication/@when]"/>
                                        </xsl:when>
                                        <!-- test if the date falls into a range -->
                                        <xsl:when
                                            test="count($v_matches/descendant-or-self::tei:biblStruct[oape:date-get-onset(descendant::tei:date) lt $v_date-publication/@when][oape:date-get-terminus(descendant::tei:date) gt $v_date-publication/@when]) = 1">
                                            <xsl:if test="$p_verbose = true()">
                                                <xsl:message>
                                                    <xsl:text>Found a single match based on publication date (range).</xsl:text>
                                                </xsl:message>
                                            </xsl:if>
                                            <xsl:copy-of
                                                select="$v_matches/descendant-or-self::tei:biblStruct[oape:date-get-onset(descendant::tei:date) lt $v_date-publication/@when][oape:date-get-terminus(descendant::tei:date) gt $v_date-publication/@when]"
                                            />
                                        </xsl:when>
                                        <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[oape:date-get-onset(descendant::tei:date) lt $v_date-publication/@when]) = 1">
                                            <xsl:if test="$p_verbose = true()">
                                                <xsl:message>
                                                    <xsl:text>Found a single match based on publication date (onset).</xsl:text>
                                                </xsl:message>
                                            </xsl:if>
                                            <xsl:copy-of select="$v_matches/descendant-or-self::tei:biblStruct[oape:date-get-onset(descendant::tei:date) lt $v_date-publication/@when]"/>
                                        </xsl:when>
                                        <!-- @oape:frequency -->
                                        <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][@oape:frequency = $v_frequency]) = 1">
                                            <xsl:if test="$p_verbose = true()">
                                                <xsl:message>
                                                    <xsl:text>Found a single match based on @type, @subtype, and @oape:frequency.</xsl:text>
                                                </xsl:message>
                                            </xsl:if>
                                            <xsl:copy-of select="$v_matches/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][@oape:frequency = $v_frequency]"/>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:when>
                                <!-- single match based on @type and @subtype -->
                                <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype]) = 1">
                                    <xsl:if test="$p_verbose = true()">
                                        <xsl:message>
                                            <xsl:text>Found a single match based on @type and @subtype.</xsl:text>
                                        </xsl:message>
                                    </xsl:if>
                                    <xsl:copy-of select="$v_matches/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype]"/>
                                </xsl:when>
                                <!-- location -->
                                <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[tei:monogr/tei:imprint/tei:pubPlace/tei:placeName = $v_place-publication]) = 1">
                                    <xsl:if test="$p_verbose = true()">
                                        <xsl:message>
                                            <xsl:text>Found a single match based on publication place.</xsl:text>
                                        </xsl:message>
                                    </xsl:if>
                                    <xsl:copy-of select="$v_matches/descendant-or-self::tei:biblStruct[tei:monogr/tei:imprint/tei:pubPlace/tei:placeName = $v_place-publication]"/>
                                </xsl:when>
                                <!--                                <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[xs:date(descendant::tei:date/@when) lt xs:date($v_date-publication/@when)]) = 1">-->
                                <!-- the comparison of dates should be based on the year only, since the data type for att.dated is not xs:date -->
                                <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[descendant::tei:date/@when lt $v_date-publication/@when]) = 1">
                                    <xsl:if test="$p_verbose = true()">
                                        <xsl:message>
                                            <xsl:text>Found a single match based on publication date.</xsl:text>
                                        </xsl:message>
                                    </xsl:if>
                                    <xsl:copy-of select="$v_matches/descendant-or-self::tei:biblStruct[descendant::tei:date/@when lt $v_date-publication/@when]"/>
                                </xsl:when>
                                <!-- test if the date falls into a range -->
                                <xsl:when
                                    test="count($v_matches/descendant-or-self::tei:biblStruct[oape:date-get-onset(descendant::tei:date) lt $v_date-publication/@when][oape:date-get-terminus(descendant::tei:date) gt $v_date-publication/@when]) = 1">
                                    <xsl:if test="$p_verbose = true()">
                                        <xsl:message>
                                            <xsl:text>Found a single match based on publication date (range).</xsl:text>
                                        </xsl:message>
                                    </xsl:if>
                                    <xsl:copy-of
                                        select="$v_matches/descendant-or-self::tei:biblStruct[oape:date-get-onset(descendant::tei:date) lt $v_date-publication/@when][oape:date-get-terminus(descendant::tei:date) gt $v_date-publication/@when]"
                                    />
                                </xsl:when>
                                <xsl:when test="count($v_matches/descendant-or-self::tei:biblStruct[oape:date-get-onset(descendant::tei:date) lt $v_date-publication/@when]) = 1">
                                    <xsl:if test="$p_verbose = true()">
                                        <xsl:message>
                                            <xsl:text>Found a single match based on publication date (onset).</xsl:text>
                                        </xsl:message>
                                    </xsl:if>
                                    <xsl:copy-of select="$v_matches/descendant-or-self::tei:biblStruct[oape:date-get-onset(descendant::tei:date) lt $v_date-publication/@when]"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!--<xsl:if test="$p_verbose = true()">-->
                                    <xsl:message>
                                        <xsl:text>Found no unique match in the authority file for </xsl:text>
                                        <xsl:value-of select="$p_title"/>
                                        <xsl:text> at </xsl:text>
                                        <xsl:value-of select="concat(base-uri($p_title), '#', $p_title/@xml:id)"/>
                                        <xsl:text>.</xsl:text>
                                    </xsl:message>
                                    <!--</xsl:if>-->
                                    <xsl:value-of select="'false()'"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- no match found -->
                <xsl:otherwise>
                    <!--                    <xsl:if test="$p_verbose = true()">-->
                    <xsl:message>
                        <xsl:text>Found no match in the authority file for </xsl:text>
                        <xsl:value-of select="$p_title"/>
                        <xsl:text> at </xsl:text>
                        <xsl:value-of select="concat(base-uri($p_title), '#', $p_title/@xml:id)"/>
                        <xsl:text>.</xsl:text>
                    </xsl:message>
                    <!--</xsl:if>-->
                    <!-- one cannot use a boolean value if the default result is non-boolean -->
                    <xsl:value-of select="'false()'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- fallback: name is not found in the authority file -->
            <xsl:when test="$v_corresponding-bibl = 'false()'">
                <xsl:element name="title">
                    <xsl:apply-templates select="$p_title/@* | $p_title/node()"/>
                </xsl:element>
            </xsl:when>
            <!-- name is found in the authority file. it will be linked and potentially updated -->
            <xsl:otherwise>
                <!-- get @xml:id of corresponding entry in authority file -->
                <!--                <xsl:variable name="v_corresponding-xml-id" select="substring-after($v_corresponding-person//tei:persName[@type = 'flattened'][. = $v_name-flat][1]/@corresp, '#')"/>-->
                <!-- construct @ref pointing to the corresponding entry -->
                <xsl:variable name="v_ref">
                    <xsl:if test="$v_corresponding-bibl/descendant::tei:idno[@type = 'oape']">
                        <xsl:value-of select="concat('oape:bibl:', $v_corresponding-bibl/descendant::tei:idno[@type = 'oape'][1])"/>
                    </xsl:if>
                    <xsl:if test="$v_corresponding-bibl/descendant::tei:idno[@type = 'OCLC']">
                        <xsl:if test="$v_corresponding-bibl/descendant::tei:idno[@type = 'oape']">
                            <xsl:text> </xsl:text>
                        </xsl:if>
                        <xsl:value-of select="concat('oclc:', $v_corresponding-bibl/descendant::tei:idno[@type = 'OCLC'][1])"/>
                    </xsl:if>
                </xsl:variable>
                <xsl:if test="$p_verbose = true() and $p_title/@ref = ''">
                    <xsl:message>
                        <xsl:text>The match has no &lt;idno&gt; child.</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:element name="title">
                    <xsl:apply-templates select="$p_title/@*"/>
                    <!-- add references to IDs -->
                    <xsl:if test="not($p_title/@ref = '')">
                        <xsl:attribute name="ref" select="$v_ref"/>
                        <!-- document change -->
                        <xsl:if test="not($p_title/@ref = $v_ref)">
                            <xsl:choose>
                                <xsl:when test="not($p_title/@change)">
                                    <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates mode="m_documentation" select="$p_title/@change"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:if>
                    <!-- replicate content -->
                    <xsl:apply-templates select="$p_title/node()"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- document the changes to source file -->
    <xsl:template match="tei:revisionDesc">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Added references to local authority file (</xsl:text>
                <tei:ref target="{$p_url-bibliography}">
                    <xsl:value-of select="$p_url-bibliography"/>
                </tei:ref>
                <xsl:text>) and to OCLC (WorldCat) IDs to </xsl:text>
                <tei:gi>titles</tei:gi>
                <xsl:text>s without such references based on  </xsl:text>
                <tei:gi>biblStruct</tei:gi>
                <xsl:text>s mentioned in the authority file (bibliography).</xsl:text>
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
