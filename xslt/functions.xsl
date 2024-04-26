<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" method="xml" omit-xml-declaration="no"/>
    <xsl:import href="parameters.xsl"/>
    <xsl:import href="../../../xslt-calendar-conversion/functions/date-functions.xsl"/>
    <xsl:include href="query-viaf.xsl"/>
    <xsl:include href="query-geonames.xsl"/>
    <xsl:import href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    <!-- debugging -->
    <!--<xsl:template match="text()"><xsl:value-of select="oape:string-normalise-arabic(.)"/></xsl:template>-->
    <!--<xsl:template match="/"><!-\-        <xsl:apply-templates selsect="descendant::tei:date" mode="m_debug"/>-\-><xsl:apply-templates select="descendant::tei:title" mode="m_debug"/></xsl:template>-->
    <xsl:template match="tei:title[@ref]" mode="m_debug">
        <xsl:copy-of select="oape:get-entity-from-authority-file(., $p_local-authority, $v_bibliography)"/>
    </xsl:template>
    <xsl:template match="tei:date" mode="m_debug">
        <xsl:value-of select="oape:date-get-onset(.)"/>
        <xsl:text> - </xsl:text>
        <xsl:value-of select="oape:date-get-terminus(.)"/>
    </xsl:template>
    <xsl:function name="oape:string-normalise-characters">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_self" select="normalize-space(replace(oape:string-remove-harakat($p_input), $p_string-match, $p_string-replace))"/>
        <!--        <xsl:value-of select="replace($v_self, '\W', '')"/>-->
        <xsl:value-of select="$v_self"/>
    </xsl:function>
    <!-- this function normalises an Arabic input string by replacing all hamzas on a carrier with the carrier letter, and final haʾ with taʾ marbuta. It also removes all harakat and shadda -->
    <xsl:function name="oape:string-normalise-arabic">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_string-alif" select="'([إأآ])'"/>
        <xsl:variable name="v_string-ya" select="'([ئىي])'"/>
        <xsl:variable name="v_string-waw" select="'([ؤ])'"/>
        <xsl:variable name="v_string-ha" select="'([ةه])'"/>
        <!-- wrapping of output in a variable seems necessary as it is otherwise a sequence of strings -->
        <xsl:variable name="v_output">
            <xsl:analyze-string regex="{concat($v_string-alif, '|', $v_string-ya, '|', $v_string-waw, '|', $v_string-ha)}" select="$p_input">
                <xsl:matching-substring>
                    <xsl:choose>
                        <xsl:when test="matches(., $v_string-alif)">
                            <xsl:value-of select="replace(., $v_string-alif, 'ا')"/>
                        </xsl:when>
                        <xsl:when test="matches(., $v_string-ya)">
                            <xsl:value-of select="replace(., $v_string-ya, 'ي')"/>
                        </xsl:when>
                        <xsl:when test="matches(., $v_string-waw)">
                            <xsl:value-of select="replace(., $v_string-waw, 'و')"/>
                        </xsl:when>
                        <xsl:when test="matches(., $v_string-ha)">
                            <xsl:value-of select="replace(., $v_string-ha, 'ة')"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:value-of select="oape:string-remove-harakat($v_output)"/>
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
    <xsl:function name="oape:string-normalise-arabic-alphabet">
        <xsl:param as="xs:string" name="p_input"/>
        <!-- unicode encodings, transliterations -->
        <!-- macOS: Arabic -->
        <xsl:variable name="v_alphabet-fa-mac" select="'اآأإبتثحخجدذرزسشصضطظعغفقکلمنهوؤيئیةء'"/>
        <!-- macOS: Arabic - North Africa -->
        <xsl:variable name="v_alphabet-ar-mac" select="'اآأإبتثحخجدذرزسشصضطظعغفقكلمنهوؤيئىةء'"/>
        <xsl:value-of select="translate($p_input, $v_alphabet-fa-mac, $v_alphabet-ar-mac)"/>
    </xsl:function>
    <xsl:function name="oape:string-parse-names">
        <xsl:param as="node()" name="p_input"/>
        <xsl:variable name="v_preprocessed">
            <xsl:for-each select="$p_input/child::node()">
                <xsl:value-of select="."/>
                <xsl:if test="following-sibling::node()">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="normalize-space($v_preprocessed)"/>
    </xsl:function>
    <!-- this function queries a local authority file
        - input: an entity name such as <persName>, <orgName>, <placeName>or <title>- output: an entity: such as <person>, <org>, <place>or <biblStruct>-->
    <!-- PROBLEMs: 
        + entities pointing with a @ref to another authority file are missed
        + what about multiple matches in the authority file?
            - should we return all?
            - currently, I settled on returning the first hit, but this should be probably toggled by an additional parameter
                - for bibls we return more than one hit!
        + it seems that the entity is compiled based on @next and @prev attributes, which we don't want to happen if we query authority files by means of an ID
            - debugging showed that this is not the case
    -->
    <!-- if no match is found, the function returns 'NA' -->
    <xsl:function name="oape:get-entity-from-authority-file">
        <!-- input: entity such as <persName>, <orgName>, <placeName> or <title> node -->
        <xsl:param as="node()" name="p_entity-name"/>
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:param name="p_authority-file"/>
        <!--        <xsl:if test="$p_entity-name/@ref or $p_entity-name != ''">-->
        <!-- this is a rather ridiculous hack, but I don't need change IDs in the context of this function -->
        <xsl:variable name="v_id-change" select="'a1'"/>
        <xsl:variable name="v_ref">
            <xsl:choose>
                <xsl:when test="$p_entity-name/@ref">
                    <xsl:value-of select="$p_entity-name/@ref"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>NA</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_entity-type">
            <xsl:choose>
                <xsl:when test="local-name($p_entity-name) = 'persName'">
                    <xsl:text>pers</xsl:text>
                </xsl:when>
                <xsl:when test="local-name($p_entity-name) = 'orgName'">
                    <xsl:text>org</xsl:text>
                </xsl:when>
                <xsl:when test="local-name($p_entity-name) = 'placeName'">
                    <xsl:text>place</xsl:text>
                </xsl:when>
                <xsl:when test="local-name($p_entity-name) = 'title'">
                    <xsl:text>bibl</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate="no">
                        <xsl:text>the input type (</xsl:text>
                        <xsl:value-of select="name($p_entity-name)"/>
                        <xsl:text>) cannot be looked up</xsl:text>
                    </xsl:message>
                    <xsl:text>NA</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- establish who was responsible for the mark-up -->
        <xsl:variable name="v_resp">
            <xsl:call-template name="t_resp">
                <xsl:with-param name="p_node" select="$p_entity-name"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- debugging -->
        <xsl:if test="$p_debug = true()">
            <xsl:message>
                <xsl:text>oape:get-entity-from-authority-file</xsl:text>
            </xsl:message>
            <xsl:message>
                <xsl:text>Input: </xsl:text>
                <xsl:copy-of select="$p_entity-name"/>
            </xsl:message>
            <!--<xsl:message>
                <xsl:text>v_resp: </xsl:text>
                <xsl:value-of select="$v_resp"/>
            </xsl:message>-->
        </xsl:if>
        <xsl:if test="$p_verbose = true() and $p_ignore-existing-refs = true()">
            <xsl:message>
                <xsl:text>As the user opted to ignore existing @ref attributes, the entity retrieval from the authority file will be solely based on the entity name</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:choose>
            <!-- check if the entity already links to an authority file by means of the @ref attribute -->
            <xsl:when test="not($v_ref = 'NA') and ($p_ignore-existing-refs = false() or $v_resp = 'ref_manual')">
                <xsl:variable name="v_authority">
                    <!-- order matters here: while our local IDs must be unique, we can have multiple entries pointing to the same ID in an external reference file -->
                    <xsl:choose>
                        <xsl:when test="contains($v_ref, 'jaraid:')">
                            <xsl:text>jaraid</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'oape:')">
                            <xsl:text>oape</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'damascus:')">
                            <xsl:text>damascus</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'viaf:')">
                            <xsl:text>VIAF</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, concat($p_acronym-geonames, ':'))">
                            <xsl:value-of select="$p_acronym-geonames"/>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'geonames.org')">
                            <xsl:value-of select="$p_acronym-geonames"/>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'oclc:')">
                            <xsl:text>OCLC</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches($v_ref, '^http')">
                            <xsl:text>url</xsl:text>
                        </xsl:when>
                        <xsl:when test="matches($v_ref, '^\w+:')">
                            <xsl:value-of select="replace($v_ref, '^(\w+):.+$', '$1')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$p_local-authority"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="v_local-uri-scheme" select="concat($v_authority, ':', $v_entity-type, ':')"/>
                <xsl:variable name="v_idno">
                    <xsl:choose>
                        <!-- the sort order here must match the one in $v_authority -->
                        <xsl:when test="contains($v_ref, concat($v_authority, ':', $v_entity-type, ':'))">
                            <xsl:value-of select="replace($v_ref, concat('.*', $v_authority, ':', $v_entity-type, ':', '(\w+).*'), '$1')"/>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'viaf:')">
                            <xsl:value-of select="replace($v_ref, '.*viaf:(\d+).*', '$1')"/>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, concat($p_acronym-geonames, ':'))">
                            <xsl:value-of select="replace($v_ref, concat('.*', $p_acronym-geonames, ':(\d+).*'), '$1')"/>
                        </xsl:when>
                        <xsl:when test="matches($v_ref, 'geonames.org/\d+')">
                            <xsl:value-of select="replace($v_ref, '.*geonames.org/(\d+).*', '$1')"/>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'oclc:')">
                            <xsl:value-of select="replace($v_ref, '.*oclc:(\d+).*', '$1')"/>
                        </xsl:when>
                        <xsl:when test="matches($v_ref, '^http')">
                            <xsl:value-of select="$v_ref"/>
                        </xsl:when>
                        <xsl:when test="matches($v_ref, '^\w+:')">
                            <xsl:value-of select="replace($v_ref, '^(\w+):(.+)$', '$2')"/>
                        </xsl:when>
                        <!--<xsl:when test="contains($v_ref, $v_local-uri-scheme)"><!-\- local IDs in Project Jaraid are not nummeric for biblStructs -\-><xsl:value-of select="replace($v_ref, concat('.*', $v_local-uri-scheme, '(\w+).*'), '$1')"/></xsl:when>-->
                        <xsl:otherwise>
                            <xsl:text>NA</xsl:text>
                        </xsl:otherwise>
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
                                    <xsl:text>There is no person with the </xsl:text>
                                    <xsl:value-of select="$v_authority"/>
                                    <xsl:text>-ID </xsl:text>
                                    <xsl:value-of select="$v_idno"/>
                                    <xsl:text> in the authority file</xsl:text>
                                </xsl:message>
                                <xsl:value-of select="'NA'"/>
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
                                    <xsl:text>There is no org with the </xsl:text>
                                    <xsl:value-of select="$v_authority"/>
                                    <xsl:text>-ID </xsl:text>
                                    <xsl:value-of select="$v_idno"/>
                                    <xsl:text> in the authority file</xsl:text>
                                </xsl:message>
                                <xsl:value-of select="'NA'"/>
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
                                    <xsl:text>There is no place with the </xsl:text>
                                    <xsl:value-of select="$v_authority"/>
                                    <xsl:text>-ID </xsl:text>
                                    <xsl:value-of select="$v_idno"/>
                                    <xsl:text> in the authority file. Add </xsl:text>
                                    <xsl:element name="tei:place">
                                        <xsl:element name="tei:placeName">
                                            <xsl:value-of select="$p_entity-name"/>
                                        </xsl:element>
                                        <xsl:element name="tei:idno">
                                            <xsl:attribute name="type" select="$v_authority"/>
                                            <xsl:value-of select="$v_idno"/>
                                        </xsl:element>
                                    </xsl:element>
                                </xsl:message>
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'bibl'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:biblStruct/tei:monogr/tei:idno[@type = $v_authority] = $v_idno">
                                <xsl:copy-of select="$p_authority-file//tei:biblStruct[tei:monogr/tei:idno[@type = $v_authority] = $v_idno]"/>
                            </xsl:when>
                            <!-- even though the input claims that there is an entry in the authority file, there isn't -->
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>There is no biblStruct with the </xsl:text>
                                    <xsl:value-of select="$v_authority"/>
                                    <xsl:text>-ID </xsl:text>
                                    <xsl:value-of select="$v_idno"/>
                                    <xsl:text> in the authority file</xsl:text>
                                </xsl:message>
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <!-- fallback message -->
                    <xsl:otherwise>
                        <!-- one cannot use a boolean value if the default result is non-boolean -->
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- check if the string is found in the authority file -->
            <xsl:otherwise>
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>The input carries no @ref attribute or the value is 'NA'</xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- this fails for nested entities -->
                <xsl:variable name="v_name-normalised" select="normalize-space(oape:string-normalise-arabic(string($p_entity-name)))"/>
                <xsl:choose>
                    <xsl:when test="$v_entity-type = 'pers'">
                        <xsl:variable name="v_name-flattened" select="oape:name-flattened($p_entity-name, '', $v_id-change)"/>
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>$v_name-flattened: </xsl:text>
                                <xsl:copy-of select="$v_name-flattened"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:variable name="v_name-marked-up" select="oape:name-add-markup($p_entity-name)"/>
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>$v_name-marked-up: </xsl:text>
                                <xsl:copy-of select="$v_name-marked-up"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:variable name="v_name-no-addnames" select="oape:name-remove-addnames($v_name-marked-up, '', $v_id-change)"/>
                        <xsl:variable name="v_name-no-addnames-flattened" select="oape:name-flattened($v_name-no-addnames, '', $v_id-change)"/>
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:person/tei:persName[oape:string-normalise-arabic(.) = $v_name-normalised]">
                                <xsl:if test="$p_debug = true()">
                                    <xsl:message>
                                        <xsl:text>The normalised name is found in the personography</xsl:text>
                                    </xsl:message>
                                </xsl:if>
                                <xsl:copy-of select="$p_authority-file/descendant::tei:person[tei:persName[oape:string-normalise-arabic(.) = $v_name-normalised]][1]"/>
                            </xsl:when>
                            <xsl:when test="$p_authority-file//tei:person[tei:persName = $v_name-flattened]">
                                <xsl:if test="$p_debug = true()">
                                    <xsl:message>
                                        <xsl:text>The flattened name is found in the personography</xsl:text>
                                    </xsl:message>
                                </xsl:if>
                                <xsl:copy-of select="$p_authority-file/descendant::tei:person[tei:persName = $v_name-flattened][1]"/>
                            </xsl:when>
                            <xsl:when test="$p_authority-file//tei:person[tei:persName = $v_name-no-addnames-flattened]">
                                <xsl:if test="$p_debug = true()">
                                    <xsl:message>
                                        <xsl:text>The flattened name without addName components is found in the personography</xsl:text>
                                    </xsl:message>
                                </xsl:if>
                                <xsl:copy-of select="$p_authority-file/descendant::tei:person[tei:persName = $v_name-no-addnames-flattened][1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>The persName </xsl:text>
                                    <xsl:value-of select="$p_entity-name"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
                                <!-- quick debugging -->
                                <!--<xsl:message><xsl:copy-of select="$v_name-marked-up"/><xsl:copy-of select="$v_name-no-addnames"/></xsl:message>-->
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'org'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:org/tei:orgName[oape:string-normalise-arabic(.) = $v_name-normalised]">
                                <xsl:copy-of select="$p_authority-file/descendant::tei:org[tei:orgName[oape:string-normalise-arabic(.) = $v_name-normalised]][1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>The orgName </xsl:text>
                                    <xsl:value-of select="$p_entity-name"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'place'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:place/tei:placeName[oape:string-normalise-arabic(.) = $v_name-normalised]">
                                <xsl:copy-of select="$p_authority-file/descendant::tei:place[tei:placeName[oape:string-normalise-arabic(.) = $v_name-normalised]][1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>The placeName </xsl:text>
                                    <xsl:value-of select="$p_entity-name"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'bibl'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file/descendant::tei:biblStruct/tei:monogr/tei:title[oape:string-normalise-arabic(.) = $v_name-normalised]">
                                <!-- problem: this should return more than one match!!!!! -->
                                <xsl:copy-of select="$p_authority-file/descendant::tei:biblStruct[tei:monogr/tei:title[oape:string-normalise-arabic(.) = $v_name-normalised]]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <!-- fallback message -->
                    <xsl:otherwise>
                        <!-- one cannot use a boolean value if the default result is non-boolean -->
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <!--        </xsl:if>-->
    </xsl:function>
    <!-- query a local TEI bibliography for titles, editors, locations, IDs etc. -->
    <xsl:function name="oape:query-bibliography">
        <!-- input is a tei <title>node -->
        <xsl:param as="node()" name="title"/>
        <!-- $bibliography expects a document -->
        <xsl:param name="bibliography"/>
        <!-- $gazetteer expects a path to a file -->
        <xsl:param name="gazetteer"/>
        <!-- local authority -->
        <xsl:param as="xs:string" name="p_local-authority"/>
        <!-- values for $p_mode are 'pubPlace', 'location', 'name', 'local-authority', 'textLang', ID -->
        <xsl:param as="xs:string" name="p_output-mode"/>
        <!-- select a target language for toponyms -->
        <xsl:param as="xs:string" name="p_output-language"/>
        <!-- load data from authority file -->
        <!--<xsl:variable name="v_bibl" select="oape:get-biblstruct-from-bibliography($title, $p_local-authority, $bibliography)"/>-->
        <xsl:variable name="v_listbibl">
            <listBibl>
                <xsl:copy-of select="oape:get-entity-from-authority-file($title, $p_local-authority, $bibliography)"/>
            </listBibl>
        </xsl:variable>
        <xsl:variable name="v_bibl" select="$v_listbibl/descendant::tei:biblStruct[1]"/>
        <xsl:choose>
            <!-- test if more detailed data is available -->
            <xsl:when test="$v_bibl != 'NA'">
                <xsl:copy-of select="oape:query-biblstruct($v_bibl, $p_output-mode, $p_output-language, $gazetteer, $p_local-authority)"/>
            </xsl:when>
            <!-- return original input toponym if nothing else is found -->
            <xsl:when test="$p_output-mode = 'name'">
                <xsl:value-of select="normalize-space($title)"/>
            </xsl:when>
            <!-- otherwise: no location data -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>no bibliographic data found for </xsl:text>
                    <xsl:value-of select="normalize-space($title)"/>
                </xsl:message>
                <xsl:value-of select="'NA'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:query-biblstruct">
        <xsl:param as="node()" name="p_bibl"/>
        <!-- values for $p_mode are 'pubPlace', 'location', 'name', 'local-authority', 'textLang', ID -->
        <xsl:param as="xs:string" name="p_output-mode"/>
        <xsl:param as="xs:string" name="p_output-language"/>
        <xsl:param name="gazetteer"/>
        <xsl:param as="xs:string" name="p_local-authority"/>
        <!-- the publication place can be further looked up -->
        <xsl:variable name="v_pubPlace">
            <xsl:choose>
                <xsl:when test="$p_bibl/descendant::tei:pubPlace/tei:placeName[@ref]">
                    <xsl:copy-of select="$p_bibl/descendant::tei:pubPlace[tei:placeName[@ref]][1]/tei:placeName[@ref][1]"/>
                </xsl:when>
                <xsl:when test="$p_bibl/descendant::tei:pubPlace/tei:placeName">
                    <xsl:copy-of select="$p_bibl/descendant::tei:pubPlace[tei:placeName][1]/tei:placeName[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'NA'"/>
                    <!--                    <tei:placeName/>-->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Problem:
            - the content model allows for multiple <monogr> children of <biblStruct> 
        -->
        <xsl:variable name="v_monogr" select="$p_bibl/descendant::tei:monogr"/>
        <!-- dates: moved to the output modes, where they were needed -->
        <!-- languages -->
        <xsl:variable name="v_mainLang">
            <xsl:choose>
                <xsl:when test="$v_monogr/tei:textLang/@mainLang">
                    <xsl:value-of select="$v_monogr[tei:textLang/@mainLang][1]/tei:textLang/@mainLang"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'NA'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- return publication place -->
            <xsl:when test="$v_pubPlace = 'NA' and $p_output-mode = ('pubPlace', 'location', 'lat', 'long', 'id-location')">
                <xsl:value-of select="'NA'"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'pubPlace'">
                <xsl:value-of select="oape:query-gazetteer($v_pubPlace//tei:placeName[1], $gazetteer, $p_local-authority, 'name', $p_output-language)"/>
            </xsl:when>
            <!-- return location -->
            <xsl:when test="$p_output-mode = ('location', 'lat', 'long')">
                <xsl:value-of select="oape:query-gazetteer($v_pubPlace//tei:placeName[1], $gazetteer, $p_local-authority, $p_output-mode, '')"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-location'">
                <xsl:value-of select="oape:query-gazetteer($v_pubPlace//tei:placeName[1], $gazetteer, $p_local-authority, 'id', '')"/>
            </xsl:when>
            <!-- return IDs -->
            <xsl:when test="$p_output-mode = 'id'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:idno[@type = 'OCLC']">
                        <xsl:value-of select="concat('oclc:', $p_bibl/descendant::tei:idno[@type = 'OCLC'][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_bibl/descendant::tei:idno[@type = $p_acronym-wikidata]">
                        <xsl:value-of select="concat('wiki:', $p_bibl/descendant::tei:idno[@type = $p_acronym-wikidata][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_bibl/descendant::tei:idno[@type = 'DOI']">
                        <xsl:value-of select="concat('DOI:', $p_bibl/descendant::tei:idno[@type = 'DOI'][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_bibl/descendant::tei:idno[@type = $p_local-authority]">
                        <xsl:value-of select="concat($p_local-authority, ':bibl:', $p_bibl/descendant::tei:idno[@type = $p_local-authority][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_bibl/descendant::tei:idno">
                        <xsl:value-of select="concat($p_bibl/descendant::tei:idno[1]/@type, ':', $p_bibl/descendant::tei:idno[1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = ('id-local', $p_local-authority)">
                <xsl:value-of select="$p_bibl/descendant::tei:idno[@type = $p_local-authority][1]"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = ('id-oclc', 'oclc') and $p_bibl/descendant::tei:idno[@type = 'OCLC']">
                <xsl:value-of select="$p_bibl/descendant::tei:idno[@type = 'OCLC'][1]"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = ('id-wiki', 'wiki')">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:idno[@type = $p_acronym-wikidata]">
                        <xsl:value-of select="$p_bibl/descendant::tei:idno[@type = $p_acronym-wikidata][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'tei-ref'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:idno[not(@type = 'URI')]">
                        <xsl:variable name="v_temp">
                            <xsl:for-each-group group-by="@type" select="$p_bibl/descendant::tei:idno[not(@type = 'URI')]">
                                <xsl:sort order="ascending" select="current-grouping-key()"/>
                                <xsl:if test="current-grouping-key() = 'OCLC'">
                                    <xsl:value-of select="concat('oclc:', .)"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = $p_acronym-wikidata">
                                    <xsl:value-of select="concat('wiki:', .)"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'oape'">
                                    <xsl:value-of select="concat('oape:bibl:', .)"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'jaraid'">
                                    <xsl:value-of select="concat('jaraid:bibl:', .)"/>
                                </xsl:if>
                                <xsl:if test="position() != last()">
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                            </xsl:for-each-group>
                        </xsl:variable>
                        <xsl:value-of select="normalize-space($v_temp)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return the publication title in selected language -->
            <xsl:when test="$p_output-mode = ('name', 'title')">
                <xsl:choose>
                    <xsl:when test="$v_monogr/tei:title[@xml:lang = $p_output-language]">
                        <xsl:value-of select="normalize-space($v_monogr[tei:title[@xml:lang = $p_output-language]][1]/tei:title[@xml:lang = $p_output-language][1])"/>
                    </xsl:when>
                    <!-- possible transcriptions into other script -->
                    <xsl:when test="($p_output-language = 'ar') and ($v_monogr/tei:title[contains(@xml:lang, '-Arab-')])">
                        <xsl:value-of select="normalize-space($v_monogr[tei:title[contains(@xml:lang, '-Arab-')]][1]/tei:title[contains(@xml:lang, '-Arab-')][1])"/>
                    </xsl:when>
                    <!-- support transcriptions between scripts -->
                    <xsl:when test="$v_monogr/tei:title[contains(@xml:lang, concat('-', $p_output-language, '-'))]">
                        <xsl:value-of
                            select="normalize-space($v_monogr[tei:title[contains(@xml:lang, concat('-', $p_output-language, '-'))]][1]/tei:title[contains(@xml:lang, concat('-', $p_output-language, '-'))][1])"
                        />
                    </xsl:when>
                    <!-- fallback to main language of publication -->
                    <xsl:when test="$v_monogr/tei:title[@xml:lang = $v_mainLang]">
                        <xsl:value-of select="normalize-space($v_monogr[tei:title[@xml:lang = $v_mainLang]][1]/tei:title[@xml:lang = $v_mainLang][1])"/>
                    </xsl:when>
                    <!-- fallback: first title in any language -->
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space($v_monogr[1]/descendant-or-self::tei:title[1])"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return a tei:title node in selected language -->
            <xsl:when test="$p_output-mode = ('title-tei')">
                <xsl:element name="title">
                    <xsl:attribute name="level" select="$v_monogr/tei:title[@level][1]/@level"/>
                    <xsl:attribute name="ref" select="oape:query-biblstruct($p_bibl, 'tei-ref', '', '', $p_local-authority)"/>
                    <xsl:attribute name="xml:lang" select="$p_output-language"/>
                    <xsl:value-of select="oape:query-biblstruct($p_bibl, 'title', $p_output-language, '', $p_local-authority)"/>
                </xsl:element>
            </xsl:when>
            <!-- return language -->
            <xsl:when test="$p_output-mode = ('textLang', 'mainLang')">
                <xsl:value-of select="$v_mainLang"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'otherLangs'">
                <xsl:variable name="v_otherLangs">
                    <xsl:choose>
                        <xsl:when test="$v_monogr/tei:textLang/@otherLangs">
                            <xsl:value-of select="$v_monogr[tei:textLang/@otherLangs][1]/tei:textLang/@otherLangs"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="'NA'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="$v_otherLangs"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'langs'">
                <xsl:for-each-group select="$v_monogr/tei:textLang/@mainLang" group-by=".">
                    <xsl:element name="lang">
                        <xsl:value-of select="current-grouping-key()"/>
                    </xsl:element>
                </xsl:for-each-group>
                <xsl:for-each-group select="tokenize($v_monogr/tei:textLang/@otherLangs, ' ')" group-by=".">
                    <xsl:element name="lang">
                        <xsl:value-of select="current-grouping-key()"/>
                    </xsl:element>
                </xsl:for-each-group>
            </xsl:when>
            <!-- return date           -->
            <xsl:when test="$p_output-mode = 'date'">
                <xsl:choose>
                    <xsl:when test="$v_monogr/tei:imprint/tei:date[@type = 'onset'][@when]">
                        <xsl:value-of select="$v_monogr/tei:imprint/tei:date[@type = 'onset'][@when][1]/@when"/>
                    </xsl:when>
                    <xsl:when test="$v_monogr/tei:imprint/tei:date/@from">
                        <xsl:value-of select="$v_monogr/tei:imprint/tei:date[@from][1]/@from"/>
                    </xsl:when>
                    <xsl:when test="$v_monogr/tei:imprint/tei:date/@notBefore">
                        <xsl:value-of select="$v_monogr/tei:imprint/tei:date[@notBefore][1]/@notBefore"/>
                    </xsl:when>
                    <xsl:when test="$v_monogr/tei:imprint/tei:date/@notAfter">
                        <xsl:value-of select="$v_monogr/tei:imprint/tei:date[@notAfter][1]/@notAfter"/>
                    </xsl:when>
                    <xsl:when test="$v_monogr/tei:imprint/tei:date[not(@type = 'onset')][@when]">
                        <xsl:value-of select="$v_monogr/tei:imprint/tei:date[not(@type = 'onset')][@when][1]/@when"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- this returns a node and all values in attritbutes have been converted to ISO -->
            <xsl:when test="$p_output-mode = 'date-onset'">
                <xsl:variable name="v_date-onset">
                    <xsl:apply-templates mode="m_iso" select="$v_monogr/tei:imprint/tei:date[@type = ('onset', 'official')]"/>
                    <xsl:apply-templates mode="m_iso" select="$v_monogr/tei:imprint/tei:date[not(@type)][@from]"/>
                    <xsl:apply-templates mode="m_iso" select="$v_monogr/tei:imprint/tei:date[not(@type)][@when]"/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$v_date-onset/descendant-or-self::tei:date/@when">
                        <!--                        <xsl:value-of select="min($v_date-onset/descendant-or-self::tei:date[@when]/@when/xs:date(.))"/>-->
                        <xsl:copy-of select="$v_date-onset/descendant-or-self::tei:date[@when = min($v_date-onset/descendant-or-self::tei:date[@when]/@when/xs:date(.))][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'year-onset'">
                <xsl:variable name="v_date" select="oape:query-biblstruct($p_bibl, 'date-onset', '', '', '')"/>
                <xsl:choose>
                    <xsl:when test="$v_date != 'NA'">
                        <xsl:value-of select="year-from-date($v_date/self::tei:date/@when)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'date-terminus'">
                <xsl:variable name="v_date-terminus">
                    <xsl:apply-templates mode="m_iso" select="$v_monogr/tei:imprint/tei:date[@type = 'terminus']"/>
                    <xsl:apply-templates mode="m_iso" select="$v_monogr/tei:imprint/tei:date[not(@type)][@to]"/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$v_date-terminus/descendant-or-self::tei:date/@when">
                        <!--                        <xsl:value-of select="max($v_date-terminus/descendant-or-self::tei:date[@when]/@when/xs:date(.))"/>-->
                        <xsl:copy-of select="$v_date-terminus/descendant-or-self::tei:date[@when = max($v_date-terminus/descendant-or-self::tei:date[@when]/@when/xs:date(.))][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'year-terminus'">
                <xsl:variable name="v_date" select="oape:query-biblstruct($p_bibl, 'date-terminus', '', '', '')"/>
                <xsl:choose>
                    <xsl:when test="$v_date != 'NA'">
                        <xsl:value-of select="year-from-date($v_date/self::tei:date/@when)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'date-documented'">
                <xsl:variable name="v_date-documented">
                    <xsl:apply-templates mode="m_iso" select="$v_monogr/tei:imprint/tei:date[@type = 'documented']"/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$v_date-documented/descendant-or-self::tei:date/@when">
                        <xsl:value-of select="max($v_date-documented/descendant-or-self::tei:date[@when]/@when/xs:date(.))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- editor: ID -->
            <xsl:when test="$p_output-mode = 'id-editor'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:editor/tei:persName">
                        <xsl:value-of select="oape:query-personography($p_bibl/descendant::tei:editor[tei:persName][1]/tei:persName[1], $v_personography, $p_local-authority, 'id', '')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-editor-viaf'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:editor/tei:persName">
                        <xsl:value-of select="oape:query-personography($p_bibl/descendant::tei:editor[tei:persName][1]/tei:persName[1], $v_personography, $p_local-authority, 'id-viaf', '')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-editor-wiki'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:editor/tei:persName">
                        <xsl:value-of select="oape:query-personography($p_bibl/descendant::tei:editor[tei:persName][1]/tei:persName[1], $v_personography, $p_local-authority, 'id-wiki', '')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'subtype'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/@subtype">
                        <xsl:value-of select="$p_bibl/@subtype"/>
                    </xsl:when>
                    <xsl:when test="$v_monogr/@subtype">
                        <xsl:value-of select="$v_monogr[@subtype][1]/@subtype"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'type'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/@type">
                        <xsl:value-of select="$p_bibl/@type"/>
                    </xsl:when>
                    <xsl:when test="$v_monogr/@type">
                        <xsl:value-of select="$v_monogr[@type][1]/@type"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'frequency'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/@oape:frequency">
                        <xsl:value-of select="$p_bibl/@oape:frequency"/>
                    </xsl:when>
                    <xsl:when test="$v_monogr/@oape:frequency">
                        <xsl:value-of select="$v_monogr[@oape:frequency][1]/@oape:frequency"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- count known holdings -->
            <xsl:when test="$p_output-mode = 'holdings'">
                <xsl:value-of select="count($p_bibl/tei:note[@type = 'holdings']/tei:list/tei:item)"/>
            </xsl:when>
            <!-- count issues/copies in known holdings -->
            <xsl:when test="$p_output-mode = 'copies'">
                <xsl:value-of select="count($p_bibl/tei:note[@type = 'holdings']/tei:list/tei:item/descendant::tei:bibl)"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'digitised'">
                <xsl:value-of
                    select="count($p_bibl/tei:note[@type = 'holdings']/tei:list/tei:item[(descendant::tei:ref[not(@type = 'about')]/@target[starts-with(., 'http')]) | descendant::tei:idno[@type = 'URI'][@subtype = 'self']])"
                />
            </xsl:when>
            <!-- fallback -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Unkown output mode: </xsl:text>
                    <xsl:value-of select="$p_output-mode"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="tei:date" mode="m_iso">
        <xsl:variable name="v_temp">
            <xsl:choose>
                <xsl:when test="@type = 'onset'">
                    <xsl:value-of select="oape:date-get-onset(.)"/>
                </xsl:when>
                <xsl:when test="@type = 'terminus'">
                    <xsl:value-of select="oape:date-get-terminus(.)"/>
                </xsl:when>
                <xsl:when test="@when">
                    <xsl:value-of select="@when"/>
                </xsl:when>
                <xsl:when test="@from">
                    <xsl:value-of select="@from"/>
                </xsl:when>
                <xsl:when test="@notBefore">
                    <xsl:value-of select="@notBefore"/>
                </xsl:when>
                <xsl:when test="@notAfter">
                    <xsl:value-of select="@notAfter"/>
                </xsl:when>
                <xsl:when test="@when-custom and @datingMethod">
                    <xsl:value-of select="oape:date-convert-calendars(@when-custom, @datingMethod, '#cal_gregorian')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!-- output -->
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@source | @type"/>
            <xsl:choose>
                <xsl:when test="matches($v_temp, '^\d{4}-\d{2}-\d{2}$')">
                    <xsl:attribute name="when" select="$v_temp"/>
                    <xsl:if test="not(@when)">
                        <xsl:attribute name="cert" select="'medium'"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="matches($v_temp, '^\d{4}$')">
                    <!-- latest possible date: this will prevent the originally less precise dates from taking precedent -->
                    <xsl:attribute name="when">
                        <xsl:choose>
                            <xsl:when test="@type = 'onset'">
                                <xsl:value-of select="concat($v_temp, '-12-31')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat($v_temp, '-12-31')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="cert" select="'low'"/>
                </xsl:when>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <!-- query a local TEI gazetteer for toponyms, locations, IDs etc. -->
    <xsl:function name="oape:query-gazetteer">
        <!-- input is a tei <placeName> node -->
        <xsl:param as="node()" name="placeName"/>
        <!-- $gazetteer expects a path to a file -->
        <xsl:param name="gazetteer"/>
        <!-- local authority -->
        <xsl:param as="xs:string" name="p_local-authority"/>
        <!-- values for $mode are 'location', 'name', 'type', 'oape' -->
        <xsl:param as="xs:string" name="p_output-mode"/>
        <!-- select a target language for toponyms -->
        <xsl:param as="xs:string" name="p_output-language"/>
        <xsl:choose>
            <!-- test if input is not empty -->
            <xsl:when test="$placeName != '' or $placeName/@ref != ''">
                <!-- load data from authority file -->
                <xsl:variable name="v_place" select="oape:get-entity-from-authority-file($placeName, $p_local-authority, $gazetteer)"/>
                <xsl:choose>
                    <!-- test for @ref pointing to auhority files -->
                    <xsl:when test="$v_place != 'NA'">
                        <!-- query the place note returned from the gazetteer -->
                        <xsl:copy-of select="oape:query-place($v_place, $p_output-mode, $p_output-language, $p_local-authority)"/>
                    </xsl:when>
                    <!-- return original input toponym if nothing else is found -->
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:text>The input placeName "</xsl:text>
                            <xsl:value-of select="normalize-space($placeName)"/>
                            <xsl:text>" was not found in the authority file</xsl:text>
                        </xsl:message>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>The input placeName was empty</xsl:text>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:query-geo">
        <xsl:param as="node()" name="p_geo"/>
        <xsl:param as="xs:string" name="p_output-mode"/>
        <xsl:choose>
            <xsl:when test="$p_output-mode = 'location'">
                <xsl:value-of select="$p_geo"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'lat'">
                <xsl:value-of select="replace($p_geo, '^(.+?),\s*(.+?)$', '$1')"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'long'">
                <xsl:value-of select="replace($p_geo, '^(.+?),\s*(.+?)$', '$2')"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:query-place">
        <!-- input is a tei <place> node -->
        <xsl:param as="node()" name="p_place"/>
        <!-- values for $mode are 'location', 'name', 'type', 'id-local', 'id', 'id-geon' -->
        <xsl:param as="xs:string" name="p_output-mode"/>
        <!-- select a target language for toponyms -->
        <xsl:param as="xs:string" name="p_output-language"/>
        <!-- local authority -->
        <xsl:param name="p_local-authority"/>
        <xsl:choose>
            <!-- return location -->
            <xsl:when test="$p_output-mode = ('location', 'lat', 'long')">
                <xsl:choose>
                    <xsl:when test="$p_place/tei:location/tei:geo">
                        <xsl:value-of select="oape:query-geo($p_place/tei:location/tei:geo, $p_output-mode)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="$p_verbose = true()">
                            <xsl:message>
                                <xsl:text>No location data for </xsl:text>
                                <xsl:value-of select="oape:query-place($p_place, 'name', 'en', $p_local-authority)"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return IDs -->
            <xsl:when test="$p_output-mode = 'id'">
                <xsl:choose>
                    <xsl:when test="$p_place/descendant::tei:idno[@type = $p_acronym-geonames]">
                        <xsl:value-of select="concat($p_acronym-geonames, ':', $p_place/descendant::tei:idno[@type = $p_acronym-geonames][1])"/>
                    </xsl:when>
                    <!-- Wikidata -->
                    <xsl:when test="$p_place/tei:idno[@type = $p_acronym-wikidata]">
                        <xsl:value-of select="concat('wiki:', $p_place/tei:idno[@type = $p_acronym-wikidata][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_place/descendant::tei:idno[@type = $p_local-authority]">
                        <xsl:value-of select="concat($p_local-authority, ':', $p_place/descendant::tei:idno[@type = $p_local-authority][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_place/descendant::tei:idno">
                        <xsl:value-of select="concat($p_place/descendant::tei:idno[1]/@type, ':', $p_place/descendant::tei:idno[1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-local'">
                <xsl:choose>
                    <xsl:when test="$p_place/tei:idno[@type = $p_local-authority]">
                        <xsl:value-of select="$p_place/tei:idno[@type = $p_local-authority][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-geon'">
                <xsl:choose>
                    <xsl:when test="$p_place/tei:idno[@type = $p_acronym-geonames]">
                        <xsl:value-of select="$p_place/tei:idno[@type = $p_acronym-geonames][1]"/>
                    </xsl:when>
                    <xsl:when test="$p_place/tei:placeName[matches(@ref, 'geon:\d+')]">
                        <xsl:value-of select="replace($p_place/tei:placeName[matches(@ref, 'geon:\d+')][1]/@ref, '^.*geon:(\d+).*$', '$1')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-wiki'">
                <xsl:choose>
                    <xsl:when test="$p_place/tei:idno[@type = $p_acronym-wikidata]">
                        <xsl:value-of select="$p_place/tei:idno[@type = $p_acronym-wikidata][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'url-geon'">
                <xsl:variable name="v_id" select="oape:query-place($p_place, 'id-geon', '', '')"/>
                <xsl:choose>
                    <xsl:when test="$v_id != 'NA'">
                        <xsl:value-of select="concat($p_url-resolve-geonames, $v_id)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'tei-ref'">
                <xsl:choose>
                    <xsl:when test="$p_place/tei:idno[not(@type = 'URI')]">
                        <xsl:variable name="v_temp">
                            <xsl:for-each-group group-by="@type" select="$p_place/tei:idno[not(@type = 'URI')]">
                                <xsl:sort order="ascending" select="@type"/>
                                <xsl:if test="current-grouping-key() = $p_acronym-geonames">
                                    <xsl:value-of select="concat($p_acronym-geonames, ':', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = $p_acronym-wikidata">
                                    <xsl:value-of select="concat($p_acronym-wikidata, ':', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'oape'">
                                    <xsl:value-of select="concat('oape:place:', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'jaraid'">
                                    <xsl:value-of select="concat('jaraid:place:', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="position() != last()">
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                            </xsl:for-each-group>
                        </xsl:variable>
                        <xsl:value-of select="normalize-space($v_temp)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return toponym in selected language -->
            <xsl:when test="$p_output-mode = 'name'">
                <xsl:choose>
                    <xsl:when test="$p_place/tei:placeName[@xml:lang = $p_output-language]">
                        <xsl:value-of select="normalize-space($p_place/tei:placeName[@xml:lang = $p_output-language][1])"/>
                    </xsl:when>
                    <!-- possible transcriptions into other script -->
                    <xsl:when test="($p_output-language = 'ar') and ($p_place/tei:placeName[contains(@xml:lang, '-Arab-')])">
                        <xsl:value-of select="normalize-space($p_place/tei:placeName[contains(@xml:lang, '-Arab-')][1])"/>
                    </xsl:when>
                    <!-- fallback to english -->
                    <xsl:when test="$p_place/tei:placeName[@xml:lang = 'en']">
                        <xsl:value-of select="normalize-space($p_place/tei:placeName[@xml:lang = 'en'][1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space($p_place/tei:placeName[1])"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'name-tei'">
                <xsl:variable name="v_placeName">
                    <xsl:choose>
                        <xsl:when test="$p_place/tei:placeName[@xml:lang = $p_output-language]">
                            <xsl:copy-of select="$p_place/tei:placeName[@xml:lang = $p_output-language][1]"/>
                        </xsl:when>
                        <!-- possible transcriptions into other script -->
                        <xsl:when test="($p_output-language = 'ar') and ($p_place/tei:placeName[contains(@xml:lang, '-Arab-')])">
                            <xsl:copy-of select="$p_place/tei:placeName[contains(@xml:lang, '-Arab-')][1]"/>
                        </xsl:when>
                        <!-- fallback to english -->
                        <xsl:when test="$p_place/tei:placeName[@xml:lang = 'en']">
                            <xsl:copy-of select="$p_place/tei:placeName[@xml:lang = 'en'][1]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$p_place/tei:placeName[1]"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- not entirely clear why there should be more than one <placeName> node -->
                <!-- placeNames can self-nest -->
                <xsl:copy select="$v_placeName/descendant-or-self::tei:placeName[1]">
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="$v_placeName/descendant-or-self::tei:placeName[1]/@xml:lang"/>
                    <xsl:attribute name="ref" select="oape:query-place($p_place, 'tei-ref', '', $p_local-authority)"/>
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="$v_placeName/descendant-or-self::tei:placeName[1]/node()"/>
                </xsl:copy>
            </xsl:when>
            <!-- return type -->
            <xsl:when test="$p_output-mode = 'type'">
                <xsl:value-of select="$p_place/@type"/>
            </xsl:when>
            <!-- fallback -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Unkown output mode: </xsl:text>
                    <xsl:value-of select="$p_output-mode"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- query a TEI org node -->
    <xsl:function name="oape:query-organizationography">
        <!-- input is a tei <placeName> node -->
        <xsl:param name="orgName"/>
        <!-- $gazetteer expects a path to a file -->
        <xsl:param name="organizationography"/>
        <!-- local authority -->
        <xsl:param as="xs:string" name="p_local-authority"/>
        <!-- values for $mode are 'id', 'id-local', 'name', 'date-birth', 'date-death' -->
        <xsl:param as="xs:string" name="p_output-mode"/>
        <!-- select a target language for names -->
        <xsl:param as="xs:string" name="p_output-language"/>
        <!-- load data from authority file -->
        <xsl:variable name="v_org" select="oape:get-entity-from-authority-file($orgName, $p_local-authority, $organizationography)"/>
        <xsl:choose>
            <!-- test for @ref pointing to auhority files -->
            <xsl:when test="$v_org != 'NA'">
                <xsl:copy-of select="oape:query-org($v_org, $p_output-mode, $p_output-language, $p_local-authority)"/>
            </xsl:when>
            <!-- return original input toponym if nothing else is fond -->
            <xsl:when test="$p_output-mode = 'name'">
                <xsl:choose>
                    <xsl:when test="$orgName != ''">
                        <xsl:value-of select="normalize-space($orgName)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- otherwise: no location data -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>no authority data found for </xsl:text>
                    <xsl:value-of select="normalize-space($orgName)"/>
                </xsl:message>
                <xsl:value-of select="'NA'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:query-org">
        <!-- input is a tei <org> node -->
        <xsl:param as="node()" name="p_org"/>
        <!-- values for $mode are 'location', 'name', 'type', 'id-local', 'id', 'id-geon' -->
        <xsl:param as="xs:string" name="p_output-mode"/>
        <!-- select a target language for toponyms -->
        <xsl:param as="xs:string" name="p_output-language"/>
        <!-- local authority -->
        <xsl:param name="p_local-authority"/>
        <xsl:choose>
            <!-- return location -->
            <xsl:when test="$p_output-mode = ('location', 'lat', 'long')">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:location/tei:geo">
                        <xsl:value-of select="oape:query-geo($p_org/tei:location[tei:geo][1]/tei:geo[1], $p_output-mode)"/>
                    </xsl:when>
                    <xsl:when test="$p_org/tei:location//tei:placeName">
                        <xsl:copy-of
                            select="oape:query-place(oape:get-entity-from-authority-file($p_org/descendant::tei:placeName[ancestor::tei:location][1], $p_local-authority, $v_gazetteer), $p_output-mode, $p_output-language, $p_local-authority)"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="$p_verbose = true()">
                            <xsl:message>
                                <xsl:text>No location data for </xsl:text>
                                <xsl:value-of select="oape:query-org($p_org, 'name', 'en', $p_local-authority)"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = ('location-name')">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:location//tei:placeName">
                        <xsl:copy-of
                            select="oape:query-place(oape:get-entity-from-authority-file($p_org/descendant::tei:placeName[ancestor::tei:location][1], $p_local-authority, $v_gazetteer), 'name', $p_output-language, $p_local-authority)"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="$p_verbose = true()">
                            <xsl:message>
                                <xsl:text>No location data for </xsl:text>
                                <xsl:value-of select="oape:query-org($p_org, 'name', 'en', $p_local-authority)"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = ('location-tei')">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:location//tei:placeName">
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>Query gazetteer for full placeName node: </xsl:text>
                                <xsl:copy-of select="$p_org/descendant::tei:placeName[ancestor::tei:location][1]"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:copy-of
                            select="oape:query-place(oape:get-entity-from-authority-file($p_org/descendant::tei:placeName[ancestor::tei:location][1], $p_local-authority, $v_gazetteer), 'name-tei', $p_output-language, $p_local-authority)"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="$p_verbose = true()">
                            <xsl:message>
                                <xsl:text>No location data for </xsl:text>
                                <xsl:value-of select="oape:query-org($p_org, 'name', 'en', $p_local-authority)"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return IDs -->
            <xsl:when test="$p_output-mode = 'id'">
                <xsl:choose>
                    <!-- VIAF -->
                    <xsl:when test="$p_org/tei:idno[@type = 'VIAF']">
                        <xsl:value-of select="concat('viaf:', $p_org/tei:idno[@type = 'VIAF'][1])"/>
                    </xsl:when>
                    <!-- Wikidata -->
                    <xsl:when test="$p_org/tei:idno[@type = $p_acronym-wikidata]">
                        <xsl:value-of select="concat('wiki:', $p_org/tei:idno[@type = $p_acronym-wikidata][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_org/tei:idno[@type = $p_local-authority]">
                        <xsl:value-of select="concat($p_local-authority, ':', $p_org/tei:idno[@type = $p_local-authority][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_org/tei:idno">
                        <xsl:value-of select="concat($p_org/tei:idno[1]/@type, ':', $p_org/tei:idno[1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-local'">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:idno[@type = $p_local-authority]">
                        <xsl:value-of select="$p_org/tei:idno[@type = $p_local-authority][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-viaf'">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:idno[@type = 'VIAF']">
                        <xsl:value-of select="$p_org/tei:idno[@type = 'VIAF'][1]"/>
                    </xsl:when>
                    <!-- look for a @ref attribute -->
                    <xsl:when test="$p_org/tei:persName/@ref[matches(., 'viaf:\d+')]">
                        <xsl:value-of select="replace($p_org/tei:persName[matches(@ref, 'viaf')][1]/@ref, '^.*viaf:(\d+).*$', '$1')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-wiki'">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:idno[@type = $p_acronym-wikidata]">
                        <xsl:value-of select="$p_org/tei:idno[@type = $p_acronym-wikidata][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-isil'">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:idno[@type = 'isil']">
                        <xsl:value-of select="$p_org/tei:idno[@type = 'isil'][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'tei-ref'">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:idno[not(@type = 'URI')]">
                        <xsl:variable name="v_temp">
                            <xsl:for-each-group group-by="@type" select="$p_org/descendant::tei:idno[not(@type = 'URI')]">
                                <xsl:sort order="ascending" select="current-grouping-key()"/>
                                <xsl:if test="current-grouping-key() = 'VIAF'">
                                    <xsl:value-of select="concat('viaf:', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = $p_acronym-wikidata">
                                    <xsl:value-of select="concat($p_acronym-wikidata, ':', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'oape'">
                                    <xsl:value-of select="concat('oape:org:', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'jaraid'">
                                    <xsl:value-of select="concat('jaraid:org:', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'isil'">
                                    <xsl:value-of select="concat('isil:', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="position() != last()">
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                            </xsl:for-each-group>
                        </xsl:variable>
                        <xsl:value-of select="normalize-space($v_temp)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return name in selected language -->
            <xsl:when test="$p_output-mode = 'name'">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:orgName[@xml:lang = $p_output-language]">
                        <xsl:value-of select="normalize-space($p_org/tei:orgName[@xml:lang = $p_output-language][1])"/>
                    </xsl:when>
                    <!-- possible transcriptions into other script -->
                    <xsl:when test="($p_output-language = 'ar') and ($p_org/tei:orgName[contains(@xml:lang, '-Arab-')])">
                        <xsl:value-of select="normalize-space($p_org/tei:orgName[contains(@xml:lang, '-Arab-')][1])"/>
                    </xsl:when>
                    <!-- fallback to english -->
                    <xsl:when test="$p_org/tei:orgName[@xml:lang = 'en']">
                        <xsl:value-of select="normalize-space($p_org/tei:orgName[@xml:lang = 'en'][1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space($p_org/tei:orgName[1])"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'url'">
                <xsl:choose>
                    <xsl:when test="$p_org/tei:idno[@type = 'url']">
                        <xsl:value-of select="$p_org/tei:idno[@type = 'url'][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- fallback -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Unkown output mode: </xsl:text>
                    <xsl:value-of select="$p_output-mode"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- query a local TEI personography  -->
    <xsl:function name="oape:query-personography">
        <!-- input is a tei <persName> node -->
        <xsl:param as="node()" name="persName"/>
        <!-- $gazetteer expects a path to a file -->
        <xsl:param name="personography"/>
        <!-- local authority -->
        <xsl:param as="xs:string" name="p_local-authority"/>
        <!-- values for $mode are 'id', 'id-local', 'name', 'date-birth', 'date-death' -->
        <xsl:param as="xs:string" name="p_output-mode"/>
        <!-- select a target language for names -->
        <xsl:param as="xs:string" name="p_output-language"/>
        <!-- load data from authority file -->
        <xsl:variable name="v_person" select="oape:get-entity-from-authority-file($persName, $p_local-authority, $personography)"/>
        <xsl:if test="$p_debug = true()">
            <xsl:message>
                <xsl:text>Return from the authority file: </xsl:text>
                <xsl:copy-of select="$v_person"/>
            </xsl:message>
        </xsl:if>
        <xsl:choose>
            <!-- If there is data from an authority file call other function to query that data. Results are passed through -->
            <xsl:when test="$v_person != 'NA'">
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>Input persName </xsl:text>
                        <xsl:value-of select="$persName"/>
                        <xsl:text> is linked to an entry in the authority file</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:copy-of select="oape:query-person($v_person, $p_output-mode, $p_output-language, $p_local-authority)"/>
            </xsl:when>
            <!-- return original input toponym if nothing else is fond -->
            <xsl:when test="$p_output-mode = 'name'">
                <xsl:choose>
                    <xsl:when test="$persName != ''">
                        <xsl:value-of select="normalize-space($persName)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- otherwise: no location data -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>no authority data found for </xsl:text>
                    <xsl:value-of select="normalize-space($persName)"/>
                </xsl:message>
                <xsl:value-of select="'NA'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="oape:query-person">
        <!-- input is a tei <person> node -->
        <xsl:param as="node()" name="p_person"/>
        <!-- values for $mode are 'id', 'id-local', 'id-viaf', 'id-wiki' 'name', 'date-birth', 'date-death' -->
        <xsl:param as="xs:string" name="p_output-mode"/>
        <!-- select a target language for toponyms -->
        <xsl:param as="xs:string" name="p_output-language"/>
        <!-- local authority -->
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:choose>
            <!-- return IDs -->
            <xsl:when test="$p_output-mode = 'id'">
                <xsl:choose>
                    <!-- VIAF -->
                    <xsl:when test="$p_person/tei:idno[@type = 'VIAF']">
                        <xsl:value-of select="concat('viaf:', $p_person/tei:idno[@type = 'VIAF'][1])"/>
                    </xsl:when>
                    <!-- Wikidata -->
                    <xsl:when test="$p_person/tei:idno[@type = $p_acronym-wikidata]">
                        <xsl:value-of select="concat('wiki:', $p_person/tei:idno[@type = $p_acronym-wikidata][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_person/tei:idno[@type = $p_local-authority]">
                        <xsl:value-of select="concat($p_local-authority, ':', $p_person/tei:idno[@type = $p_local-authority][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_person/tei:idno">
                        <xsl:value-of select="concat($p_person/tei:idno[1]/@type, ':', $p_person/tei:idno[1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-local'">
                <xsl:choose>
                    <xsl:when test="$p_person/tei:idno[@type = $p_local-authority]">
                        <xsl:value-of select="$p_person/tei:idno[@type = $p_local-authority][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-viaf'">
                <xsl:choose>
                    <xsl:when test="$p_person/tei:idno[@type = 'VIAF']">
                        <xsl:value-of select="$p_person/tei:idno[@type = 'VIAF'][1]"/>
                    </xsl:when>
                    <!-- look for a @ref attribute -->
                    <xsl:when test="$p_person/tei:persName/@ref[matches(., 'viaf:\d+')]">
                        <xsl:value-of select="replace($p_person/tei:persName[matches(@ref, 'viaf')][1]/@ref, '^.*viaf:(\d+).*$', '$1')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-wiki'">
                <xsl:choose>
                    <xsl:when test="$p_person/tei:idno[@type = $p_acronym-wikidata]">
                        <xsl:value-of select="$p_person/tei:idno[@type = $p_acronym-wikidata][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'url-viaf'">
                <xsl:variable name="v_id" select="oape:query-person($p_person, 'id-viaf', '', '')"/>
                <xsl:choose>
                    <xsl:when test="$v_id != 'NA'">
                        <xsl:value-of select="concat($p_url-resolve-viaf, $v_id)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'url-wiki'">
                <xsl:variable name="v_id" select="oape:query-person($p_person, 'id-wiki', '', '')"/>
                <xsl:choose>
                    <xsl:when test="$v_id != 'NA'">
                        <xsl:value-of select="concat($p_url-resolve-wikidata, $v_id)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'tei-ref'">
                <xsl:choose>
                    <xsl:when test="$p_person/tei:idno[not(@type = 'URI')]">
                        <xsl:variable name="v_temp">
                            <xsl:for-each-group group-by="@type" select="$p_person/descendant::tei:idno[not(@type = 'URI')]">
                                <xsl:sort order="ascending" select="current-grouping-key()"/>
                                <xsl:if test="current-grouping-key() = 'VIAF'">
                                    <xsl:value-of select="concat($p_acronym-viaf, ':', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = $p_acronym-wikidata">
                                    <xsl:value-of select="concat($p_acronym-wikidata, ':', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'oape'">
                                    <xsl:value-of select="concat('oape:pers:', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'jaraid'">
                                    <xsl:value-of select="concat('jaraid:pers:', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="current-grouping-key() = 'damascus'">
                                    <xsl:value-of select="concat('damascus:pers:', current-group()[1])"/>
                                </xsl:if>
                                <xsl:if test="position() != last()">
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                            </xsl:for-each-group>
                        </xsl:variable>
                        <xsl:value-of select="normalize-space($v_temp)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return name in selected language -->
            <xsl:when test="$p_output-mode = 'name-tei'">
                <xsl:variable name="v_name">
                    <xsl:choose>
                        <!-- preference for names without addNames -->
                        <!-- at least in one case this leads to the more commonly referenced name not being returned in Arabic: "Kurd ʿAlī" for "Muḥammad Kurd ʿAlī" -->
                        <xsl:when test="$p_person/tei:persName[@type = 'noAddName'][@xml:lang = $p_output-language]">
                            <xsl:copy-of select="$p_person/tei:persName[@type = 'noAddName'][@xml:lang = $p_output-language][1]"/>
                        </xsl:when>
                        <!-- I will never want to get the flattened node -->
                        <xsl:when test="$p_person/tei:persName[not(@type = 'flattened')][@xml:lang = $p_output-language]">
                            <xsl:copy-of select="$p_person/tei:persName[not(@type = 'flattened')][@xml:lang = $p_output-language][1]"/>
                        </xsl:when>
                        <!-- possible transcriptions into other script -->
                        <xsl:when test="($p_output-language = 'ar') and ($p_person/tei:persName[@type = 'noAddName'][contains(@xml:lang, '-Arab-')])">
                            <xsl:copy-of select="$p_person/tei:persName[@type = 'noAddName'][contains(@xml:lang, '-Arab-')][1]"/>
                        </xsl:when>
                        <xsl:when test="($p_output-language = 'ar') and ($p_person/tei:persName[not(@type = 'flattened')][contains(@xml:lang, '-Arab-')])">
                            <xsl:copy-of select="$p_person/tei:persName[not(@type = 'flattened')][contains(@xml:lang, '-Arab-')][1]"/>
                        </xsl:when>
                        <xsl:when test="($p_output-language = 'en') and ($p_person/tei:persName[@type = 'noAddName'][contains(@xml:lang, '-Latn-')])">
                            <xsl:copy-of select="$p_person/tei:persName[@type = 'noAddName'][contains(@xml:lang, '-Latn-')][1]"/>
                        </xsl:when>
                         <xsl:when test="($p_output-language = 'en') and ($p_person/tei:persName[not(@type = 'flattened')][contains(@xml:lang, '-Latn-')])">
                            <xsl:copy-of select="$p_person/tei:persName[not(@type = 'flattened')][contains(@xml:lang, '-Latn-')][1]"/>
                        </xsl:when>
                        <!-- fallback to english -->
                        <xsl:when test="$p_person/tei:persName[@type = 'noAddName'][@xml:lang = ('en', 'fr')]">
                            <xsl:copy-of select="$p_person/tei:persName[@type = 'noAddName'][@xml:lang = ('en', 'fr')][1]"/>
                        </xsl:when>
                        <xsl:when test="$p_person/tei:persName[not(@type = 'flattened')][@xml:lang = ('en', 'fr')]">
                            <xsl:copy-of select="$p_person/tei:persName[not(@type = 'flattened')][@xml:lang = ('en', 'fr')][1]"/>
                        </xsl:when>
                        <xsl:when test="$p_person/tei:persName[@type = 'noAddName'][contains(@xml:lang, '-Latn-')]">
                            <xsl:copy-of select="$p_person/tei:persName[@type = 'noAddName'][contains(@xml:lang, '-Latn-')][1]"/>
                        </xsl:when>
                        <xsl:when test="$p_person/tei:persName[@type = 'noAddName']">
                            <xsl:copy-of select="$p_person/tei:persName[@type = 'noAddName'][1]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$p_person/tei:persName[1]"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:copy select="$v_name/tei:persName">
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="@*"/>
                    <!-- add ref attribute -->
                    <xsl:attribute name="ref" select="oape:query-person($p_person, 'tei-ref', '', $p_local-authority)"/>
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="node()"/>
                </xsl:copy>
            </xsl:when>
            <!-- name as string -->
            <xsl:when test="$p_output-mode = 'name'">
                <xsl:variable name="v_name" select="oape:query-person($p_person, 'name-tei', $p_output-language, $p_local-authority)"/>
                <xsl:variable name="v_name">
                    <xsl:apply-templates mode="m_plain-text" select="$v_name"/>
                </xsl:variable>
                <xsl:value-of select="normalize-space($v_name)"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'date-birth'">
                <xsl:choose>
                    <xsl:when test="$p_person/tei:birth/@when">
                        <xsl:value-of select="$p_person/tei:birth/@when"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'date-death'">
                <xsl:choose>
                    <xsl:when test="$p_person/tei:death/@when">
                        <xsl:value-of select="$p_person/tei:death/@when"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'countWorks'">
                <xsl:variable name="v_id-viaf" select="oape:query-person($p_person, 'id-viaf', '', '')"/>
                <xsl:choose>
                    <xsl:when test="$v_id-viaf != 'NA'">
                        <xsl:variable name="v_person-viaf">
                            <xsl:call-template name="t_query-viaf-sru">
                                <xsl:with-param name="p_input-type" select="'id'"/>
                                <xsl:with-param name="p_search-term" select="$v_id-viaf"/>
                                <xsl:with-param name="p_include-bibliograpy-in-output" select="true()"/>
                                <xsl:with-param name="p_output-mode" select="'tei'"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:value-of select="count($v_person-viaf/descendant::tei:listBibl/tei:bibl)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- fallback -->
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Unkown output mode: </xsl:text>
                    <xsl:value-of select="$p_output-mode"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- this function takes a tei:date node as input and returns an ISO string -->
    <xsl:function name="oape:date-get-onset">
        <xsl:param name="p_date"/>
        <xsl:choose>
            <xsl:when test="$p_date/@when">
                <xsl:value-of select="$p_date/@when"/>
            </xsl:when>
            <xsl:when test="$p_date/@from">
                <xsl:value-of select="$p_date/@from"/>
            </xsl:when>
            <xsl:when test="$p_date/@notBefore">
                <xsl:value-of select="$p_date/@notBefore"/>
            </xsl:when>
            <!-- this should act as a fallback -->
            <xsl:when test="$p_date/@to">
                <xsl:value-of select="$p_date/@to"/>
            </xsl:when>
            <xsl:when test="$p_date/@notAfter">
                <xsl:value-of select="$p_date/@notAfter"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>date: no machine-readible onset found</xsl:text>
                    </xsl:message>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- this function takes a tei:date node as input and returns an ISO string -->
    <xsl:function name="oape:date-get-terminus">
        <xsl:param name="p_date"/>
        <xsl:choose>
            <xsl:when test="$p_date/@when">
                <xsl:value-of select="$p_date/@when"/>
            </xsl:when>
            <xsl:when test="$p_date/@to">
                <xsl:value-of select="$p_date/@to"/>
            </xsl:when>
            <xsl:when test="$p_date/@notAfter">
                <xsl:value-of select="$p_date/@notAfter"/>
            </xsl:when>
            <!-- this should act as a fallback -->
            <xsl:when test="$p_date/@from">
                <xsl:value-of select="$p_date/@from"/>
            </xsl:when>
            <xsl:when test="$p_date/@notBefore">
                <xsl:value-of select="$p_date/@notBefore"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>date: no machine-readible terminus found</xsl:text>
                    </xsl:message>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- this function returns the first node in a series of nodes linked with @prev  -->
    <xsl:function name="oape:find-first-part">
        <xsl:param as="node()" name="p_node"/>
        <xsl:choose>
            <!-- as previous parts -->
            <xsl:when test="$p_node/@prev != ''">
                <xsl:variable name="v_prev-id" select="substring-after($p_node/@prev, '#')"/>
                <xsl:variable name="v_prev-url" select="substring-before($p_node/@prev, '#')"/>
                <!-- same or different file -->
                <xsl:variable name="v_prev">
                    <xsl:choose>
                        <xsl:when test="$v_prev-url != ''">
                            <xsl:apply-templates mode="m_identity-transform" select="doc(concat($v_url-base, '/', $v_prev-url))/descendant::node()[@xml:id = $v_prev-id]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="m_identity-transform" select="$p_node/ancestor::tei:text/descendant::node()[@xml:id = $v_prev-id]"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:copy-of select="oape:find-first-part($v_prev)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="m_identity-transform" select="$p_node"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- this function compiles multi-part nodes based on the first node -->
    <xsl:function name="oape:compile-next-prev">
        <xsl:param as="node()" name="p_node"/>
        <xsl:choose>
            <!-- test if the input conforms to our expectations -->
            <xsl:when test="($p_node/@next != '' and contains($p_node/@next, '#')) or ($p_node/@prev != '' and contains($p_node/@prev, '#'))">
                <xsl:variable name="v_next-id" select="substring-after($p_node/@next, '#')"/>
                <xsl:variable name="v_next-url" select="substring-before($p_node/@next, '#')"/>
                <!-- same or different file -->
                <xsl:variable name="v_next">
                    <xsl:choose>
                        <xsl:when test="$v_next-url != ''">
                            <xsl:copy-of select="doc(concat($v_url-base, '/', $v_next-url))/descendant::node()[@xml:id = $v_next-id]"/>
                        </xsl:when>
                        <!-- problem: when the input node was generated by a variable, it will have lost its context -->
                        <xsl:otherwise>
                            <xsl:copy-of select="doc($v_url-file)/descendant::node()[@xml:id = $v_next-id]"/>
                            <!-- <xsl:copy-of select="$p_node/ancestor::tei:TEI/descendant::node()[@xml:id = $v_next-id]"/>-->
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- debugging -->
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>$v_next-url: </xsl:text>
                        <xsl:value-of select="$v_next-url"/>
                    </xsl:message>
                    <xsl:message>
                        <xsl:text>$v_next-id: </xsl:text>
                        <xsl:value-of select="$v_next-id"/>
                    </xsl:message>
                    <xsl:message>
                        <xsl:text>$v_next: </xsl:text>
                        <xsl:copy-of select="$v_next/node()"/>
                    </xsl:message>
                </xsl:if>
                <xsl:choose>
                    <!-- first -->
                    <xsl:when test="$p_node/@next and not($p_node/@prev)">
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>position: first</xsl:text>
                            </xsl:message>
                        </xsl:if>
                        <!-- problem: the namespace is not provided! -->
                        <xsl:copy copy-namespaces="yes" inherit-namespaces="yes" select="$p_node">
                            <!-- combine attributes -->
                            <!-- to do: omit @prev and @next -->
                            <xsl:apply-templates mode="m_identity-transform" select="$p_node/@*"/>
                            <xsl:copy-of select="$p_node/ancestor::tei:text/descendant::node()[@xml:id = $v_next-id]/@*"/>
                            <!-- reproduce current node -->
                            <xsl:apply-templates mode="m_identity-transform" select="$p_node/node()"/>
                            <!-- add following node -->
                            <xsl:apply-templates mode="m_identity-transform" select="oape:compile-next-prev($v_next/node())"/>
                        </xsl:copy>
                    </xsl:when>
                    <!-- middle -->
                    <xsl:when test="$p_node/@next and $p_node/@prev">
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>position: middle</xsl:text>
                            </xsl:message>
                        </xsl:if>
                        <xsl:apply-templates mode="m_identity-transform" select="$p_node/node()"/>
                        <!-- add following node -->
                        <xsl:apply-templates mode="m_identity-transform" select="oape:compile-next-prev($v_next/node())"/>
                    </xsl:when>
                    <!-- last -->
                    <xsl:when test="$p_node/@prev and not($p_node/@next)">
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>position: last</xsl:text>
                            </xsl:message>
                        </xsl:if>
                        <xsl:apply-templates mode="m_identity-transform" select="$p_node/node()"/>
                    </xsl:when>
                    <!-- nothing to compile -->
                    <!-- <xsl:otherwise>
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>nothing to compile</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:copy copy-namespaces="yes" inherit-namespaces="yes" select="$p_node">
                    <xsl:apply-templates mode="m_identity-transform" select="$p_node/@* | $p_node/node()"/>
                </xsl:copy>
            </xsl:otherwise> -->
                </xsl:choose>
            </xsl:when>
            <!-- nothing to compile -->
            <xsl:otherwise>
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>nothing to compile</xsl:text>
                    </xsl:message>
                </xsl:if>
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
    <!-- sequence of name parts is relevant!
        1. nisba: ... al-....ī
            - remainder is again checked
        2. nasab: ibn ...
            - remaidner is again checked
        3. kunya: abu ...
            - remaidner is again checked
        4. khitab: ... al-Dīn
        5. theophoric: ... Allah
        6. theophoric: ʿAbd ...
        7. single words: titles, ranks etc.
        8. strings consisting of only two words "... al-...". assume that these are forename and surname
            - doesn't work properly
    -->
    <xsl:function name="oape:string-mark-up-names">
        <xsl:param as="xs:string" name="p_input"/>
        <xsl:param as="xs:string" name="p_id-change"/>
        <xsl:variable name="v_input" select="oape:string-normalise-characters($p_input)"/>
        <xsl:if test="$p_debug = true()">
            <xsl:text>oape:string-mark-up-names</xsl:text>
            <xsl:text>Input: </xsl:text>
            <xsl:value-of select="$v_input"/>
        </xsl:if>
        <xsl:choose>
            <!-- test for Ottoman honorific addresses: ending in lū -->
            <xsl:when test="matches($v_input, '^(\w+لو)(\W.+)*$')">
                <xsl:analyze-string regex="^(\w+لو)\W*" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="addName">
                            <xsl:attribute name="type" select="'honorific'"/>
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="cert" select="'high'"/>
                            <xsl:attribute name="xml:lang" select="'ota'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- 1. test for surname beginning with "al-.." but not ending in "ī" -->
            <xsl:when test="matches($v_input, '^(.+)\s+(ال\w+[^ي])$')">
                <xsl:analyze-string regex="\s(ال\w+[^ي])$" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="surname">
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="cert" select="'high'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- 1. test for nisba -->
            <xsl:when test="matches($v_input, '^(.+\s)*(ال\w+ي)$')">
                <!--<xsl:message><xsl:value-of select="$v_input"/><xsl:text>contains a nisba</xsl:text></xsl:message>-->
                <xsl:analyze-string regex="(ال\w+ي)$" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="addName">
                            <xsl:attribute name="type" select="'nisbah'"/>
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="cert" select="'high'"/>
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
                <!--<xsl:message><xsl:value-of select="$v_input"/><xsl:text>contains a nasab</xsl:text></xsl:message>-->
                <xsl:analyze-string regex="(ابن|بن|بنت)\s(.+)$" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:variable name="v_trailing" select="regex-group(2)"/>
                        <xsl:element name="addName">
                            <xsl:attribute name="type" select="'nasab'"/>
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <!-- medium: while it is clear that we encounter the beginning of a nasab, the length is not clear  -->
                            <xsl:attribute name="cert" select="'medium'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:element name="nameLink">
                                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                                <xsl:attribute name="resp" select="'#xslt'"/>
                                <xsl:attribute name="cert" select="'high'"/>
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
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:value-of select="$v_input"/>
                        <xsl:text>contains a kunya</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:analyze-string regex="(ابو|ابي|ابا)\s(.+)$" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:variable name="v_trailing" select="regex-group(2)"/>
                        <xsl:element name="addName">
                            <xsl:attribute name="type" select="'kunyah'"/>
                            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <!-- medium: while it is clear that we encounter the beginning of a kunyah, the length is not clear  -->
                            <xsl:attribute name="cert" select="'medium'"/>
                            <xsl:element name="nameLink">
                                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                                <xsl:attribute name="resp" select="'#xslt'"/>
                                <xsl:attribute name="cert" select="'high'"/>
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
                <!--<xsl:message><xsl:value-of select="$v_input"/><xsl:text>contains a khitab</xsl:text></xsl:message>-->
                <xsl:analyze-string regex="(\w+)\s(الدين)" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="addName">
                            <xsl:attribute name="type" select="'khitab'"/>
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="cert" select="'high'"/>
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
                <!--<xsl:message><xsl:value-of select="$v_input"/><xsl:text>contains a theophoric name</xsl:text></xsl:message>-->
                <xsl:analyze-string regex="(\w+)\s(الله)" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="addName">
                            <xsl:attribute name="type" select="'theophoric'"/>
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="cert" select="'high'"/>
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
                <!--<xsl:message><xsl:value-of select="$v_input"/><xsl:text>contains a theophoric name</xsl:text></xsl:message>-->
                <xsl:analyze-string regex="(عبد)\s(\w+)" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="addName">
                            <xsl:attribute name="type" select="'theophoric'"/>
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="cert" select="'high'"/>
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
                    </xsl:matching-substring>
                    <!-- there ARE non-matching substrings -->
                    <!-- otherwise this strips symbols such as .,-' out of strings -->
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                        <!--                        <xsl:copy-of select="oape:string-mark-up-names(., $p_id-change)"/>-->
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <!-- 8. to do: <persNames> consisting of only two words "... al-...". assume that these are forename and surname -->
            <xsl:when test="matches($v_input, '^(\w+)\s+(ال\w+)$')">
                <xsl:analyze-string regex="(\w+)\s+(ال\w+)" select="$v_input">
                    <xsl:matching-substring>
                        <xsl:element name="forename">
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="cert" select="'low'"/>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:element>
                        <xsl:text> </xsl:text>
                        <xsl:element name="surname">
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="cert" select="'low'"/>
                            <xsl:value-of select="regex-group(2)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <!-- this should not be necessary -->
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
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
    <!-- this function takes a string as input and tries to find it in a nymlist. It will then try and wrap it in a name element -->
    <xsl:function name="oape:look-up-nym-and-mark-up-name">
        <xsl:param as="xs:string" name="p_input"/>
        <xsl:param name="p_authority-file"/>
        <xsl:param name="p_id-change"/>
        <!-- try to find it in the nymlist -->
        <xsl:choose>
            <xsl:when test="$p_authority-file/descendant::tei:listNym/tei:nym/tei:form = $p_input">
                <!-- <xsl:message><xsl:text>found </xsl:text><xsl:value-of select="$p_input"/><xsl:text> in nymList</xsl:text></xsl:message>-->
                <xsl:variable name="v_nymlist" select="$v_file-nyms/descendant::tei:listNym[tei:nym/tei:form = $p_input]"/>
                <xsl:variable name="v_type" select="$v_nymlist/@type"/>
                <!-- establish the kind of nym -->
                <xsl:choose>
                    <xsl:when test="$v_type = ('title', 'honorific', 'nobility', 'rank')">
                        <xsl:element name="roleName">
                            <xsl:attribute name="type" select="$v_type"/>
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="cert" select="'high'"/>
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
    <!-- contrary to its name and the value of the type attribute of results, this function mainly removes <roleName> nodes. -->
    <xsl:function name="oape:name-remove-addnames">
        <xsl:param as="node()" name="p_persname"/>
        <xsl:param as="xs:string" name="p_xml-id-output"/>
        <xsl:param as="xs:string" name="p_id-change"/>
        <xsl:variable name="v_persname" select="$p_persname/descendant-or-self::tei:persName"/>
        <xsl:variable name="v_type" select="'noAddName'"/>
        <!-- write content to variable in order to then generate a unique @xml:id -->
        <xsl:variable name="v_output">
            <xsl:element name="tei:persName">
                <!-- document change -->
                <xsl:if test="$p_id-change != ''">
                    <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                </xsl:if>
                <xsl:attribute name="type" select="$v_type"/>
                <!-- xml:id -->
                <xsl:if test="$p_xml-id-output != ''">
                    <xsl:attribute name="xml:id" select="$p_xml-id-output"/>
                </xsl:if>
                <!-- reproduce language attributes -->
                <xsl:apply-templates mode="m_identity-transform" select="$v_persname/@xml:lang"/>
                <xsl:apply-templates mode="m_remove-rolename" select="$v_persname/node()"/>
            </xsl:element>
        </xsl:variable>
        <xsl:if test="normalize-space($v_output) != ''">
            <xsl:copy-of select="$v_output"/>
        </xsl:if>
    </xsl:function>
    <!-- this function produces a flattened name -->
    <xsl:function name="oape:name-flattened_old">
        <xsl:param as="node()" name="p_persname"/>
        <xsl:param as="xs:string" name="p_xml-id-output"/>
        <xsl:param as="xs:string" name="p_id-change"/>
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
        <xsl:variable name="v_xml-id">
            <xsl:choose>
                <xsl:when test="$p_xml-id-output != ''">
                    <xsl:value-of select="$p_xml-id-output"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="oape:generate-xml-id($v_output/tei:persName)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- output -->
        <xsl:copy select="$v_output/tei:persName">
            <!-- generate xml:id -->
            <xsl:attribute name="xml:id" select="$v_xml-id"/>
            <xsl:apply-templates mode="m_identity-transform" select="$v_output/tei:persName/@* | $v_output/tei:persName/node()"/>
        </xsl:copy>
    </xsl:function>
    <!-- this is the new version -->
    <xsl:function name="oape:name-flattened">
        <xsl:param as="node()" name="p_persname"/>
        <xsl:param as="xs:string" name="p_xml-id-output"/>
        <xsl:param as="xs:string" name="p_id-change"/>
        <xsl:variable name="v_persname" select="$p_persname/descendant-or-self::tei:persName"/>
        <xsl:variable name="v_type" select="'flattened'"/>
        <xsl:element name="tei:persName">
            <!-- document change -->
            <xsl:if test="$p_id-change != ''">
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            </xsl:if>
            <xsl:attribute name="type" select="$v_type"/>
            <!-- the flattened string should point back to its origin -->
            <xsl:if test="$v_persname/@xml:id">
                <xsl:attribute name="corresp" select="concat('#', $v_persname/@xml:id)"/>
            </xsl:if>
            <!-- xml:id -->
            <xsl:if test="$p_xml-id-output != ''">
                <xsl:attribute name="xml:id" select="$p_xml-id-output"/>
            </xsl:if>
            <!-- reproduce language attributes -->
            <xsl:apply-templates mode="m_identity-transform" select="$v_persname/@xml:lang"/>
            <!-- content -->
            <xsl:value-of select="oape:string-remove-spaces(oape:string-normalise-characters($v_persname))"/>
        </xsl:element>
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
        <xsl:if test="$p_debug = true()">
            <xsl:message>
                <xsl:text>oape:name-add-markup</xsl:text>
            </xsl:message>
            <xsl:if test="$p_verbose = true()">
                <xsl:message>
                    <xsl:text>$p_persname: </xsl:text>
                    <xsl:copy-of select="$p_persname"/>
                </xsl:message>
            </xsl:if>
        </xsl:if>
        <xsl:apply-templates mode="m_mark-up" select="$p_persname"/>
    </xsl:function>
    <xsl:template match="tei:persName | tei:forename | tei:surname | tei:addName | tei:roleName | @*" mode="m_mark-up" priority="10">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <!-- add @xml:id if it isn't there -->
            <xsl:if test="not(@xml:id)">
                <xsl:attribute name="xml:id" select="oape:generate-xml-id(.)"/>
            </xsl:if>
            <xsl:apply-templates mode="m_mark-up"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:persName[not(@type = ('flattened', 'noAddName'))]/text() | tei:forename/text() | tei:surname/text()" mode="m_mark-up" priority="10">
        <xsl:choose>
            <!-- make shure that the input is more than whitespace -->
            <xsl:when test="matches(., '^\s+$')">
                <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>Input: </xsl:text>
                        <xsl:copy-of select="."/>
                    </xsl:message>
                </xsl:if>
                <!-- SOLVED: this strips symbols such as .,-' out of strings -->
                <xsl:copy-of select="oape:string-mark-up-names(string(.), $p_id-change)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:roleName | tei:nameLink[not(parent::tei:addName)]" mode="m_remove-rolename" priority="10"/>
    <xsl:template match="tei:persName | tei:persName/descendant::node() | @*" mode="m_remove-rolename">
        <xsl:copy>
            <xsl:apply-templates mode="m_remove-rolename" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id" mode="m_remove-rolename"/>
    <!-- this function takes a <tei:placeName> as input, tries to look it up in an authority file and returns a <tei:placeName> -->
    <xsl:function name="oape:link-placename-to-authority-file">
        <xsl:param name="p_placename"/>
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:param name="p_authority-file"/>
        <!-- flatened version of the persName without non-word characters -->
        <xsl:variable name="v_name-normalised" select="normalize-space(oape:string-normalise-arabic($p_placename))"/>
        <!-- this can potentially return multiple places if the toponym matches to multiple places -->
        <xsl:variable name="v_corresponding-place">
            <xsl:choose>
                <!-- test if this node already points to an authority file -->
                <xsl:when test="$p_placename/@ref">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The input already points to an authority file</xsl:message>
                    </xsl:if>
                    <!-- there seems to be a problem with this function -->
                    <xsl:copy-of select="oape:get-entity-from-authority-file($p_placename, $p_local-authority, $p_authority-file)"/>
                </xsl:when>
                <!-- test if the name is found in the authority file -->
                <xsl:when test="$p_authority-file//tei:place/tei:placeName[oape:string-normalise-arabic(.) = $v_name-normalised]">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The normalised input has been found in the authority file</xsl:message>
                    </xsl:if>
                    <xsl:copy-of select="$p_authority-file//tei:place/tei:placeName[oape:string-normalise-arabic(.) = $v_name-normalised]/parent::tei:place"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The input has not been found in the authority file</xsl:message>
                    </xsl:if>
                    <!-- one cannot use a boolean value if the default result is non-boolean -->
                    <xsl:value-of select="'NA'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- name is found in the authority file. it will be linked and potentially updated -->
            <xsl:when test="$v_corresponding-place/descendant-or-self::tei:place">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>"</xsl:text>
                        <xsl:value-of select="normalize-space($p_placename)"/>
                        <xsl:text>" is present in the authority file and will be linked</xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- construct @ref pointing to the corresponding entry -->
                <xsl:variable name="v_ref" select="oape:query-place($v_corresponding-place/descendant-or-self::tei:place[1], 'tei-ref', '', $p_local-authority)"/>
                <!-- replicate node -->
                <xsl:copy select="$p_placename">
                    <!-- replicate attributes -->
                    <xsl:apply-templates mode="m_identity-transform" select="$p_placename/@*"/>
                    <!-- add references to IDs -->
                    <xsl:attribute name="ref" select="$v_ref"/>
                    <!-- document change -->
                    <!-- this test does not catch all changes -->
                    <xsl:if test="normalize-space($p_placename/@ref) != $v_ref">
                        <xsl:attribute name="resp" select="'#xslt'"/>
                        <xsl:choose>
                            <xsl:when test="not($p_placename/@change)">
                                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="m_documentation" select="$p_placename/@change"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    <!-- replicate content -->
                    <xsl:apply-templates mode="m_identity-transform" select="node()"/>
                </xsl:copy>
            </xsl:when>
            <!-- fallback: name is not found in the authority file -->
            <xsl:when test="$v_corresponding-place = 'NA'">
                <!--                <xsl:if test="$p_verbose = true()">-->
                <xsl:message>
                    <xsl:text> The input "</xsl:text>
                    <xsl:value-of select="normalize-space($p_placename)"/>
                    <xsl:text>" was not found in authority file.</xsl:text>
                </xsl:message>
                <xsl:message>
                    <xsl:text>Add the following place to the authority file: </xsl:text>
                    <xsl:element name="place">
                        <xsl:apply-templates mode="m_copy-from-source" select="$p_placename"/>
                    </xsl:element>
                </xsl:message>
                <!--</xsl:if>-->
                <xsl:copy select="$p_placename">
                    <xsl:attribute name="ref" select="'NA'"/>
                    <xsl:attribute name="resp" select="'#xslt'"/>
                    <xsl:apply-templates mode="m_identity-transform" select="$p_placename/@* | $p_placename/node()"/>
                </xsl:copy>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    <!-- this function takes a <tei:placeName> as input, tries to look it up in an authority file and returns a <tei:placeName> -->
    <xsl:function name="oape:link-orgname-to-authority-file">
        <xsl:param name="p_orgname"/>
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:param name="p_authority-file"/>
        <!-- flatened version of the persName without non-word characters -->
        <xsl:variable name="v_name-normalised" select="lower-case(normalize-space(oape:string-normalise-arabic($p_orgname)))"/>
        <!-- this can potentially return multiple places if the toponym matches to multiple places -->
        <xsl:variable name="v_corresponding-org">
            <xsl:choose>
                <!-- test if this node already points to an authority file -->
                <xsl:when test="$p_ignore-existing-refs = false() and $p_orgname/@ref">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The input already points to an authority file</xsl:message>
                    </xsl:if>
                    <!-- there seems to be a problem with this function -->
                    <xsl:copy-of select="oape:get-entity-from-authority-file($p_orgname, $p_local-authority, $p_authority-file)"/>
                </xsl:when>
                <!-- test if the name is found in the authority file -->
                <xsl:when test="$p_authority-file//tei:org/tei:orgName[lower-case(oape:string-normalise-arabic(.)) = $v_name-normalised]">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The normalised input has been found in the authority file</xsl:message>
                    </xsl:if>
                    <xsl:copy-of select="$p_authority-file//tei:org/tei:orgName[lower-case(oape:string-normalise-arabic(.)) = $v_name-normalised]/parent::tei:org"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The input has not been found in the authority file</xsl:message>
                    </xsl:if>
                    <!-- one cannot use a boolean value if the default result is non-boolean -->
                    <xsl:value-of select="'NA'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- name is found in the authority file. it will be linked and potentially updated -->
            <xsl:when test="$v_corresponding-org/descendant-or-self::tei:org">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>"</xsl:text>
                        <xsl:value-of select="normalize-space($p_orgname)"/>
                        <xsl:text>" is present in the authority file and will be linked</xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- construct @ref pointing to the corresponding entry -->
                <xsl:variable name="v_ref" select="oape:query-org($v_corresponding-org/descendant-or-self::tei:org[1], 'tei-ref', '', $p_local-authority)"/>
                <!-- replicate node -->
                <xsl:copy select="$p_orgname">
                    <!-- replicate attributes -->
                    <xsl:apply-templates mode="m_identity-transform" select="$p_orgname/@*"/>
                    <!-- add references to IDs -->
                    <xsl:attribute name="ref" select="$v_ref"/>
                    <!-- document change -->
                    <!-- this test does not catch all changes -->
                    <xsl:if test="normalize-space($p_orgname/@ref) != $v_ref">
                        <xsl:choose>
                            <xsl:when test="not($p_orgname/@change)">
                                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="m_documentation" select="$p_orgname/@change"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:if>
                    <!-- replicate content -->
                    <xsl:apply-templates mode="m_identity-transform" select="node()"/>
                </xsl:copy>
            </xsl:when>
            <!-- fallback: name is not found in the authority file -->
            <xsl:when test="$v_corresponding-org = 'NA'">
                <!--                <xsl:if test="$p_verbose = true()">-->
                <xsl:message>
                    <xsl:text> The input "</xsl:text>
                    <xsl:value-of select="normalize-space($p_orgname)"/>
                    <xsl:text>" was not found in authority file.</xsl:text>
                </xsl:message>
                <xsl:apply-templates mode="m_identity-transform" select="$p_orgname"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    <!-- this function takes a <tei:persName> as input, tries to look it up in an authority file and returns a <tei:persName> -->
    <xsl:function name="oape:link-persname-to-authority-file">
        <xsl:param name="p_persname"/>
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:param name="p_authority-file"/>
        <xsl:param as="xs:boolean" name="p_add-mark-up"/>
        <!-- flatened version of the persName without non-word characters -->
        <xsl:variable name="v_name-flat" select="oape:string-remove-spaces(oape:string-normalise-characters($p_persname))"/>
        <!-- remove all roleNames, flatten and test again -->
        <!-- test if the flattened name is present in the authority file -->
        <!-- returns a single <person> node -->
        <xsl:variable name="v_corresponding-person">
            <xsl:choose>
                <!-- test if this node already points to an authority file -->
                <xsl:when test="$p_persname/@ref[not(. = 'NA')] and not(oape:get-entity-from-authority-file($p_persname, $p_local-authority, $p_authority-file) = 'NA')">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The input already points to the local authority file</xsl:message>
                    </xsl:if>
                    <!-- there seems to be a problem with this function -->
                    <!-- PROBLEM: names that point to another authority are not found -->
                    <xsl:copy-of select="oape:get-entity-from-authority-file($p_persname, $p_local-authority, $p_authority-file)"/>
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
                    <xsl:value-of select="'NA'"/>
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
                <xsl:variable name="v_ref" select="oape:query-person($v_corresponding-person/descendant-or-self::tei:person[1], 'tei-ref', '', $p_local-authority)"/>
                <!-- replicate node -->
                <xsl:copy select="$p_persname">
                    <!-- replicate attributes -->
                    <xsl:apply-templates mode="m_identity-transform" select="$p_persname/@*"/>
                    <!-- add references to IDs -->
                    <xsl:attribute name="ref" select="$v_ref"/>
                    <!-- document change -->
                    <!-- this test does not catch all changes -->
                    <xsl:if test="normalize-space($p_persname/@ref) != $v_ref">
                        <xsl:attribute name="resp" select="'#xslt'"/>
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
            <xsl:when test="$v_corresponding-person = 'NA'">
                <!--                <xsl:if test="$p_verbose = true()">-->
                <xsl:message>
                    <xsl:text> The input "</xsl:text>
                    <xsl:value-of select="normalize-space($p_persname)"/>
                    <xsl:text>" was not found in authority file.</xsl:text>
                </xsl:message>
                <!--</xsl:if>-->
                <xsl:copy select="$p_persname">
                    <xsl:attribute name="ref" select="'NA'"/>
                    <xsl:attribute name="resp" select="'#xslt'"/>
                    <xsl:apply-templates mode="m_identity-transform" select="$p_persname/@* | $p_persname/node()"/>
                </xsl:copy>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    <xsl:template name="t_resp">
        <xsl:param name="p_node"/>
        <xsl:choose>
            <!-- existing automated links -->
            <xsl:when test="$p_node/@ref and $p_node/@resp = '#xslt'">
                <xsl:text>ref_xslt</xsl:text>
            </xsl:when>
            <!-- manual links -->
            <xsl:when test="$p_node/@ref and $p_node/@resp != ''">
                <xsl:text>ref_manual</xsl:text>
            </xsl:when>
            <xsl:when test="$p_node/@resp = '#xslt'">
                <xsl:text>node_xslt</xsl:text>
            </xsl:when>
            <xsl:when test="$p_node/@resp != ''">
                <xsl:text>node_manual</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>NA</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- link bibliographic data to bibliography -->
    <xsl:function name="oape:link-title-to-authority-file">
        <!-- this is the input node to be linked -->
        <xsl:param as="node()" name="p_title"/>
        <!-- identifying the relevant authority for local IDs -->
        <xsl:param as="xs:string" name="p_local-authority"/>
        <!-- the authority file -->
        <xsl:param name="p_bibliography"/>
        <!-- establish who was responsible for the mark-up -->
        <xsl:variable name="v_resp">
            <xsl:call-template name="t_resp">
                <xsl:with-param name="p_node" select="$p_title"/>
            </xsl:call-template>
        </xsl:variable>
        <!-- get the ID of the input -->
        <xsl:variable name="v_id-source" select="
                if ($p_title/@xml:id) then
                    ($p_title/@xml:id)
                else
                    ($p_title/ancestor::node()[@xml:id][1]/@xml:id)"/>
        <xsl:variable name="v_url-source" select="concat($v_url-file, '#', $v_id-source)"/>
        <!-- compile the parent bibliographic entity for the title -->
        <xsl:variable name="v_biblStruct">
            <xsl:choose>
                <xsl:when test="$p_title/ancestor::tei:biblStruct">
                    <xsl:copy select="$p_title/ancestor::tei:biblStruct[1]">
                        <xsl:apply-templates mode="m_identity-transform" select="$p_title/ancestor::tei:biblStruct[1]/@*"/>
                        <xsl:attribute name="source" select="$v_url-source"/>
                        <xsl:apply-templates mode="m_identity-transform" select="$p_title/ancestor::tei:biblStruct[1]/node()"/>
                    </xsl:copy>
                </xsl:when>
                <xsl:when test="$p_title/ancestor::tei:bibl">
                    <!-- 1. compile along @next and @prev -->
                    <xsl:variable name="v_compiled" select="oape:compile-next-prev(oape:find-first-part($p_title/ancestor::tei:bibl[1]))"/>
                    <!-- 2. convert to biblStruct for easier comparison -->
                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="$v_compiled"/>
                </xsl:when>
                <xsl:otherwise>
                    <biblStruct type="periodical">
                        <xsl:attribute name="source" select="$v_url-source"/>
                        <monogr>
                            <xsl:apply-templates mode="m_identity-transform" select="$p_title"/>
                            <xsl:element name="textLang">
                                <xsl:attribute name="mainLang" select="
                                        if ($p_title/@xml:lang) then
                                            ($p_title/@xml:lang)
                                        else
                                            ($p_title/ancestor::node()[@xml:lang][1]/@xml:lang)"> </xsl:attribute>
                            </xsl:element>
                            <imprint>
                                <!-- this should be improved -->
                                <date/>
                            </imprint>
                        </monogr>
                    </biblStruct>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- figure out if the title carries a ref attribute or if the parent bibl has an idno -->
        <xsl:variable name="v_title">
            <xsl:choose>
                <xsl:when test="$p_title/@ref">
                    <xsl:copy-of select="$p_title"/>
                </xsl:when>
                <xsl:when test="$v_biblStruct/descendant::tei:monogr/tei:idno[@type = $p_local-authority]">
                    <xsl:copy select="$p_title">
                        <xsl:apply-templates mode="m_identity-transform" select="$p_title/@*"/>
                        <xsl:attribute name="ref" select="concat($p_local-authority, ':bibl:', $v_biblStruct/descendant::tei:monogr/tei:idno[@type = $p_local-authority][1])"/>
                        <xsl:apply-templates mode="m_identity-transform" select="$p_title/node()"/>
                    </xsl:copy>
                </xsl:when>
                <xsl:when test="$v_biblStruct/descendant::tei:monogr/tei:idno[@type = 'OCLC']">
                    <xsl:copy select="$p_title">
                        <xsl:apply-templates mode="m_identity-transform" select="$p_title/@*"/>
                        <xsl:attribute name="ref" select="concat('oclc:', $v_biblStruct/descendant::tei:monogr/tei:idno[@type = 'OCLC'][1])"/>
                        <xsl:apply-templates mode="m_identity-transform" select="$p_title/node()"/>
                    </xsl:copy>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$p_title"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$p_debug = true()">
            <xsl:message>
                <xsl:copy-of select="$v_title"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="v_title-string" select="normalize-space($v_title)"/>
        <!-- some messages for providing feedback to the user -->
        <xsl:variable name="v_message-success">
            <xsl:text>SUCCESS: "</xsl:text>
            <xsl:value-of select="$v_title-string"/>
            <xsl:text>" was linked to the authority file.</xsl:text>
        </xsl:variable>
        <xsl:variable name="v_message-warning">
            <xsl:text>WARNING: "</xsl:text>
            <xsl:value-of select="$v_title-string"/>
            <xsl:text>" at </xsl:text>
            <xsl:value-of select="$v_url-source"/>
            <xsl:text> could not be linked to the authority file due to ambiguous matches.</xsl:text>
        </xsl:variable>
        <xsl:variable name="v_message-failure">
            <xsl:text>FAILURE: "</xsl:text>
            <xsl:value-of select="$v_title-string"/>
            <xsl:text>" at </xsl:text>
            <xsl:value-of select="$v_url-source"/>
            <xsl:text> could not be found in the authority file.</xsl:text>
            <xsl:if test="$p_verbose = true()">
                <xsl:text> Add </xsl:text>
                <xsl:choose>
                    <xsl:when test="$v_biblStruct != 'NA'">
                        <xsl:copy-of select="$v_biblStruct"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="m_copy-from-source" select="$p_title"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:variable>
        <!-- legitimate difference between years of publication -->
        <xsl:variable name="v_margin" select="2"/>
        <!-- select a year, the reference to be linked was made in -->
        <!-- somehow this does not return the correct dates -->
        <xsl:variable name="v_year-publication">
            <xsl:choose>
                <!-- check if the input bibl has a date -->
                <xsl:when test="$v_biblStruct//tei:imprint/tei:date[@when | @notAfter | @notBefore]">
                    <xsl:if test="$p_debug = true()">
                        <xsl:message>
                            <xsl:text>Publication year: from reference </xsl:text>
                            <xsl:value-of select="oape:query-biblstruct($v_biblStruct, 'date', '', '', '')"/>
                        </xsl:message>
                    </xsl:if>
                    <xsl:value-of select="oape:date-year-only(oape:query-biblstruct($v_biblStruct, 'date-onset', '', '', ''))"/>
                </xsl:when>
                <!-- check if the input file, which is mostly the edition of a historical source, has a publication date -->
                <xsl:when test="$p_title/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct//tei:date">
                    <xsl:value-of select="oape:date-year-only(oape:query-biblstruct($p_title/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct[1], 'date', '', '', ''))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'NA'"/>
                    <!--                    <xsl:value-of select="year-from-date(current-date())"/>-->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- step 1: try to find the title in the authority file: currently either based on IDs in @ref or the title itself. If nothing is found the function returns 'NA' -->
        <!-- possible results: none, one, multiple -->
        <xsl:variable name="v_corresponding-bibls" select="oape:get-entity-from-authority-file($v_title/descendant-or-self::tei:title, $p_local-authority, $p_bibliography)"/>
        <!-- step 2: filter by publication date  -->
        <xsl:variable name="v_corresponding-bibls">
            <xsl:message>
                <xsl:text>Trying to find "</xsl:text>
                <xsl:value-of select="$v_title-string"/>
                <xsl:text>" in the authority file</xsl:text>
            </xsl:message>
            <xsl:variable name="v_bibls-compiled">
                <xsl:for-each select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct">
                    <!-- this line causes trouble if the input uses a private URI scheme in @next and @prev as my authority files do -->
                    <xsl:copy-of select="oape:compile-next-prev(.)"/>
                </xsl:for-each>
            </xsl:variable>
            <xsl:for-each select="$v_bibls-compiled/descendant-or-self::tei:biblStruct">
                <xsl:variable name="v_corresponding-bibl-year" select="oape:date-year-only(oape:query-biblstruct(., 'date', '', '', ''))"/>
                <xsl:choose>
                    <!-- compare years of publication:
                        1. assuming we have known dates of first publication for all bibls: dates should NOT DIFFER by more than x years
                    -->
                    <xsl:when test="($v_corresponding-bibl-year != 'NA' and $v_year-publication != 'NA') and (floor($v_year-publication - $v_corresponding-bibl-year) &gt; $v_margin)">
                        <xsl:message>
                            <xsl:text>WARNING: Found a corresponding entry for </xsl:text>
                            <xsl:value-of select="$v_title-string"/>
                            <xsl:text> in the authority file, but it hadn't been published yet; </xsl:text>
                            <xsl:text>year of reference: </xsl:text>
                            <xsl:value-of select="$v_year-publication"/>
                            <xsl:text> | </xsl:text>
                            <xsl:text>year in bibliography: </xsl:text>
                            <xsl:value-of select="$v_corresponding-bibl-year"/>
                        </xsl:message>
                    </xsl:when>
                    <!-- compare years of publication:
                        2. the reference to be linked CANNOT have been published BEFORE the source in the authority file
                    -->
                    <!-- our authority files contain multiple <biblStruct> for a single logical publication in the case when editors, subtitles, places of publication etc. have changed. They are tied together by @next and @prev attributes
                           - we could establish which of those is in closes temporal proximity to the current text, the references occur in 
                           - we could compile these biblStruct into a single one.
                    -->
                    <!-- possible matches -->
                    <xsl:otherwise>
                        <xsl:copy-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="v_corresponding-bibl">
            <xsl:choose>
                <!-- match based on IDs from authority files -->
                <xsl:when test="$v_biblStruct/descendant::tei:idno[@type = 'OCLC'] = $p_bibliography/descendant::tei:biblStruct/descendant::tei:idno[@type = 'OCLC']">
                    <xsl:copy-of select="$p_bibliography/descendant-or-self::tei:biblStruct[descendant::tei:idno[@type = 'OCLC'] = $v_biblStruct/descendant::tei:idno[@type = 'OCLC']][1]"/>
                </xsl:when>
                <!-- test if there is a potential match -->
                <xsl:when test="$v_corresponding-bibls/descendant-or-self::tei:biblStruct">
                    <xsl:message>
                        <xsl:text>Found </xsl:text>
                        <xsl:value-of select="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct)"/>
                        <xsl:text> possible match(es) for "</xsl:text>
                        <xsl:value-of select="$v_title-string"/>
                        <xsl:text>"</xsl:text>
                    </xsl:message>
                    <!-- depending on how much information is available in v_biblStruct, we must look for further match criteria even if there is only a single corresponding bibl in the authority file -->
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>
                            <xsl:text>Trying to match further search criteria.</xsl:text>
                        </xsl:message>
                    </xsl:if>
                    <!-- develop further matching criteria -->
                    <xsl:variable name="v_type" select="$v_biblStruct/descendant-or-self::tei:biblStruct/@type"/>
                    <xsl:variable name="v_subtype" select="$v_biblStruct/descendant-or-self::tei:biblStruct/@subtype"/>
                    <xsl:variable name="v_frequency" select="$v_biblStruct/descendant-or-self::tei:biblStruct/@oape:frequency"/>
                    <xsl:variable name="v_place-publication">
                        <xsl:choose>
                            <xsl:when test="$v_biblStruct != 'NA' and oape:query-biblstruct($v_biblStruct, 'id-location', '', $v_gazetteer, $p_local-authority) != 'NA'">
                                <xsl:value-of select="oape:query-biblstruct($v_biblStruct, 'id-location', '', $v_gazetteer, $p_local-authority)"/>
                            </xsl:when>
                            <!-- proximity to the source a text is mentioned in: this causes a lot of false negatives -->
                            <!--<xsl:when test="$p_title/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct//tei:pubPlace">
                                <xsl:message>
                                    <xsl:text>WARNING: using the location found in the teiHeader for further matching based on proximity</xsl:text>
                                </xsl:message>
                                <xsl:value-of
                                    select="oape:query-biblstruct($p_title/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct[1], 'id-location', '', $v_gazetteer, $p_local-authority)"
                                />
                            </xsl:when>-->
                            <xsl:otherwise>
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="v_editor-1">
                        <xsl:choose>
                            <xsl:when test="$v_biblStruct/descendant::tei:monogr/tei:editor[tei:persName]">
                                <xsl:copy-of
                                    select="oape:query-personography($v_biblStruct/descendant::tei:monogr/tei:editor[tei:persName][1]/tei:persName[1], $v_personography, $p_local-authority, 'id', '')"
                                />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:if test="$p_verbose">
                                    <xsl:message>
                                        <xsl:text>The reference has no machine-actionable information on editors</xsl:text>
                                    </xsl:message>
                                </xsl:if>
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- language -->
                    <xsl:variable name="v_textlang" select="oape:query-biblstruct($v_biblStruct, 'mainLang', '', '', '')"/>
                    <!-- quick debugging -->
                    <xsl:if test="$p_debug = true()">
                        <xsl:message>
                            <xsl:value-of select="'v_biblStruct: '"/>
                            <xsl:copy-of select="$v_biblStruct"/>
                        </xsl:message>
                        <xsl:message>
                            <xsl:value-of select="concat('type: ', $v_type, '; ')"/>
                            <xsl:value-of select="concat('mainLang: ', $v_textlang)"/>
                        </xsl:message>
                        <xsl:message>
                            <xsl:text>place: </xsl:text>
                            <xsl:copy-of select="$v_place-publication"/>
                        </xsl:message>
                    </xsl:if>
                    <!-- try to use further match criteria -->
                    <xsl:choose>
                        <!-- 1. negative hits: excluding criteria -->
                        <!-- different places of publication -->
                        <!-- This currently generates a lot of false negatives due to the construction of $v_place-publication, which pulls in the publication place of the primary source as  -->
                        <xsl:when
                            test="$v_place-publication != 'NA' and count($v_corresponding-bibls/descendant-or-self::tei:biblStruct) = 1 and $v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) != $v_place-publication]">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" but with a different place of publication.</xsl:text>
                                    <xsl:text> source: </xsl:text>
                                    <xsl:value-of select="$v_place-publication"/>
                                    <xsl:text> bibliography: </xsl:text>
                                    <xsl:value-of select="oape:query-biblstruct($v_corresponding-bibls/descendant-or-self::tei:biblStruct, 'id-location', '', $v_gazetteer, $p_local-authority)"/>
                                </xsl:message>
                            </xsl:if>
                            <xsl:value-of select="'NA'"/>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-failure"/>
                            </xsl:message>
                        </xsl:when>
                        <!-- 2. positive hits -->
                        <!-- @types and location -->
                        <xsl:when
                            test="$v_place-publication != 'NA' and count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication]) = 1">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" based on @type @subtype, and location.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:copy-of
                                select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication]"/>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-success"/>
                            </xsl:message>
                        </xsl:when>
                        <!-- @types and frequency -->
                        <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][@oape:frequency = $v_frequency]) = 1">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" based on @type @subtype, and @oape:frequency.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:copy-of select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][@oape:frequency = $v_frequency]"/>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-success"/>
                            </xsl:message>
                        </xsl:when>
                        <!-- location: single match -->
                        <xsl:when
                            test="$v_place-publication != 'NA' and count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication]) = 1">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" based on location.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:copy-of
                                select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication]"/>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-success"/>
                            </xsl:message>
                        </xsl:when>
                        <!-- involved editors -->
                        <xsl:when
                            test="$v_editor-1 != 'NA' and count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'id-editor', '', $v_gazetteer, $p_local-authority) = $v_editor-1]) = 1">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" based on the editor.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:copy-of select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'id-editor', '', $v_gazetteer, $p_local-authority) = $v_editor-1]"/>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-success"/>
                            </xsl:message>
                        </xsl:when>
                        <!-- @type and @subtype criteria -->
                        <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype]) = 1">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" based on @type and @subtype.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:copy-of select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype]"/>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-success"/>
                            </xsl:message>
                        </xsl:when>
                        <!-- date: onset, terminus, range -->
                        <!--<xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:date-year-only(oape:query-biblstruct(., 'date', '', '', '')) &lt;= $p_year]) = 1"><xsl:message><xsl:text>Found a single match based on publication date.</xsl:text></xsl:message><xsl:copy-of select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:date-year-only(oape:query-biblstruct(., 'date', '', '', '')) &lt;= $p_year]"/></xsl:when>-->
                        <!-- single match based on @ref -->
                        <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct) = 1 and $v_title/descendant-or-self::tei:title/@ref">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" based on the @ref attribute.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:copy-of select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct"/>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-success"/>
                            </xsl:message>
                        </xsl:when>
                        <!-- matching only the title: weak match -->
                        <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct) = 1">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" solely based on the title.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:message>
                                <xsl:choose>
                                    <xsl:when test="$p_link-matches-based-on-title-only = true()">
                                        <xsl:text>SUCCESS: A weak match for "</xsl:text>
                                        <xsl:value-of select="$v_title-string"/>
                                        <xsl:text>" was linked to the authority file.</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="$p_link-matches-based-on-title-only = false()">
                                        <xsl:text>WARNING: A weak match for "</xsl:text>
                                        <xsl:value-of select="$v_title-string"/>
                                        <xsl:text>" was not linked to the authority file.</xsl:text>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:message>
                            <xsl:choose>
                                <xsl:when test="$p_link-matches-based-on-title-only = true()">
                                    <xsl:copy-of select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="'NA'"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <!-- location: multiple matches -->
                        <xsl:when
                            test="$v_place-publication != 'NA' and count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication]) &gt; 1">
                            <xsl:message>
                                <xsl:text>Found </xsl:text>
                                <xsl:value-of
                                    select="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication])"/>
                                <xsl:text> matches for "</xsl:text>
                                <xsl:value-of select="$v_title-string"/>
                                <xsl:text>" based on location (</xsl:text>
                                <xsl:value-of select="$v_place-publication"/>
                                <xsl:text>)</xsl:text>
                            </xsl:message>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-warning"/>
                            </xsl:message>
                            <xsl:value-of select="'NA'"/>
                        </xsl:when>
                        <!-- calculate distance between locations of publication -->
                        <!-- we know that many periodicals are first and foremost self-referential. If the referenced title matches the title of the current periodical, we consider it a match -->
                        <xsl:when test="$p_title/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title = $p_title">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>We consider "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" a self reference</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:copy-of select="$p_title/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct[tei:monogr/tei:title = $p_title][1]"/>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-success"/>
                            </xsl:message>
                        </xsl:when>
                        <!-- match textLang -->
                        <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'mainLang', '', '', '') = $v_textlang]) = 1">
                            <xsl:if test="$p_verbose = true()">
                                <xsl:message>
                                    <xsl:text>Found a single match for "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" based on textLang.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:copy-of select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'mainLang', '', '', '') = $v_textlang]"/>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-success"/>
                            </xsl:message>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test="$p_debug = true()">
                                <xsl:message>
                                    <xsl:text>Found no unambiguous match for "</xsl:text>
                                    <xsl:value-of select="$v_title-string"/>
                                    <xsl:text>" at </xsl:text>
                                    <xsl:value-of select="$v_url-source"/>
                                    <xsl:text>.</xsl:text>
                                </xsl:message>
                            </xsl:if>
                            <xsl:message>
                                <xsl:copy-of select="$v_message-warning"/>
                            </xsl:message>
                            <xsl:value-of select="'NA'"/>
                            <!-- quick debugging -->
                            <!--<xsl:message><xsl:copy-of select="$v_corresponding-bibls"/></xsl:message>-->
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <!-- this is not a duplicate message -->
                    <xsl:message>
                        <xsl:copy-of select="$v_message-failure"/>
                    </xsl:message>
                    <xsl:value-of select="'NA'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- output -->
        <xsl:choose>
            <!-- fallback: name is not found in the authority file, return input -->
            <xsl:when test="$v_corresponding-bibl = 'NA'">
                <!--<xsl:copy-of select="$p_title"/>-->
                <xsl:element name="title">
                    <xsl:apply-templates mode="m_identity-transform" select="$p_title/@*"/>
                    <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                    <xsl:attribute name="ref" select="'NA'"/>
                    <xsl:attribute name="resp" select="'#xslt'"/>
                    <xsl:apply-templates mode="m_identity-transform" select="$p_title/node()"/>
                </xsl:element>
            </xsl:when>
            <!-- name is found in the authority file. it will be linked and potentially updated -->
            <xsl:otherwise>
                <xsl:variable name="v_ref" select="oape:query-biblstruct($v_corresponding-bibl, 'tei-ref', '', '', $p_local-authority)"/>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>The title will be updated with a @ref pointing to the authority file </xsl:text>
                    </xsl:message>
                </xsl:if>
                <!-- output -->
                <xsl:variable name="v_title">
                    <xsl:element name="title">
                        <xsl:apply-templates mode="m_identity-transform" select="$p_title/@*"/>
                        <!-- add references to IDs -->
                        <xsl:if test="$v_ref != 'NA'">
                            <xsl:attribute name="ref" select="$v_ref"/>
                            <!-- document change -->
                            <xsl:if test="normalize-space($p_title/@ref) != $v_ref">
                                <xsl:choose>
                                    <xsl:when test="not($p_title/@change)">
                                        <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates mode="m_documentation" select="$p_title/@change"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>
                            <!-- document agent of change -->
                            <xsl:if test="$v_resp != 'ref_manual'">
                                <xsl:attribute name="resp" select="'#xslt'"/>
                            </xsl:if>
                        </xsl:if>
                        <!-- replicate content -->
                        <xsl:apply-templates mode="m_identity-transform" select="$p_title/node()"/>
                    </xsl:element>
                </xsl:variable>
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>updated title node: </xsl:text>
                        <xsl:copy-of select="$v_title-string"/>
                    </xsl:message>
                </xsl:if>
                <xsl:copy-of select="$v_title"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- copy from authority file should not include @xml:id and @change -->
    <xsl:template match="node() | @*" mode="m_copy-from-authority-file">
        <xsl:copy>
            <xsl:apply-templates mode="m_copy-from-authority-file" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_copy-from-authority-file" priority="10"/>
    <xsl:template match="text()" mode="m_copy-from-source m_copy-from-authority-file" priority="10">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    <!-- document changes on changed elements by means of the @change attribute linking to the @xml:id of the <tei:change> element -->
    <xsl:template match="@change" mode="m_documentation">
        <xsl:attribute name="change">
            <xsl:value-of select="concat(., ' #', $p_id-change)"/>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="text()" mode="m_plain-text">
        <xsl:value-of select="concat(' ', normalize-space(.), ' ')"/>
    </xsl:template>
    <!-- helper function: convert ISO date to year only -->
    <xsl:function name="oape:date-year-only">
        <xsl:param as="xs:string" name="p_date"/>
        <xsl:choose>
            <xsl:when test="matches($p_date, '^\d{4}$|^\d{4}-.{2}-.{2}$')">
                <xsl:value-of select="number(replace($p_date, '^(\d{4}).*$', '$1'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'NA'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <!-- function to find references to periodicals in strings of Arabic text -->
    <xsl:function name="oape:find-references-to-periodicals">
        <xsl:param as="xs:string" name="p_text"/>
        <!-- find the token identifying a periodical and followed by a likely title -->
        <!-- there was a problem with the first regex trying to match 1 or more words starting with "al-" and a possible additional adjective -->
        <!-- I fixed this by explicitly excluding words ending on "iyya" from the first group of words -->
        <!-- <xsl:variable name="v_regex-1" select="'(\W|و|^)((مجلة|جريدة)\s+)((ال\w+[^ية]\s+)+?)(ال\w+ية)*'"/> -->
        <!-- regex: 3 groups -->
        <xsl:variable name="v_regex-marker" select="'(\W|و|ف|ب|^)((مجلة|جريدة)\s+)'"/>
        <!-- regex 1: 3 + 4 groups -->
        <!-- PROBLEM: negative lookahead assertion is seemingly unsupported -->
        <!--        <xsl:variable name="v_regex-1" select="concat($v_regex-marker, '(((?!ال\w+ية)(ال\w+)\s+)+)(\W*ال\w+ية)?')"/>-->
        <!-- regex 1: 3 + 2 groups -->
        <xsl:variable name="v_regex-1" select="concat($v_regex-marker, '((ال\w+\s*)+)')"/>
        <!-- regex 2: 6 groups,  works well -->
        <xsl:variable name="v_regex-2" select="'(\W|و|^)((مجلة|جريدة)\s+\()(.+?)(\)\s*(ال\w+ية)*)'"/>
        <!-- regex 3: 3 + 2 groups. matches single words or iḍāfa after the marker -->
        <xsl:variable name="v_regex-3" select="concat($v_regex-marker, '(\w+(\s+ال\w+)*)')"/>
        <xsl:analyze-string flags="m" regex="{concat($v_regex-1, '|', $v_regex-2, '|', $v_regex-3)}" select="$p_text">
            <xsl:matching-substring>
                <xsl:variable name="v_regex-1-count-groups" select="5"/>
                <xsl:variable name="v_regex-2-count-groups" select="$v_regex-1-count-groups + 6"/>
                <xsl:if test="$p_debug = true()">
                    <xsl:message>
                        <xsl:text>The string"</xsl:text>
                        <xsl:value-of select="."/>
                        <xsl:text>" could be a reference to a periodical title</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:choose>
                    <!-- sequence matters -->
                    <xsl:when test="matches(., $v_regex-2)">
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>The potential title is wrapped in brackets, which strongly indicate a named entity</xsl:text>
                                <!--<xsl:value-of select="."/><xsl:text> matches </xsl:text><xsl:value-of select="$v_regex-2"/>-->
                            </xsl:message>
                        </xsl:if>
                        <xsl:value-of select="regex-group($v_regex-1-count-groups + 1)"/>
                        <xsl:call-template name="t_ner-add-bibl">
                            <xsl:with-param name="p_prefix" select="regex-group($v_regex-1-count-groups + 2)"/>
                            <xsl:with-param name="p_title" select="regex-group($v_regex-1-count-groups + 4)"/>
                            <xsl:with-param name="p_suffix" select="regex-group($v_regex-1-count-groups + 5)"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- regex 1 with ending with  al-....iyya -->
                    <xsl:when test="matches(., $v_regex-1) and matches(., '^(.+)ال\w+ية\s*$')">
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:value-of select="."/>
                                <xsl:text> matches </xsl:text>
                                <xsl:value-of select="$v_regex-1"/>
                                <xsl:text> and ends in "iyya"</xsl:text>
                            </xsl:message>
                        </xsl:if>
                        <xsl:value-of select="regex-group(1)"/>
                        <xsl:call-template name="t_ner-add-bibl">
                            <xsl:with-param name="p_prefix" select="regex-group(2)"/>
                            <xsl:with-param name="p_title" select="replace(regex-group(4), '^(.+)(ال\w+ية)\s*$', '$1')"/>
                            <xsl:with-param name="p_suffix" select="replace(regex-group(4), '^(.+)(ال\w+ية)\s*$', '$2')"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="matches(., $v_regex-1)">
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>The potential title is a single noun with the determinded article "al-".</xsl:text>
                                <!--<xsl:value-of select="."/><xsl:text> matches </xsl:text><xsl:value-of select="$v_regex-1"/>-->
                            </xsl:message>
                            <xsl:message>
                                <xsl:text>We consider this to be a good enough indicator and added mark-up.</xsl:text>
                            </xsl:message>
                        </xsl:if>
                        <xsl:value-of select="regex-group(1)"/>
                        <xsl:call-template name="t_ner-add-bibl">
                            <xsl:with-param name="p_prefix" select="regex-group(2)"/>
                            <xsl:with-param name="p_title" select="regex-group(4)"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="matches(., $v_regex-3)">
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>The potential title is a single indeterminded word or an iḍāfa.</xsl:text>
                                <!--<xsl:value-of select="."/><xsl:text> matches </xsl:text><xsl:value-of select="$v_regex-3"/>-->
                            </xsl:message>
                        </xsl:if>
                        <xsl:variable name="v_title">
                            <xsl:element name="title">
                                <xsl:attribute name="level" select="'j'"/>
                                <xsl:value-of select="normalize-space(regex-group($v_regex-2-count-groups + 4))"/>
                            </xsl:element>
                        </xsl:variable>
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>The potential title "</xsl:text>
                                <xsl:value-of select="$v_title"/>
                                <xsl:text>" will be checked against the authority file</xsl:text>
                            </xsl:message>
                        </xsl:if>
                        <xsl:variable name="v_title-linked">
                            <xsl:copy-of select="oape:link-title-to-authority-file($v_title//tei:title, $p_local-authority, $v_bibliography)"/>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$v_title-linked/tei:title/@ref != 'NA'">
                                <xsl:if test="$p_debug = true()">
                                    <xsl:message>
                                        <xsl:text>The input was indeed a periodical title</xsl:text>
                                    </xsl:message>
                                </xsl:if>
                                <xsl:value-of select="regex-group($v_regex-2-count-groups + 1)"/>
                                <xsl:call-template name="t_ner-add-bibl">
                                    <xsl:with-param name="p_prefix" select="regex-group($v_regex-2-count-groups + 2)"/>
                                    <xsl:with-param name="p_title" select="$v_title-linked/tei:title"/>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    <xsl:function name="oape:find-references-to-people">
        <xsl:param as="xs:string" name="p_text"/>
        <xsl:param as="xs:integer" name="p_window-size"/>
        <xsl:variable name="v_text" select="normalize-space($p_text)"/>
        <!-- plan:
            - tokenize text along whitespace
            - find titles etc. 
            - look a limited number of tokens (5?) in both directions and check whether they qualify as names
        -->
        <!-- 1. tokenize input text along whitespace and find titles based on a nym list -->
        <xsl:variable name="v_step-1">
            <xsl:for-each select="tokenize($v_text, ' ')">
                <xsl:variable name="v_word" select="."/>
                <xsl:choose>
                    <xsl:when test="$v_word = $v_file-nyms/descendant::tei:listNym[@type = ('title', 'honorific', 'nobility', 'rank')]/descendant::tei:form">
                        <xsl:variable name="v_nym" select="$v_file-nyms/descendant::tei:listNym[@type = ('title', 'honorific', 'nobility', 'rank')]/tei:nym[tei:form = $v_word]"/>
                        <xsl:element name="name">
                            <xsl:attribute name="resp" select="'#xslt'"/>
                            <xsl:attribute name="ref" select="concat($p_local-authority, ':nym:', $v_nym/@xml:id)"/>
                            <xsl:value-of select="$v_word"/>
                        </xsl:element>
                        <xsl:text> </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="w">
                            <xsl:value-of select="$v_word"/>
                        </xsl:element>
                        <xsl:text> </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <!-- 2. check if the titles from step 1 are followed by other names -->
        <xsl:variable name="v_step-2">
            <!-- something is wrong with the group-starting with argument -->
            <xsl:for-each-group group-starting-with="tei:name" select="$v_step-1/*">
                <xsl:variable name="v_group">
                    <xsl:copy-of select="current-group()"/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$v_group/tei:name">
                        <!-- select first x words -->
                        <xsl:variable name="v_window">
                            <xsl:copy-of select="$v_group/tei:w[position() &lt;= $p_window-size]"/>
                        </xsl:variable>
                        <xsl:variable name="v_trailing">
                            <xsl:copy-of select="$v_group/tei:w[position() gt $p_window-size]"/>
                        </xsl:variable>
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>current-group(): </xsl:text>
                                <xsl:value-of select="current-group()"/>
                            </xsl:message>
                            <xsl:message>
                                <xsl:text>$v_window: </xsl:text>
                                <xsl:apply-templates mode="m_plain-text" select="$v_window"/>
                            </xsl:message>
                            <xsl:message>
                                <xsl:text>$v_trailing: </xsl:text>
                                <xsl:apply-templates mode="m_plain-text" select="$v_trailing"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:copy-of select="$v_group/tei:name"/>
                        <xsl:text> </xsl:text>
                        <xsl:for-each select="$v_window/tei:w">
                            <xsl:apply-templates mode="m_link-nym" select="."/>
                            <!--<xsl:if test="position() != last()"><xsl:text></xsl:text></xsl:if>-->
                        </xsl:for-each>
                        <!--<xsl:for-each select="$v_trailing/tei:w"><xsl:copy-of select="."/><xsl:if test="position() != last()"><xsl:text></xsl:text></xsl:if></xsl:for-each>-->
                        <xsl:copy-of select="$v_trailing"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$v_group"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:variable>
        <!-- 2. check if the titles from step 1 are preceded by other names -->
        <xsl:variable name="v_step-3">
            <!-- something is wrong with the group-starting with argument -->
            <xsl:for-each-group group-ending-with="tei:name" select="$v_step-2/*">
                <xsl:variable name="v_group">
                    <xsl:copy-of select="current-group()"/>
                </xsl:variable>
                <xsl:variable name="v_pos-max" select="count($v_group/tei:w)"/>
                <xsl:variable name="v_window-size" select="$v_pos-max - $p_window-size"/>
                <xsl:choose>
                    <xsl:when test="$v_group/tei:name">
                        <!-- select first x words -->
                        <xsl:variable name="v_window">
                            <xsl:copy-of select="$v_group/tei:w[position() &gt;= $v_window-size]"/>
                        </xsl:variable>
                        <xsl:variable name="v_preceding">
                            <xsl:copy-of select="$v_group/tei:w[position() lt $v_window-size]"/>
                        </xsl:variable>
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>current-group(): </xsl:text>
                                <xsl:value-of select="current-group()"/>
                            </xsl:message>
                            <xsl:message>
                                <xsl:text>$v_window: </xsl:text>
                                <xsl:apply-templates mode="m_plain-text" select="$v_window"/>
                            </xsl:message>
                            <xsl:message>
                                <xsl:text>$v_preceding: </xsl:text>
                                <xsl:apply-templates mode="m_plain-text" select="$v_preceding"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:copy-of select="$v_preceding"/>
                        <xsl:for-each select="$v_window/tei:w">
                            <xsl:apply-templates mode="m_link-nym" select="."/>
                            <!--<xsl:if test="position() != last()"><xsl:text></xsl:text></xsl:if>-->
                        </xsl:for-each>
                        <xsl:copy-of select="$v_group/tei:name"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$v_group"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="v_output" select="$v_step-3"/>
        <xsl:copy-of select="$v_output"/>
    </xsl:function>
    <xsl:template match="tei:w" mode="m_link-nym">
        <xsl:choose>
            <xsl:when test=". = $v_file-nyms/descendant::tei:listNym/descendant::tei:form">
                <xsl:variable name="v_nym" select="$v_file-nyms/descendant::tei:nym[tei:form = current()][1]"/>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>Found a nym for: </xsl:text>
                        <xsl:value-of select="."/>
                    </xsl:message>
                </xsl:if>
                <xsl:element name="name">
                    <xsl:attribute name="resp" select="'#xslt'"/>
                    <xsl:attribute name="ref" select="concat($p_local-authority, ':nym:', $v_nym/@xml:id)"/>
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:when>
            <!-- catch nisbas -->
            <xsl:when test="matches(., '^ال\w+ي$')">
                <xsl:element name="name">
                    <xsl:attribute name="resp" select="'#xslt'"/>
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="t_ner-add-bibl">
        <xsl:param name="p_prefix"/>
        <xsl:param name="p_title"/>
        <xsl:param name="p_suffix"/>
        <!-- test if the suffix string contains a toponym -->
        <xsl:variable name="v_place-ref">
            <xsl:choose>
                <xsl:when test="matches($p_suffix, '^.*ال(\w+)ية\s*$')">
                    <xsl:variable name="v_entity">
                        <xsl:element name="placeName">
                            <xsl:value-of select="replace($p_suffix, '^.*ال(\w+)ية\s*$', '$1')"/>
                        </xsl:element>
                    </xsl:variable>
                    <xsl:value-of select="oape:query-gazetteer($v_entity/descendant-or-self::tei:placeName, $v_gazetteer, $p_local-authority, 'tei-ref', '')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'NA'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- test if the suffix string contains information on frequency -->
        <xsl:variable as="xs:string" name="v_frequency">
            <xsl:choose>
                <xsl:when test="matches($p_suffix, '^.*اليومية\s*$')">
                    <xsl:text>daily</xsl:text>
                </xsl:when>
                <xsl:when test="matches($p_suffix, '^.*الاسبوعية\s*$')">
                    <xsl:text>weekly</xsl:text>
                </xsl:when>
                <xsl:when test="matches($p_suffix, '^.*الشهرية\s*$')">
                    <xsl:text>monthly</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'NA'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>Found reference to a periodical with </xsl:text>
                <xsl:text>title: </xsl:text>
                <xsl:value-of select="$p_title"/>
                <xsl:text>, suffix: </xsl:text>
                <xsl:value-of select="$p_suffix"/>
                <xsl:text>, toponym: </xsl:text>
                <xsl:value-of select="$v_place-ref"/>
                <xsl:text>, frequency: </xsl:text>
                <xsl:value-of select="$v_frequency"/>
            </xsl:message>
        </xsl:if>
        <!-- wrap everything in a bibl -->
        <xsl:element name="bibl">
            <xsl:attribute name="resp" select="'#xslt'"/>
            <xsl:attribute name="type" select="'periodical'"/>
            <!-- add @subtype based on $p_prefix -->
            <xsl:attribute name="subtype">
                <xsl:choose>
                    <xsl:when test="matches($p_prefix, 'جريدة')">
                        <xsl:text>newspaper</xsl:text>
                    </xsl:when>
                    <xsl:when test="matches($p_prefix, 'مجلة')">
                        <xsl:text>journal</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
            <xsl:if test="$v_frequency != 'NA'">
                <xsl:attribute name="oape:frequency" select="$v_frequency"/>
            </xsl:if>
            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            <xsl:value-of select="$p_prefix"/>
            <!-- title -->
            <xsl:element name="title">
                <xsl:attribute name="level" select="'j'"/>
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                <!-- this will remove toponyms from the title. They need to be added after the title -->
                <xsl:value-of select="normalize-space($p_title)"/>
            </xsl:element>
            <xsl:value-of select="$p_suffix"/>
            <!-- empty content with attributes to provide machine-readable data -->
            <xsl:if test="$v_place-ref != 'NA'">
                <xsl:element name="pubPlace">
                    <xsl:attribute name="resp" select="'#xslt'"/>
                    <xsl:element name="placeName">
                        <xsl:attribute name="ref" select="$v_place-ref"/>
                    </xsl:element>
                </xsl:element>
            </xsl:if>
        </xsl:element>
        <!-- add trailing whitespace -->
        <xsl:text> </xsl:text>
    </xsl:template>
    <!-- why do we need this function here -->
    <xsl:template match="tei:bibl" mode="m_bibl-to-biblStruct">
        <xsl:variable name="v_id-source" select="
                if (@xml:id) then
                    (@xml:id)
                else
                    (ancestor::node()[@xml:id][1]/@xml:id)"/>
        <xsl:variable name="v_url-source" select="concat($v_url-file, '#', $v_id-source)"/>
        <xsl:variable name="v_source">
            <xsl:choose>
                <xsl:when test="@source">
                    <xsl:value-of select="concat(@source, ' ', $v_url-source)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$v_url-source"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- publication date of the source file -->
        <xsl:variable name="v_source-date" select="document($v_url-file)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/descendant::tei:biblStruct[1]/descendant::tei:date[@when][1]/@when"/>
        <biblStruct change="#{$p_id-change}">
            <xsl:apply-templates mode="m_copy-from-source" select="@*"/>
            <!-- document source of information -->
            <xsl:attribute name="source" select="$v_source"/>
            <xsl:if test="tei:title[@level = 'a']">
                <analytic>
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:title[@level = 'a']"/>
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:author"/>
                </analytic>
            </xsl:if>
            <monogr>
                <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:title[@level != 'a']"/>
                <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:idno"/>
                <xsl:for-each select="tokenize(tei:title[@level != 'a'][@ref][1]/@ref, '\s+')">
                    <xsl:variable name="v_authority">
                        <xsl:choose>
                            <xsl:when test="contains(., 'oclc:')">
                                <xsl:text>OCLC</xsl:text>
                            </xsl:when>
                            <xsl:when test="contains(., 'jaraid:')">
                                <xsl:text>jaraid</xsl:text>
                            </xsl:when>
                            <xsl:when test="contains(., 'oape:')">
                                <xsl:text>oape</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="v_local-uri-scheme" select="concat($v_authority, ':bibl:')"/>
                    <xsl:variable name="v_idno">
                        <xsl:choose>
                            <xsl:when test="contains(., 'oclc:')">
                                <xsl:value-of select="replace(., '.*oclc:(\d+).*', '$1')"/>
                            </xsl:when>
                            <xsl:when test="contains(., $v_local-uri-scheme)">
                                <!-- local IDs in Project Jaraid are not nummeric for biblStructs -->
                                <xsl:value-of select="replace(., concat('.*', $v_local-uri-scheme, '(\w+).*'), '$1')"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <idno type="{$v_authority}">
                        <xsl:value-of select="$v_idno"/>
                    </idno>
                </xsl:for-each>
                <xsl:choose>
                    <xsl:when test="tei:textLang">
                        <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:textLang"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <textLang>
                            <xsl:attribute name="mainLang">
                                <xsl:choose>
                                    <!-- chose the language of the title -->
                                    <xsl:when test="tei:title[@level != 'a']/@xml:lang">
                                        <xsl:value-of select="tei:title[@level != 'a'][@xml:lang][1]/@xml:lang"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>ar</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                        </textLang>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="tei:title[@level != 'a']">
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:author"/>
                </xsl:if>
                <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:editor"/>
                <imprint>
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:date"/>
                    <!-- add a date at which this bibl was documented in the source file -->
                    <date source="{$v_source}" type="documented" when="{$v_source-date}"/>
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:pubPlace"/>
                    <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:publisher"/>
                </imprint>
                <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:biblScope"/>
            </monogr>
        </biblStruct>
    </xsl:template>
    <!-- do not copy certain attributes from one file to another -->
    <xsl:template match="@xml:id | @change | @next | @prev" mode="m_copy-from-source"/>
    <xsl:template match="node() | @*" mode="m_copy-from-source">
        <!-- source information -->
        <xsl:variable name="v_source">
            <xsl:variable name="v_base-uri" select="$v_url-file"/>
            <xsl:variable name="v_bibl-source" select="ancestor-or-self::node()[name() = ('bibl', 'biblStruct')]/@source"/>
            <xsl:variable name="v_bibl-id" select="ancestor-or-self::node()[name() = ('bibl', 'biblStruct')]/@xml:id"/>
            <!-- if the there is already a source on the node, replicate it -->
            <xsl:choose>
                <xsl:when test="@source != ''">
                    <xsl:value-of select="@source"/>
                </xsl:when>
                <xsl:when test="$v_bibl-source != ''">
                    <xsl:value-of select="$v_bibl-source"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($v_base-uri, '#', $v_bibl-id)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates mode="m_copy-from-source" select="@*"/>
            <!-- document change -->
            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            <!-- document source of additional information -->
            <xsl:attribute name="source" select="$v_source"/>
            <!-- content -->
            <xsl:apply-templates mode="m_copy-from-source" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:function name="oape:merge-nodes">
        <xsl:param as="node()" name="p_source"/>
        <xsl:param as="node()" name="p_target"/>
        <!-- a param to decide which node should get priority in case of conflicting attributes -->
        <xsl:param name="p_attribute-priority"/>
        <xsl:variable name="v_source-url" select="
                concat(base-uri($p_source), '#', if ($p_source/@xml:id) then
                    ($p_source/@xml:id)
                else
                    ($p_source/ancestor::node()[@xml:id][1]/@xml:id))"/>
        <xsl:variable name="v_source-name" select="$p_source/local-name()"/>
        <xsl:variable name="v_target-name" select="$p_target/local-name()"/>
        <xsl:variable name="v_nodes-to-merge" select="('biblStruct', 'monogr', 'imprint', 'note')"/>
        <xsl:if test="$p_debug = true()">
            <xsl:message>
                <xsl:text>oape:merge-nodes</xsl:text>
            </xsl:message>
            <xsl:message>
                <xsl:text>Source: </xsl:text>
                <xsl:copy-of select="$v_source-name"/>
            </xsl:message>
            <xsl:message>
                <xsl:text>Target: </xsl:text>
                <xsl:copy-of select="$v_target-name"/>
            </xsl:message>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$v_source-name = $v_target-name">
                <!-- decide whether to merge or not -->
                <xsl:variable name="v_merge">
                    <xsl:choose>
                        <!-- check if content is similar and assume that their attributes should be merged -->
                        <xsl:when test="$p_source = $p_target">
                            <xsl:copy select="true()"/>
                        </xsl:when>
                        <!-- do not merge elements that are distinguished by their type attributes -->
                        <xsl:when test="$p_source[@type]/@type != $p_target[@type]/@type">
                            <xsl:copy select="false()"/>
                        </xsl:when>
                        <!-- hard-coded list of elements to be merged if supplied to this function -->
                        <!-- this is necessary, as I cannot possibly decide this based on the content allone  -->
                        <xsl:when test="$v_source-name = $v_nodes-to-merge">
                            <xsl:copy select="true()"/>
                        </xsl:when>
                        <!-- look-up for entities -->
                        <xsl:when test="$v_source-name = ('pubPlace', 'editor', 'author', 'publisher')">
                            <xsl:choose>
                                <xsl:when test="$p_source/tei:placeName/@ref and $p_target/tei:placeName/@ref">
                                    <xsl:variable name="v_source-id" select="oape:query-gazetteer($p_source/tei:placeName[@ref][1], $v_gazetteer, $p_local-authority, 'id', '')"/>
                                    <xsl:variable name="v_target-id" select="oape:query-gazetteer($p_target/tei:placeName[@ref][1], $v_gazetteer, $p_local-authority, 'id', '')"/>
                                    <xsl:copy select="
                                            if ($v_source-id = $v_target-id) then
                                                (true())
                                            else
                                                (false())"/>
                                </xsl:when>
                                <xsl:when test="$p_source/tei:persName/@ref and $p_target/tei:persName/@ref">
                                    <xsl:variable name="v_source-id" select="oape:query-personography($p_source/tei:persName[@ref][1], $v_personography, $p_local-authority, 'id', '')"/>
                                    <xsl:variable name="v_target-id" select="oape:query-personography($p_target/tei:persName[@ref][1], $v_personography, $p_local-authority, 'id', '')"/>
                                    <xsl:copy select="
                                            if ($v_source-id = $v_target-id) then
                                                (true())
                                            else
                                                (false())"/>
                                </xsl:when>
                                <xsl:when test="$p_source/tei:orgName/@ref and $p_target/tei:orgName/@ref">
                                    <xsl:variable name="v_source-id" select="oape:query-organizationography($p_source/tei:orgName[@ref][1], $v_organizationography, $p_local-authority, 'id', '')"/>
                                    <xsl:variable name="v_target-id" select="oape:query-organizationography($p_target/tei:orgName[@ref][1], $v_organizationography, $p_local-authority, 'id', '')"/>
                                    <xsl:copy select="
                                            if ($v_source-id = $v_target-id) then
                                                (true())
                                            else
                                                (false())"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy select="false()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy select="false()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- writing initial output to variable in case it needs further processing -->
                <xsl:variable name="v_output">
                    <xsl:choose>
                        <!-- merge -->
                        <xsl:when test="$v_merge = true()">
                            <xsl:message>
                                <xsl:text>Source and target will be merged</xsl:text>
                            </xsl:message>
                            <xsl:copy select="$p_target">
                                <!-- attributes -->
                                <xsl:if test="$p_debug = true()">
                                    <xsl:message>
                                        <xsl:text>compare attributes</xsl:text>
                                    </xsl:message>
                                </xsl:if>
                                <!-- any attribute that is not there should be reproduced -->
                                <xsl:for-each select="$p_target/@*">
                                    <xsl:variable name="v_attr-name" select="name()"/>
                                    <xsl:choose>
                                        <xsl:when test="not($p_source/@*[name() = $v_attr-name])">
                                            <xsl:if test="$p_debug = true()">
                                                <xsl:message>
                                                    <xsl:value-of select="concat('@', $v_attr-name)"/>
                                                    <xsl:text> is not present in the source and will be reproduced</xsl:text>
                                                </xsl:message>
                                            </xsl:if>
                                            <xsl:apply-templates mode="m_identity-transform" select="."/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <!-- some attributes might need special treatment -->
                                            <!-- as I will version-control the target, it makes sense to just copy attributes from the source and validate changes with git -->
                                            <xsl:choose>
                                                <xsl:when test=". = $p_source/@*[name() = $v_attr-name]">
                                                    <xsl:apply-templates mode="m_identity-transform" select="."/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:message>
                                                        <xsl:text>The value of @</xsl:text>
                                                        <xsl:value-of select="$v_attr-name"/>
                                                        <xsl:text> differs. Will use the value of </xsl:text>
                                                        <xsl:value-of select="$p_attribute-priority"/>
                                                    </xsl:message>
                                                    <xsl:choose>
                                                        <xsl:when test="$p_attribute-priority = 'target'">
                                                            <xsl:apply-templates mode="m_identity-transform" select="."/>
                                                        </xsl:when>
                                                        <xsl:when test="$p_attribute-priority = 'source'">
                                                            <xsl:apply-templates mode="m_identity-transform" select="$p_source/@*[name() = $v_attr-name]"/>
                                                        </xsl:when>
                                                    </xsl:choose>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                                <xsl:for-each select="$p_source/@*">
                                    <xsl:variable name="v_attr-name" select="name()"/>
                                    <xsl:if test="not($p_target/@*[name() = $v_attr-name])">
                                        <xsl:if test="$p_debug = true()">
                                            <xsl:message>
                                                <xsl:value-of select="concat('@', $v_attr-name)"/>
                                                <xsl:text> is not present in the target and will be added</xsl:text>
                                            </xsl:message>
                                        </xsl:if>
                                        <!-- do not add @change and @xml:id -->
                                        <xsl:apply-templates mode="m_copy-from-source" select="."/>
                                    </xsl:if>
                                </xsl:for-each>
                                <!-- source information -->
                                <xsl:attribute name="source">
                                    <xsl:choose>
                                        <xsl:when test="$p_target/@source">
                                            <xsl:value-of select="concat($p_target/@source, ' ', $v_source-url)"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$v_source-url"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:attribute>
                                <!-- content -->
                                <!-- for every child of the target, check if there is a child of the source with the same name. If not, copy it. Otherwise merge  -->
                                <xsl:for-each select="$p_target/node()">
                                    <xsl:variable name="v_child-name" select="local-name()"/>
                                    <xsl:choose>
                                        <!-- all children that are not found on the source should be reproduced -->
                                        <xsl:when test="not($p_source/node()[local-name() = $v_child-name])">
                                            <xsl:message>
                                                <xsl:value-of select="concat('&lt;', $v_child-name, '&gt;')"/>
                                                <xsl:text> is not present in the source and will be reproduced</xsl:text>
                                            </xsl:message>
                                            <xsl:apply-templates mode="m_identity-transform" select="."/>
                                        </xsl:when>
                                        <!-- children with the same name but different content -->
                                        <xsl:otherwise>
                                            <xsl:message>
                                                <xsl:value-of select="concat('&lt;', $v_child-name, '&gt;')"/>
                                                <xsl:text> is present in the source and the two need to be merged</xsl:text>
                                            </xsl:message>
                                            <xsl:variable name="v_target" select="."/>
                                            <xsl:for-each select="$p_source/node()[local-name() = $v_child-name]">
                                                <xsl:variable name="v_source" select="."/>
                                                <!-- this is where we have to merge content -->
                                                <!-- probably limit to monogr, imprint: won't do anything due to the above construction of $v_merge -->
                                                <xsl:copy-of select="oape:merge-nodes($v_source, $v_target, $p_attribute-priority)"/>
                                            </xsl:for-each>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each>
                                <xsl:for-each select="$p_source/node()">
                                    <xsl:variable name="v_child-name" select="local-name()"/>
                                    <xsl:message>
                                        <xsl:text>processing &lt;</xsl:text>
                                        <xsl:value-of select="$v_child-name"/>
                                        <xsl:text>&gt;-child of source</xsl:text>
                                    </xsl:message>
                                    <xsl:if test="not($p_target/node()[local-name() = $v_child-name])">
                                        <xsl:message>
                                            <xsl:text>this child is not present in the target and will be reproduced</xsl:text>
                                        </xsl:message>
                                        <xsl:apply-templates mode="m_merge" select="."/>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:copy>
                        </xsl:when>
                        <xsl:when test="$v_merge = false()">
                            <xsl:message>
                                <xsl:text>The source will be amended to the target</xsl:text>
                            </xsl:message>
                            <xsl:apply-templates mode="m_identity-transform" select="$p_target"/>
                            <!-- add source only after all children of target of the same name -->
                            <xsl:if test="not($p_target/following-sibling::node()[local-name() = $v_target-name])">
                                <xsl:apply-templates mode="m_merge" select="$p_source"/>
                            </xsl:if>
                            <!--<xsl:choose>
                            <xsl:when test="$p_attribute-priority = 'source'">
                                <xsl:apply-templates mode="m_identity-transform" select="$p_source"/>
                            </xsl:when>
                            <xsl:when test="$p_attribute-priority = 'target'">
                                <xsl:apply-templates mode="m_identity-transform" select="$p_target"/>
                            </xsl:when>
                        </xsl:choose>-->
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <!-- further processing of output: remove duplicate descendants of biblStruct -->
                <xsl:copy-of select="$v_output"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Input and output elements are different and cannot be merged</xsl:text>
                </xsl:message>
                <xsl:apply-templates mode="m_identity-transform" select="$p_source"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="@xml:id | @change" mode="m_merge"/>
    <xsl:template match="node() | @*" mode="m_merge">
        <xsl:copy>
            <xsl:apply-templates mode="m_merge" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:function name="oape:resolve-id">
        <xsl:param as="node()" name="p_idno"/>
        <xsl:choose>
            <xsl:when test="$p_idno/@type = $p_acronym-geonames">
                <xsl:value-of select="concat($p_url-resolve-geonames, $p_idno)"/>
            </xsl:when>
            <xsl:when test="$p_idno/@type = $p_acronym-wikidata">
                <xsl:value-of select="concat($p_url-resolve-wikidata, $p_idno)"/>
            </xsl:when>
            <xsl:when test="$p_idno/@type = $p_acronym-viaf">
                <xsl:value-of select="concat($p_url-resolve-viaf, $p_idno)"/>
            </xsl:when>
            <xsl:when test="$p_idno/@type = 'ht_bib_key'">
                <xsl:value-of select="concat($p_url-resolve-hathi, $p_idno)"/>
            </xsl:when>
            <xsl:when test="$p_idno/@type = 'OCLC'">
                <xsl:value-of select="concat($p_url-resolve-oclc, $p_idno)"/>
            </xsl:when>
            <xsl:when test="$p_idno/@type = 'LEAUB'">
                <!-- the LEAUB number contains a control digit that must be removed for resolving -->
                <xsl:value-of select="concat($p_url-resolve-aub, substring($p_idno, 1, string-length($p_idno) - 1))"/>
            </xsl:when>
            <xsl:when test="$p_idno/@type = 'zdb'">
                <xsl:value-of select="concat($p_url-resolve-zdb, $p_idno)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$p_idno"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>
