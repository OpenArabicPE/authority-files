<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    exclude-result-prefixes="xs" 
    version="3.0" 
    xmlns:oape="https://openarabicpe.github.io/ns" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">

    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" method="xml" omit-xml-declaration="no"/>
    
    <!-- identify the author of the change by means of a @xml:id -->
    <!-- toggle debugging messages -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-nyms" select="'../data/tei/nymlist.TEIP5.xml'"/>
    <xsl:variable name="v_file-nyms" select="doc($p_url-nyms)"/>
    <!--<xsl:template match="/">
        <xsl:apply-templates select="descendant::tei:date" mode="m_debug"/>
    </xsl:template>-->
    <xsl:template match="tei:date" mode="m_debug">
        <xsl:value-of select="oape:date-get-onset(.)"/>
        <xsl:text> - </xsl:text>
        <xsl:value-of select="oape:date-get-terminus(.)"/>
    </xsl:template>
    <!-- parameters for string-replacements -->
    <xsl:param name="p_string-match" select="'([إ|أ|آ])'"/>
    <xsl:param name="p_string-replace" select="'ا'"/>
    <xsl:param name="p_string-harakat" select="'([ِ|ُ|ٓ|ٰ|ْ|ٌ|ٍ|ً|ّ|َ])'"/>
    <xsl:function name="oape:string-normalise-characters">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_self" select="normalize-space(replace(oape:string-remove-harakat($p_input), $p_string-match, $p_string-replace))"/>
<!--        <xsl:value-of select="replace($v_self, '\W', '')"/>-->
        <xsl:value-of select="$v_self"/>
    </xsl:function>
    <xsl:function name="oape:string-remove-characters">
        <xsl:param name="p_input" as="xs:string"/>
        <xsl:param name="p_string-match"/>
        <xsl:value-of select="normalize-space(replace($p_input, $p_string-match, ''))"/>
    </xsl:function>
    <xsl:function name="oape:string-remove-harakat">
        <xsl:param name="p_input"/>
        <xsl:value-of select="oape:string-remove-characters($p_input, $p_string-harakat)"/>
    </xsl:function>
    <xsl:function name="oape:string-remove-spaces">
        <xsl:param name="p_input"/>
        <xsl:value-of select="replace($p_input, '\W', '')"/>
    </xsl:function>
    <!-- function to retrieve a <biblStruct> from a local authority file -->
    <xsl:function name="oape:get-bibl-from-authority-file">
        <xsl:param name="p_idno"/>
        <xsl:param name="p_authority-file"/>
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
            <xsl:when test="$p_authority-file//tei:biblStruct[.//tei:idno[@type = $v_authority] = $v_idno]">
                <xsl:copy-of select="$p_authority-file//tei:biblStruct[.//tei:idno[@type = $v_authority] = $v_idno]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'false()'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- this function queries a local authority file with an OpenArabicPE or VIAF ID and returns a <tei:person> -->
    <xsl:function name="oape:get-person-from-authority-file">
        <xsl:param name="p_idno"/>
        <xsl:param name="p_authority-file"/>
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
        <xsl:copy-of select="$p_authority-file//tei:person[tei:idno[@type = $v_authority] = $v_idno]"/>
    </xsl:function>
    <!-- get OpenArabicPE ID from authority file with an @xml:id -->
    <xsl:function name="oape:get-id-for-person">
        <xsl:param name="p_xml-id"/>
        <xsl:param name="p_authority"/>
        <xsl:param name="p_authority-file"/>
        <xsl:value-of select="$p_authority-file//tei:person[tei:persName[@xml:id = $p_xml-id]]/tei:idno[@type = $p_authority][1]"/>
    </xsl:function>
    <xsl:function name="oape:get-place-from-authority-file">
        <xsl:param name="p_idno"/>
        <xsl:param name="p_authority-file"/>
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
        <xsl:copy-of select="$p_authority-file//tei:place[tei:idno[@type = $v_authority] = $v_idno]"/>
    </xsl:function>
    <!-- get OpenArabicPE ID from authority file with an @xml:id -->
    <xsl:function name="oape:get-id-for-place">
        <xsl:param name="p_xml-id"/>
        <xsl:param name="p_authority"/>
        <xsl:param name="p_authority-file"/>
        <xsl:value-of select="$p_authority-file/tei:place[tei:placeName[@xml:id = $p_xml-id]]/tei:idno[@type = $p_authority][1]"/>
    </xsl:function>
    <xsl:function name="oape:date-get-onset">
        <xsl:param name="p_date"/>
        <xsl:choose>
            <xsl:when test="$p_date/@when">
                <xsl:copy-of select="$p_date/@when"/>
            </xsl:when>
            <xsl:when test="$p_date/@from">
                <xsl:copy-of select="$p_date/@from"/>
            </xsl:when>
            <xsl:when test="$p_date/@notBefore">
                <xsl:copy-of select="$p_date/@notBefore"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>date: no machine-readible onset found</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:date-get-terminus">
        <xsl:param name="p_date"/>
        <xsl:choose>
            <xsl:when test="$p_date/@when">
                <xsl:copy-of select="$p_date/@when"/>
            </xsl:when>
            <xsl:when test="$p_date/@to">
                <xsl:copy-of select="$p_date/@to"/>
            </xsl:when>
            <xsl:when test="$p_date/@notAfter">
                <xsl:copy-of select="$p_date/@notAfter"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>date: no machine-readible terminus found</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:compile-next-prev">
        <xsl:param name="p_node"/>
        <xsl:variable name="v_next-id" select="substring-after($p_node/@next, '#')"/>
        <xsl:variable name="v_prev-id" select="substring-after($p_node/@prev, '#')"/>
        <xsl:choose>
            <!-- first -->
            <xsl:when test="$p_node/@next and not($p_node/@prev)">
                <!-- problem: the namespace is not provided! -->
                <xsl:copy copy-namespaces="yes" inherit-namespaces="yes" select="$p_node">
                    <xsl:apply-templates mode="m_identity-transform" select="$p_node/@*"/>
                    <xsl:copy-of select="$p_node/ancestor::tei:text/descendant::node()[@xml:id = $v_next-id]/@*"/>
                    <xsl:apply-templates mode="m_identity-transform" select="$p_node/node()"/>
                    <xsl:copy-of select="oape:compile-next-prev($p_node/ancestor::tei:text/descendant::node()[@xml:id = $v_next-id])"/>
                    <!--                    <xsl:apply-templates select="ancestor::tei:text/descendant::node()[@xml:id = $v_next-id]" mode="m_compile"/>-->
                </xsl:copy>
            </xsl:when>
            <!-- middle -->
            <xsl:when test="$p_node/@next and $p_node/@prev">
                <xsl:apply-templates mode="m_identity-transform" select="$p_node/node()"/>
                <xsl:copy-of select="oape:compile-next-prev($p_node/ancestor::tei:text/descendant::node()[@xml:id = $v_next-id])"/>
                <!--                <xsl:apply-templates select="ancestor::tei:text/descendant::node()[@xml:id = $v_next-id]" mode="m_compile"/>-->
            </xsl:when>
            <!-- last -->
            <xsl:when test="$p_node/@prev and not($p_node/@next)">
                <xsl:apply-templates mode="m_identity-transform" select="$p_node/node()"/>
            </xsl:when>
            <!-- nothing to compile -->
            <xsl:otherwise>
                <xsl:copy copy-namespaces="yes" inherit-namespaces="yes" select="$p_node">
                    <xsl:apply-templates mode="m_identity-transform" select="$p_node/@* | $p_node/node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="node() | @*" mode="m_identity-transform">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- problem: any mark-up from the input will be removed -->
    <xsl:function name="oape:string-mark-up-names">
        <xsl:param as="xs:string" name="p_input"/>
        <xsl:param name="p_id-change"/>
        <xsl:variable name="v_input" select="oape:string-normalise-characters($p_input)"/>
        <xsl:choose>
            <!-- kunya -->
            <xsl:when test="matches($v_input, '^(.+\s)*(ابو|ابي)\s(.+)$')">
                <!--<xsl:message>
                    <xsl:value-of select="$v_input"/>
                    <xsl:text> contains a kunya</xsl:text>
                </xsl:message>-->
                <xsl:analyze-string regex="(ابو|ابي)\s(.+)$" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:variable name="v_trailing" select="regex-group(2)"/>
                        <xsl:element name="tei:addName">
                            <xsl:attribute name="type" select="'kunyah'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:element name="tei:nameLink">
                                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                                <xsl:value-of select="regex-group(1)"/>
                                <xsl:text> </xsl:text>
                            </xsl:element>
                            <xsl:text> </xsl:text>
                            <xsl:copy-of select="oape:string-mark-up-names($v_trailing, $p_id-change)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- test for nasab -->
            <xsl:when test="matches($v_input, '^(.+\s)*(ابن|بن|بنت)(\s.+)$')">
                <!--<xsl:message>
                    <xsl:value-of select="$v_input"/>
                    <xsl:text> contains a nasab</xsl:text>
                </xsl:message>-->
                <xsl:analyze-string regex="(ابن|بن|بنت)\s(.+)$" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:variable name="v_trailing" select="regex-group(2)"/>
                        <xsl:element name="tei:addName">
                            <xsl:attribute name="type" select="'nasab'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:element name="tei:nameLink">
                                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                                <xsl:value-of select="regex-group(1)"/>
                            </xsl:element>
                            <xsl:text> </xsl:text>
                            <xsl:copy-of select="oape:string-mark-up-names($v_trailing, $p_id-change)"/>
                        </xsl:element>
                        <xsl:text> </xsl:text>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- test for khitab (... al-Dīn) -->
            <xsl:when test="matches($v_input, '^(.+\s)*(\w+)\s(الدين)(.*)$')">
                <!--<xsl:message>
                    <xsl:value-of select="$v_input"/>
                    <xsl:text> contains a khitab</xsl:text>
                </xsl:message>-->
                <xsl:analyze-string regex="(\w+)\s(الدين)" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="tei:addName">
                            <xsl:attribute name="type" select="'khitab'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:value-of select="concat(regex-group(1), ' ', regex-group(2))"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- test for theophoric names ending with Allah -->
            <xsl:when test="matches($v_input, '^(.+\s)*(\w+)\s(الله)(.*)$')">
                <!--<xsl:message>
                    <xsl:value-of select="$v_input"/>
                    <xsl:text> contains a theophoric name</xsl:text>
                </xsl:message>-->
                <xsl:analyze-string regex="(\w+)\s(الله)" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="tei:addName">
                            <xsl:attribute name="type" select="'theophoric'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:value-of select="concat(regex-group(1), ' ', regex-group(2))"/>
                        </xsl:element>
                        <xsl:text> </xsl:text>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- test for theophoric names beginning with ʿAbd -->
            <xsl:when test="matches($v_input, '^(.+\s)*(عبد)\s(\w+)(.*)$')">
                <!--<xsl:message>
                    <xsl:value-of select="$v_input"/>
                    <xsl:text> contains a theophoric name</xsl:text>
                </xsl:message>-->
                <xsl:analyze-string regex="(عبد)\s(\w+)" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="tei:addName">
                            <xsl:attribute name="type" select="'theophoric'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:value-of select="concat(regex-group(1), ' ', regex-group(2))"/>
                        </xsl:element>
                        <xsl:text> </xsl:text>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- test for nisba -->
            <xsl:when test="matches($v_input, '^(.+\s)*(ال\w+ي)(\s.+)*$')">
                <!--<xsl:message>
                    <xsl:value-of select="$v_input"/>
                    <xsl:text> contains a nisba</xsl:text>
                </xsl:message>-->
                <xsl:analyze-string regex="(ال\w+ي)" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="tei:addName">
                            <xsl:attribute name="type" select="'nisbah'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- test if a single word is found in a nymlist -->
            <xsl:when test="matches($v_input, '^(.+\s)*(\w+)(\s.+)*$')">
                <xsl:analyze-string regex="(\w+)" select="$v_input">
                    <!-- single word match -->
                    <xsl:matching-substring>
                        <xsl:variable name="v_word" select="regex-group(1)"/>
                        <!-- try to find it in the nymlist -->
                        <xsl:copy-of select="oape:look-up-nym-and-mark-up-name($v_word, $v_file-nyms, $p_id-change)"/>
<!--                        <xsl:text> </xsl:text>-->
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- fallback: return input -->
            <xsl:otherwise>
                <xsl:value-of select="$v_input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:look-up-nym-and-mark-up-name">
        <xsl:param as="xs:string" name="p_input"/>
        <xsl:param name="p_authority-file"/>
        <xsl:param name="p_id-change"/>
        <!-- try to find it in the nymlist -->
        <xsl:choose>
            <xsl:when test="$p_authority-file/descendant::tei:listNym/tei:nym/tei:form = $p_input">
                <!-- <xsl:message>
                    <xsl:text>found </xsl:text>
                    <xsl:value-of select="$p_input"/>
                    <xsl:text> in nymList</xsl:text>
                </xsl:message> -->
                <xsl:variable name="v_nymlist" select="$v_file-nyms/descendant::tei:listNym[tei:nym/tei:form = $p_input]"/>
                <xsl:variable name="v_type" select="$v_nymlist/@type"/>
                <!-- establish the kind of nym -->
                <xsl:choose>
                    <xsl:when test="$v_type = ('title', 'honorific', 'nobility')">
                        <xsl:element name="tei:roleName">
                            <xsl:attribute name="type" select="$v_type"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:value-of select="$p_input"/>
                        </xsl:element>
                        <xsl:text> </xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$p_input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:name-remove-addnames">
        <xsl:param name="p_persname"/>
        <xsl:param name="p_id-change"/>
        <xsl:element name="tei:persName">
            <xsl:apply-templates select="$p_persname/@xml:lang"/>
            <!-- document change -->
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            <!-- the flattened string should point back to its origin -->
                <xsl:if test="$p_persname/@xml:id">
                    <xsl:attribute name="corresp" select="concat('#',$p_persname/@xml:id)"/>
                </xsl:if>
            <xsl:attribute name="type" select="'noAddName'"/>
            <!-- generate xml:id -->
            <xsl:attribute name="xml:id" select="oape:generate-xml-id($p_persname)"/>
            <xsl:apply-templates select="$p_persname/tei:surname | $p_persname/tei:forename" mode="m_no-ids"/>
        </xsl:element>
    </xsl:function>
    <xsl:function name="oape:name-flattened">
        <xsl:param name="p_persname"/>
        <xsl:param name="p_id-change"/>
        <xsl:variable name="v_persname">
            <xsl:value-of select="$p_persname"/>
        </xsl:variable>
        <xsl:element name="persName">
                <xsl:apply-templates select="$p_persname/@xml:lang"/>
                <!-- document change -->
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            <!-- the flattened string should point back to its origin -->
                <xsl:if test="$p_persname/@xml:id">
                    <xsl:attribute name="corresp" select="concat('#',$p_persname/@xml:id)"/>
                </xsl:if>
            <xsl:attribute name="type" select="'flattened'"/>
            <!-- generate xml:id -->
            <xsl:attribute name="xml:id" select="oape:generate-xml-id($p_persname)"/>
                <xsl:value-of select="oape:string-remove-spaces(oape:string-normalise-characters($v_persname))"/>
            </xsl:element>
    </xsl:function>
    
    <!-- replicate everything except @xml:id -->
    <xsl:template match="@*[not(name() = 'xml:id')] | node()" mode="m_no-ids">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*[not(name() = 'xml:id')] | node()" mode="m_no-ids"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
