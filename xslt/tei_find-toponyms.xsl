<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"
     xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="3.0">
    
    <!-- identify the author of the change by means of a @xml:id -->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>
    
    <xsl:param name="p_url-master"
        select="'../data/tei/gazetteer_levant-phd.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="text()[not(ancestor::tei:placeName)]">
        <xsl:variable name="v_place">
            <place type="town" xml:id="lgn276781">
                                <placeName type="simple">Beirut</placeName>
                                <placeName xml:lang="ar-Latn-x-ijmes">Bayrūt</placeName>
                                <placeName n="1" source="#org_geon" type="alt">Beyrout</placeName>
                                <placeName n="2" source="#org_geon" type="alt">Beirout</placeName>
                                <placeName xml:lang="en">Beirut</placeName>
                                <placeName xml:lang="ar">بيروت</placeName>
                                <placeName xml:lang="ar">مدينة بيروت</placeName>
                                <placeName xml:lang="ar-Latn-x-ijmes">Bayrūt</placeName>
                                <location>
                                    <geo>33.88894, 35.49442</geo>
                                </location>
                                <placeName source="#org_geon" type="alt" xml:lang="fr">Beyrouth</placeName>
                                <placeName source="#org_geon" type="alt" xml:lang="de">Beirut</placeName>
                                <placeName source="#org_geon" type="alt" xml:lang="tr">Beyrut</placeName>
                                <idno type="url">http://en.wikipedia.org/wiki/Beirut</idno>
                                <idno type="geon">276781</idno>
                                <idno type="oape">26</idno>
                            </place>
        </xsl:variable>
        <xsl:variable name="v_id-oape" select="$v_place/tei:place/tei:idno[@type='oape'][1]"/>
        <xsl:variable name="v_id-geon" select="$v_place/tei:place/tei:idno[@type = $p_acronym-geonames]"/>
        <xsl:variable name="v_toponym" select="$v_place/tei:place/tei:placeName[@xml:lang='ar'][1]"/>
        <xsl:analyze-string select="." regex="([^>])([و|ب|ل])*({$v_toponym})">
            <xsl:matching-substring>
                <xsl:message>
                    <xsl:text>found </xsl:text><xsl:value-of select="$v_toponym"/><xsl:text> not surrounded by a tag</xsl:text>
                </xsl:message>
                <xsl:value-of select="regex-group(1)"/>
                <xsl:value-of select="regex-group(2)"/>
                <xsl:element name="placeName">
                    <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
                    <xsl:attribute name="ref">
                        <xsl:if test="$v_id-oape!=''">
                            <xsl:value-of select="concat('oape:place:',$v_id-oape)"/>
                        </xsl:if>
                        <xsl:if test="$v_id-geon!=''">
                            <xsl:if test="$v_id-oape!=''"><xsl:text> </xsl:text></xsl:if>
                            <xsl:value-of select="concat($p_acronym-geonames, ':',$v_id-geon)"/>
                        </xsl:if>
                    </xsl:attribute>
                    <xsl:value-of select="regex-group(3)"/>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
</xsl:stylesheet>