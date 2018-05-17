<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes" name="xml_indented" exclude-result-prefixes="#all"/>
    <!-- This xslt takes a list of place/placeName produced from a query to GeoNames.org and produces a well-formed TEI listPlace element -->
    <!--    <xsl:include href="/BachUni/projekte/XML/Functions/BachFunctions v3.xsl"/>-->
    <xsl:param name="p_limit-output-languages" select="true()"/>
    <!-- variables for string tanslation -->
    <xsl:variable name="vGeoNamesDiac" select="'’‘áḨḨḩŞşŢţz̧'"/>
    <xsl:variable name="vGeoNamesIjmes" select="'ʾʿāḤḤḥṢṣṬṭẓ'"/>
    <!--    <xsl:param name="pGeonames"/>-->
    <xsl:template match="geonames" mode="m_geon-to-tei">
        <tei:listPlace>
            <xsl:apply-templates mode="m_geon-to-tei" select="./geoname">
                <xsl:sort select="./name"/>
            </xsl:apply-templates>
        </tei:listPlace>
    </xsl:template>
    <!-- places -->
    <xsl:template match="geoname" mode="m_geon-to-tei">
        <tei:place>
            <!-- translate the type information -->
            <xsl:attribute name="type">
                <xsl:choose>
                    <xsl:when test="./fcode = 'MSQE'">
                        <xsl:text>building</xsl:text>
                    </xsl:when>
                    <xsl:when test="starts-with(./fcode, 'PPL')">
                        <xsl:text>town</xsl:text>
                    </xsl:when>
                    <xsl:when test="starts-with(./fcode, 'ADM')">
                        <xsl:text>county</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="./fcode"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="./fcode = 'MSQE'">
                    <xsl:attribute name="subtype" select="'mosque'"/>
                </xsl:when>
            </xsl:choose>
            <!-- not sure such information is needed, since it is also present in the <idno> element -->
            <!--<xsl:attribute name="corresp">
                <xsl:value-of select="concat('geon:',./geonameId)"/>
            </xsl:attribute>-->
            <xsl:apply-templates mode="m_geon-to-tei" select="./toponymName, ./name"/>
            <!-- alternateNames provides a list of CSV. This is not necessarily needed -->
            <!--            <xsl:apply-templates select="./alternateNames" mode="m_geon-to-tei"/>-->
            <xsl:apply-templates mode="m_geon-to-tei" select="./alternateName[not(@lang = 'link')]"/>
            <xsl:apply-templates mode="m_geon-to-tei" select="./lat"/>
            <xsl:apply-templates mode="m_geon-to-tei" select="./alternateName[@lang = 'link']"/>
            <xsl:apply-templates mode="m_geon-to-tei" select="./geonameId"/>
        </tei:place>
    </xsl:template>
    <!-- idno -->
    <xsl:template match="geonameId" mode="m_geon-to-tei">
        <tei:idno type="geon">
            <xsl:value-of select="."/>
        </tei:idno>
    </xsl:template>
    <!-- toponyms -->
    <xsl:template match="toponymName" mode="m_geon-to-tei">
        <tei:placeName type="toponym">
            <xsl:attribute name="resp" select="'#org_geon'"/>
            <xsl:value-of select="."/>
        </tei:placeName>
        <!-- test if the main toponym contains diacritics -->
        <xsl:analyze-string regex="((\w)+)$" select=".">
            <xsl:matching-substring>
                <xsl:if test="contains($vGeoNamesDiac, regex-group(2))">
                    <tei:placeName type="toponym" xml:lang="ar-Latn-x-ijmes">
                        <xsl:value-of
                            select="translate(regex-group(1), $vGeoNamesDiac, $vGeoNamesIjmes)"/>
                    </tei:placeName>
                </xsl:if>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    <xsl:template match="name" mode="m_geon-to-tei">
        <tei:placeName type="simple">
            <xsl:value-of select="."/>
        </tei:placeName>
    </xsl:template>
    <!-- alternateNames provides a list of CSV. This is not necessarily needed -->
    <xsl:template match="alternateNames" mode="m_geon-to-tei">
        <xsl:for-each select="tokenize(., ',')">
            <tei:placeName>
                <xsl:attribute name="type" select="'alt'"/>
                <xsl:attribute name="n" select="position()"/>
                <xsl:attribute name="source" select="'#org_geon'"/>
                <!-- one should run a language text on the input -->
                <xsl:value-of select="."/>
            </tei:placeName>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="alternateName" mode="m_geon-to-tei">
        <xsl:choose>
            <xsl:when test="@lang = 'link'">
                <tei:idno type="url"><xsl:value-of select="."/></tei:idno>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$p_limit-output-languages = true()">
                        <xsl:if test="@lang = ('ar', 'en', 'fr', 'de', 'tr')">
                            <tei:placeName>
                                <xsl:attribute name="type" select="'alt'"/>
                                <xsl:attribute name="source" select="'#org_geon'"/>
                                <xsl:if test="@lang">
                                    <xsl:attribute name="xml:lang" select="@lang"/>
                                    <xsl:value-of select="."/>
                                </xsl:if>
                            </tei:placeName>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <tei:placeName>
                            <xsl:attribute name="type" select="'alt'"/>
                            <xsl:attribute name="source" select="'#org_geon'"/>
                            <xsl:if test="@lang">
                                <xsl:attribute name="xml:lang" select="@lang"/>
                                <xsl:value-of select="."/>
                            </xsl:if>
                        </tei:placeName>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="lat" mode="m_geon-to-tei">
        <tei:location>
            <tei:geo>
                <xsl:value-of select="concat(., ', ', following-sibling::lng)"/>
            </tei:geo>
        </tei:location>
    </xsl:template>
</xsl:stylesheet>
