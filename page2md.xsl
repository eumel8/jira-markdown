<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xhtml">

  <xsl:output method="text" encoding="UTF-8"/>

  <!-- Root template -->
  <xsl:template match="/root">
    <xsl:text># </xsl:text>
    <xsl:value-of select="object[@class='Page']/property[@name='title']"/>
    <xsl:text>&#10;&#10;</xsl:text>

    <!-- Output the body content -->
    <xsl:value-of select="object[@class='BodyContent']/property[@name='body']"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
