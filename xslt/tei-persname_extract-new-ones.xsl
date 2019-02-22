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

    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no" name="xml"
        exclude-result-prefixes="#all"/>
    <!--<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"
        name="xml_indented" exclude-result-prefixes="#all"/>-->

    <xsl:include href="query-viaf.xsl"/>
    
    <!-- p_id-editor references the @xml:id of a responsible editor to be used for documentation of changes -->
    <!-- identify the author of the change by means of a @xml:id -->
    <!--    <xsl:param name="p_id-editor" select="'pers_TG'"/>-->
    <xsl:include href="../../oxygen-project/OpenArabicPE_parameters.xsl"/>

    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master"
        select="'../data/tei/personography_OpenArabicPE.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>

   
    <!-- toggle debugging messages: this is toggled through the parameter file -->
<!--    <xsl:param name="p_verbose" select="false()"/>-->

    <!-- idendity transform -->
    <!-- replicate everything except @xml:id -->
    <xsl:template match="node() | @*" mode="m_no-ids">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_no-ids"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_no-ids"/>
    <xsl:template match="text()" mode="m_no-ids">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <!-- run on root -->
    <xsl:template match="/">
        <xsl:element name="tei:listPerson">
                <xsl:apply-templates select="$v_persons-source/descendant::tei:person" mode="m_extract-new-names"/>
        </xsl:element>
    </xsl:template>

    <!-- variable to collect all persNames found in this file -->
    <!--- this transformation is run on in a list containing tei:person with tei:persName and tei:idno children -->
    <xsl:variable name="v_persons-source">
        <xsl:element name="tei:listPerson">
            <xsl:for-each-group
                select="tei:TEI/tei:text/descendant::tei:persName[not(tei:persName)]" group-by="normalize-space(.)">
                <xsl:sort select="tei:surname[1]"/>
                <xsl:sort select="tei:forename[1]"/>
                <xsl:sort select="current-grouping-key()"/>
                <!-- some variables -->
                <xsl:variable name="v_self">
                    <xsl:value-of select="normalize-space(replace(.,'([إ|أ|آ])','ا'))"/>
                </xsl:variable>
                <xsl:variable name="v_viaf-id"
                    select="replace(tokenize(@ref, ' ')[matches(., 'viaf:\d+')][1], 'viaf:(\d+)', '$1')"/>
                <xsl:variable name="v_name-flat" select="replace($v_self, '\W', '')"/>
                <!-- construct nodes -->
                <xsl:element name="tei:person">
                    <!-- copy the original -->
                    <xsl:copy>
                        <xsl:apply-templates select="@* | node()" mode="m_no-ids"/>
                    </xsl:copy>
                    <!-- construct a flattened string -->
                    <xsl:element name="tei:persName">
                        <xsl:attribute name="type" select="'flattened'"/>
                        <xsl:value-of select="$v_name-flat"/>
                    </xsl:element>
                    <!-- construct name without titles, honorary addresses etc. -->
                    <xsl:if test="child::tei:addName">
                        <xsl:element name="tei:persName">
                            <xsl:attribute name="type" select="'noAddName'"/>
                            <xsl:apply-templates select="child::node()[not(self::tei:addName)]" mode="m_no-ids"/>
                        </xsl:element>
                    </xsl:if>
                    <!-- construct the idno child -->
                    <xsl:if test="./@ref">
                        <!-- <xsl:variable name="v_viaf-id" select="replace(tokenize(@ref,' ')[matches(.,'viaf:\d+')][1],'viaf:(\d+)','$1')"/>-->
                        <xsl:element name="tei:idno">
                            <xsl:attribute name="type" select="'VIAF'"/>
                            <xsl:value-of select="$v_viaf-id"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:element>
    </xsl:variable>

    
    
    <!-- m_particDesc is exclusively run on a tei:person children of a variable that contain tei:persName and tei:idno children.
    This generates only new entries -->
    <xsl:template match="tei:person" mode="m_extract-new-names" name="t_6">
        <xsl:variable name="v_name" select="tei:persName[not(@type='flattened')]"/>
        <xsl:variable name="v_viaf-id" select="tei:idno[@type = 'VIAF']"/>
        <xsl:if test="$p_verbose = true()">
            <xsl:message>
                <xsl:text>t_6: check </xsl:text>
                <xsl:value-of select="$v_name"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="v_name-flat" select="tei:persName[@type = 'flattened']"/>
        <!-- generate new tei:person elements for all names not in the master file -->
        <xsl:choose>
            <!-- test if a name has a @ref attribute pointing to VIAF and an entry for the VIAF ID is already present in the master file -->
            <xsl:when
                test="tei:idno[@type = 'VIAF'] and $v_file-entities-master//tei:person[tei:idno[@type = 'VIAF'] = $v_viaf-id]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_6 #1: VIAF ID </xsl:text><xsl:value-of select="tei:idno[@type='VIAF']"/><xsl:text> is already present in the authority file.</xsl:text>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <!-- test if the text string is present in the master file: it would be necessary to normalise the content of persName in some way -->
            <xsl:when
                test="$v_file-entities-master//tei:person[tei:persName[@type = 'flattened'] = $v_name-flat]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_6 #2: </xsl:text><xsl:value-of select="$v_name-flat"/><xsl:text> is present in authority file.</xsl:text>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <!-- name is not present in the master file and should be copied as is -->
            <xsl:otherwise>
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_6 #3: </xsl:text>
                        <xsl:value-of select="$v_name"/>
                        <xsl:message> was not found in the authority file and added to the output.</xsl:message>
                    </xsl:message>
                </xsl:if>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()" mode="m_no-ids"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
