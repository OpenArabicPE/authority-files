<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="xs xd xi" version="3.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    
    <xsl:variable name="v_file-id" select="tei:TEI/@xml:id"/>
    <xsl:variable name="v_file-name" select="tokenize(base-uri(),'/')[last()]"/>
    
    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/">
        <xsl:apply-templates select="descendant::tei:text/tei:body"/>
    </xsl:template>
    <xsl:template match="tei:body">
       <xsl:element name="tei:listBibl">
           <xsl:attribute name="source" select="$v_file-name"/>
            <xsl:apply-templates select="descendant::tei:title[not(ancestor::tei:bibl)] | descendant::tei:bibl">
                <xsl:sort select="@ref" order="descending"/>
            </xsl:apply-templates>
       </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:title[not(ancestor::tei:bibl)]">
        <xsl:element name="tei:bibl">
            <!-- point back to source -->
            <xsl:attribute name="source" select="concat($v_file-name, '#', @xml:id)"/>
            <xsl:copy>
                <xsl:apply-templates select="@* | node()"/>
            </xsl:copy>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:bibl">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="source" select="concat($v_file-name, '#', @xml:id)"/>
            <xsl:apply-templates select="node()"/>
            <xsl:if test="matches(@ref,'\w+:\d+')">
                <xsl:element name="tei:idno">
                    <xsl:attribute name="type" select="replace(@ref,'(\w+):\d+','$1')"/>
                    <xsl:value-of select="replace(@ref,'\w+:(\d+)','$1')"/>
                </xsl:element>
            </xsl:if>
            <xsl:if test="matches(tei:title/@ref,'\w+:\d+')">
                <xsl:element name="tei:idno">
                    <xsl:attribute name="type" select="replace(tei:title/@ref,'(\w+):\d+','$1')"/>
                    <xsl:value-of select="replace(tei:title/@ref,'\w+:(\d+)','$1')"/>
                </xsl:element>
            </xsl:if>
            <!-- unite bibls linked with @next attribute -->
            <xsl:if test="starts-with(@next,'#')">
                <xsl:variable name="v_id-next-part" select="substring-after(@next,'#')"/>
                <xsl:apply-templates select="ancestor::tei:TEI/descendant::tei:bibl[@xml:id = $v_id-next-part]/node()"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
    <!-- attributes and nodes not to be replicated -->
    <xsl:template match="@xml:id | @change | tei:bibl/@ref | tei:bibl[starts-with(@prev,'#')]"/>
</xsl:stylesheet>