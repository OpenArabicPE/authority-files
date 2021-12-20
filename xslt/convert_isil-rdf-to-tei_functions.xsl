<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xmlns:agrelon="https://d-nb.info/standards/elementset/agrelon#"
    xmlns:bflc="http://id.loc.gov/ontologies/bflc/" xmlns:bibo="http://purl.org/ontology/bibo/" xmlns:dbp="http://dbpedia.org/property/" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dnb_intern="http://dnb.de/" xmlns:dnbt="https://d-nb.info/standards/elementset/dnb#"
    xmlns:ebu="http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#" xmlns:editeur="https://ns.editeur.org/thema/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:gbv="http://purl.org/ontology/gbv/"
    xmlns:geo="http://www.opengis.net/ont/geosparql#" xmlns:gndo="https://d-nb.info/standards/elementset/gnd#" xmlns:isbd="http://iflastandards.info/ns/isbd/elements/"
    xmlns:lib="http://purl.org/library/" xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#" xmlns:marcRole="http://id.loc.gov/vocabulary/relators/" xmlns:mo="http://purl.org/ontology/mo/"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdau="http://rdaregistry.info/Elements/u/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:schema="http://schema.org/" xmlns:sf="http://www.opengis.net/ont/sf#" xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:umbel="http://umbel.org/umbel#" xmlns:v="http://www.w3.org/2006/vcard/ns#" xmlns:vivo="http://vivoweb.org/ontology/core#"
    xmlns:wdrs="http://www.w3.org/2007/05/powder-s#" xmlns:xd="http://www.pnp-software.com/XSLTdoc" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>
    <xsl:template match="/">
        <xsl:apply-templates mode="m_isil-to-tei"/>
    </xsl:template>
    <xsl:template match="rdf:Description[matches(@rdf:about, 'https://ld.zdb-services.de/resource/organisations/')]" mode="m_isil-to-tei">
        <xsl:element name="org">
            <xsl:attribute name="source" select="@rdf:about"/>
            <xsl:apply-templates mode="m_isil-to-tei" select="dbp:shortName"/>
            <xsl:apply-templates mode="m_isil-to-tei" select="foaf:name"/>
            <xsl:apply-templates mode="m_isil-to-tei" select="dc:identifier"/>
            <xsl:element name="location">
                <xsl:apply-templates mode="m_isil-to-tei" select="geo:location"/>
                <xsl:apply-templates mode="m_isil-to-tei" select="v:adr"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="dbp:shortName" mode="m_isil-to-tei">
        <xsl:element name="orgName">
            <xsl:attribute name="type" select="'short'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="foaf:name" mode="m_isil-to-tei">
        <xsl:element name="orgName">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="geo:location" mode="m_isil-to-tei">
        <xsl:element name="geo">
            <xsl:value-of select="rdf:Description/geo:lat"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="rdf:Description/geo:long"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="dc:identifier" mode="m_isil-to-tei">
        <xsl:analyze-string regex="^\((\w+)\)(.+)$" select=".">
            <xsl:matching-substring>
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="regex-group(1)"/>
                    <xsl:value-of select="regex-group(2)"/>
                </xsl:element>
                <xsl:element name="idno">
                    <xsl:attribute name="type" select="'url'"/>
                    <xsl:value-of select="concat('http://ld.zdb-services.de/data/organisations/', regex-group(2))"/>
                </xsl:element>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    <xsl:template match="v:adr" mode="m_isil-to-tei">
        <xsl:element name="address">
            <xsl:apply-templates mode="m_isil-to-tei" select="rdf:Description/v:street-address"/>
            <xsl:apply-templates mode="m_isil-to-tei" select="rdf:Description/v:postal-code"/>
            <xsl:apply-templates mode="m_isil-to-tei" select="rdf:Description/v:locality"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="v:street-address" mode="m_isil-to-tei">
        <xsl:element name="street">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="v:locality" mode="m_isil-to-tei">
        <xsl:element name="placeName">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="v:postal-code" mode="m_isil-to-tei">
        <xsl:element name="postCode">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
