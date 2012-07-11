<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="2.0"
              xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:import href="cals_table.xsl"/>

<xsl:output
  method="xml"
  omit-xml-declaration="yes"
  indent="no"/>

<xsl:template match="patents">
  {
     <!-- just grab the patent files, don't try and index the genetic sequences or other objects. -->
      <xsl:for-each select="us-patent-grant">
        <xsl:apply-templates select="."/>
        <xsl:if test="not(position() = last())">,</xsl:if>
      </xsl:for-each>
  }
</xsl:template>

<xsl:template match="us-patent-grant">
  "add": { "doc": {
    "document_type":"<xsl:value-of select="@id" />",
    <xsl:apply-templates select="@date-publ"/>,
    <xsl:apply-templates select="@date-produced"/>,
    <xsl:for-each select="us-bibliographic-data-grant|abstract|description|claims">
      <xsl:apply-templates select="." />
      <xsl:if test="not(position() = last())">,</xsl:if>
    </xsl:for-each>
  }}
</xsl:template>

<xsl:template match="@date-publ|@date-produced">
  <xsl:variable name="date_y" select="substring(.,1,4)" />
  <xsl:variable name="date_m" select="substring(.,5,2)" />
  <xsl:variable name="date_d" select="substring(.,7,2)" />
  <xsl:variable name="name"><xsl:value-of select='translate(name(), "-", "_")'/></xsl:variable>
    "<xsl:value-of select='$name'/>":"<xsl:value-of select="$date_y"/>-<xsl:value-of select="$date_m"/>-<xsl:value-of select="$date_d"/>T00:00:01Z",
    "<xsl:value-of select='$name'/>_s":"<xsl:value-of select="$date_y"/>-<xsl:value-of select="$date_m"/>-<xsl:value-of select="$date_d"/>",
    "<xsl:value-of select='$name'/>_i":"<xsl:value-of select="$date_y"/><xsl:value-of select="$date_m"/><xsl:value-of select="$date_d"/>",
    "<xsl:value-of select='$name'/>_facet":["0/<xsl:value-of select="$date_y"/>","1/<xsl:value-of select="$date_y"/>/<xsl:value-of select="$date_m"/>"]
</xsl:template>

<!-- CPC facet lookup, by CPC facet id. -->
<xsl:key name="cpc-facet-lookup" match="classification" use="@id"/>
<xsl:variable name="cpc-facet-top" select="document('cpc_facets.xml')/cpc"/>
<xsl:template match="cpc" mode="cpc">
  <xsl:param name="cpc_id"/>
  <xsl:for-each select="key('cpc-facet-lookup', $cpc_id)/term">
    "<xsl:value-of select="."/>"<xsl:if test="not(position() = last())">,</xsl:if>
  </xsl:for-each>
</xsl:template>

<!-- CPC Classification Lookup by patent id -->
<xsl:key name="cpc-lookup" match="patent" use="@id"/>
<xsl:variable name="cpc-top" select="document('cpc_2005_2010.xml')/patents"/>
<xsl:template match="patents" mode="cpc">
  <xsl:param name="patent_id"/>
  "cpc_code":[
  <xsl:for-each select="key('cpc-lookup', $patent_id)/code">
    "<xsl:value-of select="."/>"<xsl:if test="not(position() = last())">,</xsl:if>
  </xsl:for-each>
  ],
  "cpc_facet":[
  <xsl:for-each select="key('cpc-lookup', $patent_id)/code">
    <xsl:variable name="cpc-facet-data">
      <xsl:apply-templates select="$cpc-facet-top" mode="cpc"><xsl:with-param name="cpc_id" select="."/></xsl:apply-templates>  
    </xsl:variable>
    <xsl:copy-of select="$cpc-facet-data"/>
    <xsl:if test="$cpc-facet-data = ''">""</xsl:if>
    <xsl:if test="not(position() = last())">,</xsl:if>
  </xsl:for-each>  
  ],
</xsl:template>

<xsl:template match="us-bibliographic-data-grant">
  <xsl:variable name="doc_number" select="publication-reference/document-id/doc-number"/>
  "id":"<xsl:value-of select="$doc_number"/>",
  "doc_number":"<xsl:value-of select="$doc_number"/>",
  <xsl:apply-templates select="invention-title" />,
  "assignee_orgname_s":"<xsl:value-of select="assignees/assignee/addressbook/orgname" />",
  <xsl:apply-templates select="classification-national/main-classification" />,
  <xsl:apply-templates select="$cpc-top" mode="cpc"><xsl:with-param name="patent_id" select="$doc_number"/></xsl:apply-templates>
  <xsl:for-each select="parties/applicants/applicant/addressbook">
    <xsl:apply-templates select="." />
    <xsl:if test="not(position() = last())">,</xsl:if>
  </xsl:for-each> 
</xsl:template>

<!-- Category Lookup -->
<xsl:key name="cat-lookup" match="category" use="@id"/>
<xsl:variable name="cat-top" select="document('categories.xml')/categories"/>
<xsl:template match="categories">
  <xsl:param name="catid"/>
  <xsl:for-each select="key('cat-lookup', $catid)/term">
    <xsl:apply-templates select="."/>
    <xsl:if test="not(position() = last())">,</xsl:if>
  </xsl:for-each>
</xsl:template>

<xsl:template match="term">
  "<xsl:value-of select="."/>"
</xsl:template>

  <xsl:template match="main-classification">
    <xsl:variable name="main_class_m"  select='substring(concat(translate(substring(.,1,3), " ", "0"), "000"), 1, 3)' />
    <xsl:variable name="main_class_s1" select='substring(concat("000", translate(substring(.,4,3), " ", "0")), string-length(substring(.,4,3)) + 1, 3)'/>
    <xsl:variable name="main_class_s2" select='substring(concat("000", translate(substring(.,7,3), " ", "0")), string-length(substring(.,7,3)) + 1, 3)' />

    <!-- If the category ends with a letter, forward pad the subclasses with 0, if it doesn't, just pad with 0's on the end -->
    <xsl:variable name="catcode">
      <xsl:choose>
      <xsl:when test="matches(., '[A-Z]$')">
        <xsl:value-of select='concat($main_class_m, $main_class_s1, $main_class_s2)'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='substring(concat(translate(., " ", "0"), "000000000"), 1, 9)'/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- If you skill can't find the code, then fall back to just the main class -->
    <xsl:variable name="check1">
       <xsl:apply-templates select="$cat-top"><xsl:with-param name="catid" select="$catcode"/></xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="category_facet">
      <xsl:choose>
      <xsl:when test="$check1 != ''">
        <xsl:value-of select='$check1'/>
       </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="catmain" select='substring(concat(translate(substring(.,1,3), " ", "0"), "000000000"), 1, 9)'/>
        <xsl:apply-templates select="$cat-top"><xsl:with-param name="catid" select="$catmain"/></xsl:apply-templates>
      </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    "main_classification":"<xsl:value-of select="." />",
    "main_classification_std":"<xsl:value-of select="$catcode"/>",
    "category_facet":[<xsl:value-of select="$category_facet"/>]
  </xsl:template>

<xsl:template match="further-classification">
  "further_classification":"<xsl:value-of select="." />"
</xsl:template>

<xsl:template match="citation/patcit/document-id/doc-number">
  "citation_s":"<xsl:value-of select="." />"
</xsl:template>

<xsl:template match="parties/applicants/applicant/addressbook">
  "applicant_inventor":"<xsl:value-of select='concat(first-name," ",last-name)' />",
  "applicant_inventor_facet":"<xsl:value-of select='concat(last-name,", ",first-name)' />",
  "applicant_inventor_last_name":"<xsl:value-of select="last-name" />",
  "applicant_inventor_first_name":"<xsl:value-of select="first-name" />"
</xsl:template>

<xsl:template match="invention-title|abstract|description">
  "<xsl:value-of select='translate(name(), "-", "_")'/>_raw":
    "<xsl:call-template name="escape"><xsl:with-param name="e" select="."/></xsl:call-template>",
  "<xsl:value-of select='translate(name(), "-", "_")'/>_html":"<xsl:apply-templates/>"
</xsl:template>

<xsl:template match="claims">
  "claims_raw":"   <xsl:call-template name="escape"><xsl:with-param name="e" select="."/></xsl:call-template>",
  "claims_html":"
    <ol class='claims'>
        <xsl:apply-templates/>
    </ol>"
</xsl:template>

<xsl:template match="claim">
  <xsl:variable name="num" select="number(@num)"/>
  <li value='{$num}'>
    <xsl:apply-templates />
  </li>
</xsl:template>

  <xsl:template match="claim/claim-text">
    <!-- trim off a leading number, period and space from the beginning of the claim text"
         so that  "1. A bla bla " becomes just "A bla bla" -->
  <xsl:for-each select="node()">
    <xsl:choose>
      <xsl:when test="self::text()">
        <!-- trim leading numbers off the claims text.-->
        <xsl:if test="position() &lt; 3">
          <!--
          <xsl:call-template name="trim-leading-numbers">
            <xsl:with-param name="text" select="." />
          </xsl:call-template>
          -->
          <xsl:value-of select="replace(., '^[0-9]{1,4}\.? ?', '')"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
  </xsl:template>

  <xsl:template match="claim-text">
        <blockquote class='claim-text'>
          <xsl:apply-templates />
        </blockquote>
  </xsl:template>


<!-- NOT USED IN US: best-mode, disclosure, background-art, technical-field, mode-for-invention -->
<xsl:template match="disclosure|sequence-list-text|technical-field|background-art|description-of-drawings|best-mode|mode-for-invention|industrial-applicability|tech-problem|tech-solution|advantageous-effects">
  <xsl:variable name="class"><xsl:value-of select="name()"/></xsl:variable>
  <div class='{$class}'>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="heading">
  <xsl:variable name="el_name">h<xsl:value-of select="@level"/></xsl:variable>
  <xsl:element name="{$el_name}">
    <xsl:apply-templates/>
  </xsl:element>
</xsl:template>

<xsl:template match="smallcaps">
  <span class='smallcaps'>
    <xsl:apply-templates/>
  </span>
</xsl:template>

<xsl:template match="p | b | i | o | u | sup | sub | ol | ul | li | br | dl | table ">
  <xsl:element name="{name()}">
    <xsl:apply-templates/>
  </xsl:element>
</xsl:template>

<xsl:template match="text()">
   <xsl:call-template name="escape"><xsl:with-param name="e" select="."/></xsl:call-template>
</xsl:template>

  <!-- we must escape the \ character, if it occurs naturally in the next, because the json output considers
       it an escape character, and will bomb if it occurs out of context when loading into solr, same is
       true of a double quote. ) -->
<xsl:template name="escape">
  <xsl:param name="e"/>

  <!-- This the xslt2 version of the escape method -->

  <xsl:variable name="txt" select="replace($e, '\\', '\\\\')"/>
  <xsl:value-of select="replace($txt, '&quot;', '\\&quot;')"/>

    <!-- This the xslt1 version of the escape method -->
  <!--
  <xsl:variable name="txt">
    <xsl:call-template name="str:replace">
        <xsl:with-param name="string" select="$e"/>
        <xsl:with-param name="search">\</xsl:with-param>
        <xsl:with-param name="replace">\\</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="str:replace">
        <xsl:with-param name="string" select="$e" />
        <xsl:with-param name="search">\</xsl:with-param>
        <xsl:with-param name="replace">\\</xsl:with-param>
      </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="escaped">
    <xsl:call-template name="str:replace">
        <xsl:with-param name="string" select="$txt" />
        <xsl:with-param name="search">"</xsl:with-param>
        <xsl:with-param name="replace">\"</xsl:with-param>
      </xsl:call-template>
  </xsl:variable>
  <xsl:value-of select="$escaped"/>
  -->

</xsl:template>


  <!-- trim off a leading number, period and space from the beginning of the claim text"
       so that  "1. A bla bla " becomes just "A bla bla" -->
  <!-- Provides string replacement when using xsl1 -->
  <xsl:template name="trim-leading-numbers">
    <xsl:param name="text" />
    <xsl:choose>
      <xsl:when test="$text = ''">
        <xsl:value-of select="$text" />
      </xsl:when>
      <xsl:when test="contains('0123456789. ', substring($text, 1, 1))">
        <xsl:call-template name="trim-leading-numbers">
          <xsl:with-param name="text" select="substring($text,2)" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


<!-- TABLES (please see cals_table.xsl) -->
<xsl:template match="tables">
  <div class="tables">
    <xsl:apply-templates/>
  </div>
</xsl:template>

</xsl:stylesheet>
