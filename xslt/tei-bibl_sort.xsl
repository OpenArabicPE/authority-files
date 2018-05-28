<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs xd xi" version="3.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    
    <xsl:output method="xml" omit-xml-declaration="no" indent="no" encoding="UTF-8"/>
    
    <xsl:variable name="v_file-id" select="tei:TEI/@xml:id"/>
    <xsl:variable name="v_file-name" select="tokenize(base-uri(),'/')[last()]"/>
    
    
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- remove all listBibl -->
    <!--<xsl:template match="tei:listBibl">
        <xsl:apply-templates/>
    </xsl:template>-->
    <!-- sort by oclc, title level, title -->
    <xsl:template match="tei:div[child::tei:bibl]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!--<xsl:apply-templates select="tei:bibl">
                <xsl:sort select="descendant::tei:title[@level = ('m','j')][1]"/>
                <xsl:sort select="tei:idno[@type='oclc'][1]" order="descending"/>
                <xsl:sort select="descendant::tei:title[@level = 'a'][1]"/>
                <!-\- sort by author -\->
                <xsl:sort select="descendant::tei:author[1]/tei:persName[1]"/>
                <!-\-<xsl:sort select="if(tei:title[not(@level='a')]) then(tei:title[not(@level='a')](1)) else(tei:title[@level='a'][1])"/>
                <xsl:sort select="if(tei:title[not(@level='a')]) then(tei:title[not(@level='a')](1)) else(tei:title[@level='a'][1])"/>-\->
            </xsl:apply-templates>-->
            
            <!-- group by absence of information and type of publication: i.e. book or periodical -->
            <!-- books -->
            <xsl:element name="tei:listBibl">
                <xsl:element name="tei:head">
                    <xsl:text>Books</xsl:text>
                </xsl:element>
                <xsl:apply-templates select="tei:bibl[descendant::tei:title[@level = 'm']]">
                <xsl:sort select="descendant::tei:title[@level = 'm'][1]"/>
                <xsl:sort select="tei:idno[@type='oclc'][1]" order="descending"/>
                <xsl:sort select="descendant::tei:title[@level = 'a'][1]"/>
                <!-- sort by author -->
                <xsl:sort select="descendant::tei:author[1]/tei:persName[1]"/>
                <!--<xsl:sort select="if(tei:title[not(@level='a')]) then(tei:title[not(@level='a')](1)) else(tei:title[@level='a'][1])"/>
                <xsl:sort select="if(tei:title[not(@level='a')]) then(tei:title[not(@level='a')](1)) else(tei:title[@level='a'][1])"/>-->
            </xsl:apply-templates>
            </xsl:element>
            <!-- periodicals -->
            <xsl:element name="tei:listBibl">
                <xsl:element name="tei:head">
                    <xsl:text>Periodicals</xsl:text>
                </xsl:element>
            <xsl:apply-templates select="tei:bibl[descendant::tei:title[@level = 'j']]">
                <xsl:sort select="descendant::tei:title[@level = 'j'][1]"/>
                <xsl:sort select="tei:idno[@type='oclc'][1]" order="descending"/>
                <xsl:sort select="descendant::tei:title[@level = 'a'][1]"/>
                <!-- sort by author -->
                <xsl:sort select="descendant::tei:author[1]/tei:persName[1]"/>
                <!--<xsl:sort select="if(tei:title[not(@level='a')]) then(tei:title[not(@level='a')](1)) else(tei:title[@level='a'][1])"/>
                <xsl:sort select="if(tei:title[not(@level='a')]) then(tei:title[not(@level='a')](1)) else(tei:title[@level='a'][1])"/>-->
            </xsl:apply-templates>
            </xsl:element>
            
            <!-- neither books nor periodicals -->
            <!-- books -->
            <xsl:element name="tei:listBibl">
                <xsl:element name="tei:head">
                    <xsl:text>Unclassified</xsl:text>
                </xsl:element>
            <xsl:apply-templates select="tei:bibl[descendant::tei:title[not(@level = ('m','j'))]]">
                <xsl:sort select="descendant::tei:title[1]"/>
                <xsl:sort select="tei:idno[@type='oclc'][1]" order="descending"/>
                <xsl:sort select="descendant::tei:title[@level = 'a'][1]"/>
                <!-- sort by author -->
                <xsl:sort select="descendant::tei:author[1]/tei:persName[1]"/>
                <!--<xsl:sort select="if(tei:title[not(@level='a')]) then(tei:title[not(@level='a')](1)) else(tei:title[@level='a'][1])"/>
                <xsl:sort select="if(tei:title[not(@level='a')]) then(tei:title[not(@level='a')](1)) else(tei:title[@level='a'][1])"/>-->
            </xsl:apply-templates>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    
    
    
</xsl:stylesheet>