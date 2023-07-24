<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xpath="http://www.w3.org/2005/xpath-functions" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!--    <xsl:import href="https://openarabicpe.github.io/convert_tei-to-bibliographic-data/xslt/convert_marc-xml-to-tei_functions.xsl"/>-->
    <xsl:import href="../../convert_tei-to-bibliographic-data/xslt/convert_marc-xml-to-tei_functions.xsl"/>
<!--    <xsl:import href="functions.xsl"/>-->
    <xsl:output encoding="UTF-8" indent="yes" method="xml"/>
    <!-- identity transform -->
    <!--<xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@*  | node()"/>
        </xsl:copy>
    </xsl:template>-->
    <xsl:template match="/">
        <xsl:apply-templates select="tei:TEI/tei:standOff/descendant::tei:biblStruct"/>
    </xsl:template>
    <xsl:template match="tei:biblStruct" priority="10">
        <xsl:variable name="v_digital-holdings">
            <xsl:choose>
                <!-- HathiTrust -->
                <xsl:when test="tei:monogr/tei:idno[@type = 'ht_bib_key']">
                    <xsl:copy-of select="true()"/>
                </xsl:when>
                <xsl:when test="tei:monogr/tei:idno[@type = 'zdb']">
                    <xsl:copy-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- content -->
        <xsl:copy>
            <xsl:if test="$v_digital-holdings = true()">
                <xsl:message>
                    <xsl:text>There are digitised collections, which can be queried</xsl:text>
                </xsl:message>
                <xsl:apply-templates mode="m_query-holdings" select="tei:monogr/tei:idno[@type = 'ht_bib_key'] | tei:monogr/tei:idno[@type = 'zdb']"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:monogr/tei:idno[@type = ('zdb', 'ht_bib_key')]" mode="m_query-holdings">
        <!-- get the MARC XML record -->
        <xsl:variable name="v_marcx-record">
            <xsl:choose>
                <xsl:when test="@type = 'zdb'">
                    <xsl:copy-of select="doc(concat('https://ld.zdb-services.de/data/', ., '.plus-1.mrcx'))"/>
                </xsl:when>
                <xsl:when test="@type = 'ht_bib_key'">
                    <!-- the MARC XML is encapsulated in the JSON string -->
                    <xsl:variable name="v_json-string" select="unparsed-text(concat('https://catalog.hathitrust.org/api/volumes/full/recordnumber/', ., '.json'))"/>
                    <xsl:if test="$p_debug = true()">
                        <xsl:message>
                            <xsl:text>$v_json-string: </xsl:text>
                            <xsl:value-of select="$v_json-string"/>
                        </xsl:message>
                    </xsl:if>
                    <xsl:variable as="document-node()" name="v_json-xml" select="json-to-xml($v_json-string)"/>
                    <xsl:variable name="v_marc-string" select="$v_json-xml/descendant::xpath:string[@key = 'marc-xml'][1]"/>
                    <xsl:if test="$p_debug = true()">
                        <xsl:message>
                            <xsl:text>$v_marc-string: </xsl:text>
                            <xsl:copy-of select="$v_marc-string"/>
                        </xsl:message>
                    </xsl:if>
                    <xsl:variable name="v_marc-xml">
                        <xsl:apply-templates mode="m_marc-add-ns" select="parse-xml($v_marc-string)/element()"/>
                    </xsl:variable>
                    <xsl:if test="$p_debug = true()">
                        <xsl:message>
                            <xsl:text>$v_marc-xml: </xsl:text>
                            <xsl:copy-of select="$v_marc-xml"/>
                        </xsl:message>
                    </xsl:if>
                    <xsl:copy-of select="$v_marc-xml/marc:collection/marc:record"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!-- query the MARC XML record -->
        <xsl:copy-of select="oape:query-marcx($v_marcx-record, 'holdings')"/>
    </xsl:template>
</xsl:stylesheet>
