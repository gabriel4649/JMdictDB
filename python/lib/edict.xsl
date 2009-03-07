<?xml version="1.0" encoding="ISO-8859-1" ?>
<!--
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008 Jean-Luc Leger <jean-luc.leger@dspnet.fr>
# 
#  JMdictDB is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published 
#  by the Free Software Foundation; either version 2 of the License, 
#  or (at your option) any later version.
# 
#  JMdictDB is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with JMdictDB; if not, write to the Free Software Foundation,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#######################################################################

This xslt stylesheet (originally named to_edict.xsl), in conjuction
with "edicttmp.xsl", will convert JMdict XML entries to Edict format
when used in the following sh script:

  sed 's/ENTITY \([^ ]*\) ".*"/ENTITY \1 "\1"/' $1 | \
  xsltproc edicttmp.xsl - | \
  xsltproc edict.xsl - | \
  iconv -c -f UTF-8 -t EUC-JP - | \
  sort > $2
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>

<xsl:template match="/">
  <xsl:apply-templates select="JMdict/entry[ent_seq &lt; '9000000']"/>
</xsl:template>

<xsl:template match="entry">
  <xsl:apply-templates select="line" />
</xsl:template>

<xsl:template match="line">
  <xsl:choose>
    <xsl:when test="not(keb)">
      <xsl:value-of select="reb" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="keb" /><xsl:text > [</xsl:text>
      <xsl:value-of select="reb" /><xsl:text >]</xsl:text>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:text > /</xsl:text>

  <xsl:apply-templates select="line_info" />

  <xsl:for-each select="sense">
    <xsl:if test="@active = 'true'">
      <xsl:apply-templates select="pos" />
      <xsl:if test="@seq = 1 and not(pos)">
        <xsl:apply-templates select="preceding-sibling::sense/pos" />
      </xsl:if>

<!-- Use this to implement a bug in current Edict generator
      <xsl:if test="count(../sense) > 1">
-->
      <xsl:if test="count(../sense[@active = 'true']) > 1">
        <xsl:text >(</xsl:text>
        <xsl:value-of select="@seq" />
        <xsl:text >) </xsl:text>
      </xsl:if>

      <xsl:apply-templates select="field_misc" />
      <xsl:apply-templates select="dial" />

      <xsl:for-each select="gloss">
        <xsl:value-of select="." />

        <xsl:if test="position() = 1">
          <xsl:apply-templates select="../lsource" />
        </xsl:if>

        <xsl:text >/</xsl:text>
      </xsl:for-each>
    </xsl:if>
  </xsl:for-each>

  <xsl:if test="pri">
    <xsl:text >(P)/</xsl:text>
  </xsl:if>

  <xsl:text >
</xsl:text>

</xsl:template>

<xsl:template match="line_info">
  <xsl:text >(</xsl:text>
  <xsl:value-of select="." />
  <xsl:text >) </xsl:text>
</xsl:template>

<xsl:template match="pos">
  <xsl:if test="position() = 1">
    <xsl:text >(</xsl:text>
  </xsl:if>
  <xsl:if test="position() > 1">
    <xsl:text >,</xsl:text>
  </xsl:if>
  <xsl:value-of select="." />
  <xsl:if test="position() = last()">
    <xsl:text >) </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="field_misc">
  <xsl:text >(</xsl:text>
  <xsl:value-of select="." />
  <xsl:text >) </xsl:text>
</xsl:template>
 
<xsl:template match="dial">
  <xsl:if test="position() = 1">
    <xsl:text >(</xsl:text>
  </xsl:if>
  <xsl:if test="position() > 1">
    <xsl:text >,</xsl:text>
  </xsl:if>
  <xsl:value-of select="." />
  <xsl:text >:</xsl:text>
  <xsl:if test="position() = last()">
    <xsl:text >) </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="lsource">
  <xsl:if test="position() = 1">
    <xsl:text > (</xsl:text>
  </xsl:if>
  <xsl:if test="position() > 1">
    <xsl:text >, </xsl:text>
  </xsl:if>

  <xsl:choose>
    <xsl:when test="@ls_wasei = 'y'">
      <xsl:text >wasei:</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@xml:lang" />
      <xsl:text >:</xsl:text>
    </xsl:otherwise>
  </xsl:choose>

  <xsl:if test="string-length() > 0">
    <xsl:text > </xsl:text>
    <xsl:value-of select="." />
  </xsl:if> 

  <xsl:if test="position() = last()">
    <xsl:text >)</xsl:text>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
