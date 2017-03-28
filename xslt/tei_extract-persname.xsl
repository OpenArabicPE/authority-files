<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
     version="2.0">
    
    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    
    <xsl:include href="query-viaf.xsl"/>
    
    <!-- p_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on -->
    <xsl:param name="p_file-entities-master" select="doc('../tei/entities_master.TEIP5.xml')"/>
    
    <!-- p_id-editor references the @xml:id of a responsible editor to be used for documentation of changes -->
    <xsl:param name="p_id-editor" select="'pers_TG'"/>
    
    <xsl:variable name="v_id-file" select="tei:TEI/@xml:id"/>
    <xsl:variable name="v_url-file" select="base-uri()"/>
    
    
    <!-- This template replicates attributes as they are found in the source -->
    <xsl:template match="@* | node()" mode="m_replicate">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/">
        <xsl:copy>
            <!--<xsl:apply-templates select="$v_persName-all/descendant-or-self::tei:persName" mode="m_mark-up"/>-->
        </xsl:copy>
        <xsl:result-document href="../tei/{$v_id-file}/entities_master.TEIP5.xml">
            <xsl:apply-templates select="$p_file-entities-master" mode="m_replicate"/>
        </xsl:result-document>
    </xsl:template>
    
    <!-- variable to collect all persNames -->
    <xsl:variable name="v_persName-all">
        <xsl:element name="tei:list">
            <xsl:for-each-group select="tei:TEI/tei:text/descendant::tei:persName" group-by=".">
                <xsl:copy-of select="."/>
            </xsl:for-each-group>
        </xsl:element>
    </xsl:variable>
    
    <!-- mode m_mark-up-source will at some point provide automatic addition of information from $p_file-entities-master to a TEI file  -->
    <xsl:template match="tei:persName" mode="m_mark-up-source">
        <xsl:variable name="v_self" select="."/>
        <xsl:variable name="v_viaf-id" select="replace(tokenize(@ref,' ')[matches(.,'viaf:\d+')][1],'viaf:(\d+)','$1')"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_replicate"/>
            <xsl:choose>
                <!-- test if a name has a @ref attribute pointing to VIAF and an entry for the VIAF ID is already present in the master file -->
                <xsl:when test="$v_viaf-id and $p_file-entities-master//tei:person[tei:idno[@type='viaf']=$v_viaf-id]">
                    <!-- <xsl:message><xsl:value-of select="$v_self"/><xsl:text> is present in master file</xsl:text></xsl:message>-->
                </xsl:when>
                <!-- test if the text string is present in the master file -->
                <xsl:when test="$p_file-entities-master//tei:person[tei:persName/text()=$v_self/text()]">
                    <xsl:message><xsl:value-of select="$v_self"/><xsl:text> is present in master file but has no VIAF ID</xsl:text></xsl:message>
                    <xsl:attribute name="ref" select="concat('viaf:',$p_file-entities-master//tei:person[tei:persName/text()=$v_self/text()][1]/tei:idno[@type='viaf'])"/>
                </xsl:when>
                <!-- test if a name has a @ref attribute pointing to VIAF  -->
                <xsl:when test="$v_viaf-id">
                    <xsl:message><xsl:value-of select="$v_self"/><xsl:text> has a VIAF ID but is not present in master file</xsl:text></xsl:message>
                </xsl:when>
                <!-- name has no reference to VIAF and is not present in the master file -->
                <xsl:otherwise>
                    
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- ammend master file with entities found in the current TEI file -->
    <xsl:template match="tei:particDesc/tei:listPerson" mode="m_replicate">
        <xsl:copy>
            <xsl:apply-templates select="@* |node()" mode="m_replicate"/>
        </xsl:copy>
        <xsl:element name="tei:listPerson">
<!--            <xsl:attribute name="xml:id" select="concat('listPerson_',$v_id-file)"/>-->
            <xsl:attribute name="corresp" select="$v_url-file"/>
            <!-- add missing persons -->
            <xsl:apply-templates select="$v_persName-all/descendant-or-self::tei:persName" mode="m_particDesc"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:persName" mode="m_particDesc">
        <xsl:variable name="v_self" select="."/>
        <xsl:variable name="v_viaf-id" select="replace(tokenize(@ref,' ')[matches(.,'viaf:\d+')][1],'viaf:(\d+)','$1')"/>
        <!-- generate new tei:person elements for all names not in the master file -->
                <xsl:choose>
                    <!-- test if a name has a @ref attribute pointing to VIAF and an entry for the VIAF ID is already present in the master file -->
                    <xsl:when test="$v_viaf-id and $p_file-entities-master//tei:person[tei:idno[@type='viaf']=$v_viaf-id]"/>
                    <!-- test if the text string is present in the master file: it would be necessary to normalise the content of persName in some way -->
                    <xsl:when test="$p_file-entities-master//tei:person[tei:persName/text()=$v_self/text()]"/>
                    <!-- name is not present in the master file -->
                    <xsl:otherwise>
                        <xsl:element name="tei:person">
                            <xsl:element name="tei:persName">
                                <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:persName/text() | tei:surname/text() | tei:forename/text() | tei:addName/text()" mode="m_replicate">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    
    
    
</xsl:stylesheet>