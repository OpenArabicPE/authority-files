<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    version="3.0">
    <!-- currently supported local authorities: oape, jaraid, damascus -->
    <xsl:param name="p_local-authority" select="'oape'"/>
    <xsl:param name="p_github-action" select="false()"/>
    
    <!-- file IDs -->
    <xsl:variable name="v_id-file" select="if(tei:TEI/@xml:id) then(tei:TEI/@xml:id) else(substring-before(tokenize(base-uri(),'/')[last()],'.TEIP5'))"/>
    <xsl:variable name="v_url-file" select="base-uri()"/>
    <xsl:variable name="v_url-base" select="replace($v_url-file, '^(.+)/([^/]+?)$', '$1')"/>
    <xsl:variable name="v_name-file" select="replace($v_url-file, '^(.+)/([^/]+?)$', '$2')"/>
    <!-- options for functions -->
    <!-- link titles to bibliography: toggle whether to link weak matches or not -->
    <xsl:param name="p_link-matches-based-on-title-only" select="true()"/>
    <!-- select whether existing refs should be used for matching -->
    <xsl:param name="p_ignore-existing-refs" select="false()"/>
    <!-- currently not used: toggle whether existing @ref  should be updated-->
    <!--<xsl:param name="p_update-existing-refs" select="false()"/>-->
    <!-- authorities -->
    <xsl:param name="p_acronym-geonames" select="'geon'"/> <!-- in WHG this is 'gn' -->
    <xsl:param name="p_acronym-viaf" select="'viaf'"/>
    <xsl:param name="p_acronym-wikidata" select="'wiki'"/> <!-- in WHG this is 'wd' -->
    <xsl:param name="p_acronym-wikimapia" select="'lwm'"/>
    <xsl:param name="p_url-resolve-wikidata" select="'https://wikidata.org/'"/>
    <xsl:param name="p_url-resolve-viaf" select="'https://viaf.org/'"/>
    <xsl:param name="p_url-resolve-geonames" select="'https://geonames.org/'"/>
    <xsl:param name="p_url-resolve-oclc" select="'https://worldcat.org/oclc/'"/>
    <xsl:param name="p_url-resolve-hathi" select="'https://catalog.hathitrust.org/Record/'"/>
    <xsl:param name="p_url-resolve-zdb" select="'https://ld.zdb-services.de/resource/'"/>
    <xsl:param name="p_url-resolve-aub" select="'https://libcat.aub.edu.lb/record='"/>
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
                <xsl:value-of select="'/Users/Shared/BachUni/BachBibliothek/GitHub/'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_path-authority-files-folder">
        <!-- note that these paths are relative to the computer they are run on. 
            If called from Github, these need to be adopted-->
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'damascus'">
                <xsl:value-of select="'Damascus/damascus_data/authority-files/'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'jaraid'">
                <xsl:value-of select="'ProjectJaraid/jaraid_source/authority-files/'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'OpenArabicPE/authority-files/data/tei/'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_path-authority-test-folder">
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'OpenArabicPE/authority-files/data/test-data/'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <!-- this param falls back to a personography -->
    <xsl:param name="p_file-authority">
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'damascus'">
                <xsl:value-of select="'personography_damascus.TEIP5.xml'"/>
            </xsl:when>
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
<!--                <xsl:value-of select="'bibliography_OpenArabicPE-periodicals_simple.TEIP5.xml'"/>-->
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_file-gazetteer">
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'damascus'">
                <xsl:value-of select="'gazetteer_levant-phd.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'jaraid'">
                <xsl:value-of select="'jaraid_authority-file.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'gazetteer_OpenArabicPE.TEIP5.xml'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_file-personography">
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'damascus'">
                <xsl:value-of select="'personography_damascus.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'jaraid'">
                <xsl:value-of select="'jaraid_authority-file.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'personography_OpenArabicPE.TEIP5.xml'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:param name="p_file-organizationography">
        <xsl:choose>
            <xsl:when test="$p_local-authority = 'damascus'">
                <xsl:value-of select="'organizationography_damascus.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'jaraid'">
                <xsl:value-of select="'jaraid_authority-file.TEIP5.xml'"/>
            </xsl:when>
            <xsl:when test="$p_local-authority = 'oape'">
                <xsl:value-of select="'organizationography_OpenArabicPE.TEIP5.xml'"/>
            </xsl:when>
        </xsl:choose>
    </xsl:param>
    <xsl:variable name="v_file-entities-master" select="doc(concat($p_path-base, $p_path-authority-files-folder, $p_file-authority))"/>
     <!-- load the authority files -->
    <xsl:param name="p_url-gazetteer" select="concat($p_path-base, $p_path-authority-files-folder, $p_file-gazetteer)"/>
    <xsl:variable name="v_gazetteer" select="doc($p_url-gazetteer)"/>
    <xsl:param name="p_url-personography" select="concat($p_path-base, $p_path-authority-files-folder, $p_file-personography)"/>
    <xsl:variable name="v_personography" select="doc($p_url-personography)"/>
    <xsl:param name="p_url-organizationography" select="concat($p_path-base, $p_path-authority-files-folder, $p_file-organizationography)"/>
    <xsl:variable name="v_organizationography" select="doc($p_url-organizationography)"/>
    <xsl:param name="p_url-bibliography" select="concat($p_path-base, $p_path-authority-files-folder, $p_file-bibliography)"/>
    <xsl:variable name="v_bibliography" select="doc($p_url-bibliography)"/>
    <xsl:variable name="v_bibliography-test" select="doc(concat($p_path-base, $p_path-authority-test-folder, 'test_bibliography.TEIP5.xml'))"/>
    <!-- select tsv or csv as output -->
    <xsl:param name="p_format" select="'csv'"/>
    <xsl:param name="p_quoted" select="true()"/>
    <!-- strings -->
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_quot" select="'&quot;'"/>
    <xsl:variable name="v_comma" select="','"/>
    <xsl:variable name="v_tab" select="'&#0009;'"/>
    <xsl:variable name="v_seperator">
        <xsl:if test="$p_quoted = true()">
            <xsl:value-of select="$v_quot"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$p_format = 'tsv'">
                <xsl:value-of  select="$v_tab"/>
            </xsl:when>
            <xsl:when test="$p_format = 'csv'">
                <xsl:value-of  select="$v_comma"/>
            </xsl:when>
            <!-- fallback: csv -->
            <xsl:otherwise>
                 <xsl:value-of  select="$v_comma"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$p_quoted = true()">
            <xsl:value-of select="$v_quot"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="v_beginning-of-line">
        <xsl:if test="$p_quoted = true()">
            <xsl:value-of select="$v_quot"/>
        </xsl:if>
    </xsl:variable>
    <xsl:variable name="v_end-of-line">
        <xsl:if test="$p_quoted = true()">
            <xsl:value-of select="$v_quot"/>
        </xsl:if>
        <xsl:value-of select="$v_new-line"/>
    </xsl:variable>
    <!-- parameters for string-replacements -->
    <xsl:param name="p_string-match" select="'([إ|أ|آ])'"/>
    <xsl:param name="p_string-replace" select="'ا'"/>
    <xsl:param name="p_string-harakat" select="'([ِ|ُ|ٓ|ٰ|ْ|ٌ|ٍ|ً|ّ|َ])'"/>

</xsl:stylesheet>