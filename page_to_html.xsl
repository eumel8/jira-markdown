<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/root">
    <html>
      <head>
        <title><xsl:value-of select="//object[@class='Page']/property[@name='title']"/></title>
        <meta charset="utf-8"/>
      </head>
      <body>
        <h1><xsl:value-of select="//object[@class='Page']/property[@name='title']"/></h1>
        <div>
          <xsl:value-of select="//object[@class='BodyContent']/property[@name='body']" disable-output-escaping="yes"/>
        </div>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>

