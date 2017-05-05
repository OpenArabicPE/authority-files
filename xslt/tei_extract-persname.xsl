<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
     version="2.0">
    
    <!-- this stylesheet extracts all <persName> elements from a TEI XML file and groups them into a <listPerson> element. Similarly, it extracts all <placeName> elements and creates a <listPlace> with the toponyms nested as child elements -->
    <!-- this stylesheet also tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="no"/>
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes" name="xml_indented"/>
    
    <xsl:include href="query-viaf.xsl"/>
    
    <!-- v_file-entities-master: relative paths relate to this stylesheet and NOT the file this transformation is run on; default: '../tei/entities_master.TEIP5.xml' -->
    <xsl:param name="p_url-master" select="'../tei/entities_master.TEIP5.xml'"/>
    <xsl:variable name="v_file-entities-master" select="doc($p_url-master)"/>
    
    <!-- parameter to select whether the master file should be updated  -->
    <xsl:param name="p_update-master" select="true()"/>
    <!-- parameter to select whether the source file should be updated  -->
    <xsl:param name="p_update-source" select="true()"/>
    <!-- toggle debugging messages -->
    <xsl:param name="p_verbose" select="false()"/>
    
    <!-- p_id-editor references the @xml:id of a responsible editor to be used for documentation of changes -->
    <xsl:param name="p_id-editor" select="'pers_TG'"/>
    
    <xsl:variable name="v_id-file" select="if(tei:TEI/@xml:id) then(tei:TEI/@xml:id) else('_output')"/>
    <xsl:variable name="v_url-file" select="concat('../../',substring-after(base-uri(),'OpenArabicPE/'))"/>
    
    
    <!-- This template replicates attributes as they are found in the source -->
    <xsl:template match="node() | @* " mode="m_replicate">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="node() | @* " mode="m_mark-up-source">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" mode="m_mark-up-source"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/">
        <xsl:if test="$p_update-source = true()">
            <xsl:copy>
                <xsl:apply-templates mode="m_mark-up-source"/>
            </xsl:copy>
        </xsl:if>
        <xsl:if test="$p_update-master = true()">
            <xsl:result-document href="../tei/{$v_id-file}/entities_master.TEIP5.xml" format="xml_indented">
                <xsl:apply-templates select="$v_file-entities-master" mode="m_replicate"/>
            </xsl:result-document>
        </xsl:if>
    </xsl:template>
    
    <!-- variable to collect all persNames in a list containing tei:person with tei:persName and tei:idno children -->
    <xsl:variable name="v_persons-source">
        <xsl:element name="tei:list">
            <xsl:for-each-group select="tei:TEI/tei:text/descendant::tei:persName[not(tei:persName)]" group-by=".">
                <xsl:sort select="tei:surname[1]"/>
                <xsl:sort select="tei:forename[1]"/>
                <xsl:sort select="current-grouping-key()"/>
                <!-- some variables -->
                <xsl:variable name="v_self">
                    <xsl:value-of select="normalize-space(.)"/>
                </xsl:variable>
                <xsl:variable name="v_viaf-id" select="replace(tokenize(@ref,' ')[matches(.,'viaf:\d+')][1],'viaf:(\d+)','$1')"/>
                <xsl:variable name="v_name-flat" select="replace($v_self,'\W','')"/>
                <!-- construct nodes -->
                <xsl:element name="tei:person">
                    <xsl:copy-of select="."/>
                    <!-- construct a flattened string -->
                    <xsl:element name="tei:persName">
                        <xsl:attribute name="type" select="'flattened'"/>
                        <xsl:value-of select="$v_name-flat"/>
                    </xsl:element>
                    <!-- construct the idno child -->
                    <xsl:if test="./@ref">
                       <!-- <xsl:variable name="v_viaf-id" select="replace(tokenize(@ref,' ')[matches(.,'viaf:\d+')][1],'viaf:(\d+)','$1')"/>-->
                        <xsl:element name="tei:idno">
                            <xsl:attribute name="type" select="'viaf'"/>
                            <xsl:value-of select="$v_viaf-id"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:element>
    </xsl:variable>
    
    <!-- mode m_mark-up-source will at some point provide automatic addition of information from $v_file-entities-master to a TEI file  -->
    <xsl:template match="tei:persName" mode="m_mark-up-source">
        <xsl:variable name="v_self">
            <xsl:value-of select="normalize-space(.)"/>
        </xsl:variable>
        <xsl:variable name="v_viaf-id" select="replace(tokenize(@ref,' ')[matches(.,'viaf:\d+')][1],'viaf:(\d+)','$1')"/>
        <xsl:variable name="v_name-flat" select="replace($v_self,'\W','')"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="m_replicate"/>
            <!-- check if a reference to VIAF can be provided based on the master file -->
            <xsl:choose>
                <!-- test if a name has a @ref attribute pointing to VIAF and an entry for the VIAF ID is already present in the master file -->
                <xsl:when test="$v_viaf-id and $v_file-entities-master//tei:person[tei:idno[@type='viaf']=$v_viaf-id]">
                     <xsl:message><xsl:text>source #1: VIAF ID for </xsl:text><xsl:value-of select="$v_self"/><xsl:text> is present in master file</xsl:text></xsl:message>
                </xsl:when>
                <!-- test if the text string is present in the master file -->
                <xsl:when test="$v_file-entities-master//tei:person[tei:idno[@type='viaf']][tei:persName[@type='flattened']=$v_name-flat]">
                    <xsl:message><xsl:text>source #2:</xsl:text><xsl:value-of select="$v_self"/><xsl:text> is present in master file but has no VIAF ID and was updated</xsl:text></xsl:message>
                    <xsl:attribute name="ref" select="concat('viaf:',$v_file-entities-master//tei:person[tei:persName[@type='flattened']=$v_name-flat]/tei:idno[@type='viaf'])"/>
                </xsl:when>
                <!-- test if a name has a @ref attribute pointing to VIAF  -->
                <xsl:when test="$v_viaf-id">
                    <xsl:message><xsl:text>source #3:</xsl:text><xsl:value-of select="$v_self"/><xsl:text> has a VIAF ID but is not present in master file</xsl:text></xsl:message>
                </xsl:when>
                <!-- name has no reference to VIAF and is not present in the master file -->
                <xsl:otherwise/>
            </xsl:choose>
            <xsl:apply-templates mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- ammend master file with entities found in the current TEI file -->
    <xsl:template match="tei:particDesc" mode="m_replicate">
        <xsl:copy>
            <xsl:apply-templates select="@* |node()" mode="m_replicate"/>
            <!-- build a listPerson with persons present in the source file but missing from the master -->
            <xsl:element name="tei:listPerson">
                <xsl:attribute name="corresp" select="$v_url-file"/>
                <xsl:apply-templates select="$v_persons-source/descendant-or-self::tei:person" mode="m_particDesc"/>
            </xsl:element>
        </xsl:copy>
    </xsl:template>
    <!-- m_particDesc is exclusively run on a tei:person children of a variable that contain tei:persName and tei:idno children.
    This generates only new entries -->
    <xsl:template match="tei:person" mode="m_particDesc">
        <xsl:variable name="v_name-flat" select="tei:persName[@type='flattened']"/>
        <!-- generate new tei:person elements for all names not in the master file -->
        <xsl:choose>
            <!-- test if a name has a @ref attribute pointing to VIAF and an entry for the VIAF ID is already present in the master file -->
            <xsl:when test="tei:idno[@type='viaf'] and $v_file-entities-master//tei:person[tei:idno[@type='viaf']=tei:idno[@type='viaf']]"/>
            <!-- test if the text string is present in the master file: it would be necessary to normalise the content of persName in some way -->
            <xsl:when test="$v_file-entities-master//tei:person[tei:persName[@type='flattened']=$v_name-flat]"/>
            <!-- name is not present in the master file and should be copied as is -->
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- existing tei:person in the master file should updated with new information if available -->
    <xsl:template match="tei:person" mode="m_replicate">
        <xsl:variable name="v_name-flat" select="tei:persName[@type='flattened']"/>
        <xsl:copy>
            <!-- update or  replicate tei:person elements in the master file -->
            <xsl:choose>
                <!-- test if a person has no VIAF ID and if a person with the same name is present in $v_persons-source with VIAF ID -->
                <xsl:when test="not(tei:idno[@type='viaf']) and $v_persons-source/descendant-or-self::tei:person[tei:persName[@type='flattened']=$v_name-flat][tei:idno[@type='viaf']]">
                    <xsl:message><xsl:text>master #1: VIAF ID was added from source to </xsl:text><xsl:value-of select="tei:persName[not(@type='flattened')][1]"/></xsl:message>
                    <xsl:apply-templates select="@* |node()" mode="m_replicate"/>
                    <!-- add idno -->
                    <xsl:copy-of select="$v_persons-source/descendant-or-self::tei:person[tei:persName[@type='flattened']=$v_name-flat]/tei:idno[@type='viaf']"/>
                </xsl:when>
                <!-- potentially test if there is an additional spelling in $v_persons-source not precent in the entity master -->
                <xsl:otherwise>
                    <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    <!--<xsl:template match="tei:persName/text() | tei:surname/text() | tei:forename/text() | tei:addName/text()" mode="m_replicate">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>-->
    <!-- omit xml:id from output -->
    <xsl:template match="tei:list//tei:persName/@xml:id | tei:list//tei:surname/@xml:id | tei:list//tei:forename/@xml:id | tei:list//tei:addName/@xml:id " mode="m_replicate"/>
    <xsl:template match="tei:persName//tei:pb | tei:persName//tei:lb | tei:persName//tei:note" mode="m_replicate">
        <xsl:text> </xsl:text>
    </xsl:template>
    
    <!-- document the changes to master file -->
    <xsl:template match="tei:revisionDesc" mode="m_replicate">
        <xsl:copy>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="$p_id-editor"/>
                <xsl:text>Added </xsl:text><tei:gi>listPerson</tei:gi><xsl:text> with </xsl:text><tei:gi>person</tei:gi><xsl:text>s mentioned in </xsl:text><tei:ref target="{$v_url-file}"><xsl:value-of select="$v_url-file"/></tei:ref><xsl:text> but not previously present in this master file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
    <!-- document the changes to source file -->
    <xsl:template match="tei:revisionDesc" mode="m_mark-up-source">
        <xsl:copy>
            <xsl:element name="tei:change">
                <xsl:attribute name="when" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>
                <xsl:attribute name="who" select="$p_id-editor"/>
                <xsl:text>Added references to VIAF IDs to </xsl:text><tei:gi>persName</tei:gi><xsl:text>s without such references based on  </xsl:text><tei:gi>person</tei:gi><xsl:text>s mentioned in </xsl:text><tei:ref target="{$p_url-master}"><xsl:value-of select="$p_url-master"/></tei:ref><xsl:text> but not previously present in this master file.</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="@* | node()" mode="m_replicate"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>