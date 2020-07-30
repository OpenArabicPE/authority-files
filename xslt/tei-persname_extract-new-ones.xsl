<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" 
    xmlns:bgn="http://bibliograph.net/"
    xmlns:oape="https://openarabicpe.github.io/ns" 
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:genont="http://www.w3.org/2006/gen/ont#"
    xmlns:opf="http://www.idpf.org/2007/opf" xmlns:pto="http://www.productontology.org/id/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:re="http://oclcsrw.google.code/redirect" xmlns:schema="http://schema.org/"
    xmlns:srw="http://www.loc.gov/zing/srw/" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:umbel="http://umbel.org/umbel#" xmlns:viaf="http://viaf.org/viaf/terms#"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    
    <!-- To do:
            - use the same code for constructing nodes missing from the authority file as in tei-person_improve-records.xsl
            - check if this stylesheet really tries to query external authority files as claimed below
    -->
    
    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml" 
        omit-xml-declaration="no"/>
    <!--<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"
        name="xml_indented" exclude-result-prefixes="#all"/>-->
    <xsl:include href="query-viaf.xsl"/>
    
    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master" select="'../data/tei/personography_OpenArabicPE.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>
    <!-- toggle debugging messages: this is toggled through the parameter file -->
    <!--    <xsl:param name="p_verbose" select="false()"/>-->
    
    <!-- idendity transform -->
    <!-- replicate everything except @xml:id -->
    <!--<xsl:template match="node() | @*" mode="m_no-ids">
        <xsl:copy>
            <xsl:apply-templates mode="m_no-ids" select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@xml:id | @change" mode="m_no-ids"/>
    <xsl:template match="text()" mode="m_no-ids">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>-->
    <!-- run on root -->
    <xsl:template match="/">
        <xsl:copy>
        <xsl:element name="tei:listPerson">
<!--            <xsl:copy-of select="$v_persons-source"/>-->
            <xsl:apply-templates mode="m_extract-new-names" select="$v_persons-source/descendant::tei:person"/>
        </xsl:element>
            <!-- document changes -->
            
        </xsl:copy>
    </xsl:template>
    <!-- variable to collect all persNames found in this file -->
    <!--- this transformation is run on in a list containing tei:person with tei:persName and tei:idno children -->
    <xsl:variable name="v_persons-source">
        <xsl:element name="tei:listPerson">
            <xsl:for-each-group group-by="normalize-space(.)"
                select="tei:TEI/tei:text/descendant::tei:persName[not(tei:persName)]">
                <xsl:sort select="tei:surname[1]"/>
                <xsl:sort select="tei:forename[1]"/>
                <xsl:sort select="current-grouping-key()"/>
                <!-- some variables -->
<!--                <xsl:variable name="v_self" select="oape:string-normalise-characters(.)"/>-->
                <xsl:variable name="v_authority">
                    <xsl:choose>
                        <xsl:when test="contains(@ref, 'oape:pers:')">
                            <xsl:text>oape</xsl:text>
                        </xsl:when>
                        <xsl:when test="contains(@ref, 'viaf:')">
                            <xsl:text>VIAF</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="v_idno">
                    <xsl:choose>
                        <xsl:when test="contains(@ref, 'oape:pers:')">
                            <xsl:value-of select="replace(@ref, '.*oape:pers:(\d+).*', '$1')"/>
                        </xsl:when>
                        <xsl:when test="contains(@ref, 'viaf:')">
                            <xsl:value-of select="replace(@ref, '.*viaf:(\d+).*', '$1')"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <!-- does the node in this variable get @xml:id? this is needed to link it to the flattened version -->
                <xsl:variable name="v_name-marked-up" select="oape:name-add-markup(.)"/>
                <!-- construct nodes -->
                <xsl:element name="tei:person">
                    <!-- document source of information -->
                <xsl:attribute name="source" select="base-uri()"/>            
                    <!-- add mark-up to the original -->
                    <xsl:copy-of select="$v_name-marked-up"/>
                    <!-- construct a flattened string -->
                    <xsl:copy-of select="oape:name-flattened($v_name-marked-up, $p_id-change)"/>
                    <!-- construct name without titles, honorary addresses etc. -->
                    <!-- this will currently result in empty nodes -->
                    <!--<xsl:if test="$v_name-marked-up/tei:addName or $v_name-marked-up/tei:roleName">
                        <xsl:copy-of select="oape:name-remove-addnames($v_name-marked-up, $p_id-change)"/>
                    </xsl:if>-->
                    <!-- construct the idno child -->
                    <xsl:if test="./@ref">
                        <xsl:element name="tei:idno">
                            <xsl:attribute name="type" select="$v_authority"/>
                            <xsl:value-of select="$v_idno"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:element>
    </xsl:variable>
    <!-- m_particDesc is exclusively run on a tei:person children of a variable that contain tei:persName and tei:idno children.
    This generates only new entries -->
    <xsl:template match="tei:person" mode="m_extract-new-names" name="t_6">
        <xsl:variable name="v_name" select="tei:persName[not(@type = 'flattened')]"/>
        <xsl:variable name="v_viaf-id" select="tei:idno[@type = 'VIAF']"/>
        <xsl:variable name="v_oape-id" select="tei:idno[@type = 'oape']"/>
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
                        <xsl:text>t_6 #1: VIAF ID </xsl:text>
                        <xsl:value-of select="$v_viaf-id"/>
                        <xsl:text> is already present in the authority file.</xsl:text>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <!-- test if a name has a @ref attribute pointing to our own authority files and an entry for the OAPE ID is already present in the master file -->
            <xsl:when
                test="tei:idno[@type = 'oape'] and $v_file-entities-master//tei:person[tei:idno[@type = 'oape'] = $v_oape-id]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_6 #1: OAPE ID </xsl:text>
                        <xsl:value-of select="$v_oape-id"/>
                        <xsl:text> is already present in the authority file.</xsl:text>
                    </xsl:message>
                </xsl:if>
            </xsl:when>
            <!-- test if the text string is present in the master file -->
            <xsl:when
                test="$v_file-entities-master//tei:person[tei:persName[@type = 'flattened'] = $v_name-flat]">
                <xsl:if test="$p_verbose = true()">
                    <xsl:message>
                        <xsl:text>t_6 #2: </xsl:text>
                        <xsl:value-of select="$v_name-flat"/>
                        <xsl:text> is already present in the authority file.</xsl:text>
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
                    <xsl:apply-templates select="@* | node()" mode="m_identity-transform"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
