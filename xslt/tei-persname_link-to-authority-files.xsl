<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0"
    xmlns:oape="https://openarabicpe.github.io/ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <!-- PROBLEMS: 
         - no known problems
    -->
    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml"
        omit-xml-declaration="no"/>
    <xsl:include href="functions.xsl"/>

    <!-- variables for local IDs (OpenArabicPE) -->
    <xsl:param name="p_local-authority" select="'oape'"/>
    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-personography" select="'../data/tei/personography_OpenArabicPE.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-personography)"/>
    <xsl:param name="p_add-mark-up-to-input" select="true()"/>
    
    <!-- idendity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="tei:persName" priority="30">
        <xsl:variable name="v_self-linked" select="oape:link-persname-to-authority-file(., $p_local-authority, $v_file-entities-master, $p_add-mark-up-to-input)"/>
        <xsl:choose>
            <!-- test if a match was found in the authority file -->
            <xsl:when test="$v_self-linked/@ref">
                <xsl:copy-of select="$v_self-linked"/>
            </xsl:when>
            <!-- fall back -->
            <xsl:otherwise>
                <!-- add mark-up to the input name -->
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>Starting further processing</xsl:text>
                    </xsl:message>
                </xsl:if>
                <xsl:variable name="v_name-marked-up" select="oape:name-add-markup(.)"/>
                <xsl:variable name="v_no-rolename">
                    <xsl:apply-templates select="$v_name-marked-up" mode="m_remove-rolename"/>
                </xsl:variable>
<!--                <xsl:variable name="v_no-rolename-flat" select="oape:string-remove-spaces(oape:string-normalise-characters($v_no-rolename))"/>-->
                <!--<xsl:message>
                    <xsl:copy-of select="$v_no-rolename/descendant-or-self::tei:persName"/>
                </xsl:message>-->
                <!-- call this function again with the new, marked-up name -->
                <xsl:variable name="v_name-marked-up-linked" select="oape:link-persname-to-authority-file($v_no-rolename/tei:persName, $p_local-authority, $v_file-entities-master, $p_add-mark-up-to-input)"/>
                    <xsl:choose>
                    <!-- test if a match was found in the authority file -->
                    <xsl:when test="$v_name-marked-up-linked/@ref">
                        <xsl:copy>
                            <!-- original attributes -->
                            <xsl:apply-templates select="@*"/>
                            <!-- link to authority file -->
                            <xsl:copy-of select="$v_name-marked-up-linked/@ref"/>
                            <xsl:choose>
                                <!-- name with additional mark-up -->
                                <xsl:when test="$p_add-mark-up-to-input = true()">
                                    <xsl:apply-templates select="$v_name-marked-up/node()"/>
                                </xsl:when>
                                <!-- fallback: original content -->
                                <xsl:otherwise>
                                    <xsl:apply-templates select="node()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:copy>
                    </xsl:when>
                    <!-- add mark-up to the input  -->
                    <xsl:when test="$p_add-mark-up-to-input = true()">
                        <xsl:copy-of select="$v_name-marked-up"/>
                        <!-- message to add the missing name to the authority file -->
                        <xsl:message>
                            <xsl:text>Add the following to the authority file: </xsl:text>
                            <xsl:element name="tei:person">
                                <xsl:copy-of select="$v_name-marked-up"/>
                            </xsl:element>
                        </xsl:message>
                    </xsl:when>
                    <!-- fallback replicate original input -->
                    <xsl:otherwise>
                        <xsl:copy>
                            <xsl:apply-templates select="@* | node()"/>
                        </xsl:copy>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- copy from authority file should not include @xml:id and @change -->
   <!-- <xsl:template match="node() | @*" mode="m_copy-from-authority-file">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_copy-from-authority-file"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_copy-from-authority-file" priority="10"/>-->
    
    <!-- document the changes to source file -->
    <xsl:template match="tei:revisionDesc">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:element name="tei:change">
                <xsl:attribute name="when"
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="concat('#', $p_id-editor)"/>
                <xsl:attribute name="xml:id" select="$p_id-change"/>
                <xsl:attribute name="xml:lang" select="'en'"/>
                <xsl:text>Added references to local authority file (</xsl:text>
                <tei:ref target="{$p_url-personography}">
                    <xsl:value-of select="$p_url-personography"/>
                </tei:ref>
                <xsl:text>) and VIAF to </xsl:text>
                <tei:gi>persName</tei:gi>
                <xsl:text>s without such references based on </xsl:text>
                <tei:gi>person</tei:gi>
                <xsl:text>s in the local authority file. If the source </xsl:text>
                <tei:gi>persName</tei:gi>
                <xsl:text> did not contain any further TEI mark-up, this has been added from the local authority file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
  
</xsl:stylesheet>
