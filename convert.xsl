<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" indent="yes"/>

<xsl:strip-space elements="field" />

<xsl:template match="/">
  <add>
  <xsl:apply-templates/>
  </add>
</xsl:template>

<xsl:template match="us-patent-grant">
  <doc>
    <field name="document_type_s"><xsl:value-of select="@id" /></field>

    <xsl:apply-templates select="@date-publ|@date-produced"/>
    <xsl:apply-templates select="child::*" />
  </doc>
</xsl:template>

<xsl:template match="@date-publ|@date-produced">
  <xsl:variable name="date_y" select="substring(.,1,4)" />
  <xsl:variable name="date_m" select="substring(.,5,2)" />
  <xsl:variable name="date_d" select="substring(.,7,2)" />
  <xsl:variable name="name"><xsl:value-of select='translate(name(), "-", "_")'/></xsl:variable>


  <xsl:element name="field">
    <xsl:attribute name="name"><xsl:value-of select='$name'/></xsl:attribute>
    <xsl:value-of select="$date_y"/>-<xsl:value-of select="$date_m"/>-<xsl:value-of select="$date_d"/>T00:00:01Z</xsl:element>  

  <xsl:element name="field">
    <xsl:attribute name="name"><xsl:value-of select='$name'/>_s</xsl:attribute>
    <xsl:value-of select="$date_y"/>-<xsl:value-of select="$date_m"/>-<xsl:value-of select="$date_d"/></xsl:element>  

  <xsl:element name="field">
    <xsl:attribute name="name"><xsl:value-of select='$name'/>_i</xsl:attribute>
    <xsl:value-of select="$date_y"/><xsl:value-of select="$date_m"/><xsl:value-of select="$date_d"/></xsl:element>  

  <xsl:element name="field">
    <xsl:attribute name="name"><xsl:value-of select='$name'/>_facet_s</xsl:attribute>0/<xsl:value-of select="$date_y"/></xsl:element>  

  <xsl:element name="field">
    <xsl:attribute name="name"><xsl:value-of select='$name'/>_facet_s</xsl:attribute>1/<xsl:value-of select="$date_y"/>/<xsl:value-of select="$date_m"/></xsl:element>  

</xsl:template>

<xsl:template match="us-bibliographic-data-grant">
    <field name="id"><xsl:value-of select="publication-reference/document-id/doc-number" /></field>
    <field name="doc_number_s"><xsl:value-of select="publication-reference/document-id/doc-number" /></field>  
    <field name="invention_title_txt"><xsl:value-of select="invention-title" /></field>
    <field name="assignee_orgname_s"><xsl:value-of select="assignees/assignee/addressbook/orgname" /></field>    
    <xsl:apply-templates select="classification-national/main-classification|parties/applicants/applicant/addressbook"/>
</xsl:template>

<!-- Category Lookup -->
<xsl:key name="cat-lookup" match="category" use="@id"/>
<xsl:variable name="cat-top" select="document('categories.xml')/categories"/>
<xsl:template match="categories">
  <xsl:param name="catid"/>
  <xsl:apply-templates select="key('cat-lookup', $catid)/term"/>
</xsl:template>

<xsl:template match="term">
  <field name="category_facet_s"><xsl:value-of select="."/></field>
</xsl:template>

<xsl:template match="main-classification">
  <xsl:variable name="main_class_m" select="substring(.,1,3)" />
  <xsl:variable name="main_class_s" select="substring(.,4,4)" />
  <field name="main_classification_s"><xsl:value-of select="." /></field>
  <field name="main_classification_facet_s"><xsl:value-of select="$main_class_m"/>/<xsl:value-of select="$main_class_s"/></field>

  <!-- Convert spaces in the category code to 0, and pad 0's to the left so that it is 9 digits long -->
  <xsl:variable name="catcode"><xsl:value-of select='substring(concat(translate(., " ", "0"), "000000000"), 1, 9)'/></xsl:variable>
  <!-- now convert that into values in the categories.xml lookup file -->
  <xsl:apply-templates select="$cat-top">
    <xsl:with-param name="catid" select="$catcode"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="further-classification">
  <field name="further_classification_s"><xsl:value-of select="." /></field>
</xsl:template>

<xsl:template match="citation/patcit/document-id/doc-number">
  <field name="citation_s"><xsl:value-of select="." /></field>
</xsl:template>

<xsl:template match="parties/applicants/applicant/addressbook">
  <field name="applicant_inventor_s"><xsl:value-of select='concat(first-name," ",last-name)' /></field>
  <field name="applicant_inventor_facet_s"><xsl:value-of select='concat(last-name,", ",first-name)' /></field>
  <field name="applicant_inventor_last_name_s"><xsl:value-of select="last-name" /></field>
  <field name="applicant_inventor_first_name_s"><xsl:value-of select="first-name" /></field>
</xsl:template>

<xsl:template match="invention-title|abstract|description|claim-text">
      <xsl:element name="field">
	<xsl:attribute name="name"><xsl:value-of select='translate(name(), "-", "_")'/>_txt</xsl:attribute>
	<xsl:value-of select="."/>
      </xsl:element>
</xsl:template>

</xsl:stylesheet>