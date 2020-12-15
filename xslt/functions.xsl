<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
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
        <xsl:param as="xs:string" name="p_input"/>
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
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:param name="p_authority-file"/>
        <xsl:variable name="v_local-uri-scheme" select="concat($p_local-authority, ':pers:')"/>
        <xsl:variable name="v_authority">
            <xsl:choose>
                <xsl:when test="contains($p_idno, 'viaf:')">
                    <xsl:text>VIAF</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$p_local-authority"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_idno">
            <xsl:choose>
                <xsl:when test="contains($p_idno, 'viaf:')">
                    <xsl:value-of select="replace($p_idno, '.*viaf:(\d+).*', '$1')"/>
                </xsl:when>
                <xsl:when test="contains($p_idno, $v_local-uri-scheme)">
                    <xsl:value-of select="replace($p_idno, concat('.*', $v_local-uri-scheme, '(\d+).*'), '$1')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!--<xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>oape:get-person-from-authority-file: $v_authority="</xsl:text><xsl:value-of select="$v_authority"/><xsl:text>" and $v_idno="</xsl:text><xsl:value-of select="$v_idno"/><xsl:text>"</xsl:text>
            </xsl:message>
        </xsl:if>-->
        <xsl:choose>
            <xsl:when test="$p_authority-file//tei:person/tei:idno[@type = $v_authority] = $v_idno">
                <xsl:copy-of select="$p_authority-file//tei:person[tei:idno[@type = $v_authority] = $v_idno]"/>
            </xsl:when>
            <!-- even though the input claims that there is an entry in the authority file, there isn't -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>There is no person with the ID </xsl:text>
                    <xsl:value-of select="$v_idno"/>
                    <xsl:text> in the authority file</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- this function queries a local authority file with an OpenArabicPE or VIAF ID and returns a <tei:person> -->
    <xsl:function name="oape:get-entity-from-authority-file">
        <!-- input: entity such as <persName>, <orgName>, or <placeName> node -->
        <xsl:param name="p_entity"/>
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:param name="p_authority-file"/>
        <xsl:variable name="v_ref" select="$p_entity/@ref"/>
        <xsl:variable name="v_entity-type">
            <xsl:choose>
                <xsl:when test="name($p_entity) = 'persName'">
                    <xsl:text>pers</xsl:text>
                </xsl:when>
                <xsl:when test="name($p_entity) = 'orgName'">
                    <xsl:text>org</xsl:text>
                </xsl:when>
                <xsl:when test="name($p_entity) = 'placeName'">
                    <xsl:text>place</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="no">
                        <xsl:text>the input type cannot be looked up</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_local-uri-scheme" select="concat($p_local-authority, $v_entity-type)"/>
        <xsl:choose>
            <!-- check if the entity already links to an authority file by means of the @ref attribute -->
            <xsl:when test="$p_entity/@ref != ''">
                <xsl:variable name="v_authority">
                    <xsl:choose>
                        <xsl:when test="contains($v_ref, 'viaf:')">
                            <xsl:text>VIAF</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'geon:')">
                            <xsl:text>geon</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$p_local-authority"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="v_idno">
                    <xsl:choose>
                        <xsl:when test="contains($v_ref, 'viaf:')">
                            <xsl:value-of select="replace($v_ref, '.*viaf:(\d+).*', '$1')"/>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'geon:')">
                            <xsl:value-of select="replace($v_ref, '.*geon:(\d+).*', '$1')"/>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, $v_local-uri-scheme)">
                            <xsl:value-of select="replace($v_ref, concat('.*', $v_local-uri-scheme, '(\d+).*'), '$1')"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$v_entity-type = 'pers'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:person/tei:idno[@type = $v_authority] = $v_idno">
                                <xsl:copy-of select="$p_authority-file//tei:person[tei:idno[@type = $v_authority] = $v_idno]"/>
                            </xsl:when>
                            <!-- even though the input claims that there is an entry in the authority file, there isn't -->
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>There is no person with the ID </xsl:text>
                                    <xsl:value-of select="$v_idno"/>
                                    <xsl:text> in the authority file</xsl:text>
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'org'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:org/tei:idno[@type = $v_authority] = $v_idno">
                                <xsl:copy-of select="$p_authority-file//tei:org[tei:idno[@type = $v_authority] = $v_idno]"/>
                            </xsl:when>
                            <!-- even though the input claims that there is an entry in the authority file, there isn't -->
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>There is no org with the ID </xsl:text>
                                    <xsl:value-of select="$v_idno"/>
                                    <xsl:text> in the authority file</xsl:text>
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'place'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:place/tei:idno[@type = $v_authority] = $v_idno">
                                <xsl:copy-of select="$p_authority-file//tei:place[tei:idno[@type = $v_authority] = $v_idno]"/>
                            </xsl:when>
                            <!-- even though the input claims that there is an entry in the authority file, there isn't -->
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>There is no place with the ID </xsl:text>
                                    <xsl:value-of select="$v_idno"/>
                                    <xsl:text> in the authority file</xsl:text>
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <!-- fallback message -->
                    <xsl:otherwise>
                        <!-- one cannot use a boolean value if the default result is non-boolean -->
                        <xsl:value-of select="'false()'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- check if the string is found in the authority file -->
            <xsl:otherwise>
                <xsl:variable name="v_name-flat" select="oape:string-normalise-characters(string($p_entity))"/>
                <xsl:choose>
                    <xsl:when test="$v_entity-type = 'pers'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:person[tei:persName = $v_name-flat]">
                                <xsl:copy-of select="$p_authority-file/descendant::tei:person[tei:persName = $v_name-flat][1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>The persName </xsl:text>
                                    <xsl:value-of select="$p_entity"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'false()'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'org'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:org[tei:orgName = $v_name-flat]">
                                <xsl:copy-of select="$p_authority-file/descendant::tei:org[tei:orgName = $v_name-flat][1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>The orgName </xsl:text>
                                    <xsl:value-of select="$p_entity"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'false()'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'place'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:place[tei:placeName = $v_name-flat]">
                                <xsl:copy-of select="$p_authority-file/descendant::tei:place[tei:placeName = $v_name-flat][1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>The placeName </xsl:text>
                                    <xsl:value-of select="$p_entity"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'false()'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <!-- fallback message -->
                    <xsl:otherwise>
                        <!-- one cannot use a boolean value if the default result is non-boolean -->
                        <xsl:value-of select="'false()'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
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
    <!-- identity transform -->
    <xsl:template match="node() | @*" mode="m_identity-transform">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- problem: any mark-up from the input will be removed -->
    <!-- SOLVED: this strips symbols such as .,-' out of strings -->
    <xsl:function name="oape:string-mark-up-names">
        <xsl:param as="xs:string" name="p_input"/>
        <xsl:param name="p_id-change"/>
        <xsl:variable name="v_input" select="oape:string-normalise-characters($p_input)"/>
        <xsl:choose>
            <!-- 1. test for nisba -->
            <xsl:when test="matches($v_input, '^(.+\s)*(ال\w+ي)$')">
                <!--<xsl:message>
                    <xsl:value-of select="$v_input"/>
                    <xsl:text> contains a nisba</xsl:text>
                </xsl:message>-->
                <xsl:analyze-string regex="(ال\w+ي)$" select="$v_input">
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
            <!-- 2. test for nasab -->
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
            <!-- 3. kunya -->
            <xsl:when test="matches($v_input, '^(.+\s)*(ابو|ابي|ابا)\s(.+)$')">
                <!--<xsl:message>
                    <xsl:value-of select="$v_input"/>
                    <xsl:text> contains a kunya</xsl:text>
                </xsl:message>-->
                <xsl:analyze-string regex="(ابو|ابي|ابا)\s(.+)$" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:variable name="v_trailing" select="regex-group(2)"/>
                        <xsl:element name="tei:addName">
                            <xsl:attribute name="type" select="'kunyah'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:element name="tei:nameLink">
                                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                                <xsl:value-of select="regex-group(1)"/>
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
            <!-- test if a single word is found in a nymlist -->
            <xsl:when test="matches($v_input, '^(.+\s)*(\w+)(\s.+)*$')">
                <xsl:analyze-string regex="(\w+)(\s*)" select="$v_input">
                    <!-- single word match -->
                    <xsl:matching-substring>
                        <xsl:variable name="v_word" select="regex-group(1)"/>
                        <xsl:variable name="v_trailing-space" select="regex-group(2)"/>
                        <!-- try to find it in the nymlist -->
                        <xsl:copy-of select="oape:look-up-nym-and-mark-up-name($v_word, $v_file-nyms, $p_id-change)"/>
                        <xsl:value-of select="$v_trailing-space"/>
                        <!-- debugging -->
                        <!--<xsl:message>
                            <xsl:value-of select="$v_word"/>
                        </xsl:message>-->
                    </xsl:matching-substring>
                    <!-- there ARE non-matching substrings -->
                    <!-- otherwise this strips symbols such as .,-' out of strings -->
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                        <!--                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>-->
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- fallback: return input -->
            <xsl:otherwise>
                <xsl:value-of select="$v_input"/>
                <xsl:text> </xsl:text>
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
                    <xsl:when test="$v_type = ('title', 'honorific', 'nobility', 'rank')">
                        <xsl:element name="tei:roleName">
                            <xsl:attribute name="type" select="$v_type"/>
                            <xsl:if test="$v_nymlist/@subtype">
                                <xsl:copy-of select="$v_nymlist/@subtype"/>
                            </xsl:if>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:value-of select="$p_input"/>
                        </xsl:element>
                        <xsl:text> </xsl:text>
                    </xsl:when>
                    <!-- fallback -->
                    <xsl:otherwise>
                        <xsl:value-of select="$p_input"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- fallback -->
            <xsl:otherwise>
                <xsl:value-of select="$p_input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:name-remove-addnames">
        <xsl:param name="p_persname"/>
        <xsl:param name="p_id-change"/>
        <xsl:variable name="v_persname" select="$p_persname/descendant-or-self::tei:persName"/>
        <!-- write content to variable in order to then generate a unique @xml:id -->
        <xsl:variable name="v_output">
            <xsl:element name="tei:persName">
                <!-- document change -->
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                <xsl:attribute name="type" select="'noAddName'"/>
                <!-- reproduce language attributes -->
                <xsl:apply-templates mode="m_identity-transform" select="$v_persname/@xml:lang"/>
                <xsl:apply-templates mode="m_no-ids" select="$v_persname/tei:surname | $v_persname/tei:forename"/>
            </xsl:element>
        </xsl:variable>
        <!-- output -->
        <xsl:copy select="$v_output/tei:persName">
            <!-- generate xml:id -->
            <xsl:attribute name="xml:id" select="oape:generate-xml-id($v_output/tei:persName)"/>
            <xsl:apply-templates mode="m_identity-transform" select="$v_output/tei:persName/@* | $v_output/tei:persName/node()"/>
        </xsl:copy>
    </xsl:function>
    <xsl:function name="oape:name-flattened">
        <xsl:param name="p_persname"/>
        <xsl:param name="p_id-change"/>
        <xsl:variable name="v_persname" select="$p_persname/descendant-or-self::tei:persName"/>
        <!-- write content to variable in order to then generate a unique @xml:id -->
        <xsl:variable name="v_output">
            <xsl:element name="tei:persName">
                <!-- document change -->
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                <xsl:attribute name="type" select="'flattened'"/>
                <!-- the flattened string should point back to its origin -->
                <xsl:if test="$v_persname/@xml:id">
                    <xsl:attribute name="corresp" select="concat('#', $v_persname/@xml:id)"/>
                </xsl:if>
                <!-- reproduce language attributes -->
                <xsl:apply-templates mode="m_identity-transform" select="$v_persname/@xml:lang"/>
                <!-- content -->
                <xsl:value-of select="oape:string-remove-spaces(oape:string-normalise-characters($v_persname))"/>
            </xsl:element>
        </xsl:variable>
        <!-- output -->
        <xsl:copy select="$v_output/tei:persName">
            <!-- generate xml:id -->
            <xsl:attribute name="xml:id" select="oape:generate-xml-id($v_output/tei:persName)"/>
            <xsl:apply-templates mode="m_identity-transform" select="$v_output/tei:persName/@*"/>
            <xsl:apply-templates mode="m_identity-transform" select="$v_output/tei:persName/node()"/>
        </xsl:copy>
    </xsl:function>
    <!-- replicate everything except @xml:id -->
    <xsl:template match="node() | @*" mode="m_no-ids">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates mode="m_no-ids" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id" mode="m_no-ids" priority="10"/>
    <!-- delete nodes -->
    <xsl:template match="node() | @*" mode="m_delete"/>
    <!-- this function adds internal markup to a persName node -->
    <!-- output is a persName node -->
    <!-- SOLVED: this strips symbols such as .,-' out of strings -->
    <xsl:function name="oape:name-add-markup">
        <xsl:param name="p_persname"/>
        <xsl:apply-templates mode="m_mark-up" select="$p_persname"/>
    </xsl:function>
    <xsl:template match="tei:persName | tei:forename | tei:surname | tei:addName | tei:roleName | @*" mode="m_mark-up" priority="10">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <!-- add @xml:id if it isn't there -->
            <xsl:if test="not(@xml:id)">
                <xsl:attribute name="xml:id" select="oape:generate-xml-id(.)"/>
            </xsl:if>
            <xsl:apply-templates mode="m_mark-up" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:persName[not(@type = ('flattened', 'noAddName'))]/text() | tei:forename/text() | tei:surname/text()" mode="m_mark-up">
        <!-- SOLVED: this strips symbols such as .,-' out of strings -->
        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
    </xsl:template>
    <xsl:template match="tei:roleName | tei:nameLink" mode="m_remove-rolename"/>
    <xsl:template match="tei:persName | tei:forename | tei:surname | tei:addName | @*" mode="m_remove-rolename">
        <xsl:copy>
            <xsl:apply-templates mode="m_remove-rolename" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- this function takes a <tei:persName> as input, tries to look it up in an authority file and returns a <tei:persName> -->
    <xsl:function name="oape:link-persname-to-authority-file">
        <xsl:param name="p_persname"/>
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:param name="p_authority-file"/>
        <xsl:param name="p_add-mark-up"/>
        <!-- flatened version of the persName without non-word characters -->
        <xsl:variable name="v_name-flat" select="oape:string-remove-spaces(oape:string-normalise-characters($p_persname))"/>
        <!-- remove all roleNames, flatten and test again -->
        <!-- test if the flattened name is present in the authority file -->
        <xsl:variable name="v_corresponding-person">
            <xsl:choose>
                <!-- test if this node already points to an authority file -->
                <xsl:when test="$p_persname/@ref">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The input already points to an authority file</xsl:message>
                    </xsl:if>
                    <!-- there seems to be a problem with this function -->
                    <xsl:copy-of select="oape:get-person-from-authority-file($p_persname/@ref, $p_local-authority, $p_authority-file)"/>
                </xsl:when>
                <!-- test if the name is found in the authority file -->
                <xsl:when test="$p_authority-file//tei:person[tei:persName[@type = 'flattened'] = $v_name-flat]">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The flattened input has been found in the authority file</xsl:message>
                    </xsl:if>
                    <xsl:copy-of select="$p_authority-file/descendant::tei:person[tei:persName[@type = 'flattened'] = $v_name-flat][1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The input has not been found in the authority file</xsl:message>
                    </xsl:if>
                    <!-- one cannot use a boolean value if the default result is non-boolean -->
                    <xsl:value-of select="'false()'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- name is found in the authority file. it will be linked and potentially updated -->
            <xsl:when test="$v_corresponding-person/descendant-or-self::tei:person">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>"</xsl:text>
                        <xsl:value-of select="normalize-space($p_persname)"/>
                        <xsl:text>" is present in the authority file and will be linked</xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- get @xml:id of corresponding entry in authority file -->
                <xsl:variable name="v_corresponding-xml-id" select="substring-after($v_corresponding-person//tei:persName[@type = 'flattened'][. = $v_name-flat][1]/@corresp, '#')"/>
                <!-- construct @ref pointing to the corresponding entry -->
                <xsl:variable name="v_ref">
                    <xsl:value-of select="concat($p_local-authority, ':pers:', $v_corresponding-person/descendant::tei:idno[@type = $p_local-authority][1])"/>
                    <xsl:if test="$v_corresponding-person/descendant::tei:idno[@type = 'VIAF']">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="concat('viaf:', $v_corresponding-person/descendant::tei:idno[@type = 'VIAF'][1])"/>
                    </xsl:if>
                </xsl:variable>
                <!-- replicate node -->
                <xsl:copy select="$p_persname">
                    <!-- replicate attributes -->
                    <xsl:apply-templates mode="m_identity-transform" select="$p_persname/@*"/>
                    <!-- add references to IDs -->
                    <xsl:attribute name="ref" select="$v_ref"/>
                    <!-- document change -->
                    <!-- this test does not catch all changes -->
                    <xsl:if
                        test="($p_persname/@ref != $v_ref) or ($p_persname/descendant::node() != $v_corresponding-person/descendant-or-self::tei:persName[@xml:id = $v_corresponding-xml-id]/descendant::node())">
                        <xsl:choose>
                            <xsl:when test="not($p_persname/@change)">
                                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="m_documentation" select="$p_persname/@change"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    <!-- replicate content -->
                    <!-- NOTE: one could try to add mark-up from $v_corresponding-person -->
                    <xsl:choose>
                        <xsl:when test="$p_add-mark-up = false()">
                            <xsl:apply-templates mode="m_identity-transform" select="node()"/>
                        </xsl:when>
                        <xsl:when test="$p_add-mark-up = true()">
                            <!-- test of corresponding person contains mark-up -->
                            <!-- SOLVED: this strips symbols such as .,-' out of strings -->
                            <xsl:choose>
                                <xsl:when test="$v_corresponding-person/descendant-or-self::tei:persName[@xml:id = $v_corresponding-xml-id]/node()[namespace::tei]">
                                    <xsl:apply-templates mode="m_copy-from-authority-file" select="$v_corresponding-person/descendant-or-self::tei:persName[@xml:id = $v_corresponding-xml-id]/node()"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates mode="m_identity-transform" select="node()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                    </xsl:choose>
                </xsl:copy>
            </xsl:when>
            <!-- fallback: name is not found in the authority file -->
            <xsl:when test="$v_corresponding-person = 'false()'">
                <!--                <xsl:if test="$p_verbose = true()">-->
                <xsl:message>
                    <xsl:text> The input "</xsl:text>
                    <xsl:value-of select="normalize-space($p_persname)"/>
                    <xsl:text>" was not found in authority file.</xsl:text>
                </xsl:message>
                <!--</xsl:if>-->
                <xsl:copy select="$p_persname">
                    <xsl:apply-templates mode="m_identity-transform" select="$p_persname/@* | $p_persname/node()"/>
                </xsl:copy>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    <!-- copy from authority file should not include @xml:id and @change -->
    <xsl:template match="node() | @*" mode="m_copy-from-authority-file">
        <xsl:copy>
            <xsl:apply-templates mode="m_copy-from-authority-file" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_copy-from-authority-file" priority="10"/>
    <!-- document changes on changed elements by means of the @change attribute linking to the @xml:id of the <tei:change> element -->
    <xsl:template match="@change" mode="m_documentation">
        <xsl:attribute name="change">
            <xsl:value-of select="concat(., ' #', $p_id-change)"/>
        </xsl:attribute>
    </xsl:template>
</xsl:stylesheet>
