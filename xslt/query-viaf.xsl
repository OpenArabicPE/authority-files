<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns:bgn="http://bibliograph.net/"
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
    <!-- this stylesheet  tries to query external authority files if they are linked through the @ref attribute -->
    <xsl:output encoding="UTF-8" exclude-result-prefixes="#all" indent="no" method="xml"
        name="xml_indented" omit-xml-declaration="no"/>
    <xsl:include href="convert_viaf-to-tei_functions.xsl"/>
    <xsl:include href="functions.xsl"/>
    
    <!-- the file path is relative to this stylesheet!  -->
    <xsl:param name="p_viaf-file-path" select="'../data/viaf/'"/>
    
    <!-- query VIAF and return RDF -->
    <xsl:template name="t_query-viaf-rdf">
        <xsl:param name="p_viaf-id"/>
        <!-- available values are 'tei' and 'file' -->
        <xsl:param name="p_output-mode" select="'tei'"/>
        <xsl:variable name="v_viaf-rdf"
            select="doc(concat('https://viaf.org/viaf/', $p_viaf-id, '/rdf.xml'))"/>
        <xsl:choose>
            <xsl:when test="$p_output-mode = 'tei'">
                <!-- add VIAF ID -->
                <xsl:element name="tei:idno">
                    <xsl:attribute name="type" select="'viaf'"/>
                    <xsl:value-of select="$p_viaf-id"/>
                </xsl:element>
                <!-- add birth and death dates -->
                <xsl:apply-templates mode="m_viaf-to-tei"
                    select="$v_viaf-rdf//rdf:RDF/rdf:Description/schema:birthDate"/>
                <xsl:apply-templates mode="m_viaf-to-tei"
                    select="$v_viaf-rdf//rdf:RDF/rdf:Description/schema:deathDate"/>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'file'">
                <xsl:result-document format="xml_indented" href="../viaf/viaf_{$p_viaf-id}.rdf">
                    <xsl:copy-of select="$v_viaf-rdf"/>
                </xsl:result-document>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- query VIAF using SRU -->
    <!-- output can be either a SRU file or a <tei:person> node -->
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
                <xsl:when
                    test="$p_input-type = 'id' and doc-available(concat($p_viaf-file-path, 'viaf_', $p_search-term, '.SRW.xml'))">
                    <xsl:copy-of
                        select="doc(concat($p_viaf-file-path, 'viaf_', $p_search-term, '.SRW.xml'))"
                    />
                </xsl:when>
                <!-- else query VIAF for ID -->
                <xsl:when test="$p_input-type = 'id' and matches($p_search-term,'^\d+$')">
                    <xsl:copy-of
                        select="doc(concat('https://viaf.org/viaf/search?query=local.viafID+any+&quot;',$p_search-term,'&quot;&amp;httpAccept=application/xml'))"
                    />
                </xsl:when>
                <!-- query VIAF for personal name -->
                <xsl:when test="$p_input-type = 'persName'">
                    <!-- note that, depending on the sort order, we are not necessarily looking for the first entry -->
                    <xsl:copy-of
                        select="doc(concat('https://viaf.org/viaf/search?query=local.personalNames+any+&quot;',$p_search-term,'&quot;','&amp;sortKeys=name&amp;maximumRecords=',$p_records-max,'&amp;httpAccept=application/xml'))"
                    />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of
                        select="doc(concat('https://viaf.org/viaf/search?query=cql.any+all+',$p_search-term,'&amp;sortKeys=name&amp;maximumRecords=',$p_records-max,'&amp;httpAccept=application/xml'))"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- note that, depending on the sort order, we are not necessarily looking for the first entry -->
        <xsl:variable name="v_record-1">
            <xsl:choose>
                <xsl:when test="$p_input-type = 'id'">
                    <xsl:copy-of
                        select="$v_viaf-srw/descendant-or-self::srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type = 'ns1:stringOrXmlFragment']/viaf:VIAFCluster"
                    />
                </xsl:when>
                <xsl:when test="$p_input-type = 'persName'">
                    <xsl:choose>
                        <xsl:when
                            test="count($v_viaf-srw/descendant-or-self::srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type = 'ns1:stringOrXmlFragment']/viaf:VIAFCluster) = 1">
                            <xsl:copy-of
                                select="$v_viaf-srw/descendant-or-self::srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type = 'ns1:stringOrXmlFragment']/viaf:VIAFCluster"
                            />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of
                                select="$v_viaf-srw/descendant-or-self::srw:searchRetrieveResponse/srw:records/srw:record/srw:recordData[@xsi:type = 'ns1:stringOrXmlFragment']/viaf:VIAFCluster[.//viaf:datafield[@dtype = 'MARC21']/viaf:subfield[@code = 'a'][contains(., normalize-space($p_search-term))]]"/>
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
            <xsl:for-each-group group-by="replace(., '\W', '')"
                select="$v_record-1//viaf:datafield[@dtype = 'MARC21'][@tag = '400']/viaf:subfield[@code = 'a']">
                <xsl:apply-templates select="."/>
            </xsl:for-each-group>
        </xsl:variable>
        <!-- add VIAF ID -->
        <xsl:choose>
            <xsl:when test="$p_output-mode = 'tei'">
                <tei:person>
                    <!-- add alternative names -->
                    <xsl:copy-of select="$v_alternative-names"/>
                    <!-- add VIAF ID -->
                    <xsl:apply-templates mode="m_viaf-to-tei" select="$v_record-1//viaf:viafID"/>
                    <!-- add other IDs -->
                    <xsl:if test="$p_verbose = true()">
                        <xsl:message>Try to parse other IDs</xsl:message>
                    </xsl:if>
                    <xsl:apply-templates mode="m_viaf-to-tei" select="$v_record-1/descendant::viaf:mainHeadings/viaf:data/viaf:sources/viaf:sid"/>
                    <!-- add birth and death dates -->
                    <xsl:apply-templates mode="m_viaf-to-tei" select="$v_record-1//viaf:birthDate"/>
                    <xsl:apply-templates mode="m_viaf-to-tei" select="$v_record-1//viaf:deathDate"/>
                    <!-- add works -->
                    <xsl:if test="$p_include-bibliograpy-in-output = true()">
                        <xsl:apply-templates mode="m_viaf-to-tei" select="$v_record-1//viaf:titles"
                        />
                    </xsl:if>
                </tei:person>
            </xsl:when>
            <xsl:when test="$p_output-mode = 'file'">
                <xsl:choose>
                    <xsl:when test="$v_viaf-id != ''">
                        <xsl:result-document format="xml_indented"
                            href="../viaf/viaf_{$v_viaf-id}.SRW.xml">
                            <xsl:copy-of select="$v_viaf-srw"/>
                        </xsl:result-document>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:text>No result for: </xsl:text>
                            <xsl:value-of select="normalize-space($p_search-term)"/>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
