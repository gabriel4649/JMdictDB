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

This xslt stylesheet (originally named to_edict2.xsl) will convert
JMdict XML entries to Edict2 format when used in the following sh
script:

  sed 's/ENTITY \([^ ]*\) ".*"/ENTITY \1 "\1"/' $1 | \
  xsltproc edict2.xsl - | \
  iconv -c -f UTF-8 -t EUC-JP - | \
  sort > $2
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text"/>

<xsl:template match="/">
  <xsl:apply-templates select="JMdict/entry[ent_seq &lt; '9000000']"/>
</xsl:template>

<xsl:template match="entry">
  <xsl:apply-templates select="k_ele" />

  <xsl:apply-templates select="r_ele" />

  <xsl:text > /</xsl:text>

  <xsl:apply-templates select="sense[count(gloss[@xml:lang='eng']) > 0]" />

  <xsl:if test="count(k_ele/ke_pri[.='ichi1' or .='jdd1' or .='gai1' or .='spec1' or .='news1' or .='spec2']) > 0 or count(r_ele/re_pri[.='ichi1' or .='jdd1' or .='gai1' or .='spec1' or .='news1' or .='spec2']) > 0">
    <xsl:text>(P)/</xsl:text>
  </xsl:if>

  <xsl:apply-templates select="ent_seq" />

  <xsl:text >
</xsl:text>

</xsl:template>

<xsl:template match="ent_seq">
  <xsl:text >EntL</xsl:text>
  <xsl:value-of select="." />
  <xsl:text >/</xsl:text>
</xsl:template>

<xsl:template match="k_ele">
  <xsl:if test="position() > 1">
    <xsl:text>;</xsl:text>
  </xsl:if>
  <xsl:value-of select="keb" />
  <xsl:apply-templates select="ke_inf" />
  <xsl:if test="last() > 1 and (ke_pri = 'ichi1' or ke_pri = 'jdd1' or ke_pri = 'gai1' or ke_pri = 'spec1' or ke_pri = 'news1' or ke_pri = 'spec2')">
    <xsl:text>(P)</xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="ke_inf">
  <xsl:text >(</xsl:text>
  <xsl:value-of select="." />
  <xsl:text >)</xsl:text>
</xsl:template>

<xsl:template match="r_ele">
  <xsl:if test="position() = 1 and ../k_ele">
    <xsl:text > [</xsl:text>
  </xsl:if>
  <xsl:if test="position() > 1">
    <xsl:text >;</xsl:text>
  </xsl:if>
  <xsl:value-of select="reb" />
  <xsl:apply-templates select="re_restr" />
  <xsl:apply-templates select="re_inf" />
  <xsl:if test="last() > 1 and (re_pri = 'ichi1' or re_pri = 'jdd1' or re_pri = 'gai1' or re_pri = 'spec1' or re_pri = 'news1' or re_pri = 'spec2')">
    <xsl:text>(P)</xsl:text>
  </xsl:if>

  <xsl:if test="position() = last() and ../k_ele">
    <xsl:text >]</xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="re_inf">
  <xsl:text >(</xsl:text>
  <xsl:value-of select="." />
  <xsl:text >)</xsl:text>
</xsl:template>

<xsl:template match="re_restr">
  <xsl:if test="position() = 1">
    <xsl:text >(</xsl:text>
  </xsl:if>
  <xsl:if test="position() > 1">
    <xsl:text >;</xsl:text>
  </xsl:if>
  <xsl:value-of select="." />
  <xsl:if test="position() = last()">
    <xsl:text >)</xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="sense">
  <xsl:apply-templates select="pos" />

  <xsl:if test="last() > 1">
    <xsl:text >(</xsl:text>
    <xsl:value-of select="position()" />
    <xsl:text >) </xsl:text>
  </xsl:if>

  <xsl:if test="stagk or stagr">
    <xsl:text >(</xsl:text>
    <xsl:apply-templates select="stagk" />
    <xsl:apply-templates select="stagr" />
    <xsl:text > only) </xsl:text>
  </xsl:if>

  <xsl:apply-templates select="s_inf" />
  <xsl:apply-templates select="xref" />
  <xsl:apply-templates select="ant" />

  <xsl:apply-templates select="misc" />
  <xsl:apply-templates select="dial" />
  <xsl:apply-templates select="field" />

  <xsl:apply-templates select="gloss[@xml:lang='eng']" />
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
 
<xsl:template match="field">
  <xsl:if test="position() = 1">
    <xsl:text >{</xsl:text>
  </xsl:if>
  <xsl:if test="position() > 1">
    <xsl:text >;</xsl:text>
  </xsl:if>
  <xsl:value-of select="." />
  <xsl:if test="position() = last()">
    <xsl:text >} </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="misc">
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

<xsl:template match="stagk">
  <xsl:if test="position() > 1">
    <xsl:text >, </xsl:text>
  </xsl:if>
  <xsl:value-of select="." />
</xsl:template>

<xsl:template match="stagr">
  <xsl:if test="position() > 1 or ../stagk">
    <xsl:text >, </xsl:text>
  </xsl:if>
  <xsl:value-of select="." />
</xsl:template>

<xsl:template match="xref">
  <xsl:if test="position() = 1">
    <xsl:text >(See </xsl:text>
  </xsl:if>
  <xsl:if test="position() > 1">
    <xsl:text >,</xsl:text>
  </xsl:if>
  <xsl:value-of select="." />
  <xsl:if test="position() = last()">
    <xsl:text >) </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="ant">
  <xsl:if test="position() = 1">
    <xsl:text >(ant: </xsl:text>
  </xsl:if>
  <xsl:if test="position() > 1">
    <xsl:text >,</xsl:text>
  </xsl:if>
  <xsl:value-of select="." />
  <xsl:if test="position() = last()">
    <xsl:text >) </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="s_inf">
  <xsl:text >(</xsl:text>
  <xsl:value-of select="." />
  <xsl:text >) </xsl:text>
</xsl:template>

<xsl:template match="gloss">
  <xsl:value-of select="." />

  <xsl:if test="position() = 1">
    <xsl:apply-templates select="../lsource" />
  </xsl:if>

  <xsl:text >/</xsl:text>
</xsl:template>

</xsl:stylesheet>
