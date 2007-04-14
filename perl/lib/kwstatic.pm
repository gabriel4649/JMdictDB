#======================================================
# CAUTION!
# This file was generated automatically my mkkwmod.pl
# and any changes made to this file will be overwritten 
# the next time it is regenerated.
#======================================================
use strict;  use warnings;
package kwstatic;

BEGIN {
    use Exporter();
    our ($VERSION, @ISA, @EXPORT);
    @ISA = qw(Exporter);
    @EXPORT   = qw($Kdws $KWMISC_X $KWMISC_abbr $KWMISC_aphorism $KWMISC_arch $KWMISC_ateji $KWMISC_chn $KWMISC_col $KWMISC_derog $KWMISC_ek $KWMISC_fam $KWMISC_fem $KWMISC_gikun $KWMISC_hon $KWMISC_hum $KWMISC_id $KWMISC_m_sl $KWMISC_male $KWMISC_male_sl $KWMISC_obs $KWMISC_obsc $KWMISC_pol $KWMISC_proverb $KWMISC_quote $KWMISC_rare $KWMISC_sens $KWMISC_sl $KWMISC_uK $KWMISC_uk $KWMISC_vulg $KWFREQ_gA $KWFREQ_gai $KWFREQ_ichi $KWFREQ_news $KWFREQ_nf $KWFREQ_spec $KWXREF_ant $KWXREF_cf $KWXREF_ex $KWXREF_pref $KWXREF_see $KWXREF_syn $KWXREF_uses $KWSRC_atsuko $KWSRC_bonji1 $KWSRC_cg5 $KWSRC_dbjg $KWSRC_ejud $KWSRC_email $KWSRC_examples $KWSRC_gc4 $KWSRC_inet $KWSRC_jmdict $KWSRC_jmdictx $KWSRC_jmnedict $KWSRC_kcadj $KWSRC_krje $KWSRC_misc $KWSRC_mnn $KWSRC_mnn1cd1 $KWSRC_mnn1cd2 $KWSRC_mnn1cd3 $KWSRC_mnn1cd4 $KWSRC_mnn2cd1 $KWSRC_mnn2cd3 $KWSRC_mnncd2 $KWSRC_mnncd4 $KWSRC_mp3 $KWSRC_nakama1 $KWSRC_numb $KWSRC_satomi $KWSRC_slj $KWSRC_undef $KWSRC_wav $KWSRC_yamasa $KWSRC_yk1 $KWSRC_yk1cd1 $KWSRC_yk1cd2 $KWSRC_yk1wb $KWSRC_yk1wbcd1 $KWSRC_yk1wbcd2 $KWSRC_yk1wbcd3 $KWSRC_yk1wbcd4 $KWSRC_yppp $KWRINF_ateji $KWRINF_gikun $KWRINF_ik $KWRINF_ok $KWRINF_rare $KWRINF_uK $KWRINF_uk $KWSTAT_A $KWSTAT_D $KWSTAT_M $KWSTAT_N $KWSTAT_O $KWSTAT_R $KWSTAT_X $KWKINF_iK $KWKINF_ik $KWKINF_io $KWKINF_oK $KWFLD_Buddh $KWFLD_MA $KWFLD_comp $KWFLD_food $KWFLD_geom $KWFLD_ling $KWFLD_math $KWFLD_mil $KWFLD_physics $KWLANG_ai $KWLANG_ar $KWLANG_bo $KWLANG_de $KWLANG_el $KWLANG_en $KWLANG_eo $KWLANG_es $KWLANG_fr $KWLANG_hi $KWLANG_in $KWLANG_it $KWLANG_iw $KWLANG_ja $KWLANG_kl $KWLANG_ko $KWLANG_kr $KWLANG_lt $KWLANG_mn $KWLANG_nl $KWLANG_no $KWLANG_pl $KWLANG_pt $KWLANG_ru $KWLANG_sa $KWLANG_sanskr $KWLANG_sv $KWLANG_uk $KWLANG_ur $KWLANG_zh $KWDIAL_ksb $KWDIAL_ktb $KWDIAL_kyb $KWDIAL_osb $KWDIAL_std $KWDIAL_thb $KWDIAL_tsb $KWDIAL_tsug $KWPOS_adj $KWPOS_adj_na $KWPOS_adj_no $KWPOS_adj_pn $KWPOS_adj_t $KWPOS_adv $KWPOS_adv_n $KWPOS_adv_to $KWPOS_aff $KWPOS_alt $KWPOS_aux $KWPOS_aux_adj $KWPOS_aux_v $KWPOS_cause $KWPOS_cause2 $KWPOS_cnt $KWPOS_comp $KWPOS_company $KWPOS_cond $KWPOS_conj $KWPOS_conjec $KWPOS_cop $KWPOS_cp $KWPOS_demo $KWPOS_dict $KWPOS_exp $KWPOS_fem $KWPOS_fg $KWPOS_fml $KWPOS_given $KWPOS_imp $KWPOS_infml $KWPOS_int $KWPOS_intr $KWPOS_io $KWPOS_iv $KWPOS_masc $KWPOS_mg $KWPOS_n $KWPOS_n_adv $KWPOS_n_loc $KWPOS_n_pref $KWPOS_n_suf $KWPOS_n_t $KWPOS_naff $KWPOS_neg $KWPOS_neg_v $KWPOS_ng $KWPOS_num $KWPOS_pass $KWPOS_past $KWPOS_person $KWPOS_place $KWPOS_poten $KWPOS_pref $KWPOS_product $KWPOS_pron $KWPOS_prov $KWPOS_prt $KWPOS_station $KWPOS_suf $KWPOS_surname $KWPOS_te $KWPOS_te2 $KWPOS_unclass $KWPOS_v1 $KWPOS_v1x $KWPOS_v5 $KWPOS_v5aru $KWPOS_v5b $KWPOS_v5g $KWPOS_v5k $KWPOS_v5k_s $KWPOS_v5kx $KWPOS_v5m $KWPOS_v5mx $KWPOS_v5n $KWPOS_v5r $KWPOS_v5r_i $KWPOS_v5rx $KWPOS_v5ry $KWPOS_v5s $KWPOS_v5t $KWPOS_v5u $KWPOS_v5u_s $KWPOS_v5uru $KWPOS_v5ux $KWPOS_vh $KWPOS_vh2 $KWPOS_vi $KWPOS_vk $KWPOS_vs $KWPOS_vs_i $KWPOS_vs_s $KWPOS_vt $KWPOS_vz); }

our (@EXPORT);

our($KWMISC_X) = 1;
our($KWMISC_abbr) = 2;
our($KWMISC_aphorism) = 82;
our($KWMISC_arch) = 3;
our($KWMISC_ateji) = 202;
our($KWMISC_chn) = 4;
our($KWMISC_col) = 5;
our($KWMISC_derog) = 6;
our($KWMISC_ek) = 7;
our($KWMISC_fam) = 8;
our($KWMISC_fem) = 9;
our($KWMISC_gikun) = 10;
our($KWMISC_hon) = 11;
our($KWMISC_hum) = 12;
our($KWMISC_id) = 13;
our($KWMISC_m_sl) = 14;
our($KWMISC_male) = 15;
our($KWMISC_male_sl) = 201;
our($KWMISC_obs) = 17;
our($KWMISC_obsc) = 18;
our($KWMISC_pol) = 19;
our($KWMISC_proverb) = 81;
our($KWMISC_quote) = 83;
our($KWMISC_rare) = 20;
our($KWMISC_sens) = 25;
our($KWMISC_sl) = 21;
our($KWMISC_uK) = 203;
our($KWMISC_uk) = 22;
our($KWMISC_vulg) = 24;
our($KWFREQ_gA) = 6;
our($KWFREQ_gai) = 2;
our($KWFREQ_ichi) = 1;
our($KWFREQ_news) = 7;
our($KWFREQ_nf) = 5;
our($KWFREQ_spec) = 4;
our($KWXREF_ant) = 2;
our($KWXREF_cf) = 4;
our($KWXREF_ex) = 5;
our($KWXREF_pref) = 7;
our($KWXREF_see) = 3;
our($KWXREF_syn) = 1;
our($KWXREF_uses) = 6;
our($KWSRC_examples) = 3;
our($KWSRC_jmdict) = 1;
our($KWSRC_jmnedict) = 2;
our($KWRINF_ateji) = 1;
our($KWRINF_gikun) = 2;
our($KWRINF_ik) = 4;
our($KWRINF_ok) = 3;
our($KWRINF_rare) = 201;
our($KWRINF_uK) = 5;
our($KWRINF_uk) = 202;
our($KWSTAT_A) = 2;
our($KWSTAT_D) = 5;
our($KWSTAT_M) = 3;
our($KWSTAT_N) = 1;
our($KWSTAT_O) = 6;
our($KWSTAT_R) = 8;
our($KWSTAT_X) = 4;
our($KWKINF_iK) = 1;
our($KWKINF_ik) = 4;
our($KWKINF_io) = 2;
our($KWKINF_oK) = 3;
our($KWFLD_Buddh) = 1;
our($KWFLD_MA) = 6;
our($KWFLD_comp) = 2;
our($KWFLD_food) = 3;
our($KWFLD_geom) = 4;
our($KWFLD_ling) = 5;
our($KWFLD_math) = 7;
our($KWFLD_mil) = 8;
our($KWFLD_physics) = 9;
our($KWLANG_ai) = 2;
our($KWLANG_ar) = 3;
our($KWLANG_bo) = 23;
our($KWLANG_de) = 4;
our($KWLANG_el) = 5;
our($KWLANG_en) = 1;
our($KWLANG_eo) = 6;
our($KWLANG_es) = 7;
our($KWLANG_fr) = 8;
our($KWLANG_hi) = 24;
our($KWLANG_in) = 9;
our($KWLANG_it) = 10;
our($KWLANG_iw) = 20;
our($KWLANG_ja) = 0;
our($KWLANG_kl) = 27;
our($KWLANG_ko) = 11;
our($KWLANG_kr) = 28;
our($KWLANG_lt) = 12;
our($KWLANG_mn) = 26;
our($KWLANG_nl) = 13;
our($KWLANG_no) = 14;
our($KWLANG_pl) = 21;
our($KWLANG_pt) = 15;
our($KWLANG_ru) = 16;
our($KWLANG_sa) = 29;
our($KWLANG_sanskr) = 17;
our($KWLANG_sv) = 22;
our($KWLANG_uk) = 18;
our($KWLANG_ur) = 25;
our($KWLANG_zh) = 19;
our($KWDIAL_ksb) = 2;
our($KWDIAL_ktb) = 3;
our($KWDIAL_kyb) = 4;
our($KWDIAL_osb) = 5;
our($KWDIAL_std) = 1;
our($KWDIAL_thb) = 7;
our($KWDIAL_tsb) = 6;
our($KWDIAL_tsug) = 8;
our($KWPOS_adj) = 1;
our($KWPOS_adj_na) = 2;
our($KWPOS_adj_no) = 3;
our($KWPOS_adj_pn) = 4;
our($KWPOS_adj_t) = 5;
our($KWPOS_adv) = 6;
our($KWPOS_adv_n) = 201;
our($KWPOS_adv_to) = 8;
our($KWPOS_aff) = 313;
our($KWPOS_alt) = 331;
our($KWPOS_aux) = 9;
our($KWPOS_aux_adj) = 54;
our($KWPOS_aux_v) = 10;
our($KWPOS_cause) = 325;
our($KWPOS_cause2) = 326;
our($KWPOS_cnt) = 302;
our($KWPOS_comp) = 202;
our($KWPOS_company) = 184;
our($KWPOS_cond) = 321;
our($KWPOS_conj) = 12;
our($KWPOS_conjec) = 330;
our($KWPOS_cop) = 301;
our($KWPOS_cp) = 327;
our($KWPOS_demo) = 309;
our($KWPOS_dict) = 317;
our($KWPOS_exp) = 13;
our($KWPOS_fem) = 187;
our($KWPOS_fg) = 208;
our($KWPOS_fml) = 316;
our($KWPOS_given) = 189;
our($KWPOS_imp) = 332;
our($KWPOS_infml) = 315;
our($KWPOS_int) = 14;
our($KWPOS_intr) = 312;
our($KWPOS_io) = 205;
our($KWPOS_iv) = 206;
our($KWPOS_masc) = 186;
our($KWPOS_mg) = 207;
our($KWPOS_n) = 17;
our($KWPOS_n_adv) = 18;
our($KWPOS_n_loc) = 311;
our($KWPOS_n_pref) = 20;
our($KWPOS_n_suf) = 19;
our($KWPOS_n_t) = 21;
our($KWPOS_naff) = 314;
our($KWPOS_neg) = 203;
our($KWPOS_neg_v) = 204;
our($KWPOS_ng) = 209;
our($KWPOS_num) = 24;
our($KWPOS_pass) = 324;
our($KWPOS_past) = 318;
our($KWPOS_person) = 188;
our($KWPOS_place) = 182;
our($KWPOS_poten) = 323;
our($KWPOS_pref) = 25;
our($KWPOS_product) = 185;
our($KWPOS_pron) = 310;
our($KWPOS_prov) = 322;
our($KWPOS_prt) = 26;
our($KWPOS_station) = 190;
our($KWPOS_suf) = 27;
our($KWPOS_surname) = 181;
our($KWPOS_te) = 319;
our($KWPOS_te2) = 320;
our($KWPOS_unclass) = 183;
our($KWPOS_v1) = 28;
our($KWPOS_v1x) = 303;
our($KWPOS_v5) = 29;
our($KWPOS_v5aru) = 30;
our($KWPOS_v5b) = 31;
our($KWPOS_v5g) = 32;
our($KWPOS_v5k) = 33;
our($KWPOS_v5k_s) = 34;
our($KWPOS_v5kx) = 304;
our($KWPOS_v5m) = 35;
our($KWPOS_v5mx) = 306;
our($KWPOS_v5n) = 36;
our($KWPOS_v5r) = 37;
our($KWPOS_v5r_i) = 38;
our($KWPOS_v5rx) = 305;
our($KWPOS_v5ry) = 308;
our($KWPOS_v5s) = 39;
our($KWPOS_v5t) = 40;
our($KWPOS_v5u) = 41;
our($KWPOS_v5u_s) = 42;
our($KWPOS_v5uru) = 43;
our($KWPOS_v5ux) = 307;
our($KWPOS_vh) = 328;
our($KWPOS_vh2) = 329;
our($KWPOS_vi) = 44;
our($KWPOS_vk) = 45;
our($KWPOS_vs) = 46;
our($KWPOS_vs_i) = 48;
our($KWPOS_vs_s) = 47;
our($KWPOS_vt) = 50;
our($KWPOS_vz) = 49;


our ($Kwds)   = do {
  my $a = {
    DIAL => {
              1 => { descr => "Tokyo-ben (std)", id => 1, kw => "std" },
              2 => { descr => "Kansai-ben", id => 2, kw => "ksb" },
              3 => { descr => "Kantou-ben", id => 3, kw => "ktb" },
              4 => { descr => "Kyoto-ben", id => 4, kw => "kyb" },
              5 => { descr => "Osaka-ben", id => 5, kw => "osb" },
              6 => { descr => "Tosa-ben", id => 6, kw => "tsb" },
              7 => { descr => "Hokaido-ben", id => 7, kw => "thb" },
              8 => { descr => "Tsugaru-ben", id => 8, kw => "tsug" },
              ksb => 'fix',
              ktb => 'fix',
              kyb => 'fix',
              osb => 'fix',
              std => 'fix',
              thb => 'fix',
              tsb => 'fix',
              tsug => 'fix',
            },
    FLD  => {
              1 => { descr => "Buddhist term", id => 1, kw => "Buddh" },
              2 => { descr => "computer terminology", id => 2, kw => "comp" },
              3 => { descr => "food term", id => 3, kw => "food" },
              4 => { descr => "geometry term", id => 4, kw => "geom" },
              5 => { descr => "linguistics terminology", id => 5, kw => "ling" },
              6 => { descr => "martial arts term", id => 6, kw => "MA" },
              7 => { descr => "mathematics", id => 7, kw => "math" },
              8 => { descr => "military", id => 8, kw => "mil" },
              9 => { descr => "physics terminology", id => 9, kw => "physics" },
              Buddh => 'fix',
              MA => 'fix',
              comp => 'fix',
              food => 'fix',
              geom => 'fix',
              ling => 'fix',
              math => 'fix',
              mil => 'fix',
              physics => 'fix',
            },
    FREQ => {
              1 => { descr => undef, id => 1, kw => "ichi" },
              2 => { descr => undef, id => 2, kw => "gai" },
              4 => { descr => undef, id => 4, kw => "spec" },
              5 => { descr => undef, id => 5, kw => "nf" },
              6 => {
                    descr => "2007-01-14 Google counts (Kale Stutzman)",
                    id => 6,
                    kw => "gA",
                  },
              7 => { descr => undef, id => 7, kw => "news" },
              gA => 'fix',
              gai => 'fix',
              ichi => 'fix',
              news => 'fix',
              nf => 'fix',
              spec => 'fix',
            },
    KINF => {
              1  => { descr => "word containing irregular kanji usage", id => 1, kw => "iK" },
              2  => { descr => "irregular okurigana usage", id => 2, kw => "io" },
              3  => { descr => "word containing out-dated kanji", id => 3, kw => "oK" },
              4  => { descr => "word containing irregular kana usage", id => 4, kw => "ik" },
              iK => 'fix',
              ik => 'fix',
              io => 'fix',
              oK => 'fix',
            },
    LANG => {
              "0"    => { descr => "Japanese", id => 0, kw => "ja" },
              1      => { descr => "English", id => 1, kw => "en" },
              10     => { descr => "Italian", id => 10, kw => "it" },
              11     => { descr => "Korean", id => 11, kw => "ko" },
              12     => { descr => "Latin", id => 12, kw => "lt" },
              13     => { descr => "Dutch", id => 13, kw => "nl" },
              14     => { descr => "Norwegian", id => 14, kw => "no" },
              15     => { descr => "Portuguese", id => 15, kw => "pt" },
              16     => { descr => "Russian", id => 16, kw => "ru" },
              17     => { descr => "Sanskrit", id => 17, kw => "sanskr" },
              18     => { descr => "Ukrainian", id => 18, kw => "uk" },
              19     => { descr => "Chinese (Zhongwen)", id => 19, kw => "zh" },
              2      => { descr => "Aino", id => 2, kw => "ai" },
              20     => { descr => "Hebrew (Iwrith)", id => 20, kw => "iw" },
              21     => { descr => "Polish", id => 21, kw => "pl" },
              22     => { descr => "Swedish", id => 22, kw => "sv" },
              23     => { descr => "Tibetan (Bodskad)", id => 23, kw => "bo" },
              24     => { descr => "Hindi", id => 24, kw => "hi" },
              25     => { descr => "Urdu", id => 25, kw => "ur" },
              26     => { descr => "Mongolian", id => 26, kw => "mn" },
              27     => { descr => "Inuit (formerly Eskimo)", id => 27, kw => "kl" },
              28     => { descr => "Kanuri", id => 28, kw => "kr" },
              29     => { descr => "Sanskrit", id => 29, kw => "sa" },
              3      => { descr => "Arabic", id => 3, kw => "ar" },
              4      => { descr => "German (Deutsch)", id => 4, kw => "de" },
              5      => { descr => "Greek (Ellinika)", id => 5, kw => "el" },
              6      => { descr => "Esperanto", id => 6, kw => "eo" },
              7      => { descr => "Spanish", id => 7, kw => "es" },
              8      => { descr => "French", id => 8, kw => "fr" },
              9      => { descr => "Indonesian", id => 9, kw => "in" },
              ai     => 'fix',
              ar     => 'fix',
              bo     => 'fix',
              de     => 'fix',
              el     => 'fix',
              en     => 'fix',
              eo     => 'fix',
              es     => 'fix',
              fr     => 'fix',
              hi     => 'fix',
              in     => 'fix',
              it     => 'fix',
              iw     => 'fix',
              ja     => 'fix',
              kl     => 'fix',
              ko     => 'fix',
              kr     => 'fix',
              "lt"   => 'fix',
              mn     => 'fix',
              nl     => 'fix',
              "no"   => 'fix',
              pl     => 'fix',
              pt     => 'fix',
              ru     => 'fix',
              sa     => 'fix',
              sanskr => 'fix',
              sv     => 'fix',
              uk     => 'fix',
              ur     => 'fix',
              zh     => 'fix',
            },
    MISC => {
              1         => {
                             descr => "rude or X-rated term (not displayed in educational software)",
                             id => 1,
                             kw => "X",
                           },
              10        => { descr => "gikun (meaning) reading", id => 10, kw => "gikun" },
              11        => {
                             descr => "honorific or respectful (sonkeigo) language",
                             id => 11,
                             kw => "hon",
                           },
              12        => { descr => "humble (kenjougo) language", id => 12, kw => "hum" },
              13        => { descr => "idiomatic expression", id => 13, kw => "id" },
              14        => { descr => "manga slang", id => 14, kw => "m-sl" },
              15        => { descr => "male term or language", id => 15, kw => "male" },
              17        => { descr => "obsolete term", id => 17, kw => "obs" },
              18        => { descr => "obscure term", id => 18, kw => "obsc" },
              19        => { descr => "polite (teineigo) language", id => 19, kw => "pol" },
              2         => { descr => "abbreviation", id => 2, kw => "abbr" },
              20        => { descr => "rare", id => 20, kw => "rare" },
              201       => { descr => "male slang", id => 201, kw => "male-sl" },
              202       => { descr => "ateji (phonetic) reading", id => 202, kw => "ateji" },
              203       => {
                             descr => "word usually written using kanji alone",
                             id => 203,
                             kw => "uK",
                           },
              21        => { descr => "slang", id => 21, kw => "sl" },
              22        => { descr => "word usually written using kana alone", id => 22, kw => "uk" },
              24        => { descr => "vulgar expression or word", id => 24, kw => "vulg" },
              25        => { descr => "sensitive", id => 25, kw => "sens" },
              3         => { descr => "archaism", id => 3, kw => "arch" },
              4         => { descr => "children's language", id => 4, kw => "chn" },
              5         => { descr => "colloquialism", id => 5, kw => "col" },
              6         => { descr => "derogatory", id => 6, kw => "derog" },
              7         => { descr => "exclusively kanji", id => 7, kw => "ek" },
              8         => { descr => "familiar language", id => 8, kw => "fam" },
              81        => { descr => "proverb", id => 81, kw => "proverb" },
              82        => { descr => "aphorism (pithy saying)", id => 82, kw => "aphorism" },
              83        => { descr => "quotation", id => 83, kw => "quote" },
              9         => { descr => "female term or language", id => 9, kw => "fem" },
              X         => 'fix',
              abbr      => 'fix',
              aphorism  => 'fix',
              arch      => 'fix',
              ateji     => 'fix',
              chn       => 'fix',
              col       => 'fix',
              derog     => 'fix',
              ek        => 'fix',
              fam       => 'fix',
              fem       => 'fix',
              gikun     => 'fix',
              hon       => 'fix',
              hum       => 'fix',
              id        => 'fix',
              "m-sl"    => 'fix',
              male      => 'fix',
              "male-sl" => 'fix',
              obs       => 'fix',
              obsc      => 'fix',
              pol       => 'fix',
              proverb   => 'fix',
              quote     => 'fix',
              rare      => 'fix',
              sens      => 'fix',
              sl        => 'fix',
              uK        => 'fix',
              uk        => 'fix',
              vulg      => 'fix',
            },
    POS  => {
              1         => { descr => "adjective (keiyoushi)", id => 1, kw => "adj" },
              10        => { descr => "auxiliary verb", id => 10, kw => "aux-v" },
              12        => { descr => "conjunction", id => 12, kw => "conj" },
              13        => { descr => "Expressions (phrases, clauses, etc.)", id => 13, kw => "exp" },
              14        => { descr => "interjection (kandoushi)", id => 14, kw => "int" },
              17        => { descr => "noun (common) (futsuumeishi)", id => 17, kw => "n" },
              18        => { descr => "adverbial noun (fukushitekimeishi)", id => 18, kw => "n-adv" },
              181       => { descr => "family or surname", id => 181, kw => "surname" },
              182       => { descr => "place name", id => 182, kw => "place" },
              183       => { descr => "unclassified name", id => 183, kw => "unclass" },
              184       => { descr => "company name", id => 184, kw => "company" },
              185       => { descr => "product name", id => 185, kw => "product" },
              186       => { descr => "male given name or forename", id => 186, kw => "masc" },
              187       => { descr => "female given name or forename", id => 187, kw => "fem" },
              188       => { descr => "full name of a particular person", id => 188, kw => "person" },
              189       => {
                             descr => "given name or forename, gender not specified",
                             id => 189,
                             kw => "given",
                           },
              19        => { descr => "noun, used as a suffix", id => 19, kw => "n-suf" },
              190       => { descr => "railway station", id => 190, kw => "station" },
              2         => {
                             descr => "adjectival nouns or quasi-adjectives (keiyodoshi)",
                             id => 2,
                             kw => "adj-na",
                           },
              20        => { descr => "noun, used as a prefix", id => 20, kw => "n-pref" },
              201       => { descr => "adverbial noun", id => 201, kw => "adv-n" },
              202       => { descr => "computer terminology", id => 202, kw => "comp" },
              203       => {
                             descr => "negative (in a negative sentence, or with negative verb)",
                             id => 203,
                             kw => "neg",
                           },
              204       => { descr => "negative verb (when used with)", id => 204, kw => "neg-v" },
              205       => { descr => "irregular okurigana usage", id => 205, kw => "io" },
              206       => { descr => "irregular verb", id => 206, kw => "iv" },
              207       => { descr => "masculine gender", id => 207, kw => "mg" },
              208       => { descr => "feminine gender", id => 208, kw => "fg" },
              209       => { descr => "neuter gender", id => 209, kw => "ng" },
              21        => { descr => "noun (temporal) (jisoumeishi)", id => 21, kw => "n-t" },
              24        => { descr => "numeric", id => 24, kw => "num" },
              25        => { descr => "prefix", id => 25, kw => "pref" },
              26        => { descr => "particle", id => 26, kw => "prt" },
              27        => { descr => "suffix", id => 27, kw => "suf" },
              28        => { descr => "Ichidan verb", id => 28, kw => "v1" },
              29        => { descr => "Godan verb (not completely classified)", id => 29, kw => "v5" },
              3         => {
                             descr => "nouns which may take the genitive case particle `no'",
                             id => 3,
                             kw => "adj-no",
                           },
              30        => { descr => "Godan verb - -aru special class", id => 30, kw => "v5aru" },
              301       => { descr => "copula", id => 301, kw => "cop" },
              302       => { descr => "counter", id => 302, kw => "cnt" },
              303       => {
                             descr => "like v1 but no potential, passive, causative forms",
                             id => 303,
                             kw => "v1x",
                           },
              304       => {
                             descr => "like v5k but no potential, passive, causative forms",
                             id => 304,
                             kw => "v5kx",
                           },
              305       => {
                             descr => "like v5r but no potential, passive, causative forms",
                             id => 305,
                             kw => "v5rx",
                           },
              306       => {
                             descr => "like v5m but no potential, causative forms",
                             id => 306,
                             kw => "v5mx",
                           },
              307       => {
                             descr => "like v1 but no potential, causative forms",
                             id => 307,
                             kw => "v5ux",
                           },
              308       => { descr => "like v5r but no potential form", id => 308, kw => "v5ry" },
              309       => { descr => "demonstrative pronoun", id => 309, kw => "demo" },
              31        => { descr => "Godan verb with `bu' ending", id => 31, kw => "v5b" },
              310       => { descr => "pronoun", id => 310, kw => "pron" },
              311       => { descr => "noun, positional", id => 311, kw => "n-loc" },
              312       => { descr => "interogative", id => 312, kw => "intr" },
              313       => { descr => "affermative form", id => 313, kw => "aff" },
              314       => { descr => "negative form", id => 314, kw => "naff" },
              315       => { descr => "formal (polite) form", id => 315, kw => "infml" },
              316       => { descr => "informal (plain) form", id => 316, kw => "fml" },
              317       => { descr => "infl - dictionary form", id => 317, kw => "dict" },
              318       => { descr => "infl - past form", id => 318, kw => "past" },
              319       => { descr => "infl - te-form", id => 319, kw => "te" },
              32        => { descr => "Godan verb with `gu' ending", id => 32, kw => "v5g" },
              320       => { descr => "infl - te-form (alt)", id => 320, kw => "te2" },
              321       => { descr => "infl - conditional form", id => 321, kw => "cond" },
              322       => { descr => "infl - provisional", id => 322, kw => "prov" },
              323       => { descr => "infl - potential", id => 323, kw => "poten" },
              324       => { descr => "infl - passive", id => 324, kw => "pass" },
              325       => { descr => "infl - causative", id => 325, kw => "cause" },
              326       => { descr => "infl - causative (alt)", id => 326, kw => "cause2" },
              327       => { descr => "infl - causative-passive", id => 327, kw => "cp" },
              328       => { descr => "infl - volitional-hortative", id => 328, kw => "vh" },
              329       => { descr => "infl - volitional-hortative (alt)", id => 329, kw => "vh2" },
              33        => { descr => "Godan verb with `ku' ending", id => 33, kw => "v5k" },
              330       => { descr => "infl - conjectural", id => 330, kw => "conjec" },
              331       => { descr => "infl - alternative", id => 331, kw => "alt" },
              332       => { descr => "infl - imperative", id => 332, kw => "imp" },
              34        => { descr => "Godan verb - Iku/Yuku special class", id => 34, kw => "v5k-s" },
              35        => { descr => "Godan verb with `mu' ending", id => 35, kw => "v5m" },
              36        => { descr => "Godan verb with `nu' ending", id => 36, kw => "v5n" },
              37        => { descr => "Godan verb with `ru' ending", id => 37, kw => "v5r" },
              38        => {
                             descr => "Godan verb with `ru' ending (irregular verb)",
                             id => 38,
                             kw => "v5r-i",
                           },
              39        => { descr => "Godan verb with `su' ending", id => 39, kw => "v5s" },
              4         => { descr => "pre-noun adjectival (rentaishi)", id => 4, kw => "adj-pn" },
              40        => { descr => "Godan verb with `tsu' ending", id => 40, kw => "v5t" },
              41        => { descr => "Godan verb with `u' ending", id => 41, kw => "v5u" },
              42        => {
                             descr => "Godan verb with `u' ending (special class)",
                             id => 42,
                             kw => "v5u-s",
                           },
              43        => {
                             descr => "Godan verb - Uru old class verb (old form of Eru)",
                             id => 43,
                             kw => "v5uru",
                           },
              44        => { descr => "intransitive verb", id => 44, kw => "vi" },
              45        => { descr => "Kuru verb - special class", id => 45, kw => "vk" },
              46        => {
                             descr => "noun or participle which takes the aux. verb suru",
                             id => 46,
                             kw => "vs",
                           },
              47        => { descr => "suru verb - special class", id => 47, kw => "vs-s" },
              48        => { descr => "suru verb - irregular", id => 48, kw => "vs-i" },
              49        => {
                             descr => "zuru verb - (alternative form of -jiru verbs)",
                             id => 49,
                             kw => "vz",
                           },
              5         => { descr => "`taru' adjective", id => 5, kw => "adj-t" },
              50        => { descr => "transitive verb", id => 50, kw => "vt" },
              54        => { descr => "auxiliary adjective", id => 54, kw => "aux-adj" },
              6         => { descr => "adverb (fukushi)", id => 6, kw => "adv" },
              8         => { descr => "adverb taking the `to' particle", id => 8, kw => "adv-to" },
              9         => { descr => "auxiliary", id => 9, kw => "aux" },
              adj       => 'fix',
              "adj-na"  => 'fix',
              "adj-no"  => 'fix',
              "adj-pn"  => 'fix',
              "adj-t"   => 'fix',
              adv       => 'fix',
              "adv-n"   => 'fix',
              "adv-to"  => 'fix',
              aff       => 'fix',
              alt       => 'fix',
              aux       => 'fix',
              "aux-adj" => 'fix',
              "aux-v"   => 'fix',
              cause     => 'fix',
              cause2    => 'fix',
              cnt       => 'fix',
              comp      => 'fix',
              company   => 'fix',
              cond      => 'fix',
              conj      => 'fix',
              conjec    => 'fix',
              cop       => 'fix',
              cp        => 'fix',
              demo      => 'fix',
              dict      => 'fix',
              "exp"     => 'fix',
              fem       => 'fix',
              fg        => 'fix',
              fml       => 'fix',
              given     => 'fix',
              imp       => 'fix',
              infml     => 'fix',
              "int"     => 'fix',
              intr      => 'fix',
              io        => 'fix',
              iv        => 'fix',
              masc      => 'fix',
              mg        => 'fix',
              n         => 'fix',
              "n-adv"   => 'fix',
              "n-loc"   => 'fix',
              "n-pref"  => 'fix',
              "n-suf"   => 'fix',
              "n-t"     => 'fix',
              naff      => 'fix',
              neg       => 'fix',
              "neg-v"   => 'fix',
              ng        => 'fix',
              num       => 'fix',
              pass      => 'fix',
              past      => 'fix',
              person    => 'fix',
              place     => 'fix',
              poten     => 'fix',
              pref      => 'fix',
              product   => 'fix',
              pron      => 'fix',
              prov      => 'fix',
              prt       => 'fix',
              station   => 'fix',
              suf       => 'fix',
              surname   => 'fix',
              te        => 'fix',
              te2       => 'fix',
              unclass   => 'fix',
              v1        => 'fix',
              v1x       => 'fix',
              v5        => 'fix',
              v5aru     => 'fix',
              v5b       => 'fix',
              v5g       => 'fix',
              v5k       => 'fix',
              "v5k-s"   => 'fix',
              v5kx      => 'fix',
              v5m       => 'fix',
              v5mx      => 'fix',
              v5n       => 'fix',
              v5r       => 'fix',
              "v5r-i"   => 'fix',
              v5rx      => 'fix',
              v5ry      => 'fix',
              v5s       => 'fix',
              v5t       => 'fix',
              v5u       => 'fix',
              "v5u-s"   => 'fix',
              v5uru     => 'fix',
              v5ux      => 'fix',
              vh        => 'fix',
              vh2       => 'fix',
              vi        => 'fix',
              vk        => 'fix',
              vs        => 'fix',
              "vs-i"    => 'fix',
              "vs-s"    => 'fix',
              vt        => 'fix',
              vz        => 'fix',
            },
    RINF => {
              1 => { descr => "ateji (phonetic) reading", id => 1, kw => "ateji" },
              2 => { descr => "gikun (meaning) reading", id => 2, kw => "gikun" },
              201 => { descr => "rare", id => 201, kw => "rare" },
              202 => { descr => "word usually written using kana alone", id => 202, kw => "uk" },
              3 => { descr => "out-dated or obsolete kana usage", id => 3, kw => "ok" },
              4 => { descr => "word containing irregular kana usage", id => 4, kw => "ik" },
              5 => { descr => "word usually written using kanji alone", id => 5, kw => "uK" },
              ateji => 'fix',
              gikun => 'fix',
              ik => 'fix',
              ok => 'fix',
              rare => 'fix',
              uK => 'fix',
              uk => 'fix',
            },
    SRC  => {
              1        => {
                            descr => "Entry from the JMdict file",
                            id => 1,
                            info => undef,
                            kw => "jmdict",
                          },
              2        => {
                            descr => "Entry from the JMnedict (names) file",
                            id => 2,
                            info => undef,
                            kw => "jmnedict",
                          },
              3        => {
                            descr => "Entry from the Examples_s file",
                            id => 3,
                            info => undef,
                            kw => "examples",
                          },
              examples => 'fix',
              jmdict   => 'fix',
              jmnedict => 'fix',
            },
    STAT => {
              1 => { descr => "New, approval pending", id => 1, kw => "N" },
              2 => { descr => "Active", id => 2, kw => "A" },
              3 => { descr => "Modified, approval pending", id => 3, kw => "M" },
              4 => { descr => "Deleted", id => 4, kw => "X" },
              5 => { descr => "Deleted, approval pending", id => 5, kw => "D" },
              6 => { descr => "Obsoleted", id => 6, kw => "O" },
              8 => { descr => "Rejected", id => 8, kw => "R" },
              A => 'fix',
              D => 'fix',
              M => 'fix',
              N => 'fix',
              O => 'fix',
              R => 'fix',
              X => 'fix',
            },
    XREF => {
              1 => { descr => "Synonym", id => 1, kw => "syn" },
              2 => { descr => "Antonym", id => 2, kw => "ant" },
              3 => { descr => "See also", id => 3, kw => "see" },
              4 => { descr => "c.f.", id => 4, kw => "cf" },
              5 => { descr => "Usage example", id => 5, kw => "ex" },
              6 => { descr => "Uses", id => 6, kw => "uses" },
              7 => { descr => "Preferred", id => 7, kw => "pref" },
              ant => 'fix',
              cf => 'fix',
              ex => 'fix',
              pref => 'fix',
              see => 'fix',
              syn => 'fix',
              uses => 'fix',
            },
  };
  $a->{DIAL}{ksb} = $a->{DIAL}{2};
  $a->{DIAL}{ktb} = $a->{DIAL}{3};
  $a->{DIAL}{kyb} = $a->{DIAL}{4};
  $a->{DIAL}{osb} = $a->{DIAL}{5};
  $a->{DIAL}{std} = $a->{DIAL}{1};
  $a->{DIAL}{thb} = $a->{DIAL}{7};
  $a->{DIAL}{tsb} = $a->{DIAL}{6};
  $a->{DIAL}{tsug} = $a->{DIAL}{8};
  $a->{FLD}{Buddh} = $a->{FLD}{1};
  $a->{FLD}{MA} = $a->{FLD}{6};
  $a->{FLD}{comp} = $a->{FLD}{2};
  $a->{FLD}{food} = $a->{FLD}{3};
  $a->{FLD}{geom} = $a->{FLD}{4};
  $a->{FLD}{ling} = $a->{FLD}{5};
  $a->{FLD}{math} = $a->{FLD}{7};
  $a->{FLD}{mil} = $a->{FLD}{8};
  $a->{FLD}{physics} = $a->{FLD}{9};
  $a->{FREQ}{gA} = $a->{FREQ}{6};
  $a->{FREQ}{gai} = $a->{FREQ}{2};
  $a->{FREQ}{ichi} = $a->{FREQ}{1};
  $a->{FREQ}{news} = $a->{FREQ}{7};
  $a->{FREQ}{nf} = $a->{FREQ}{5};
  $a->{FREQ}{spec} = $a->{FREQ}{4};
  $a->{KINF}{iK} = $a->{KINF}{1};
  $a->{KINF}{ik} = $a->{KINF}{4};
  $a->{KINF}{io} = $a->{KINF}{2};
  $a->{KINF}{oK} = $a->{KINF}{3};
  $a->{LANG}{ai} = $a->{LANG}{2};
  $a->{LANG}{ar} = $a->{LANG}{3};
  $a->{LANG}{bo} = $a->{LANG}{23};
  $a->{LANG}{de} = $a->{LANG}{4};
  $a->{LANG}{el} = $a->{LANG}{5};
  $a->{LANG}{en} = $a->{LANG}{1};
  $a->{LANG}{eo} = $a->{LANG}{6};
  $a->{LANG}{es} = $a->{LANG}{7};
  $a->{LANG}{fr} = $a->{LANG}{8};
  $a->{LANG}{hi} = $a->{LANG}{24};
  $a->{LANG}{in} = $a->{LANG}{9};
  $a->{LANG}{it} = $a->{LANG}{10};
  $a->{LANG}{iw} = $a->{LANG}{20};
  $a->{LANG}{ja} = $a->{LANG}{"0"};
  $a->{LANG}{kl} = $a->{LANG}{27};
  $a->{LANG}{ko} = $a->{LANG}{11};
  $a->{LANG}{kr} = $a->{LANG}{28};
  $a->{LANG}{"lt"} = $a->{LANG}{12};
  $a->{LANG}{mn} = $a->{LANG}{26};
  $a->{LANG}{nl} = $a->{LANG}{13};
  $a->{LANG}{"no"} = $a->{LANG}{14};
  $a->{LANG}{pl} = $a->{LANG}{21};
  $a->{LANG}{pt} = $a->{LANG}{15};
  $a->{LANG}{ru} = $a->{LANG}{16};
  $a->{LANG}{sa} = $a->{LANG}{29};
  $a->{LANG}{sanskr} = $a->{LANG}{17};
  $a->{LANG}{sv} = $a->{LANG}{22};
  $a->{LANG}{uk} = $a->{LANG}{18};
  $a->{LANG}{ur} = $a->{LANG}{25};
  $a->{LANG}{zh} = $a->{LANG}{19};
  $a->{MISC}{X} = $a->{MISC}{1};
  $a->{MISC}{abbr} = $a->{MISC}{2};
  $a->{MISC}{aphorism} = $a->{MISC}{82};
  $a->{MISC}{arch} = $a->{MISC}{3};
  $a->{MISC}{ateji} = $a->{MISC}{202};
  $a->{MISC}{chn} = $a->{MISC}{4};
  $a->{MISC}{col} = $a->{MISC}{5};
  $a->{MISC}{derog} = $a->{MISC}{6};
  $a->{MISC}{ek} = $a->{MISC}{7};
  $a->{MISC}{fam} = $a->{MISC}{8};
  $a->{MISC}{fem} = $a->{MISC}{9};
  $a->{MISC}{gikun} = $a->{MISC}{10};
  $a->{MISC}{hon} = $a->{MISC}{11};
  $a->{MISC}{hum} = $a->{MISC}{12};
  $a->{MISC}{id} = $a->{MISC}{13};
  $a->{MISC}{"m-sl"} = $a->{MISC}{14};
  $a->{MISC}{male} = $a->{MISC}{15};
  $a->{MISC}{"male-sl"} = $a->{MISC}{201};
  $a->{MISC}{obs} = $a->{MISC}{17};
  $a->{MISC}{obsc} = $a->{MISC}{18};
  $a->{MISC}{pol} = $a->{MISC}{19};
  $a->{MISC}{proverb} = $a->{MISC}{81};
  $a->{MISC}{quote} = $a->{MISC}{83};
  $a->{MISC}{rare} = $a->{MISC}{20};
  $a->{MISC}{sens} = $a->{MISC}{25};
  $a->{MISC}{sl} = $a->{MISC}{21};
  $a->{MISC}{uK} = $a->{MISC}{203};
  $a->{MISC}{uk} = $a->{MISC}{22};
  $a->{MISC}{vulg} = $a->{MISC}{24};
  $a->{POS}{adj} = $a->{POS}{1};
  $a->{POS}{"adj-na"} = $a->{POS}{2};
  $a->{POS}{"adj-no"} = $a->{POS}{3};
  $a->{POS}{"adj-pn"} = $a->{POS}{4};
  $a->{POS}{"adj-t"} = $a->{POS}{5};
  $a->{POS}{adv} = $a->{POS}{6};
  $a->{POS}{"adv-n"} = $a->{POS}{201};
  $a->{POS}{"adv-to"} = $a->{POS}{8};
  $a->{POS}{aff} = $a->{POS}{313};
  $a->{POS}{alt} = $a->{POS}{331};
  $a->{POS}{aux} = $a->{POS}{9};
  $a->{POS}{"aux-adj"} = $a->{POS}{54};
  $a->{POS}{"aux-v"} = $a->{POS}{10};
  $a->{POS}{cause} = $a->{POS}{325};
  $a->{POS}{cause2} = $a->{POS}{326};
  $a->{POS}{cnt} = $a->{POS}{302};
  $a->{POS}{comp} = $a->{POS}{202};
  $a->{POS}{company} = $a->{POS}{184};
  $a->{POS}{cond} = $a->{POS}{321};
  $a->{POS}{conj} = $a->{POS}{12};
  $a->{POS}{conjec} = $a->{POS}{330};
  $a->{POS}{cop} = $a->{POS}{301};
  $a->{POS}{cp} = $a->{POS}{327};
  $a->{POS}{demo} = $a->{POS}{309};
  $a->{POS}{dict} = $a->{POS}{317};
  $a->{POS}{"exp"} = $a->{POS}{13};
  $a->{POS}{fem} = $a->{POS}{187};
  $a->{POS}{fg} = $a->{POS}{208};
  $a->{POS}{fml} = $a->{POS}{316};
  $a->{POS}{given} = $a->{POS}{189};
  $a->{POS}{imp} = $a->{POS}{332};
  $a->{POS}{infml} = $a->{POS}{315};
  $a->{POS}{"int"} = $a->{POS}{14};
  $a->{POS}{intr} = $a->{POS}{312};
  $a->{POS}{io} = $a->{POS}{205};
  $a->{POS}{iv} = $a->{POS}{206};
  $a->{POS}{masc} = $a->{POS}{186};
  $a->{POS}{mg} = $a->{POS}{207};
  $a->{POS}{n} = $a->{POS}{17};
  $a->{POS}{"n-adv"} = $a->{POS}{18};
  $a->{POS}{"n-loc"} = $a->{POS}{311};
  $a->{POS}{"n-pref"} = $a->{POS}{20};
  $a->{POS}{"n-suf"} = $a->{POS}{19};
  $a->{POS}{"n-t"} = $a->{POS}{21};
  $a->{POS}{naff} = $a->{POS}{314};
  $a->{POS}{neg} = $a->{POS}{203};
  $a->{POS}{"neg-v"} = $a->{POS}{204};
  $a->{POS}{ng} = $a->{POS}{209};
  $a->{POS}{num} = $a->{POS}{24};
  $a->{POS}{pass} = $a->{POS}{324};
  $a->{POS}{past} = $a->{POS}{318};
  $a->{POS}{person} = $a->{POS}{188};
  $a->{POS}{place} = $a->{POS}{182};
  $a->{POS}{poten} = $a->{POS}{323};
  $a->{POS}{pref} = $a->{POS}{25};
  $a->{POS}{product} = $a->{POS}{185};
  $a->{POS}{pron} = $a->{POS}{310};
  $a->{POS}{prov} = $a->{POS}{322};
  $a->{POS}{prt} = $a->{POS}{26};
  $a->{POS}{station} = $a->{POS}{190};
  $a->{POS}{suf} = $a->{POS}{27};
  $a->{POS}{surname} = $a->{POS}{181};
  $a->{POS}{te} = $a->{POS}{319};
  $a->{POS}{te2} = $a->{POS}{320};
  $a->{POS}{unclass} = $a->{POS}{183};
  $a->{POS}{v1} = $a->{POS}{28};
  $a->{POS}{v1x} = $a->{POS}{303};
  $a->{POS}{v5} = $a->{POS}{29};
  $a->{POS}{v5aru} = $a->{POS}{30};
  $a->{POS}{v5b} = $a->{POS}{31};
  $a->{POS}{v5g} = $a->{POS}{32};
  $a->{POS}{v5k} = $a->{POS}{33};
  $a->{POS}{"v5k-s"} = $a->{POS}{34};
  $a->{POS}{v5kx} = $a->{POS}{304};
  $a->{POS}{v5m} = $a->{POS}{35};
  $a->{POS}{v5mx} = $a->{POS}{306};
  $a->{POS}{v5n} = $a->{POS}{36};
  $a->{POS}{v5r} = $a->{POS}{37};
  $a->{POS}{"v5r-i"} = $a->{POS}{38};
  $a->{POS}{v5rx} = $a->{POS}{305};
  $a->{POS}{v5ry} = $a->{POS}{308};
  $a->{POS}{v5s} = $a->{POS}{39};
  $a->{POS}{v5t} = $a->{POS}{40};
  $a->{POS}{v5u} = $a->{POS}{41};
  $a->{POS}{"v5u-s"} = $a->{POS}{42};
  $a->{POS}{v5uru} = $a->{POS}{43};
  $a->{POS}{v5ux} = $a->{POS}{307};
  $a->{POS}{vh} = $a->{POS}{328};
  $a->{POS}{vh2} = $a->{POS}{329};
  $a->{POS}{vi} = $a->{POS}{44};
  $a->{POS}{vk} = $a->{POS}{45};
  $a->{POS}{vs} = $a->{POS}{46};
  $a->{POS}{"vs-i"} = $a->{POS}{48};
  $a->{POS}{"vs-s"} = $a->{POS}{47};
  $a->{POS}{vt} = $a->{POS}{50};
  $a->{POS}{vz} = $a->{POS}{49};
  $a->{RINF}{ateji} = $a->{RINF}{1};
  $a->{RINF}{gikun} = $a->{RINF}{2};
  $a->{RINF}{ik} = $a->{RINF}{4};
  $a->{RINF}{ok} = $a->{RINF}{3};
  $a->{RINF}{rare} = $a->{RINF}{201};
  $a->{RINF}{uK} = $a->{RINF}{5};
  $a->{RINF}{uk} = $a->{RINF}{202};
  $a->{SRC}{examples} = $a->{SRC}{3};
  $a->{SRC}{jmdict} = $a->{SRC}{1};
  $a->{SRC}{jmnedict} = $a->{SRC}{2};
  $a->{STAT}{A} = $a->{STAT}{2};
  $a->{STAT}{D} = $a->{STAT}{5};
  $a->{STAT}{M} = $a->{STAT}{3};
  $a->{STAT}{N} = $a->{STAT}{1};
  $a->{STAT}{O} = $a->{STAT}{6};
  $a->{STAT}{R} = $a->{STAT}{8};
  $a->{STAT}{X} = $a->{STAT}{4};
  $a->{XREF}{ant} = $a->{XREF}{2};
  $a->{XREF}{cf} = $a->{XREF}{4};
  $a->{XREF}{ex} = $a->{XREF}{5};
  $a->{XREF}{pref} = $a->{XREF}{7};
  $a->{XREF}{see} = $a->{XREF}{3};
  $a->{XREF}{syn} = $a->{XREF}{1};
  $a->{XREF}{uses} = $a->{XREF}{6};
  $a;
}; 

1;
