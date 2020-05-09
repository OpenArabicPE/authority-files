<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"  
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:zot="https://zotero.org"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:opf="http://www.idpf.org/2007/opf"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="dc html opf xd"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    
     <xsl:param name="p_url-zirikli" select="'/BachUni/BachBibliothek/GitHub/TEI/oclc_165855925/tei?select=*.TEIP5.xml'"/>
    <xsl:param name="p_url-sarkis" select="'/BachUni/BachBibliothek/GitHub/TEI/oclc_618896732/tei?select=*.TEIP5.xml'"/>
    <xsl:variable name="v_zirikli" select="collection($p_url-zirikli)/descendant::tei:text"/>
    <xsl:variable name="v_sarkis" select="collection($p_url-sarkis)/descendant::tei:text"/>
    <xsl:param name="p_lang" select="'ar'"/>
    
    <xsl:variable name="v_separator" select="', '"/>
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:body">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:for-each-group select="descendant::tei:biblStruct" group-by="tei:monogr/tei:title[@xml:lang = $p_lang][not(@type = 'sub')][1]">
                <xsl:sort select="current-grouping-key()"/>
                <xsl:apply-templates select="."/>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:biblStruct">
        <xsl:variable name="v_title-publication" select="tei:monogr/tei:title[@xml:lang = $p_lang][not(@type = 'sub')][1]"/>
        <!--<xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
            <xsl:copy-of select="oape:query-text-for-bibliographic-references($v_zirikli, $v_title-publication)"/>
            <xsl:copy-of select="oape:query-text-for-bibliographic-references($v_sarkis, $v_title-publication)"/>
        </xsl:copy>-->
        <div type="section" xml:lang="{$p_lang}">
            <head><xsl:apply-templates select="$v_title-publication" mode="m_copy-from-source"/></head>
            <!-- sarkis -->
            <div type="section">
                <head>سركيس</head>
                <xsl:copy-of select="oape:query-text-for-bibliographic-references($v_sarkis, $v_title-publication, 'j')"/>
            </div>
            <!-- zirikli -->
            <div type="section">
                <head>زركلي</head>
                <xsl:copy-of select="oape:query-text-for-bibliographic-references($v_zirikli, $v_title-publication, 'j')"/>
            </div>
        </div>
    </xsl:template>
    
    <xsl:function name="oape:query-text-for-bibliographic-references">
        <xsl:param name="p_text"/>
        <xsl:param name="p_title"/>
        <xsl:param name="p_level"/>
        <xsl:apply-templates select="$p_text/descendant::node()[self::tei:p | self::tei:ab][descendant::tei:title[@level = $p_level] = $p_title]" mode="m_generate-note"/>
    </xsl:function>
    
    <xsl:template match="tei:p | tei:ab" mode="m_generate-note">
        <xsl:param name="p_output-div" select="true()"/>
        <xsl:variable name="v_source-biblStruct" select="ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct"/>
        <xsl:variable name="v_source-url" select="concat(base-uri(),'#',@xml:id)"/>
        <xsl:variable name="v_pb-onset" select="preceding::tei:pb[@ed = 'print'][1]/@n"/>
        <xsl:variable name="v_pb-terminus">
            <xsl:choose>
                            <xsl:when test="descendant::tei:pb[@ed = 'print']">
                                <xsl:value-of select="descendant::tei:pb[@ed = 'print'][last()]/@n"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$v_pb-onset"/>
                            </xsl:otherwise>
                        </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference">
            <note type="bibliographic" place="inline">
                <!-- technical pointer to the source -->
                <ref target="{$v_source-url}">
                    <!-- human-readable bibliographic reference -->
                    <bibl>
                        <xsl:apply-templates select="$v_source-biblStruct/tei:monogr/tei:author"/>
                        <xsl:value-of select="$v_separator"/>
                        <xsl:apply-templates select="$v_source-biblStruct/tei:monogr/tei:title[@xml:lang = $p_lang][1]"/>
                        <xsl:value-of select="$v_separator"/>
                        <xsl:apply-templates select="$v_source-biblStruct/tei:monogr/tei:biblScope[@unit = 'volume']"/>
                        <xsl:value-of select="$v_separator"/>
                        
                        <biblScope unit="page" from="{$v_pb-onset}" to="{$v_pb-terminus}">
                            <xsl:value-of select="concat($v_pb-onset,'-',$v_pb-terminus)"/>
                        </biblScope>
                    </bibl>
                </ref>
            </note>
        </xsl:variable>
        <!-- generate output -->
        <xsl:choose>
            <xsl:when test="$p_output-div = true()">
                <div type="item" subtype="entry">
                    <xsl:apply-templates select="ancestor::tei:div[1]/tei:head" mode="m_copy-from-source"/>
                    <!-- information about and links to the sourc -->
                    <xsl:copy-of select="$v_reference"/>
                    <gap/>
                    <xsl:apply-templates select="." mode="m_copy-from-source"/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <note place="inline">
        <!-- information about and links to the sourc -->
            <xsl:copy-of select="$v_reference"/>
        <!-- the source -->
            <quote>
                <xsl:apply-templates select="ancestor::tei:div[1]/tei:head/node()" mode="m_copy-from-source"/>
            </quote>
            <quote>
                <!-- replicate the node() containing the searched for <title> -->
                <!-- PROBLEM: some child::tei:note are not replicated -->
                <xsl:apply-templates select="node()" mode="m_copy-from-source"/>
            </quote>
        </note>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="node() | @*" mode="m_copy-from-source">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_copy-from-source"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- select which attributes not to copy from the source -->
    <xsl:template match="@xml:id | @change" mode="m_copy-from-source"/>
    
</xsl:stylesheet>