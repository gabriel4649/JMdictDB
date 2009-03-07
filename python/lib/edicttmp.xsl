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

This xslt stylesheet (originally named to_temp.xsl), in conjuction
with "edict.xsl", will convert JMdict XML entries to Edict format
when used in the following sh script:

  sed 's/ENTITY \([^ ]*\) ".*"/ENTITY \1 "\1"/' $1 | \
  xsltproc edicttmp.xsl - | \
  xsltproc edict.xsl - | \
  iconv -c -f UTF-8 -t EUC-JP - | \
  sort > $2
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" indent="yes" />

<xsl:template match="/">
  <JMdict>
  <xsl:apply-templates select="JMdict/entry"/>
  </JMdict>
</xsl:template>

<xsl:template match="entry">
  <entry>
  <xsl:copy-of select="ent_seq" />

  <xsl:apply-templates select="r_ele" />
  </entry>
</xsl:template>

<xsl:template match="r_ele">
  <xsl:variable name="reb" select="reb" />

  <xsl:choose>
    <xsl:when test="not(../k_ele) or re_nokanji">

      <line>
      <xsl:copy-of select="reb" />
      <xsl:apply-templates select="re_inf" />

      <xsl:if test="re_pri = 'ichi1' or re_pri = 'jdd1' or re_pri = 'gai1' or re_pri = 'spec1' or re_pri = 'news1' or re_pri = 'spec2'">
        <pri />
      </xsl:if>

      <xsl:for-each select="../sense[count(gloss[@xml:lang='eng']) > 0]">
        <sense>
        <xsl:attribute name="active">
          <xsl:value-of select="(not(stagr) or stagr=$reb) and not(stagk)" />
        </xsl:attribute> 

        <xsl:if test="(not(stagr) or stagr=$reb) and not(stagk)">
          <xsl:attribute name="seq">
            <xsl:value-of select="count(preceding-sibling::sense[count(gloss[@xml:lang='eng']) > 0 and (not(stagr) or stagr=$reb) and not(stagk)]) + 1" />
          </xsl:attribute> 
        </xsl:if>

        <xsl:copy-of select="pos" />

        <xsl:if test="(not(stagr) or stagr=$reb) and not(stagk)">
          <xsl:apply-templates select="field" />
          <xsl:apply-templates select="misc" />
          <xsl:copy-of select="xref" />
          <xsl:copy-of select="ant" />
          <xsl:copy-of select="s_inf" />
          <xsl:copy-of select="lsource" />
          <xsl:copy-of select="dial" />
          <xsl:copy-of select="gloss[@xml:lang='eng']" />
        </xsl:if>

        </sense>
      </xsl:for-each>
      </line>

    </xsl:when>

    <xsl:otherwise>
      <xsl:variable name="re_restr" select="re_restr" />
      <xsl:variable name="re_pri" select="re_pri[.='ichi1' or .='jdd1' or .='gai1' or .='spec1' or .='news1' or .='spec2']" />
      <xsl:variable name="re_inf">
        <xsl:apply-templates select="re_inf" />
      </xsl:variable>

      <xsl:for-each select="../k_ele[not($re_restr) or $re_restr=keb]">
        <xsl:variable name="keb" select="keb" />

        <line>
        <xsl:copy-of select="keb" />
        <reb>
        <xsl:value-of select="$reb" />
        </reb>
        <xsl:apply-templates select="ke_inf" />
        <xsl:copy-of select="$re_inf" />

        <xsl:for-each select="ke_pri[$re_pri and $re_pri=.]">
          <pri />
        </xsl:for-each>

        <xsl:for-each select="../sense[count(gloss[@xml:lang='eng']) > 0]">
          <sense>
          <xsl:attribute name="active">
            <xsl:value-of select="(not(stagr) or stagr=$reb) and (not(stagk) or stagk=$keb)" />
          </xsl:attribute> 

          <xsl:if test="(not(stagr) or stagr=$reb) and (not(stagk) or stagk=$keb)">
            <xsl:attribute name="seq">
              <xsl:value-of select="count(preceding-sibling::sense[count(gloss[@xml:lang='eng']) > 0 and (not(stagr) or stagr=$reb) and (not(stagk) or stagk=$keb)]) + 1" />
            </xsl:attribute> 
          </xsl:if>

          <xsl:copy-of select="pos" />

          <xsl:if test="(not(stagr) or stagr=$reb) and (not(stagk) or stagk=$keb)">
            <xsl:apply-templates select="field" />
            <xsl:apply-templates select="misc" />
            <xsl:copy-of select="xref" />
            <xsl:copy-of select="ant" />
            <xsl:copy-of select="s_inf" />
            <xsl:copy-of select="lsource" />
            <xsl:copy-of select="dial" />
            <xsl:copy-of select="gloss[@xml:lang='eng']" />
          </xsl:if>

          </sense>
        </xsl:for-each>

        </line>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template match="ke_inf">
 <line_info>
 <xsl:value-of select="." />
 </line_info>
</xsl:template>

<xsl:template match="re_inf">
 <line_info>
 <xsl:value-of select="." />
 </line_info>
</xsl:template>

<xsl:template match="field">
 <field_misc>
 <xsl:value-of select="." />
 </field_misc>
</xsl:template>
 
<xsl:template match="misc">
 <field_misc>
 <xsl:value-of select="." />
 </field_misc>
</xsl:template>

</xsl:stylesheet>
