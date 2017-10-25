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
    
    <!-- this stylesheet  tries to query external authority files if they are linked through the @ref attribute -->
    
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes" name="xml_indented" exclude-result-prefixes="#all"/>
    
    <!-- the file path is relative to this stylesheet!  -->
    <xsl:param name="p_viaf-file-path" select="'../viaf/'"/>
    <!-- these variables are used to establish the language of any given string -->
    <xsl:variable name="v_string-transcribe-ijmes" select="'btḥḫjdrzsṣḍṭẓʿfqklmnhāūīwy0123456789'"/>
    <xsl:variable name="v_string-transcribe-arabic" select="'بتحخجدرزسصضطظعفقكلمنهاويوي٠١٢٣٤٥٦٧٨٩'"/>
    
  
    <!-- query VIAF and return RDF -->
    <xsl:template name="t_query-viaf-rdf">
        <xsl:param name="p_viaf-id"/>
        <!-- available values are 'tei' and 'file' -->
        <xsl:param name="p_output-mode" select="'tei'"/>
        <xsl:variable name="v_viaf-rdf" select="doc(concat('https://viaf.org/viaf/',$p_viaf-id,'/rdf.xml'))"/>
        <xsl:choose>
            <xsl:when test="$p_output-mode = 'tei'">
                <!-- add VIAF ID -->
                <xsl:element name="tei:idno">
                    <xsl:attribute name="type" select="'viaf'"/>
                    <xsl:value-of select="$p_viaf-id"/>
                </xsl:element>
                <!-- add birth and death dates -->
                <xsl:apply-templates select="$v_viaf-rdf//rdf:RDF/rdf:Description/schema:birthDate"/>
                <xsl:apply-templates select="$v_viaf-rdf//rdf:RDF/rdf:Description/schema:deathDate"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'file'">
                <xsl:result-document href="../viaf/viaf_{$p_viaf-id}.rdf" format="xml_indented">
                    <xsl:copy-of select="$v_viaf-rdf"/>
                </xsl:result-document>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- query VIAF using SRU -->
    <xsl:template name="t_query-viaf-sru">
        <xsl:param name="p_search-term"/>
        <!-- available values are 'id' and 'persName' -->
        <xsl:param name="p_input-type"/>
        <xsl:param name="p_records-max" select="5"/>
        <!-- available values are 'tei' and 'file' -->
        <xsl:param name="p_output-mode" select="'tei'"/>
        <xsl:param name="p_include-bibliograpy-in-output" select="false()"/>
        <xsl:variable name="v_viaf-srw">
            <xsl:choose>
                <!-- check if a local copy of the VIAF result is present  -->
                <xsl:when test="$p_input-type='id' and doc-available(concat($p_viaf-file-path,'viaf_',$p_search-term,'.SRW.xml'))">
                    <xsl:copy-of select="doc(concat($p_viaf-file-path,'viaf_',$p_search-term,'.SRW.xml'))"/>
                </xsl:when>
                <!-- query VIAF for ID -->
                <xsl:when test="$p_input-type='id'">
                    <xsl:copy-of select="doc(concat('https://viaf.org/viaf/search?query=local.viafID+any+&quot;',$p_search-term,'&quot;&amp;httpAccept=application/xml'))"/>
                </xsl:when>
                <!-- query VIAF for personal name -->
                <xsl:when test="$p_input-type='persName'">
                    <!-- note that, depending on the sort order, we are not necessarily looking for the first entry -->
                    <xsl:copy-of select="doc(concat('https://viaf.org/viaf/search?query=local.personalNames+any+&quot;',$p_search-term,'&quot;','&amp;sortKeys=name&amp;maximumRecords=',$p_records-max,'&amp;httpAccept=application/xml'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="doc(concat('https://viaf.org/viaf/search?query=cql.any+all+',$p_search-term,'&amp;sortKeys=name&amp;maximumRecords=',$p_records-max,'&amp;httpAccept=application/xml'))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- note that, depending on the sort order, we are not necessarily looking for the first entry -->
        <xsl:variable name="v_record-1">
            <xsl:choose>
                <xsl:when test="$p_input-type='id'">
                    <xsl:copy-of select="$v_viaf-srw/descendant-or-self::srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster[.//viaf:viafID=$p_search-term]"/>
                </xsl:when>
                <xsl:when test="$p_input-type='persName'">
                    <xsl:choose>
                        <xsl:when test="count($v_viaf-srw/descendant-or-self::srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster) = 1">
                            <xsl:copy-of select="$v_viaf-srw/descendant-or-self::srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="$v_viaf-srw/descendant-or-self::srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster[.//viaf:datafield[@dtype='MARC21']/viaf:subfield[@code='a'][contains(.,normalize-space($p_search-term))]]"/>
                            <!-- <xsl:copy-of select="$v_viaf-srw/descendant-or-self::srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type='ns1:stringOrXmlFragment']/viaf:VIAFCluster[ contains(.//viaf:datafield[@dtype='MARC21']/viaf:subfield[@code='a'][replace(.,'\W','')],replace($p_search-term,'\W',''))]"/>-->
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_viaf-id" select="$v_record-1//viaf:viafID"/>
        <!-- add alternative names: 
                    the VIAF files contain many duplicates of name records that need to be unified -->
        <xsl:variable name="v_alternative-names">
            <xsl:for-each-group select="$v_record-1//viaf:datafield[@dtype='MARC21'][@tag='400']/viaf:subfield[@code='a']" group-by="replace(.,'\W','')">
                <xsl:apply-templates select="."/>    
            </xsl:for-each-group>
        </xsl:variable>
        <!-- add VIAF ID -->
        <xsl:choose>
            <xsl:when test="$p_output-mode = 'tei'">
                <!-- add alternative names -->
<!--                <xsl:copy-of select="$v_alternative-names"/>-->
                <!-- add VIAF ID -->
                <xsl:apply-templates select="$v_record-1//viaf:viafID"/>
                <!-- add birth and death dates -->
                <xsl:apply-templates select="$v_record-1//viaf:birthDate"/>
                <xsl:apply-templates select="$v_record-1//viaf:deathDate"/>
                <!-- add works -->
                <xsl:if test="$p_include-bibliograpy-in-output=true()">
                    <xsl:apply-templates select="$v_record-1//viaf:titles"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'file'">
                <xsl:choose>
                    <xsl:when test="$v_viaf-id!=''">
                        <xsl:result-document href="../viaf/viaf_{$v_viaf-id}.SRW.xml" format="xml_indented">
                            <xsl:copy-of select="$v_viaf-srw"/>
                        </xsl:result-document>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message><xsl:text>No result for: </xsl:text><xsl:value-of select="normalize-space($p_search-term)"/></xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- transform VIAF results to TEI -->
    <xsl:template match="schema:birthDate | viaf:birthDate">
        <xsl:element name="tei:birth">
            <xsl:attribute name="resp" select="'viaf'"/>
            <xsl:call-template name="t_dates-normalise">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="schema:deathDate | viaf:deathDate">
        <xsl:element name="tei:death">
            <xsl:attribute name="resp" select="'viaf'"/>
            <xsl:call-template name="t_dates-normalise">
                <xsl:with-param name="p_input" select="."/>
            </xsl:call-template>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="viaf:viafID">
        <xsl:element name="tei:idno">
            <xsl:attribute name="type" select="'viaf'"/>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    
    <!-- additional personal names -->
    <xsl:template match="viaf:subfield[@code='a']">
        <!-- check if the name is in Arabic script -->
        <xsl:if test="contains($v_string-transcribe-arabic,replace(.,'.*(\w).+','$1'))">
            <xsl:element name="tei:persName">
                <xsl:attribute name="xml:lang" select="'ar'"/>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <!-- transform viaf works to TEI bibls -->
    <xsl:template match="viaf:titles">
        <xsl:element name="tei:listBibl">
            <xsl:attribute name="resp" select="'viaf'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="viaf:work">
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
            <xsl:apply-templates select="descendant::viaf:title"/>
            <!-- identifiers -->
            <xsl:apply-templates select="@id"/>
            <xsl:apply-templates select="descendant::viaf:sid"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="viaf:work/@id">
        <xsl:variable name="v_authority" select="lower-case(tokenize(.,'\|')[1])"/>
        <xsl:variable name="v_id" select="tokenize(.,'\|')[2]"/>
        <xsl:element name="tei:idno">
            <xsl:attribute name="type" select="$v_authority"/>
            <xsl:value-of select="$v_id"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="viaf:title">
        <xsl:element name="tei:title">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="viaf:sources/viaf:sid">
        <xsl:variable name="v_authority" select="lower-case(tokenize(.,'\|')[1])"/>
        <xsl:variable name="v_id" select="tokenize(.,'\|')[2]"/>
        <xsl:element name="tei:idno">
            <xsl:attribute name="type" select="$v_authority"/>
            <xsl:value-of select="$v_id"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="t_dates-normalise">
        <!-- the dates returned by VIAF can be formatted as
            - yyyy-mm-dd: no issue
            - yyy-mm-dd: the year needs an additional leading 0
            - yyyy-mm-00: this indicates a date range of a full month
        -->
        <!-- output are ATTRIBUTES! -->
        <xsl:param name="p_input"/>
        <xsl:analyze-string select="$p_input" regex="(\d{{4}})$|(\d{{3,4}})-(\d{{2}})-(\d{{2}})$">
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
                            <xsl:attribute name="when" select="regex-group(1)"/>
                        </xsl:when>
                    </xsl:choose>
<!--                    <xsl:value-of select="$p_input"/>-->
                <!--</xsl:element>-->
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    
</xsl:stylesheet>