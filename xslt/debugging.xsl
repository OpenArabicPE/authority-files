<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" 
    xmlns:bgn="http://bibliograph.net/" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:genont="http://www.w3.org/2006/gen/ont#" 
    xmlns:oape="https://openarabicpe.github.io/ns" 
    xmlns:opf="http://www.idpf.org/2007/opf" 
    xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:re="http://oclcsrw.google.code/redirect" 
    xmlns:schema="http://schema.org/" 
    xmlns:srw="http://www.loc.gov/zing/srw/"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:umbel="http://umbel.org/umbel#" 
    xmlns:viaf="http://viaf.org/viaf/terms#" 
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xi="http://www.w3.org/2001/XInclude" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    
    <xsl:import href="functions.xsl"/>
    <xsl:output method="xml" indent="true"/>
    
        <xsl:template match="/">
        <!-- test if the URL of the personography resolves to an actual file -->
        <xsl:if test="not(doc-available($p_url-bibliography))">
            <xsl:message terminate="yes">
                <xsl:text>The specified authority file has not been found at </xsl:text><xsl:value-of select="$p_url-bibliography"/>
            </xsl:message>
        </xsl:if>
        <xsl:copy>
            <list>
<!--                <xsl:apply-templates select="descendant::tei:placeName" mode="m_debug"/>-->
                <!--<xsl:apply-templates select="descendant::tei:title[@level = 'j']" mode="m_debug"/>-->
                <xsl:apply-templates select="descendant::tei:orgName" mode="m_debug"/>
            </list>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:orgName" mode="m_debug">
        <item>
            <ab><xsl:copy-of select="oape:get-entity-from-authority-file(., $p_local-authority, $v_organizationography)"/></ab>
        </item>
    </xsl:template>
    <xsl:template match="tei:placeName" mode="m_debug">
        <!-- output -->
        <item>
            <ab><xsl:value-of select="oape:query-gazetteer(., $v_gazetteer, $p_local-authority, 'id', '')"/></ab>
        </item>
    </xsl:template>
    
       <xsl:template match="tei:title[ancestor::tei:bibl][@level = 'j'][not(@type = 'sub')]" mode="m_debug" priority="10">
           <xsl:variable name="v_first" select="oape:find-first-part(ancestor::tei:bibl[1])"/>
           <xsl:variable name="v_compiled" select="oape:compile-next-prev(oape:find-first-part(ancestor::tei:bibl[1]))"/>
           <xsl:variable name="v_self" select="."/>
           <xsl:variable name="v_biblStruct">
            <xsl:choose>
                <xsl:when test="$v_self/ancestor::tei:biblStruct">
                    <xsl:apply-templates select="./ancestor::tei:biblStruct[1]" mode="m_identity-transform"/>
                </xsl:when>
                <xsl:when test="$v_self/ancestor::tei:bibl">
                    <xsl:message>
                        <xsl:text>has ancestor tei:bibl</xsl:text>
                    </xsl:message>
                    <!-- 1. compile along @next and @prev -->
                    <xsl:variable name="v_first" select="oape:find-first-part($v_self/ancestor::tei:bibl[1])"/>
                    <xsl:variable name="v_compiled" select="oape:compile-next-prev(oape:find-first-part($v_self/ancestor::tei:bibl[1]))"/>
<!--                    <xsl:copy-of select="$v_self/ancestor::tei:bibl"/>-->
                    <!-- 2. convert to biblStruct for easier comparison -->
                    <xsl:apply-templates mode="m_bibl-to-biblStruct" select="$v_compiled"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- the original 'NA' was not making sense anymore -->
                    <!--<xsl:value-of select="'NA'"/>-->
                    <biblStruct type="periodical">
                        <monogr>
                            <xsl:apply-templates mode="m_identity-transform" select="."/>
                        </monogr>
                    </biblStruct>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
           <item>
<!--               <ab><xsl:copy-of select="$v_first"/></ab>-->
<!--               <ab><xsl:copy-of select="$v_compiled"/></ab>-->
<!--               <ab><xsl:copy-of select="$v_biblStruct"/></ab>-->
               <ab><xsl:value-of select="oape:query-biblstruct($v_biblStruct, 'id-location', '', $v_gazetteer, $p_local-authority)"/></ab>
               <!-- there is a problem in this function, which I cannot debug -->
               <ab><xsl:copy-of select="oape:link-title-to-authority-file(., $p_local-authority, $v_bibliography)"/></ab>
           </item>
    </xsl:template>
    <!-- no problems with titles without ancestor::tei:bibl -->
    <xsl:template match="tei:title[@level = 'j']" mode="m_debug">
        <item>
            <ab><xsl:copy-of select="oape:link-title-to-authority-file(., $p_local-authority, $v_bibliography)"/></ab>
        </item>
    </xsl:template>
    
</xsl:stylesheet>