<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <!--  -->
    <xsl:param name="p_local-authority" select="'oape'"/>
    <xsl:param name="p_github-action" select="false()"/>
    <xsl:variable name="v_id-file" select="if(tei:TEI/@xml:id) then(tei:TEI/@xml:id) else(substring-before(tokenize(base-uri(),'/')[last()],'.TEIP5'))"/>    
    <!-- files -->
    <xsl:param name="p_url-nyms" select="'../data/tei/nymlist.TEIP5.xml'"/>
    <xsl:variable name="v_file-nyms" select="doc($p_url-nyms)"/>
    <!-- locate authority files -->
    <xsl:variable name="v_base-directory">
        <xsl:choose>
            <xsl:when test="$p_github-action = true()"/>
            <xsl:when test="$p_github-action = false()">
                <xsl:value-of select="'../'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:param name="p_path-base">
        <xsl:choose>
            <xsl:when test="$p_github-action = true()">
                <xsl:value-of select="'https://github.com/'"/>
            </xsl:when>
            <xsl:when test="$p_github-action = false()">
                <xsl:value-of select="'/BachUni/BachBibliothek/GitHub/'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_path-authority-files-folder">
        <!-- note that these paths are relative to the computer they are run on. 
            If called from Github, these need to be adopted-->
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'jaraid'">
                <xsl:value-of select="'ProjectJaraid/jaraid_source/authority-files/'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'OpenArabicPE/authority-files/data/tei/'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_file-authority">
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'jaraid'">
                <xsl:value-of select="'jaraid_authority-file.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'personography_OpenArabicPE.TEIP5.xml'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_file-bibliography">
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'jaraid'">
                <xsl:value-of select="'../tei/jaraid_master-biblStruct.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'bibliography_OpenArabicPE-periodicals.TEIP5.xml'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_file-gazetteer">
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'jaraid'">
                <xsl:value-of select="'jaraid_authority-file.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'gazetteer_levant-phd.TEIP5.xml'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_file-personography">
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'jaraid'">
                <xsl:value-of select="'jaraid_authority-file.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'personography_OpenArabicPE.TEIP5.xml'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:variable name="v_file-entities-master" select="doc(concat($p_path-base, $p_path-authority-files-folder, $p_file-authority))"/>
     <!-- load the authority files -->
    <xsl:param name="p_url-gazetteer" select="concat($p_path-base, $p_path-authority-files-folder, $p_file-gazetteer)"/>
    <xsl:variable name="v_gazetteer" select="doc($p_url-gazetteer)"/>
    <xsl:param name="p_url-personography" select="concat($p_path-base, $p_path-authority-files-folder, $p_file-personography)"/>
    <xsl:variable name="v_personography" select="doc($p_url-personography)"/>
    <xsl:param name="p_url-bibliography" select="concat($p_path-base, $p_path-authority-files-folder, $p_file-bibliography)"/>
    <xsl:variable name="v_bibliography" select="doc($p_url-bibliography)"/>
    <!-- strings -->
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_quot" select="'&quot;'"/>
    <xsl:variable name="v_comma" select="','"/>
    <xsl:variable name="v_seperator" select="concat($v_quot,$v_comma,$v_quot)"/>
    <xsl:variable name="v_beginning-of-line" select="$v_quot"/>
    <xsl:variable name="v_end-of-line" select="concat($v_quot, $v_new-line)"/>
    <!-- parameters for string-replacements -->
    <xsl:param name="p_string-match" select="'([إ|أ|آ])'"/>
    <xsl:param name="p_string-replace" select="'ا'"/>
    <xsl:param name="p_string-harakat" select="'([ِ|ُ|ٓ|ٰ|ْ|ٌ|ٍ|ً|ّ|َ])'"/>

</xsl:stylesheet>