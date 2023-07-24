<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:xpath="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!--    <xsl:import href="https://openarabicpe.github.io/convert_tei-to-bibliographic-data/xslt/convert_marc-xml-to-tei_functions.xsl"/>-->
    <xsl:import href="../../convert_tei-to-bibliographic-data/xslt/convert_marc-xml-to-tei_functions.xsl"/>
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:template match="/">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
        <!--        <xsl:apply-templates select="tei:TEI/tei:standOff/descendant::tei:biblStruct"/>-->
    </xsl:template>
    <!-- identity transform -->
    <xsl:template match="node()[namespace::tei] | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblStruct" priority="10">
        <xsl:variable name="v_self-plus-holdings">
            <xsl:copy>
                <xsl:apply-templates mode="m_identity-transform" select="@* | node()"/>
                <xsl:apply-templates mode="m_query-holdings" select="."/>
            </xsl:copy>
        </xsl:variable>
        <xsl:apply-templates mode="m_postprocess" select="$v_self-plus-holdings"/>
    </xsl:template>
    <!-- remove existing holding information from the sources that will be queried by this stylesheet -->
    <xsl:template match="tei:note[@type = 'holdings'][@source = ('#zdb', '#hathi')]" mode="m_identity-transform" priority="10"/>
    <xsl:template match="tei:bibl[ancestor::tei:note[@type = 'holdings']][@source = ('#zdb', '#hathi')]" mode="m_identity-transform" priority="10"/>
    <xsl:template match="tei:item[ancestor::tei:note[@type = 'holdings']][matches(@source, 'catalog.hathitrust.org/Record')]" mode="m_identity-transform" priority="10"/>
    <!-- this was too aggressive -->
    <!--<xsl:template match="tei:item[ancestor::tei:note[@type = 'holdings']][matches(@source, 'ld.zdb-services.de/|catalog.hathitrust.org/Record')]" mode="m_identity-transform" priority="10"/>-->
    <!-- query holdings -->
    <xsl:template match="tei:biblStruct" mode="m_query-holdings">
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
        <!-- generate a note with the holding information for each <idno> that points to a digitised collection -->
        <xsl:if test="$v_digital-holdings = true()">
            <xsl:message>
                <xsl:text>There are digitised collections, which can be queried</xsl:text>
            </xsl:message>
            <xsl:apply-templates mode="m_query-holdings" select="tei:monogr/tei:idno[@type = 'ht_bib_key'] | tei:monogr/tei:idno[@type = 'zdb']"/>
        </xsl:if>
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
    <!-- some post processing -->
    <xsl:template match="node() | @*" mode="m_postprocess">
        <xsl:copy>
            <xsl:apply-templates mode="m_postprocess" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:listBibl[ancestor::tei:note/@type = 'holdings']" mode="m_postprocess">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_postprocess"/>
            <xsl:apply-templates select="node()" mode="m_postprocess">
                <xsl:sort select="tei:bibl/descendant::tei:biblScope[@unit = 'volume'][1]/@from"/>
                <xsl:sort select="tei:bibl/descendant::tei:biblScope[@unit = 'issue'][1]/@from"/>
                <xsl:sort select="tei:bibl/descendant::tei:date[@when][1]/@when"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:bibl[ancestor::tei:note/@type = 'holdings']" mode="m_postprocess">
        <xsl:copy>
            <xsl:apply-templates mode="m_identity-transform" select="@*"/>
            <xsl:attribute name="corresp">
                <xsl:value-of select="oape:query-biblstruct(ancestor::tei:biblStruct[1], 'tei-ref', '', '', $p_local-authority)"/>
            </xsl:attribute>
            <xsl:apply-templates mode="m_postprocess" select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:biblScope" mode="m_postprocess">
        <xsl:choose>
            <!-- volume and issue  -->
            <!-- 1:1-48  -->
            <xsl:when test="matches(., '\d+:\d+-\d+')">
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <xsl:attribute name="unit">
                        <xsl:value-of select="'volume'"/>
                    </xsl:attribute>
                    <xsl:attribute name="from">
                        <xsl:value-of select="replace(., '^.*(\d+):\d+-\d+.*$', '$1')"/>
                    </xsl:attribute>
                    <xsl:attribute name="to">
                        <xsl:value-of select="replace(., '^.*(\d+):\d+-\d+.*$', '$1')"/>
                    </xsl:attribute>
                    <xsl:apply-templates mode="m_identity-transform"/>
                </xsl:copy>
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <xsl:attribute name="unit">
                        <xsl:value-of select="'issue'"/>
                    </xsl:attribute>
                    <xsl:attribute name="from">
                        <xsl:value-of select="replace(., '^.*\d+:(\d+)-\d+.*$', '$1')"/>
                    </xsl:attribute>
                    <xsl:attribute name="to">
                        <xsl:value-of select="replace(., '^.*\d+:\d+-(\d+).*$', '$1')"/>
                    </xsl:attribute>
                    <xsl:apply-templates mode="m_identity-transform"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates mode="m_identity-transform" select="@*"/>
                    <!-- volume information -->
                    <xsl:if test="matches(., 'vol\.\s*\d+')">
                        <xsl:attribute name="unit" select="'volume'"/>
                        <xsl:attribute name="from">
                            <xsl:value-of select="replace(., '^.*vol\.\s*(\d+).*$', '$1')"/>
                        </xsl:attribute>
                        <xsl:attribute name="to">
                            <xsl:choose>
                                <xsl:when test="matches(., '\d+\s*-\s*\d+')">
                                    <xsl:value-of select="replace(., '^.*\d+\s*-\s*(\d+).*$', '$1')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="replace(., '^.*vol\.\s*(\d+).*$', '$1')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates mode="m_identity-transform"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
