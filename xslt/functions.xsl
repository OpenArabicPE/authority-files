<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" method="xml" omit-xml-declaration="no"/>
    <xsl:include href="parameters.xsl"/>
    <!-- identify the author of the change by means of a @xml:id -->
    <!-- toggle debugging messages -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    <xsl:include href="query-viaf.xsl"/>
    <xsl:include href="query-geonames.xsl"/>
    <!--<xsl:template match="/">
        <xsl:apply-templates select="descendant::tei:date" mode="m_debug"/>
    </xsl:template>-->
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
    <!-- this function queries a local authority file
        - input: an entity name such as <persName>, <orgName>, <placeName> or <title>
        - output: an entity: such as <person>, <org>, <place> or <biblStruct>
    -->
    <xsl:function name="oape:get-entity-from-authority-file">
        <!-- input: entity such as <persName>, <orgName>, <placeName> or <title> node -->
        <xsl:param as="node()" name="p_entity-name"/>
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:param name="p_authority-file"/>
        <!-- this is a rather ridiculous hack, but I don't need change IDs in the context of this function -->
        <xsl:variable name="v_id-change" select="'a1'"/>
        <xsl:variable name="v_ref" select="$p_entity-name/@ref"/>
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
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_local-uri-scheme" select="concat($p_local-authority, ':', $v_entity-type, ':')"/>
        <!-- debugging -->
        <!--<xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>p_entity-name: </xsl:text>
                <xsl:copy-of select="$p_entity-name"/>
            </xsl:message>
        </xsl:if>
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>v_entity-type: </xsl:text>
                <xsl:value-of select="$v_entity-type"/>
            </xsl:message>
        </xsl:if>-->
        <xsl:choose>
            <!-- check if the entity already links to an authority file by means of the @ref attribute -->
            <xsl:when test="$v_ref != ''">
                <xsl:variable name="v_authority">
                    <xsl:choose>
                        <xsl:when test="contains($v_ref, 'viaf:')">
                            <xsl:text>VIAF</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'geon:')">
                            <xsl:text>geon</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains($v_ref, 'oclc:')">
                            <xsl:text>OCLC</xsl:text>
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
                        <xsl:when test="contains($v_ref, 'oclc:')">
                            <xsl:value-of select="replace($v_ref, '.*oclc:(\d+).*', '$1')"/>
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
                                    <xsl:text>There is no person with the </xsl:text>
                                    <xsl:value-of select="$v_authority"/>
                                    <xsl:text>-ID </xsl:text>
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
                                    <xsl:text>There is no org with the </xsl:text>
                                    <xsl:value-of select="$v_authority"/>
                                    <xsl:text>-ID </xsl:text>
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
                                    <xsl:text>There is no place with the </xsl:text>
                                    <xsl:value-of select="$v_authority"/>
                                    <xsl:text>-ID </xsl:text>
                                    <xsl:value-of select="$v_idno"/>
                                    <xsl:text> in the authority file</xsl:text>
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'bibl'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:biblStruct//tei:idno[@type = $v_authority] = $v_idno">
                                <xsl:copy-of select="$p_authority-file//tei:biblStruct[.//tei:idno[@type = $v_authority] = $v_idno]"/>
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
                <!-- this fails for nested entities -->
                <xsl:variable name="v_name-flat" select="oape:string-normalise-characters(string($p_entity-name))"/>
                <xsl:choose>
                    <xsl:when test="$v_entity-type = 'pers'">
                        <xsl:variable name="v_name-flattened" select="oape:name-flattened($p_entity-name, '', $v_id-change)"/>
                        <xsl:variable name="v_name-marked-up" select="oape:name-add-markup($p_entity-name)"/>
                        <xsl:variable name="v_name-no-addnames" select="oape:name-remove-addnames($v_name-marked-up, '', $v_id-change)"/>
                        <xsl:variable name="v_name-no-addnames-flattened" select="oape:name-flattened($v_name-no-addnames, '', $v_id-change)"/>
                        <xsl:choose>
                            <xsl:when test="$p_authority-file//tei:person[tei:persName = $v_name-flat]">
                                <xsl:copy-of select="$p_authority-file/descendant::tei:person[tei:persName = $v_name-flat][1]"/>
                            </xsl:when>
                            <xsl:when test="$p_authority-file//tei:person[tei:persName = $v_name-flattened]">
                                <xsl:copy-of select="$p_authority-file/descendant::tei:person[tei:persName = $v_name-flattened][1]"/>
                            </xsl:when>
                            <xsl:when test="$p_authority-file//tei:person[tei:persName = $v_name-no-addnames-flattened]">
                                <xsl:copy-of select="$p_authority-file/descendant::tei:person[tei:persName = $v_name-no-addnames-flattened][1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>The persName </xsl:text>
                                    <xsl:value-of select="$v_name-flat"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
                                <!-- quick debugging -->
                                <!--<xsl:message>
                                    <xsl:copy-of select="$v_name-marked-up"/>
                                    <xsl:copy-of select="$v_name-no-addnames"/>
                                </xsl:message>-->
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'NA'"/>
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
                                    <xsl:value-of select="$v_name-flat"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'NA'"/>
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
                                    <xsl:value-of select="$v_name-flat"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
                                <!-- one cannot use a boolean value if the default result is non-boolean -->
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$v_entity-type = 'bibl'">
                        <xsl:choose>
                            <xsl:when test="$p_authority-file/descendant::tei:biblStruct[tei:monogr/tei:title = $v_name-flat]">
                                <xsl:copy-of select="$p_authority-file/descendant::tei:biblStruct[tei:monogr/tei:title = $v_name-flat]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>The title </xsl:text>
                                    <xsl:value-of select="$v_name-flat"/>
                                    <xsl:text> was not found in the authority file</xsl:text>
                                </xsl:message>
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
    </xsl:function>
    <!-- query a local TEI bibliography for titles, editors, locations, IDs etc. -->
    <xsl:function name="oape:query-bibliography">
        <!-- input is a tei <title> node -->
        <xsl:param name="title"/>
        <!-- $bibliography expects a document -->
        <xsl:param name="bibliography"/>
        <!-- $gazetteer expects a path to a file -->
        <xsl:param name="gazetteer"/>
        <!-- local authority -->
        <xsl:param name="p_local-authority"/>
        <!-- values for $p_mode are 'pubPlace', 'location', 'name', 'local-authority', 'textLang', ID -->
        <xsl:param name="p_output-mode"/>
        <!-- select a target language for toponyms -->
        <xsl:param name="p_output-language"/>
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
                    <xsl:copy-of select="$p_bibl/descendant::tei:pubPlace/tei:placeName[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <!--                    <xsl:value-of select="'NA'"/>-->
                    <tei:placeName/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- return publication place -->
            <xsl:when test="$p_output-mode = 'pubPlace'">
                <!--<xsl:message>
                        <xsl:copy-of select="$v_pubPlace//tei:placeName"/>
                    </xsl:message>-->
                <xsl:value-of select="oape:query-gazetteer($v_pubPlace//tei:placeName, $gazetteer, $p_local-authority, 'name', $p_output-language)"/>
            </xsl:when>
            <!-- return location -->
            <xsl:when test="$p_output-mode = ('location', 'lat', 'long')">
                <xsl:value-of select="oape:query-gazetteer($v_pubPlace//tei:placeName, $gazetteer, $p_local-authority, $p_output-mode, '')"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'id-location'">
                <xsl:value-of select="oape:query-gazetteer($v_pubPlace//tei:placeName, $gazetteer, $p_local-authority, 'id', '')"/>
            </xsl:when>
            <!-- return IDs -->
            <xsl:when test="$p_output-mode = 'id'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:idno[@type = 'OCLC']">
                        <xsl:value-of select="concat('oclc:', $p_bibl/descendant::tei:idno[@type = 'OCLC'][1])"/>
                    </xsl:when>
                    <xsl:when test="$p_bibl/descendant::tei:idno[@type = $p_local-authority]">
                        <xsl:value-of select="concat($p_local-authority, ':', $p_bibl/descendant::tei:idno[@type = $p_local-authority][1])"/>
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
            <xsl:when test="$p_output-mode = ('id-oclc', 'oclc')">
                <xsl:value-of select="$p_bibl/descendant::tei:idno[@type = 'OCLC'][1]"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'tei-ref'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:idno[not(@type = 'URI')]">
                        <xsl:for-each-group group-by="@type" select="$p_bibl/descendant::tei:idno[not(@type = 'URI')]">
                            <xsl:sort order="ascending" select="@type"/>
                            <xsl:if test="current-grouping-key() = 'OCLC'">
                                <xsl:value-of select="concat('oclc:', current-group()[1])"/>
                            </xsl:if>
                            <xsl:if test="current-grouping-key() = 'oape'">
                                <xsl:value-of select="concat('oape:bibl:', current-group()[1])"/>
                            </xsl:if>
                            <xsl:if test="current-grouping-key() = 'jaraid'">
                                <xsl:value-of select="concat('jaraid:bibl:', current-group()[1])"/>
                            </xsl:if>
                            <xsl:if test="position() != last()">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:for-each-group>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return the publication title in selected language -->
            <xsl:when test="$p_output-mode = ('name', 'title')">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:monogr/tei:title[@xml:lang = $p_output-language]">
                        <xsl:value-of select="normalize-space($p_bibl/descendant::tei:monogr/tei:title[@xml:lang = $p_output-language][1])"/>
                    </xsl:when>
                    <!-- possible transcriptions into other script -->
                    <xsl:when test="($p_output-language = 'ar') and ($p_bibl/descendant::tei:monogr/tei:title[contains(@xml:lang, '-Arab-')])">
                        <xsl:value-of select="normalize-space($p_bibl/descendant::tei:monogr/tei:title[contains(@xml:lang, '-Arab-')][1])"/>
                    </xsl:when>
                    <!-- fallback to main language of publication -->
                    <xsl:when test="$p_bibl/descendant::tei:monogr/tei:title[@xml:lang = $p_bibl/descendant::tei:monogr/tei:textLang/@mainLang]">
                        <xsl:value-of select="normalize-space($p_bibl/descendant::tei:monogr/tei:title[@xml:lang = $p_bibl/descendant::tei:monogr/tei:textLang/@mainLang][1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space($p_bibl/descendant::tei:monogr/tei:title[1])"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return language -->
            <xsl:when test="$p_output-mode = 'textLang'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:monogr/tei:textLang/@mainLang">
                        <xsl:value-of select="$p_bibl/descendant::tei:monogr/tei:textLang/@mainLang"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'date'">
                <xsl:choose>
                    <xsl:when test="$p_bibl/descendant::tei:monogr/tei:imprint/tei:date[@when]">
                        <xsl:value-of select="$p_bibl/descendant::tei:monogr/tei:imprint/tei:date[@when][1]/@when"/>
                    </xsl:when>
                    <xsl:when test="$p_bibl/descendant::tei:monogr/tei:imprint/tei:date/@from">
                        <xsl:value-of select="$p_bibl/descendant::tei:monogr/tei:imprint/tei:date[@from][1]/@from"/>
                    </xsl:when>
                    <xsl:when test="$p_bibl/descendant::tei:monogr/tei:imprint/tei:date/@notBefore">
                        <xsl:value-of select="$p_bibl/descendant::tei:monogr/tei:imprint/tei:date[@notBefore][1]/@notBefore"/>
                    </xsl:when>
                    <xsl:when test="$p_bibl/descendant::tei:monogr/tei:imprint/tei:date/@notAfter">
                        <xsl:value-of select="$p_bibl/descendant::tei:monogr/tei:imprint/tei:date[@notAfter][1]/@notAfter"/>
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
                        <xsl:choose>
                            <xsl:when test="$p_output-mode = 'location'">
                                <xsl:value-of select="$p_place/tei:location/tei:geo"/>
                            </xsl:when>
                            <xsl:when test="$p_output-mode = 'lat'">
                                <xsl:value-of select="replace($p_place/tei:location/tei:geo, '^(.+?),\s*(.+?)$', '$1')"/>
                            </xsl:when>
                            <xsl:when test="$p_output-mode = 'long'">
                                <xsl:value-of select="replace($p_place/tei:location/tei:geo, '^(.+?),\s*(.+?)$', '$2')"/>
                            </xsl:when>
                        </xsl:choose>
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
                    <xsl:when test="$p_place/descendant::tei:idno[@type = 'geon']">
                        <xsl:value-of select="concat('geon:', $p_place/descendant::tei:idno[@type = 'geon'][1])"/>
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
                    <xsl:when test="$p_place/tei:idno[@type = 'geon']">
                        <xsl:value-of select="$p_place/tei:idno[@type = 'geon'][1]"/>
                    </xsl:when>
                    <xsl:when test="$p_place/tei:placeName[matches(@ref, 'geon:\d+')]">
                        <xsl:value-of select="replace($p_place/tei:placeName[matches(@ref, 'geon:\d+')][1]/@ref, '^.*geon:(\d+).*$', '$1')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'tei-ref'">
                <xsl:choose>
                    <xsl:when test="$p_place/tei:idno[not(@type = 'URI')]">
                        <xsl:for-each-group group-by="@type" select="$p_place/tei:idno[not(@type = 'URI')]">
                            <xsl:sort order="ascending" select="@type"/>
                            <xsl:if test="current-grouping-key() = 'geon'">
                                <xsl:value-of select="concat('geon:', current-group()[1])"/>
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
    <!-- query a local TEI personography  -->
    <xsl:function name="oape:query-personography">
        <!-- input is a tei <placeName> node -->
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
        <xsl:choose>
            <!-- test for @ref pointing to auhority files -->
            <xsl:when test="$v_person != 'NA'">
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
                    <xsl:when test="$p_person/tei:idno[@type = 'wiki']">
                        <xsl:value-of select="concat('wiki:', $p_person/tei:idno[@type = 'wiki'][1])"/>
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
                    <xsl:when test="$p_person/tei:idno[@type = 'wiki']">
                        <xsl:value-of select="$p_person/tei:idno[@type = 'wiki'][1]"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'tei-ref'">
                <xsl:choose>
                    <xsl:when test="$p_person/tei:idno[not(@type = 'URI')]">
                        <xsl:for-each-group group-by="@type" select="$p_person/descendant::tei:idno[not(@type = 'URI')]">
                            <xsl:sort order="ascending" select="@type"/>
                            <xsl:if test="current-grouping-key() = 'VIAF'">
                                <xsl:value-of select="concat('viaf:', current-group()[1])"/>
                            </xsl:if>
                            <xsl:if test="current-grouping-key() = 'wiki'">
                                <xsl:value-of select="concat('wiki:', current-group()[1])"/>
                            </xsl:if>
                            <xsl:if test="current-grouping-key() = 'oape'">
                                <xsl:value-of select="concat('oape:pers:', current-group()[1])"/>
                            </xsl:if>
                            <xsl:if test="current-grouping-key() = 'jaraid'">
                                <xsl:value-of select="concat('jaraid:pers:', current-group()[1])"/>
                            </xsl:if>
                            <xsl:if test="position() != last()">
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:for-each-group>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'NA'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- return name in selected language -->
            <xsl:when test="$p_output-mode = 'name'">
                <xsl:variable name="v_name">
                    <xsl:choose>
                        <!-- preference for names without addNames -->
                        <xsl:when test="$p_person/tei:persName[@type = 'noAddName'][@xml:lang = $p_output-language]">
                            <xsl:copy-of select="$p_person/tei:persName[@type = 'noAddName'][@xml:lang = $p_output-language][1]"/>
                        </xsl:when>
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
                        <!-- fallback to english -->
                        <xsl:when test="$p_person/tei:persName[@type = 'noAddName'][@xml:lang = 'en']">
                            <xsl:copy-of select="$p_person/tei:persName[@type = 'noAddName'][@xml:lang = 'en'][1]"/>
                        </xsl:when>
                        <xsl:when test="$p_person/tei:persName[not(@type = 'flattened')][@xml:lang = 'en']">
                            <xsl:copy-of select="$p_person/tei:persName[not(@type = 'flattened')][@xml:lang = 'en'][1]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$p_person/tei:persName[1]"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
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
    <!-- get OpenArabicPE ID from authority file with an @xml:id -->
    <xsl:function name="oape:get-id-for-person">
        <xsl:param name="p_xml-id"/>
        <xsl:param name="p_authority"/>
        <xsl:param name="p_authority-file"/>
        <xsl:value-of select="$p_authority-file//tei:person[tei:persName[@xml:id = $p_xml-id]]/tei:idno[@type = $p_authority][1]"/>
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
    <!-- this function takes a string as input and tries to find it in a nymlist. It will then try and wrap it in a name element -->
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
        <xsl:param as="node()" name="p_persname"/>
        <xsl:param as="xs:string" name="p_xml-id-output"/>
        <xsl:param as="xs:string" name="p_id-change"/>
        <xsl:variable name="v_persname" select="$p_persname/descendant-or-self::tei:persName"/>
        <!-- write content to variable in order to then generate a unique @xml:id -->
        <xsl:variable name="v_output">
            <xsl:element name="tei:persName">
                <!-- document change -->
                <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                <xsl:attribute name="type" select="'noAddName'"/>
                <!-- reproduce language attributes -->
                <xsl:apply-templates mode="m_identity-transform" select="$v_persname/@xml:lang"/>
                <xsl:apply-templates mode="m_remove-rolename" select="$v_persname/node()"/>
            </xsl:element>
        </xsl:variable>
        <xsl:if test="normalize-space($v_output) != ''">
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
        </xsl:if>
    </xsl:function>
    <!-- this function produces a flattened name -->
    <xsl:function name="oape:name-flattened">
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
    <xsl:template match="tei:roleName | tei:nameLink[not(parent::tei:addName)]" mode="m_remove-rolename"/>
    <xsl:template match="tei:persName | tei:forename | tei:surname | tei:addName | @*" mode="m_remove-rolename">
        <xsl:copy>
            <xsl:apply-templates mode="m_remove-rolename" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id" mode="m_remove-rolename"/>
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
        <!-- returns a single <person> node -->
        <xsl:variable name="v_corresponding-person">
            <xsl:choose>
                <!-- test if this node already points to an authority file -->
                <xsl:when test="$p_persname/@ref">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>The input already points to an authority file</xsl:message>
                    </xsl:if>
                    <!-- there seems to be a problem with this function -->
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
                <xsl:variable name="v_ref" select="oape:query-person($v_corresponding-person, 'tei-ref', '', '')"/>
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
            <xsl:when test="$v_corresponding-person = 'NA'">
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
    <!-- link bibliographic data to bibliography -->
    <xsl:param name="p_update-existing-refs" select="false()"/>
    <xsl:function name="oape:link-title-to-authority-file">
        <xsl:param as="node()" name="p_title"/>
        <xsl:param name="p_year"/>
        <xsl:param as="xs:string" name="p_local-authority"/>
        <xsl:param name="p_bibliography"/>
        <!-- try to find the title in the authority file: currently either based on IDs in @ref or the title itself. If nothing is found the function returns 'NA' -->
        <!-- possible results: none, one, multiple -->
        <xsl:variable name="v_corresponding-bibls" select="oape:get-entity-from-authority-file($p_title, $p_local-authority, $p_bibliography)"/>
        <xsl:variable name="v_corresponding-bibl">
            <xsl:choose>
                <!-- assuming that a single match is actually correct might not always prove true -->
                <!-- add date as condition: referenced periodical must have been published before the source was written -->
                <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct) = 1 and oape:date-year-only(oape:query-biblstruct($v_corresponding-bibls/descendant-or-self::tei:biblStruct, 'date', '', '', '')) &lt;= $p_year">
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>
                            <xsl:text>Found a single match for </xsl:text>
                            <xsl:value-of select="$p_title"/>
                            <xsl:text> in the authority file.</xsl:text>
                        </xsl:message>
                    </xsl:if>
                    <xsl:copy-of select="$v_corresponding-bibls/self::tei:biblStruct"/>
                </xsl:when>
                <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct) = 1">
<!--                    <xsl:if test="$p_verbose = true()">-->
                        <xsl:message>
                            <xsl:text>Found a single match for </xsl:text>
                            <xsl:value-of select="$p_title"/>
                            <xsl:text> in the authority file but publication dates suggest it is erroneous</xsl:text>
                        </xsl:message>
                    <!--</xsl:if>-->
<!--                    <xsl:copy-of select="$v_corresponding-bibls/self::tei:biblStruct"/>-->
                </xsl:when>
                <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct) gt 1">
                    <!--                    <xsl:if test="$p_verbose = true()">-->
                    <xsl:message>
                        <xsl:text>Found multiple matches for </xsl:text>
                        <xsl:value-of select="$p_title"/>
                        <xsl:text> in the authority file. Trying to match further search criteria.</xsl:text>
                    </xsl:message>
                    <!--</xsl:if>-->
                    <!-- develop further matching criteria -->
                    <xsl:variable name="v_bibl">
                        <xsl:choose>
                            <xsl:when test="$p_title/ancestor::tei:biblStruct">
                                <xsl:copy-of select="$p_title/ancestor::tei:biblStruct[1]"/>
                            </xsl:when>
                            <xsl:when test="$p_title/ancestor::tei:bibl">
                                <xsl:copy-of select="oape:compile-next-prev($p_title/ancestor::tei:bibl[1])"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
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
                    <!-- get the place of publication -->
                    <xsl:variable name="v_place-publication">
                        <xsl:choose>
                            <xsl:when test="$v_bibl != 'NA' and oape:query-biblstruct($v_bibl, 'id-location', '', $v_gazetteer, $p_local-authority) != 'NA'">
                                <xsl:value-of select="oape:query-biblstruct($v_bibl, 'id-location', '', $v_gazetteer, $p_local-authority)"/>
                            </xsl:when>
                            <!-- prxomity to the source a text is mentioned in -->
                            <xsl:when test="$p_title/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct">
                                <xsl:value-of
                                    select="oape:query-biblstruct($p_title/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct[1], 'id-location', '', $v_gazetteer, $p_local-authority)"
                                />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'NA'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!-- try to use further match criteria -->
                    <xsl:choose>
                        <!-- this should start with @type and @subtype criteria -->
                        <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype]) = 1">
                            <!--                            <xsl:if test="$p_verbose = true()">-->
                            <xsl:message>
                                <xsl:text>Found a single match based on @type and @subtype.</xsl:text>
                            </xsl:message>
                            <!--</xsl:if>-->
                            <xsl:copy-of select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype]"/>
                        </xsl:when>
                        <!-- location -->
                        <xsl:when
                            test="$v_place-publication != 'NA' and count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication]) = 1">
                            <!--                            <xsl:if test="$p_verbose = true()">-->
                            <xsl:message>
                                <xsl:text>Found a single match based on location.</xsl:text>
                            </xsl:message>
                            <!--</xsl:if>-->
                            <xsl:copy-of
                                select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication]"
                            />
                        </xsl:when>
                        <!-- @types and location -->
                        <xsl:when
                            test="$v_place-publication != 'NA' and count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication]) = 1">
                            <!--                            <xsl:if test="$p_verbose = true()">-->
                            <xsl:message>
                                <xsl:text>Found a single match based on @type @subtype, and location.</xsl:text>
                            </xsl:message>
                            <!--</xsl:if>-->
                            <xsl:copy-of
                                select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][oape:query-biblstruct(., 'id-location', '', $v_gazetteer, $p_local-authority) = $v_place-publication]"
                            />
                        </xsl:when>
                        <xsl:when test="count($v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][@oape:frequency = $v_frequency]) = 1">
                            <!--                            <xsl:if test="$p_verbose = true()">-->
                            <xsl:message>
                                <xsl:text>Found a single match based on @type @subtype, and @oape:frequency.</xsl:text>
                            </xsl:message>
                            <!--</xsl:if>-->
                            <xsl:copy-of select="$v_corresponding-bibls/descendant-or-self::tei:biblStruct[@type = $v_type][@subtype = $v_subtype][@oape:frequency = $v_frequency]"/>
                        </xsl:when>
                        <!-- involved editors -->
                        <!-- date -->
                        <xsl:otherwise>
                            <!-- this is a duplicate message -->
                            <!--<xsl:message>
                                <xsl:text>Found no match in the authority file for </xsl:text>
                                <xsl:value-of select="$p_title"/>
                                <xsl:text> at </xsl:text>
                                <xsl:value-of select="concat(base-uri($p_title), '#', $p_title/@xml:id)"/>
                                <xsl:text>.</xsl:text>
                            </xsl:message>-->
                            <xsl:value-of select="'NA'"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <!-- this is a duplicate message -->
                    <!--<xsl:message>
                        <xsl:text>Found no match in the authority file for </xsl:text>
                        <xsl:value-of select="$p_title"/>
                        <xsl:text> at </xsl:text>
                        <xsl:value-of select="concat(base-uri($p_title), '#', $p_title/@xml:id)"/>
                        <xsl:text>.</xsl:text>
                    </xsl:message>-->
                    <xsl:value-of select="'NA'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <!-- fallback: name is not found in the authority file, return input -->
            <xsl:when test="$v_corresponding-bibl = 'NA'">
                <xsl:copy-of select="$p_title"/>
            </xsl:when>
            <!-- name is found in the authority file. it will be linked and potentially updated -->
            <xsl:otherwise>
                <xsl:variable name="v_ref" select="oape:query-biblstruct($v_corresponding-bibl, 'tei-ref', '', '', $p_local-authority)"/>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>The title will be updated with a @ref pointing to the authority file.</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:element name="title">
                    <xsl:apply-templates select="$p_title/@*"/>
                    <!-- add references to IDs -->
                    <xsl:if test="$v_ref != 'NA'">
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
    <xsl:template match="text()" mode="m_plain-text">
        <xsl:value-of select="concat(' ', normalize-space(.), ' ')"/>
    </xsl:template>
    <!-- helper function: convert ISO date to year only -->
    <xsl:function name="oape:date-year-only">
        <xsl:param as="xs:string" name="p_date"/>
        <xsl:choose>
            <xsl:when test="matches($p_date, '^\d{4}$|^\d{4}-.{2}-.{2}$')">
                <xsl:value-of select="replace($p_date, '^(\d{4})', '$1')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'NA'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>
