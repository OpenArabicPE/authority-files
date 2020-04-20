<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="3.0">
    
    <xsl:output method="xml" encoding="UTF-8" indent="no" exclude-result-prefixes="#all" omit-xml-declaration="no"/>
    
    <!-- parameters for string-replacements -->
    <xsl:param name="p_string-match" select="'([إ|أ|آ])'"/>
    <xsl:param name="p_string-replace" select="'ا'"/>
    <xsl:param name="p_string-harakat" select="'([ِ|ُ|ٓ|ٰ|ْ|ٌ|ٍ|ً|ّ|َ])'"/>
    
    <xsl:function name="oape:string-normalise-name">
        <xsl:param name="p_input"/>
        <xsl:variable name="v_self" select="normalize-space(replace(oape:string-remove-harakat($p_input),$p_string-match,$p_string-replace))"/>
        <xsl:value-of select="replace($v_self, '\W', '')"/>
    </xsl:function>
    
    <xsl:function name="oape:string-remove-characters">
        <xsl:param name="p_input"/>
        <xsl:param name="p_string-match"/>
        <xsl:value-of select="normalize-space(replace($p_input,$p_string-match,''))"/>
    </xsl:function>
    
    <xsl:function name="oape:string-remove-harakat">
        <xsl:param name="p_input"/>
        <xsl:value-of select="oape:string-remove-characters($p_input,$p_string-harakat)"/>
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
                <xsl:copy-of
            select="$p_authority-file//tei:biblStruct[.//tei:idno[@type = $v_authority] = $v_idno]"/>
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
        <xsl:copy-of
            select="$p_authority-file//tei:person[tei:idno[@type = $v_authority] = $v_idno]"/>
    </xsl:function>
    <!-- get OpenArabicPE ID from authority file with an @xml:id -->
    <xsl:function name="oape:get-id-for-person">
        <xsl:param name="p_xml-id"/>
        <xsl:param name="p_authority"/>
        <xsl:param name="p_authority-file"/>
        <xsl:value-of
            select="$p_authority-file//tei:person[tei:persName[@xml:id = $p_xml-id]]/tei:idno[@type = $p_authority][1]"
        />
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
        <xsl:copy-of
            select="$p_authority-file//tei:place[tei:idno[@type = $v_authority] = $v_idno]"/>
    </xsl:function>
    <!-- get OpenArabicPE ID from authority file with an @xml:id -->
    <xsl:function name="oape:get-id-for-place">
        <xsl:param name="p_xml-id"/>
        <xsl:param name="p_authority"/>
        <xsl:param name="p_authority-file"/>
        <xsl:value-of
            select="$p_authority-file/tei:place[tei:placeName[@xml:id = $p_xml-id]]/tei:idno[@type = $p_authority][1]"
        />
    </xsl:function>
    
</xsl:stylesheet>