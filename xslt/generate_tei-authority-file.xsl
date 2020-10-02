<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    
    <!-- this stylesheet generates an authority file from the TEI input file with:
        - persons
        - places
        using the <standOff> element.
        The inclusion of groups of entities can be toggled by parameters
    -->
    <xsl:include href="functions.xsl"/>
    <xsl:param name="p_include-persons" select="true()"/>
    <xsl:param name="p_include-places" select="true()"/>
    <xsl:template match="/">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:TEI" mode="m_identity-transform">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <!-- teiHeader -->
            <xsl:copy-of select="$v_tei-header"/>
            <!-- standOff -->
            <xsl:element name="standOff">
                <xsl:if test="$p_include-persons = true()">
                    <xsl:element name="listPerson">
                        <xsl:copy-of select="$v_persons"/>
                    </xsl:element>
                </xsl:if>
                <xsl:if test="$p_include-places = true()">
                    <xsl:element name="listPlace">
                        <xsl:copy-of select="$v_places"/>
                    </xsl:element>
                </xsl:if>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <!-- compile entities -->
    <xsl:variable name="v_persons">
        <xsl:for-each-group group-by="." select="descendant::tei:editor | descendant::tei:author">
            <xsl:element name="person">
                <xsl:apply-templates mode="m_identity-transform" select="@xml:lang | @type | @ref"/>
                <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:persName"/>
            </xsl:element>
        </xsl:for-each-group>
        <xsl:for-each-group group-by="." select="descendant::tei:persName[not(parent::tei:editor | parent::tei:author)]">
            <xsl:element name="person">
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@xml:lang | @type | @ref"/>
                    <xsl:apply-templates mode="m_copy-from-authority-file"/>
                </xsl:copy>
            </xsl:element>
        </xsl:for-each-group>
    </xsl:variable>
    <xsl:variable name="v_places">
        <xsl:for-each-group group-by="." select="descendant::tei:pubPlace">
            <xsl:element name="place">
                <xsl:apply-templates mode="m_identity-transform" select="@xml:lang | @type | @ref"/>
                <xsl:apply-templates mode="m_copy-from-authority-file" select="tei:placeName"/>
            </xsl:element>
        </xsl:for-each-group>
        <xsl:for-each-group group-by="." select="descendant::tei:placeName[not(parent::tei:pubPlace)]">
            <xsl:element name="place">
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@xml:lang | @type | @ref"/>
                    <xsl:apply-templates mode="m_copy-from-authority-file"/>
                </xsl:copy>
            </xsl:element>
        </xsl:for-each-group>
    </xsl:variable>
    <!-- teiHeader -->
    <xsl:variable name="v_tei-header">
        <teiHeader xml:lang="en">
            <fileDesc>
                <titleStmt>
                    <title>
                        <xsl:text>Generic </xsl:text>
                        <xsl:choose>
                            <xsl:when test="$p_include-places = true() and $p_include-persons = true()">
                                <xsl:text>Authority File</xsl:text>
                            </xsl:when>
                            <xsl:when test="$p_include-places = true()">
                                <xsl:text>Gazetteer</xsl:text>
                            </xsl:when>
                            <xsl:when test="$p_include-persons = true()">
                                <xsl:text>Prosopography</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </title>
                    <editor>
                        <xsl:apply-templates select="$p_editor/descendant::tei:persName" mode="m_identity-transform"/>
                    </editor>
                    <!-- contributors to the source file -->
                    <respStmt>
                        <resp>Contributed to the original file from which the entities were extracted</resp>
                        <xsl:apply-templates select="descendant::tei:fileDesc/tei:titleStmt/descendant::tei:persName" mode="m_copy-from-authority-file"/>
                    </respStmt>
                </titleStmt>
                <publicationStmt>
                    <authority>
                        <xsl:apply-templates select="$p_editor/descendant::tei:persName" mode="m_copy-from-authority-file"/>
                        <date>
                            <xsl:attribute name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                            <xsl:value-of select="format-date(current-date(), '[Y0001]')"/>
                        </date>
                        <availability status="restricted">
                            <licence target="http://creativecommons.org/licenses/by-sa/4.0/" xml:lang="en">Distributed under a Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0) license</licence>
                        </availability>
                    </authority>
                </publicationStmt>
                <sourceDesc>
                    <p>Born digital.</p>
                </sourceDesc>
            </fileDesc>
            <revisionDesc xml:lang="en">
                <xsl:element name="change">
                    <xsl:attribute name="when" select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                    <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                    <xsl:attribute name="xml:lang" select="'en'"/>
                    <xsl:attribute name="xml:id" select="$p_id-change"/>
                    <xsl:text>Generated this file from </xsl:text>
                    <xsl:element name="ref">
                        <xsl:attribute name="target" select="base-uri()"/>
                        <xsl:value-of select="base-uri()"/>
                    </xsl:element>
                    <xsl:text>.</xsl:text>
                </xsl:element>
            </revisionDesc>
        </teiHeader>
    </xsl:variable>
</xsl:stylesheet>
