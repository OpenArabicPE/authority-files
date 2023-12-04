<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="xml"/>
    <xsl:import href="functions.xsl"/>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:item/tei:ab[tei:bibl]">
        <xsl:element name="listBibl">
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="source" select="ancestor::node()[@source][1]/@source"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:note[@type = 'holdings']/tei:list/tei:item[tei:label][tei:ref]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tei:label"/>
            <xsl:element name="listBibl">
                <xsl:attribute name="source" select="@source"/>
                <xsl:choose>
                    <xsl:when test="count(tei:ref) = 1">
                        <xsl:element name="bibl">
                            <xsl:apply-templates mode="m_ref-to-idno" select="tei:label/following-sibling::node()"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="text()"/>
                        <xsl:for-each select="tei:ref">
                            <xsl:element name="bibl">
                                <xsl:apply-templates mode="m_ref-to-idno" select="."/>
                            </xsl:element>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:ref" mode="m_ref-to-idno">
        <xsl:element name="idno">
            <xsl:attribute name="change" select="concat('#', $p_id-change)"/>
            <xsl:choose>
                <xsl:when test="matches(@target, '(gpa.eastview)|(ima.bibalex.org)|(/ark:/)|(jrayed/Pages/)|(/archive.org/)|(/openarabicpe.github.io/)|(archive.alsharekh.org)|(eap.bl.uk)')">
                    <xsl:attribute name="type" select="'URI'"/>
                    <xsl:attribute name="subtype" select="'self'"/>
                </xsl:when>
                <xsl:when test="matches(@target, '(urn:)')">
                    <xsl:attribute name="type" select="'URN'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="type" select="'url'"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="@target"/>
        </xsl:element>
        <!-- reproduce the old content -->
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="tei:ab[matches(., '^\s*source:')]"/>
    <xsl:template match="tei:ab[matches(tei:ref, '^\s*catalogue')]"/>
    <xsl:template match="tei:bibl/element()/@source">
        <xsl:choose>
            <xsl:when test="starts-with(., concat($p_local-authority, ':org'))"/>
            <!--            <xsl:when test=". = ancestor::element()[@source][1]/@source"/>-->
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- create date[@type = documented] based on the holdings -->
    <xsl:template match="tei:imprint" mode="m_off">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <xsl:variable name="v_date-holdings-onset" select="min(ancestor::tei:biblStruct/tei:note[@type = 'holdings']/descendant::tei:bibl/tei:date[@when]/@when)"/>
            <xsl:variable name="v_date-holdings-terminus" select="max(ancestor::tei:biblStruct/tei:note[@type = 'holdings']/descendant::tei:bibl/tei:date[@when]/@when)"/>
            <xsl:if test="empty($v_date-holdings-onset) = false()">
                <!-- create a variable -->
                <xsl:variable name="v_date-documented">
                    <xsl:element name="date">
                        <xsl:attribute name="type" select="'documented'"/>
                        <xsl:choose>
                            <xsl:when test="$v_date-holdings-onset = $v_date-holdings-terminus">
                                <xsl:attribute name="when" select="$v_date-holdings-terminus"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="notBefore" select="$v_date-holdings-onset"/>
                                <xsl:attribute name="notAfter" select="$v_date-holdings-terminus"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <!-- document sources -->
                        <xsl:attribute name="source">
                            <xsl:for-each-group group-by="ancestor::tei:listBibl/@source" select="ancestor::tei:biblStruct/tei:note[@type = 'holdings']/descendant::tei:bibl/tei:date[@when]">
                                <xsl:value-of select="current-grouping-key()"/>
                                <!-- add a separator between multiple values -->
                                <xsl:text> </xsl:text>
                            </xsl:for-each-group>
                        </xsl:attribute>
                    </xsl:element>
                </xsl:variable>
                <xsl:if test="not(tei:date[@type = 'documented'] = $v_date-documented/tei:date)">
                    <xsl:copy-of select="$v_date-documented/tei:date"/>
                </xsl:if>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
