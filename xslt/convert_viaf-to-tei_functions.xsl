<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet  xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" 
    xmlns:opf="http://www.idpf.org/2007/opf" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:bgn="http://bibliograph.net/" 
    xmlns:genont="http://www.w3.org/2006/gen/ont#" 
    xmlns:pto="http://www.productontology.org/id/" 
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:re="http://oclcsrw.google.code/redirect" 
    xmlns:schema="http://schema.org/" 
    xmlns:umbel="http://umbel.org/umbel#"
    xmlns:srw="http://www.loc.gov/zing/srw/"
    xmlns:viaf="http://viaf.org/viaf/terms#"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="#all" version="2.0">
    
    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>
    
    <!-- these variables are used to establish the language of any given string -->
    <xsl:variable name="v_string-transcribe-ijmes" select="'btḥḫjdrzsṣḍṭẓʿfqklmnhāūīwy0123456789'"/>
    <xsl:variable name="v_string-transcribe-arabic" select="'بتحخجدرزسصضطظعفقكلمنهاويوي٠١٢٣٤٥٦٧٨٩'"/>
    
     <!-- transform VIAF results to TEI -->
    <xsl:template match="schema:birthDate | viaf:birthDate" mode="m_viaf-to-tei">
        <xsl:element name="tei:birth">
            <xsl:attribute name="resp" select="'viaf'"/>
            <xsl:call-template name="t_dates-normalise">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="schema:deathDate | viaf:deathDate" mode="m_viaf-to-tei">
        <xsl:element name="tei:death">
            <xsl:attribute name="resp" select="'viaf'"/>
            <xsl:call-template name="t_dates-normalise">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="viaf:viafID" mode="m_viaf-to-tei">
        <xsl:element name="tei:idno">
            <xsl:attribute name="type" select="'viaf'"/>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    
    <!-- additional personal names -->
    <xsl:template match="viaf:subfield[@code='a']" mode="m_viaf-to-tei">
        <!-- check if the name is in Arabic script -->
        <xsl:if test="contains($v_string-transcribe-arabic,replace(.,'.*(\w).+','$1'))">
            <xsl:element name="tei:persName">
                <xsl:attribute name="xml:lang" select="'ar'"/>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <!-- transform viaf works to TEI bibls -->
    <xsl:template match="viaf:titles" mode="m_viaf-to-tei">
        <xsl:element name="tei:listBibl">
            <xsl:attribute name="resp" select="'viaf'"/>
            <xsl:apply-templates mode="m_viaf-to-tei"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="viaf:work" mode="m_viaf-to-tei">
        <xsl:element name="tei:bibl">
            <xsl:attribute name="resp" select="'viaf'"/>
            <!-- author information might be redundant but helpful -->
            <xsl:element name="tei:author">
                <xsl:element name="tei:persName">
                    <xsl:attribute name="ref">
                        <xsl:value-of select="concat('viaf:',ancestor::viaf:VIAFCluster/viaf:viafID)"/>
                    </xsl:attribute>
                    <!-- it would be great to actually pull a name from the record -->
                </xsl:element>
            </xsl:element>
            <!-- title -->
            <xsl:apply-templates select="descendant::viaf:title" mode="m_viaf-to-tei"/>
            <!-- identifiers -->
            <xsl:apply-templates select="@id"/>
            <xsl:apply-templates select="descendant::viaf:sid" mode="m_viaf-to-tei"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="viaf:work/@id" mode="m_viaf-to-tei">
        <xsl:variable name="v_authority" select="lower-case(tokenize(.,'\|')[1])"/>
        <xsl:variable name="v_id" select="tokenize(.,'\|')[2]"/>
        <xsl:element name="tei:idno">
            <xsl:attribute name="type" select="$v_authority"/>
            <xsl:value-of select="$v_id"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="viaf:title" mode="m_viaf-to-tei">
        <xsl:element name="tei:title">
            <xsl:apply-templates mode="m_viaf-to-tei"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="viaf:sources/viaf:sid" mode="m_viaf-to-tei">
        <xsl:variable name="v_authority" select="lower-case(tokenize(.,'\|')[1])"/>
        <xsl:variable name="v_id" select="tokenize(.,'\|')[2]"/>
        <xsl:element name="tei:idno">
            <xsl:attribute name="type" select="$v_authority"/>
            <xsl:value-of select="$v_id"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="t_dates-normalise">
        <!-- the dates returned by VIAF can be formatted as
            - yyyy: no issue
            - yyy: needs a leading 0
            - yyyy-mm-dd: no issue
            - yyy-mm-dd: the year needs an additional leading 0
            - yyyy-mm-00: this indicates a date range of a full month
        -->
        <!-- output are ATTRIBUTES! -->
        <xsl:param name="p_input"/>
        <xsl:analyze-string select="$p_input" regex="(\d{{3,4}})$|(\d{{3,4}})-(\d{{2}})-(\d{{2}})$">
            <xsl:matching-substring>
<!--                <xsl:element name="tei:date">-->
                    <xsl:variable name="v_year">
                        <xsl:value-of select="format-number(number(regex-group(2)),'0000')"/>
                    </xsl:variable>
                    <xsl:variable name="v_month">
                        <xsl:value-of select="format-number(number(regex-group(3)),'00')"/>
                    </xsl:variable>
                    <!-- check if the result is a date range -->
                    <xsl:choose>
                        <xsl:when test="regex-group(4)='00'">
                            <xsl:attribute name="notBefore" select="concat($v_year,'-',$v_month,'-01')"/>
                            <!-- in order to not produce invalid dates, we pretend that all Gregorian months have only 28 days-->
                            <xsl:attribute name="notAfter" select="concat($v_year,'-',$v_month,'-28')"/>
                        </xsl:when>
                        <xsl:when test="regex-group(2)">
                            <xsl:attribute name="when" select="concat($v_year,'-',$v_month,'-',regex-group(4))"/>
                        </xsl:when>
                        <xsl:when test="regex-group(1)">
                            <xsl:attribute name="when" select="format-number(number(regex-group(1)),'0000')"/>
                        </xsl:when>
                    </xsl:choose>
<!--                    <xsl:value-of select="$p_input"/>-->
                <!--</xsl:element>-->
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
</xsl:stylesheet>