<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- this stylesheet tries to remove automatically generated mark-up -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml" omit-xml-declaration="no"/>
    
    <xsl:import href="functions.xsl"/>
    <xsl:param name="p_local-authority" select="'jaraid'"/>
    
    <xsl:template match="/">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform"/>
<!--            <xsl:apply-templates select="descendant::tei:listPerson" mode="m_oape"/>-->
<!--            <xsl:apply-templates select="descendant::tei:listPlace"/>-->
        </xsl:copy>
    </xsl:template>
    
    <!--<xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>-->
    <xsl:template match="tei:listPerson" mode="m_identity-transform">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <xsl:apply-templates mode="m_oape"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tei:person" mode="m_oape">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_identity-transform"/>
            <xsl:apply-templates select="tei:persName" mode="m_identity-transform"/>
            <!-- add potentially missing names from Jaraid -->
            <xsl:choose>
            <!-- //tei:person[tei:idno/@type = 'jaraid'][not(tei:persName[@xml:lang = ('und-Lang', 'ar-Latn-x-ijmes')])] -->
            
            <xsl:when test="tei:idno[@type = 'jaraid'] and not(tei:persName[@xml:lang = ('und-Latn', 'ar-Latn-x-ijmes')])">
                <xsl:variable name="v_persname">
                    <persName ref="jaraid:pers:{tei:idno[@type = 'jaraid'][1]}"/>
                </xsl:variable>
                <xsl:variable name="v_person-jaraid" select="oape:get-entity-from-authority-file($v_persname/tei:persName, $p_local-authority, $v_personography)"/>
                <xsl:message>
                    <xsl:text>might have additional information: </xsl:text>
                    <xsl:value-of select="$v_person-jaraid//tei:persName"/>
                </xsl:message>
                <xsl:copy-of select="$v_person-jaraid//tei:persName[@xml:lang = 'ar-Latn-x-ijmes']"/>
                <xsl:copy-of select="$v_person-jaraid//tei:persName[@xml:lang = 'und-Latn']"/>
            </xsl:when>
                <!-- search for those names that are not linked to Jaraid -->
                <xsl:when test="not(tei:idno[@type = 'jaraid']) and not(tei:persName[@xml:lang = ('und-Latn', 'ar-Latn-x-ijmes')])">
                    <!-- check if there is a person in Jaraid with the OAPE ID -->
                    <xsl:variable name="v_persname">
                    <persName ref="oape:pers:{tei:idno[@type = 'oape'][1]}"/>
                </xsl:variable>
                    <xsl:variable name="v_person-jaraid" select="oape:get-entity-from-authority-file($v_persname/tei:persName, 'oape', $v_personography)"/>
                    <xsl:message>
                    <xsl:text>might have additional information: </xsl:text>
                    <xsl:value-of select="$v_person-jaraid//tei:persName"/>
                </xsl:message>
                    <xsl:copy-of select="$v_person-jaraid//tei:persName[@xml:lang = 'ar-Latn-x-ijmes']"/>
                    <xsl:copy-of select="$v_person-jaraid//tei:persName[@xml:lang = 'und-Latn']"/>
                    <xsl:copy-of select="$v_person-jaraid//tei:idno[@type = 'jaraid']"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates select="node()[not(local-name() = 'persName')]" mode="m_identity-transform"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:person" mode="m_jaraid">
        <!-- if any persName points to oape, ignore it -->
        <xsl:choose>
            <xsl:when test="tei:persName/@ref[matches(., 'oape:pers:\d+')]"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:place" mode="m_jaraid">
        <!-- if any persName points to oape, ignore it -->
        <xsl:choose>
            <xsl:when test="tei:placeName/@ref[matches(., 'oape:place:\d+')]"/>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>