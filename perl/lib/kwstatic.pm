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
    @EXPORT   = qw($Kdws $KWGINF_equ $KWGINF_expl $KWGINF_id $KWGINF_lit $KWMISC_X $KWMISC_abbr $KWMISC_aphorism $KWMISC_arch $KWMISC_chn $KWMISC_col $KWMISC_derog $KWMISC_eK $KWMISC_fam $KWMISC_fem $KWMISC_hon $KWMISC_hum $KWMISC_id $KWMISC_m_sl $KWMISC_male $KWMISC_obs $KWMISC_obsc $KWMISC_poet $KWMISC_pol $KWMISC_proverb $KWMISC_quote $KWMISC_rare $KWMISC_sens $KWMISC_sl $KWMISC_uk $KWMISC_vulg $KWFREQ_gA $KWFREQ_gai $KWFREQ_ichi $KWFREQ_news $KWFREQ_nf $KWFREQ_spec $KWXREF_ant $KWXREF_cf $KWXREF_ex $KWXREF_kvar $KWXREF_pref $KWXREF_see $KWXREF_syn $KWXREF_uses $KWSTAT_A $KWSTAT_D $KWSTAT_N $KWSTAT_R $KWRINF_gikun $KWRINF_go $KWRINF_ik $KWRINF_jouyou $KWRINF_kan $KWRINF_kanyou $KWRINF_kun $KWRINF_name $KWRINF_ok $KWRINF_on $KWRINF_rad $KWRINF_tou $KWRINF_uK $KWKINF_ateji $KWKINF_iK $KWKINF_ik $KWKINF_io $KWKINF_oK $KWCINF_busy_people $KWCINF_crowley $KWCINF_deroo $KWCINF_four_corner $KWCINF_gakken $KWCINF_halpern_kkld $KWCINF_halpern_njecd $KWCINF_heisig $KWCINF_henshall $KWCINF_henshall3 $KWCINF_jf_cards $KWCINF_jis208 $KWCINF_jis212 $KWCINF_jis213 $KWCINF_kanji_in_ctx $KWCINF_kodansha_comp $KWCINF_korean_h $KWCINF_korean_r $KWCINF_misclass $KWCINF_moro $KWCINF_nelson_c $KWCINF_nelson_n $KWCINF_nelson_rad $KWCINF_oneill_kk $KWCINF_oneill_names $KWCINF_pinyin $KWCINF_s_h $KWCINF_sakade $KWCINF_sh_desc $KWCINF_sh_kk $KWCINF_skip $KWCINF_skip_mis $KWCINF_strokes $KWCINF_tutt_cards $KWFLD_Buddh $KWFLD_MA $KWFLD_comp $KWFLD_food $KWFLD_geom $KWFLD_ling $KWFLD_math $KWFLD_mil $KWFLD_physics $KWLANG_aa $KWLANG_ab $KWLANG_ae $KWLANG_af $KWLANG_ain $KWLANG_ak $KWLANG_am $KWLANG_an $KWLANG_ar $KWLANG_as $KWLANG_av $KWLANG_ay $KWLANG_az $KWLANG_ba $KWLANG_be $KWLANG_bg $KWLANG_bi $KWLANG_bm $KWLANG_bn $KWLANG_bo $KWLANG_br $KWLANG_bs $KWLANG_ca $KWLANG_ce $KWLANG_ch $KWLANG_co $KWLANG_cr $KWLANG_cs $KWLANG_cu $KWLANG_cv $KWLANG_cy $KWLANG_da $KWLANG_de $KWLANG_dv $KWLANG_dz $KWLANG_ee $KWLANG_el $KWLANG_en $KWLANG_eo $KWLANG_es $KWLANG_et $KWLANG_eu $KWLANG_fa $KWLANG_ff $KWLANG_fi $KWLANG_fj $KWLANG_fo $KWLANG_fr $KWLANG_fy $KWLANG_ga $KWLANG_gd $KWLANG_gl $KWLANG_gn $KWLANG_gu $KWLANG_gv $KWLANG_ha $KWLANG_he $KWLANG_hi $KWLANG_ho $KWLANG_hr $KWLANG_ht $KWLANG_hu $KWLANG_hy $KWLANG_hz $KWLANG_ia $KWLANG_id $KWLANG_ie $KWLANG_ig $KWLANG_ii $KWLANG_ik $KWLANG_io $KWLANG_is $KWLANG_it $KWLANG_iu $KWLANG_ja $KWLANG_jv $KWLANG_ka $KWLANG_kg $KWLANG_ki $KWLANG_kj $KWLANG_kk $KWLANG_kl $KWLANG_km $KWLANG_kn $KWLANG_ko $KWLANG_kr $KWLANG_ks $KWLANG_ku $KWLANG_kv $KWLANG_kw $KWLANG_ky $KWLANG_la $KWLANG_lb $KWLANG_lg $KWLANG_li $KWLANG_ln $KWLANG_lo $KWLANG_lt $KWLANG_lu $KWLANG_lv $KWLANG_mg $KWLANG_mh $KWLANG_mi $KWLANG_mk $KWLANG_ml $KWLANG_mn $KWLANG_mo $KWLANG_mr $KWLANG_ms $KWLANG_mt $KWLANG_my $KWLANG_na $KWLANG_nb $KWLANG_nd $KWLANG_ne $KWLANG_ng $KWLANG_nl $KWLANG_nn $KWLANG_no $KWLANG_nr $KWLANG_nv $KWLANG_ny $KWLANG_oc $KWLANG_oj $KWLANG_om $KWLANG_or $KWLANG_os $KWLANG_pa $KWLANG_pi $KWLANG_pl $KWLANG_ps $KWLANG_pt $KWLANG_qu $KWLANG_rm $KWLANG_rn $KWLANG_ro $KWLANG_ru $KWLANG_rw $KWLANG_sa $KWLANG_sc $KWLANG_sd $KWLANG_se $KWLANG_sg $KWLANG_sh $KWLANG_si $KWLANG_sk $KWLANG_sl $KWLANG_sm $KWLANG_sn $KWLANG_so $KWLANG_sq $KWLANG_sr $KWLANG_ss $KWLANG_st $KWLANG_su $KWLANG_sv $KWLANG_sw $KWLANG_ta $KWLANG_te $KWLANG_tg $KWLANG_th $KWLANG_ti $KWLANG_tk $KWLANG_tl $KWLANG_tn $KWLANG_to $KWLANG_tr $KWLANG_ts $KWLANG_tt $KWLANG_tw $KWLANG_ty $KWLANG_ug $KWLANG_uk $KWLANG_ur $KWLANG_uz $KWLANG_ve $KWLANG_vi $KWLANG_vo $KWLANG_wa $KWLANG_wo $KWLANG_xh $KWLANG_yi $KWLANG_yo $KWLANG_za $KWLANG_zh $KWLANG_zu $KWDIAL_ksb $KWDIAL_ktb $KWDIAL_kyb $KWDIAL_kyu $KWDIAL_osb $KWDIAL_std $KWDIAL_thb $KWDIAL_tsb $KWDIAL_tsug $KWPOS_adj $KWPOS_adj_na $KWPOS_adj_no $KWPOS_adj_pn $KWPOS_adj_t $KWPOS_adv $KWPOS_adv_to $KWPOS_aux $KWPOS_aux_adj $KWPOS_aux_v $KWPOS_company $KWPOS_conj $KWPOS_ctr $KWPOS_exp $KWPOS_fem $KWPOS_given $KWPOS_int $KWPOS_masc $KWPOS_n $KWPOS_n_adv $KWPOS_n_pref $KWPOS_n_suf $KWPOS_n_t $KWPOS_num $KWPOS_person $KWPOS_place $KWPOS_pref $KWPOS_product $KWPOS_prt $KWPOS_station $KWPOS_suf $KWPOS_surname $KWPOS_unclass $KWPOS_v1 $KWPOS_v4r $KWPOS_v5 $KWPOS_v5aru $KWPOS_v5b $KWPOS_v5g $KWPOS_v5k $KWPOS_v5k_s $KWPOS_v5m $KWPOS_v5n $KWPOS_v5r $KWPOS_v5r_i $KWPOS_v5s $KWPOS_v5t $KWPOS_v5u $KWPOS_v5u_s $KWPOS_v5uru $KWPOS_v5z $KWPOS_vi $KWPOS_vk $KWPOS_vn $KWPOS_vs $KWPOS_vs_i $KWPOS_vs_s $KWPOS_vt $KWPOS_vz); }

our (@EXPORT);

our($KWGINF_equ) = 1;
our($KWGINF_expl) = 4;
our($KWGINF_id) = 3;
our($KWGINF_lit) = 2;
our($KWMISC_X) = 1;
our($KWMISC_abbr) = 2;
our($KWMISC_aphorism) = 82;
our($KWMISC_arch) = 3;
our($KWMISC_chn) = 4;
our($KWMISC_col) = 5;
our($KWMISC_derog) = 6;
our($KWMISC_eK) = 7;
our($KWMISC_fam) = 8;
our($KWMISC_fem) = 9;
our($KWMISC_hon) = 11;
our($KWMISC_hum) = 12;
our($KWMISC_id) = 13;
our($KWMISC_m_sl) = 14;
our($KWMISC_male) = 15;
our($KWMISC_obs) = 17;
our($KWMISC_obsc) = 18;
our($KWMISC_poet) = 26;
our($KWMISC_pol) = 19;
our($KWMISC_proverb) = 81;
our($KWMISC_quote) = 83;
our($KWMISC_rare) = 20;
our($KWMISC_sens) = 25;
our($KWMISC_sl) = 21;
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
our($KWXREF_kvar) = 8;
our($KWXREF_pref) = 7;
our($KWXREF_see) = 3;
our($KWXREF_syn) = 1;
our($KWXREF_uses) = 6;
our($KWSTAT_A) = 2;
our($KWSTAT_D) = 4;
our($KWSTAT_N) = 1;
our($KWSTAT_R) = 6;
our($KWRINF_gikun) = 1;
our($KWRINF_go) = 130;
our($KWRINF_ik) = 3;
our($KWRINF_jouyou) = 105;
our($KWRINF_kan) = 129;
our($KWRINF_kanyou) = 132;
our($KWRINF_kun) = 106;
our($KWRINF_name) = 103;
our($KWRINF_ok) = 2;
our($KWRINF_on) = 128;
our($KWRINF_rad) = 104;
our($KWRINF_tou) = 131;
our($KWRINF_uK) = 4;
our($KWKINF_ateji) = 5;
our($KWKINF_iK) = 1;
our($KWKINF_ik) = 4;
our($KWKINF_io) = 2;
our($KWKINF_oK) = 3;
our($KWCINF_busy_people) = 16;
our($KWCINF_crowley) = 14;
our($KWCINF_deroo) = 21;
our($KWCINF_four_corner) = 20;
our($KWCINF_gakken) = 6;
our($KWCINF_halpern_kkld) = 4;
our($KWCINF_halpern_njecd) = 3;
our($KWCINF_heisig) = 5;
our($KWCINF_henshall) = 10;
our($KWCINF_henshall3) = 28;
our($KWCINF_jf_cards) = 31;
our($KWCINF_jis208) = 25;
our($KWCINF_jis212) = 26;
our($KWCINF_jis213) = 27;
our($KWCINF_kanji_in_ctx) = 15;
our($KWCINF_kodansha_comp) = 17;
our($KWCINF_korean_h) = 29;
our($KWCINF_korean_r) = 30;
our($KWCINF_misclass) = 22;
our($KWCINF_moro) = 9;
our($KWCINF_nelson_c) = 1;
our($KWCINF_nelson_n) = 2;
our($KWCINF_nelson_rad) = 32;
our($KWCINF_oneill_kk) = 8;
our($KWCINF_oneill_names) = 7;
our($KWCINF_pinyin) = 23;
our($KWCINF_s_h) = 34;
our($KWCINF_sakade) = 12;
our($KWCINF_sh_desc) = 19;
our($KWCINF_sh_kk) = 11;
our($KWCINF_skip) = 18;
our($KWCINF_skip_mis) = 33;
our($KWCINF_strokes) = 24;
our($KWCINF_tutt_cards) = 13;
our($KWFLD_Buddh) = 1;
our($KWFLD_MA) = 6;
our($KWFLD_comp) = 2;
our($KWFLD_food) = 3;
our($KWFLD_geom) = 4;
our($KWFLD_ling) = 5;
our($KWFLD_math) = 7;
our($KWFLD_mil) = 8;
our($KWFLD_physics) = 9;
our($KWLANG_aa) = 3;
our($KWLANG_ab) = 4;
our($KWLANG_ae) = 12;
our($KWLANG_af) = 5;
our($KWLANG_ain) = 2;
our($KWLANG_ak) = 6;
our($KWLANG_am) = 7;
our($KWLANG_an) = 9;
our($KWLANG_ar) = 8;
our($KWLANG_as) = 10;
our($KWLANG_av) = 11;
our($KWLANG_ay) = 13;
our($KWLANG_az) = 14;
our($KWLANG_ba) = 15;
our($KWLANG_be) = 17;
our($KWLANG_bg) = 23;
our($KWLANG_bi) = 19;
our($KWLANG_bm) = 16;
our($KWLANG_bn) = 18;
our($KWLANG_bo) = 20;
our($KWLANG_br) = 22;
our($KWLANG_bs) = 21;
our($KWLANG_ca) = 24;
our($KWLANG_ce) = 27;
our($KWLANG_ch) = 26;
our($KWLANG_co) = 31;
our($KWLANG_cr) = 32;
our($KWLANG_cs) = 25;
our($KWLANG_cu) = 28;
our($KWLANG_cv) = 29;
our($KWLANG_cy) = 33;
our($KWLANG_da) = 34;
our($KWLANG_de) = 35;
our($KWLANG_dv) = 36;
our($KWLANG_dz) = 37;
our($KWLANG_ee) = 42;
our($KWLANG_el) = 38;
our($KWLANG_en) = 1;
our($KWLANG_eo) = 39;
our($KWLANG_es) = 150;
our($KWLANG_et) = 40;
our($KWLANG_eu) = 41;
our($KWLANG_fa) = 44;
our($KWLANG_ff) = 49;
our($KWLANG_fi) = 46;
our($KWLANG_fj) = 45;
our($KWLANG_fo) = 43;
our($KWLANG_fr) = 47;
our($KWLANG_fy) = 48;
our($KWLANG_ga) = 51;
our($KWLANG_gd) = 50;
our($KWLANG_gl) = 52;
our($KWLANG_gn) = 54;
our($KWLANG_gu) = 55;
our($KWLANG_gv) = 53;
our($KWLANG_ha) = 57;
our($KWLANG_he) = 59;
our($KWLANG_hi) = 61;
our($KWLANG_ho) = 62;
our($KWLANG_hr) = 63;
our($KWLANG_ht) = 56;
our($KWLANG_hu) = 64;
our($KWLANG_hy) = 65;
our($KWLANG_hz) = 60;
our($KWLANG_ia) = 71;
our($KWLANG_id) = 72;
our($KWLANG_ie) = 70;
our($KWLANG_ig) = 66;
our($KWLANG_ii) = 68;
our($KWLANG_ik) = 73;
our($KWLANG_io) = 67;
our($KWLANG_is) = 74;
our($KWLANG_it) = 75;
our($KWLANG_iu) = 69;
our($KWLANG_ja) = 77;
our($KWLANG_jv) = 76;
our($KWLANG_ka) = 81;
our($KWLANG_kg) = 89;
our($KWLANG_ki) = 85;
our($KWLANG_kj) = 91;
our($KWLANG_kk) = 83;
our($KWLANG_kl) = 78;
our($KWLANG_km) = 84;
our($KWLANG_kn) = 79;
our($KWLANG_ko) = 90;
our($KWLANG_kr) = 82;
our($KWLANG_ks) = 80;
our($KWLANG_ku) = 92;
our($KWLANG_kv) = 88;
our($KWLANG_kw) = 30;
our($KWLANG_ky) = 87;
our($KWLANG_la) = 94;
our($KWLANG_lb) = 99;
our($KWLANG_lg) = 101;
our($KWLANG_li) = 96;
our($KWLANG_ln) = 97;
our($KWLANG_lo) = 93;
our($KWLANG_lt) = 98;
our($KWLANG_lu) = 100;
our($KWLANG_lv) = 95;
our($KWLANG_mg) = 106;
our($KWLANG_mh) = 102;
our($KWLANG_mi) = 110;
our($KWLANG_mk) = 105;
our($KWLANG_ml) = 103;
our($KWLANG_mn) = 109;
our($KWLANG_mo) = 108;
our($KWLANG_mr) = 104;
our($KWLANG_ms) = 111;
our($KWLANG_mt) = 107;
our($KWLANG_my) = 112;
our($KWLANG_na) = 113;
our($KWLANG_nb) = 121;
our($KWLANG_nd) = 116;
our($KWLANG_ne) = 118;
our($KWLANG_ng) = 117;
our($KWLANG_nl) = 119;
our($KWLANG_nn) = 120;
our($KWLANG_no) = 122;
our($KWLANG_nr) = 115;
our($KWLANG_nv) = 114;
our($KWLANG_ny) = 123;
our($KWLANG_oc) = 124;
our($KWLANG_oj) = 125;
our($KWLANG_om) = 127;
our($KWLANG_or) = 126;
our($KWLANG_os) = 128;
our($KWLANG_pa) = 129;
our($KWLANG_pi) = 130;
our($KWLANG_pl) = 131;
our($KWLANG_ps) = 133;
our($KWLANG_pt) = 132;
our($KWLANG_qu) = 134;
our($KWLANG_rm) = 135;
our($KWLANG_rn) = 137;
our($KWLANG_ro) = 136;
our($KWLANG_ru) = 138;
our($KWLANG_rw) = 86;
our($KWLANG_sa) = 140;
our($KWLANG_sc) = 152;
our($KWLANG_sd) = 147;
our($KWLANG_se) = 144;
our($KWLANG_sg) = 139;
our($KWLANG_sh) = 58;
our($KWLANG_si) = 141;
our($KWLANG_sk) = 142;
our($KWLANG_sl) = 143;
our($KWLANG_sm) = 145;
our($KWLANG_sn) = 146;
our($KWLANG_so) = 148;
our($KWLANG_sq) = 151;
our($KWLANG_sr) = 153;
our($KWLANG_ss) = 154;
our($KWLANG_st) = 149;
our($KWLANG_su) = 155;
our($KWLANG_sv) = 157;
our($KWLANG_sw) = 156;
our($KWLANG_ta) = 159;
our($KWLANG_te) = 161;
our($KWLANG_tg) = 162;
our($KWLANG_th) = 164;
our($KWLANG_ti) = 165;
our($KWLANG_tk) = 169;
our($KWLANG_tl) = 163;
our($KWLANG_tn) = 167;
our($KWLANG_to) = 166;
our($KWLANG_tr) = 170;
our($KWLANG_ts) = 168;
our($KWLANG_tt) = 160;
our($KWLANG_tw) = 171;
our($KWLANG_ty) = 158;
our($KWLANG_ug) = 172;
our($KWLANG_uk) = 173;
our($KWLANG_ur) = 174;
our($KWLANG_uz) = 175;
our($KWLANG_ve) = 176;
our($KWLANG_vi) = 177;
our($KWLANG_vo) = 178;
our($KWLANG_wa) = 179;
our($KWLANG_wo) = 180;
our($KWLANG_xh) = 181;
our($KWLANG_yi) = 182;
our($KWLANG_yo) = 183;
our($KWLANG_za) = 184;
our($KWLANG_zh) = 185;
our($KWLANG_zu) = 186;
our($KWDIAL_ksb) = 2;
our($KWDIAL_ktb) = 3;
our($KWDIAL_kyb) = 4;
our($KWDIAL_kyu) = 9;
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
our($KWPOS_adv_to) = 8;
our($KWPOS_aux) = 9;
our($KWPOS_aux_adj) = 10;
our($KWPOS_aux_v) = 11;
our($KWPOS_company) = 184;
our($KWPOS_conj) = 12;
our($KWPOS_ctr) = 51;
our($KWPOS_exp) = 13;
our($KWPOS_fem) = 187;
our($KWPOS_given) = 189;
our($KWPOS_int) = 14;
our($KWPOS_masc) = 186;
our($KWPOS_n) = 17;
our($KWPOS_n_adv) = 18;
our($KWPOS_n_pref) = 20;
our($KWPOS_n_suf) = 19;
our($KWPOS_n_t) = 21;
our($KWPOS_num) = 24;
our($KWPOS_person) = 188;
our($KWPOS_place) = 182;
our($KWPOS_pref) = 25;
our($KWPOS_product) = 185;
our($KWPOS_prt) = 26;
our($KWPOS_station) = 190;
our($KWPOS_suf) = 27;
our($KWPOS_surname) = 181;
our($KWPOS_unclass) = 183;
our($KWPOS_v1) = 28;
our($KWPOS_v4r) = 53;
our($KWPOS_v5) = 29;
our($KWPOS_v5aru) = 30;
our($KWPOS_v5b) = 31;
our($KWPOS_v5g) = 32;
our($KWPOS_v5k) = 33;
our($KWPOS_v5k_s) = 34;
our($KWPOS_v5m) = 35;
our($KWPOS_v5n) = 36;
our($KWPOS_v5r) = 37;
our($KWPOS_v5r_i) = 38;
our($KWPOS_v5s) = 39;
our($KWPOS_v5t) = 40;
our($KWPOS_v5u) = 41;
our($KWPOS_v5u_s) = 42;
our($KWPOS_v5uru) = 43;
our($KWPOS_v5z) = 55;
our($KWPOS_vi) = 44;
our($KWPOS_vk) = 45;
our($KWPOS_vn) = 52;
our($KWPOS_vs) = 46;
our($KWPOS_vs_i) = 48;
our($KWPOS_vs_s) = 47;
our($KWPOS_vt) = 50;
our($KWPOS_vz) = 49;


our ($Kwds)   = do {
  my $a = {
    CINF => {
              1 => {
                    descr => "\"Modern Reader's Japanese-English Character Dictionary\", edited by Andrew Nelson (now published as the \"Classic\" Nelson).",
                    id => 1,
                    kw => "nelson_c",
                  },
              10 => {
                    descr => "\"A Guide To Remembering Japanese Characters\" by Kenneth G.  Henshall.",
                    id => 10,
                    kw => "henshall",
                  },
              11 => {
                    descr => "\"Kanji and Kana\" by Spahn and Hadamitzky.",
                    id => 11,
                    kw => "sh_kk",
                  },
              12 => {
                    descr => "\"A Guide To Reading and Writing Japanese\" edited by Florence Sakade.",
                    id => 12,
                    kw => "sakade",
                  },
              13 => {
                    descr => "Tuttle Kanji Cards, compiled by Alexander Kask.",
                    id => 13,
                    kw => "tutt_cards",
                  },
              14 => {
                    descr => "\"The Kanji Way to Japanese Language Power\" by Dale Crowley.",
                    id => 14,
                    kw => "crowley",
                  },
              15 => {
                    descr => "\"Kanji in Context\" by Nishiguchi and Kono.",
                    id => 15,
                    kw => "kanji_in_ctx",
                  },
              16 => {
                    descr => "\"Japanese For Busy People\" vols I-III, published by the AJLT. The codes are the volume.chapter.",
                    id => 16,
                    kw => "busy_people",
                  },
              17 => {
                    descr => "The \"Kodansha Compact Kanji Guide\".",
                    id => 17,
                    kw => "kodansha_comp",
                  },
              18 => {
                    descr => "Halpern's SKIP (System  of  Kanji  Indexing  by  Patterns) code.",
                    id => 18,
                    kw => "skip",
                  },
              19 => {
                    descr => "Descriptor codes for The Kanji Dictionary (Tuttle 1996) by Spahn and Hadamitzky.",
                    id => 19,
                    kw => "sh_desc",
                  },
              2 => {
                    descr => "\"The New Nelson Japanese-English Character Dictionary\", edited by John Haig.",
                    id => 2,
                    kw => "nelson_n",
                  },
              20 => {
                    descr => "\"Four Corner\" code for the kanji invented by Wang Chen in 1928.",
                    id => 20,
                    kw => "four_corner",
                  },
              21 => {
                    descr => "Codes developed by the late Father Joseph De Roo, and published in  his book \"2001 Kanji\" (Bojinsha).",
                    id => 21,
                    kw => "deroo",
                  },
              22 => {
                    descr => "A possible misclassification of the kanji according to one of the code types.",
                    id => 22,
                    kw => "misclass",
                  },
              23 => {
                    descr => "Modern PinYin romanization of the Chinese reading.",
                    id => 23,
                    kw => "pinyin",
                  },
              24 => {
                    descr => "Stroke miscount or alternate count.",
                    id => 24,
                    kw => "strokes",
                  },
              25 => {
                    descr => "JIS X 0208-1997 - kuten coding (nn-nn).",
                    id => 25,
                    kw => "jis208",
                  },
              26 => {
                    descr => "JIS X 0212-1990 - kuten coding (nn-nn).",
                    id => 26,
                    kw => "jis212",
                  },
              27 => {
                    descr => "JIS X 0213-2000 - kuten coding (p-nn-nn).",
                    id => 27,
                    kw => "jis213",
                  },
              28 => {
                    descr => "\"A Guide To Reading and Writing Japanese\" 3rd edition, edited by Henshall, Seeley and De Groot.",
                    id => 28,
                    kw => "henshall3",
                  },
              29 => {
                    descr => "Korean reading of the kanji in hangul.",
                    id => 29,
                    kw => "korean_h",
                  },
              3 => {
                    descr => "\"New Japanese-English Character Dictionary\", edited by Jack Halpern.",
                    id => 3,
                    kw => "halpern_njecd",
                  },
              30 => {
                    descr => "Romanized form of the Korean reading of the kanji.",
                    id => 30,
                    kw => "korean_r",
                  },
              31 => {
                    descr => "Japanese Kanji Flashcards, by Max Hodges and Tomoko Okazaki.",
                    id => 31,
                    kw => "jf_cards",
                  },
              32 => {
                    descr => "Radical number given in nelson_c.",
                    id => 32,
                    kw => "nelson_rad",
                  },
              33 => { descr => "SKIP code misclasification.", id => 33, kw => "skip_mis" },
              34 => {
                    descr => "\"The Kanji Dictionary\" by Spahn and Hadamitzky.",
                    id => 34,
                    kw => "s_h",
                  },
              4 => {
                    descr => "\"Kanji Learners Dictionary\" (Kodansha) edited by Jack Halpern.",
                    id => 4,
                    kw => "halpern_kkld",
                  },
              5 => {
                    descr => "\"Remembering The  Kanji\"  by  James Heisig.",
                    id => 5,
                    kw => "heisig",
                  },
              6 => {
                    descr => "\"A  New Dictionary of Kanji Usage\" (Gakken).",
                    id => 6,
                    kw => "gakken",
                  },
              7 => {
                    descr => "\"Japanese Names\", by P.G. O'Neill.",
                    id => 7,
                    kw => "oneill_names",
                  },
              8 => {
                    descr => "\"Essential Kanji\" by P.G. O'Neill.",
                    id => 8,
                    kw => "oneill_kk",
                  },
              9 => {
                    descr => "\"Daikanwajiten\" compiled by Morohashi.",
                    id => 9,
                    kw => "moro",
                  },
              busy_people => 'fix',
              crowley => 'fix',
              deroo => 'fix',
              four_corner => 'fix',
              gakken => 'fix',
              halpern_kkld => 'fix',
              halpern_njecd => 'fix',
              heisig => 'fix',
              henshall => 'fix',
              henshall3 => 'fix',
              jf_cards => 'fix',
              jis208 => 'fix',
              jis212 => 'fix',
              jis213 => 'fix',
              kanji_in_ctx => 'fix',
              kodansha_comp => 'fix',
              korean_h => 'fix',
              korean_r => 'fix',
              misclass => 'fix',
              moro => 'fix',
              nelson_c => 'fix',
              nelson_n => 'fix',
              nelson_rad => 'fix',
              oneill_kk => 'fix',
              oneill_names => 'fix',
              pinyin => 'fix',
              s_h => 'fix',
              sakade => 'fix',
              sh_desc => 'fix',
              sh_kk => 'fix',
              skip => 'fix',
              skip_mis => 'fix',
              strokes => 'fix',
              tutt_cards => 'fix',
            },
    DIAL => {
              1 => { descr => "Tokyo-ben (std)", id => 1, kw => "std" },
              2 => { descr => "Kansai-ben", id => 2, kw => "ksb" },
              3 => { descr => "Kantou-ben", id => 3, kw => "ktb" },
              4 => { descr => "Kyoto-ben", id => 4, kw => "kyb" },
              5 => { descr => "Osaka-ben", id => 5, kw => "osb" },
              6 => { descr => "Tosa-ben", id => 6, kw => "tsb" },
              7 => { descr => "Touhoku-ben", id => 7, kw => "thb" },
              8 => { descr => "Tsugaru-ben", id => 8, kw => "tsug" },
              9 => { descr => "Kyuushuu-ben", id => 9, kw => "kyu" },
              ksb => 'fix',
              ktb => 'fix',
              kyb => 'fix',
              kyu => 'fix',
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
              1 => {
                    descr => "Ranking from \"Ichimango goi bunruishuu\", 1-2.",
                    id => 1,
                    kw => "ichi",
                  },
              2 => {
                    descr => "Common loanwords based on wordfreq file, 1-2",
                    id => 2,
                    kw => "gai",
                  },
              4 => {
                    descr => "Ranking assigned by JMdict editors, 1-2 ",
                    id => 4,
                    kw => "spec",
                  },
              5 => { descr => "Ranking in wordfreq file, 1-48", id => 5, kw => "nf" },
              6 => {
                    descr => "Google counts (by Kale Stutzman, 2007-01-14)",
                    id => 6,
                    kw => "gA",
                  },
              7 => { descr => "Ranking in wordfreq file, 1-2", id => 7, kw => "news" },
              gA => 'fix',
              gai => 'fix',
              ichi => 'fix',
              news => 'fix',
              nf => 'fix',
              spec => 'fix',
            },
    GINF => {
              1 => { descr => "equivalent", id => 1, kw => "equ" },
              2 => { descr => "literaly", id => 2, kw => "lit" },
              3 => { descr => "idiomatically", id => 3, kw => "id" },
              4 => { descr => "explanatory", id => 4, kw => "expl" },
              equ => 'fix',
              expl => 'fix',
              id => 'fix',
              lit => 'fix',
            },
    KINF => {
              1     => { descr => "word containing irregular kanji usage", id => 1, kw => "iK" },
              2     => { descr => "irregular okurigana usage", id => 2, kw => "io" },
              3     => { descr => "word containing out-dated kanji", id => 3, kw => "oK" },
              4     => { descr => "word containing irregular kana usage", id => 4, kw => "ik" },
              5     => { descr => "ateji (phonetic) reading", id => 5, kw => "ateji" },
              ateji => 'fix',
              iK    => 'fix',
              ik    => 'fix',
              io    => 'fix',
              oK    => 'fix',
            },
    LANG => {
              1    => { descr => "English", id => 1, kw => "en" },
              10   => { descr => "Assamese", id => 10, kw => "as" },
              100  => { descr => "Luba-Katanga", id => 100, kw => "lu" },
              101  => { descr => "Ganda", id => 101, kw => "lg" },
              102  => { descr => "Marshallese", id => 102, kw => "mh" },
              103  => { descr => "Malayalam", id => 103, kw => "ml" },
              104  => { descr => "Marathi", id => 104, kw => "mr" },
              105  => { descr => "Macedonian", id => 105, kw => "mk" },
              106  => { descr => "Malagasy", id => 106, kw => "mg" },
              107  => { descr => "Maltese", id => 107, kw => "mt" },
              108  => { descr => "Moldavian", id => 108, kw => "mo" },
              109  => { descr => "Mongolian", id => 109, kw => "mn" },
              11   => { descr => "Avaric", id => 11, kw => "av" },
              110  => { descr => "Maori", id => 110, kw => "mi" },
              111  => { descr => "Malay (macrolanguage)", id => 111, kw => "ms" },
              112  => { descr => "Burmese", id => 112, kw => "my" },
              113  => { descr => "Nauru", id => 113, kw => "na" },
              114  => { descr => "Navajo", id => 114, kw => "nv" },
              115  => { descr => "South Ndebele", id => 115, kw => "nr" },
              116  => { descr => "North Ndebele", id => 116, kw => "nd" },
              117  => { descr => "Ndonga", id => 117, kw => "ng" },
              118  => { descr => "Nepali", id => 118, kw => "ne" },
              119  => { descr => "Dutch", id => 119, kw => "nl" },
              12   => { descr => "Avestan", id => 12, kw => "ae" },
              120  => { descr => "Norwegian Nynorsk", id => 120, kw => "nn" },
              121  => { descr => "Norwegian Bokm\xC3\xA5l", id => 121, kw => "nb" },
              122  => { descr => "Norwegian", id => 122, kw => "no" },
              123  => { descr => "Nyanja", id => 123, kw => "ny" },
              124  => { descr => "Occitan (post 1500)", id => 124, kw => "oc" },
              125  => { descr => "Ojibwa", id => 125, kw => "oj" },
              126  => { descr => "Oriya", id => 126, kw => "or" },
              127  => { descr => "Oromo", id => 127, kw => "om" },
              128  => { descr => "Ossetian", id => 128, kw => "os" },
              129  => { descr => "Panjabi", id => 129, kw => "pa" },
              13   => { descr => "Aymara", id => 13, kw => "ay" },
              130  => { descr => "Pali", id => 130, kw => "pi" },
              131  => { descr => "Polish", id => 131, kw => "pl" },
              132  => { descr => "Portuguese", id => 132, kw => "pt" },
              133  => { descr => "Pushto", id => 133, kw => "ps" },
              134  => { descr => "Quechua", id => 134, kw => "qu" },
              135  => { descr => "Romansh", id => 135, kw => "rm" },
              136  => { descr => "Romanian", id => 136, kw => "ro" },
              137  => { descr => "Rundi", id => 137, kw => "rn" },
              138  => { descr => "Russian", id => 138, kw => "ru" },
              139  => { descr => "Sango", id => 139, kw => "sg" },
              14   => { descr => "Azerbaijani", id => 14, kw => "az" },
              140  => { descr => "Sanskrit", id => 140, kw => "sa" },
              141  => { descr => "Sinhala", id => 141, kw => "si" },
              142  => { descr => "Slovak", id => 142, kw => "sk" },
              143  => { descr => "Slovenian", id => 143, kw => "sl" },
              144  => { descr => "Northern Sami", id => 144, kw => "se" },
              145  => { descr => "Samoan", id => 145, kw => "sm" },
              146  => { descr => "Shona", id => 146, kw => "sn" },
              147  => { descr => "Sindhi", id => 147, kw => "sd" },
              148  => { descr => "Somali", id => 148, kw => "so" },
              149  => { descr => "Southern Sotho", id => 149, kw => "st" },
              15   => { descr => "Bashkir", id => 15, kw => "ba" },
              150  => { descr => "Spanish", id => 150, kw => "es" },
              151  => { descr => "Albanian", id => 151, kw => "sq" },
              152  => { descr => "Sardinian", id => 152, kw => "sc" },
              153  => { descr => "Serbian", id => 153, kw => "sr" },
              154  => { descr => "Swati", id => 154, kw => "ss" },
              155  => { descr => "Sundanese", id => 155, kw => "su" },
              156  => { descr => "Swahili (macrolanguage)", id => 156, kw => "sw" },
              157  => { descr => "Swedish", id => 157, kw => "sv" },
              158  => { descr => "Tahitian", id => 158, kw => "ty" },
              159  => { descr => "Tamil", id => 159, kw => "ta" },
              16   => { descr => "Bambara", id => 16, kw => "bm" },
              160  => { descr => "Tatar", id => 160, kw => "tt" },
              161  => { descr => "Telugu", id => 161, kw => "te" },
              162  => { descr => "Tajik", id => 162, kw => "tg" },
              163  => { descr => "Tagalog", id => 163, kw => "tl" },
              164  => { descr => "Thai", id => 164, kw => "th" },
              165  => { descr => "Tigrinya", id => 165, kw => "ti" },
              166  => { descr => "Tonga (Tonga Islands)", id => 166, kw => "to" },
              167  => { descr => "Tswana", id => 167, kw => "tn" },
              168  => { descr => "Tsonga", id => 168, kw => "ts" },
              169  => { descr => "Turkmen", id => 169, kw => "tk" },
              17   => { descr => "Belarusian", id => 17, kw => "be" },
              170  => { descr => "Turkish", id => 170, kw => "tr" },
              171  => { descr => "Twi", id => 171, kw => "tw" },
              172  => { descr => "Uighur", id => 172, kw => "ug" },
              173  => { descr => "Ukrainian", id => 173, kw => "uk" },
              174  => { descr => "Urdu", id => 174, kw => "ur" },
              175  => { descr => "Uzbek", id => 175, kw => "uz" },
              176  => { descr => "Venda", id => 176, kw => "ve" },
              177  => { descr => "Vietnamese", id => 177, kw => "vi" },
              178  => { descr => "Volap\xC3\xBCk", id => 178, kw => "vo" },
              179  => { descr => "Walloon", id => 179, kw => "wa" },
              18   => { descr => "Bengali", id => 18, kw => "bn" },
              180  => { descr => "Wolof", id => 180, kw => "wo" },
              181  => { descr => "Xhosa", id => 181, kw => "xh" },
              182  => { descr => "Yiddish", id => 182, kw => "yi" },
              183  => { descr => "Yoruba", id => 183, kw => "yo" },
              184  => { descr => "Zhuang", id => 184, kw => "za" },
              185  => { descr => "Chinese", id => 185, kw => "zh" },
              186  => { descr => "Zulu", id => 186, kw => "zu" },
              19   => { descr => "Bislama", id => 19, kw => "bi" },
              2    => { descr => "Ainu", id => 2, kw => "ain" },
              20   => { descr => "Tibetan", id => 20, kw => "bo" },
              21   => { descr => "Bosnian", id => 21, kw => "bs" },
              22   => { descr => "Breton", id => 22, kw => "br" },
              23   => { descr => "Bulgarian", id => 23, kw => "bg" },
              24   => { descr => "Catalan", id => 24, kw => "ca" },
              25   => { descr => "Czech", id => 25, kw => "cs" },
              26   => { descr => "Chamorro", id => 26, kw => "ch" },
              27   => { descr => "Chechen", id => 27, kw => "ce" },
              28   => { descr => "Church Slavic", id => 28, kw => "cu" },
              29   => { descr => "Chuvash", id => 29, kw => "cv" },
              3    => { descr => "Afar", id => 3, kw => "aa" },
              30   => { descr => "Cornish", id => 30, kw => "kw" },
              31   => { descr => "Corsican", id => 31, kw => "co" },
              32   => { descr => "Cree", id => 32, kw => "cr" },
              33   => { descr => "Welsh", id => 33, kw => "cy" },
              34   => { descr => "Danish", id => 34, kw => "da" },
              35   => { descr => "German", id => 35, kw => "de" },
              36   => { descr => "Dhivehi", id => 36, kw => "dv" },
              37   => { descr => "Dzongkha", id => 37, kw => "dz" },
              38   => { descr => "Modern Greek (1453-)", id => 38, kw => "el" },
              39   => { descr => "Esperanto", id => 39, kw => "eo" },
              4    => { descr => "Abkhazian", id => 4, kw => "ab" },
              40   => { descr => "Estonian", id => 40, kw => "et" },
              41   => { descr => "Basque", id => 41, kw => "eu" },
              42   => { descr => "Ewe", id => 42, kw => "ee" },
              43   => { descr => "Faroese", id => 43, kw => "fo" },
              44   => { descr => "Persian", id => 44, kw => "fa" },
              45   => { descr => "Fijian", id => 45, kw => "fj" },
              46   => { descr => "Finnish", id => 46, kw => "fi" },
              47   => { descr => "French", id => 47, kw => "fr" },
              48   => { descr => "Western Frisian", id => 48, kw => "fy" },
              49   => { descr => "Fulah", id => 49, kw => "ff" },
              5    => { descr => "Afrikaans", id => 5, kw => "af" },
              50   => { descr => "Scottish Gaelic", id => 50, kw => "gd" },
              51   => { descr => "Irish", id => 51, kw => "ga" },
              52   => { descr => "Galician", id => 52, kw => "gl" },
              53   => { descr => "Manx", id => 53, kw => "gv" },
              54   => { descr => "Guarani", id => 54, kw => "gn" },
              55   => { descr => "Gujarati", id => 55, kw => "gu" },
              56   => { descr => "Haitian", id => 56, kw => "ht" },
              57   => { descr => "Hausa", id => 57, kw => "ha" },
              58   => { descr => "Serbo-Croatian", id => 58, kw => "sh" },
              59   => { descr => "Hebrew", id => 59, kw => "he" },
              6    => { descr => "Akan", id => 6, kw => "ak" },
              60   => { descr => "Herero", id => 60, kw => "hz" },
              61   => { descr => "Hindi", id => 61, kw => "hi" },
              62   => { descr => "Hiri Motu", id => 62, kw => "ho" },
              63   => { descr => "Croatian", id => 63, kw => "hr" },
              64   => { descr => "Hungarian", id => 64, kw => "hu" },
              65   => { descr => "Armenian", id => 65, kw => "hy" },
              66   => { descr => "Igbo", id => 66, kw => "ig" },
              67   => { descr => "Ido", id => 67, kw => "io" },
              68   => { descr => "Sichuan Yi", id => 68, kw => "ii" },
              69   => { descr => "Inuktitut", id => 69, kw => "iu" },
              7    => { descr => "Amharic", id => 7, kw => "am" },
              70   => { descr => "Interlingue", id => 70, kw => "ie" },
              71   => {
                        descr => "Interlingua (International Auxiliary Language Association)",
                        id => 71,
                        kw => "ia",
                      },
              72   => { descr => "Indonesian", id => 72, kw => "id" },
              73   => { descr => "Inupiaq", id => 73, kw => "ik" },
              74   => { descr => "Icelandic", id => 74, kw => "is" },
              75   => { descr => "Italian", id => 75, kw => "it" },
              76   => { descr => "Javanese", id => 76, kw => "jv" },
              77   => { descr => "Japanese", id => 77, kw => "ja" },
              78   => { descr => "Kalaallisut", id => 78, kw => "kl" },
              79   => { descr => "Kannada", id => 79, kw => "kn" },
              8    => { descr => "Arabic", id => 8, kw => "ar" },
              80   => { descr => "Kashmiri", id => 80, kw => "ks" },
              81   => { descr => "Georgian", id => 81, kw => "ka" },
              82   => { descr => "Kanuri", id => 82, kw => "kr" },
              83   => { descr => "Kazakh", id => 83, kw => "kk" },
              84   => { descr => "Central Khmer", id => 84, kw => "km" },
              85   => { descr => "Kikuyu", id => 85, kw => "ki" },
              86   => { descr => "Kinyarwanda", id => 86, kw => "rw" },
              87   => { descr => "Kirghiz", id => 87, kw => "ky" },
              88   => { descr => "Komi", id => 88, kw => "kv" },
              89   => { descr => "Kongo", id => 89, kw => "kg" },
              9    => { descr => "Aragonese", id => 9, kw => "an" },
              90   => { descr => "Korean", id => 90, kw => "ko" },
              91   => { descr => "Kuanyama", id => 91, kw => "kj" },
              92   => { descr => "Kurdish", id => 92, kw => "ku" },
              93   => { descr => "Lao", id => 93, kw => "lo" },
              94   => { descr => "Latin", id => 94, kw => "la" },
              95   => { descr => "Latvian", id => 95, kw => "lv" },
              96   => { descr => "Limburgan", id => 96, kw => "li" },
              97   => { descr => "Lingala", id => 97, kw => "ln" },
              98   => { descr => "Lithuanian", id => 98, kw => "lt" },
              99   => { descr => "Luxembourgish", id => 99, kw => "lb" },
              aa   => 'fix',
              ab   => 'fix',
              ae   => 'fix',
              af   => 'fix',
              ain  => 'fix',
              ak   => 'fix',
              am   => 'fix',
              an   => 'fix',
              ar   => 'fix',
              as   => 'fix',
              av   => 'fix',
              ay   => 'fix',
              az   => 'fix',
              ba   => 'fix',
              be   => 'fix',
              bg   => 'fix',
              bi   => 'fix',
              bm   => 'fix',
              bn   => 'fix',
              bo   => 'fix',
              br   => 'fix',
              bs   => 'fix',
              ca   => 'fix',
              ce   => 'fix',
              ch   => 'fix',
              co   => 'fix',
              cr   => 'fix',
              cs   => 'fix',
              cu   => 'fix',
              cv   => 'fix',
              cy   => 'fix',
              da   => 'fix',
              de   => 'fix',
              dv   => 'fix',
              dz   => 'fix',
              ee   => 'fix',
              el   => 'fix',
              en   => 'fix',
              eo   => 'fix',
              es   => 'fix',
              et   => 'fix',
              eu   => 'fix',
              fa   => 'fix',
              ff   => 'fix',
              fi   => 'fix',
              fj   => 'fix',
              fo   => 'fix',
              fr   => 'fix',
              fy   => 'fix',
              ga   => 'fix',
              gd   => 'fix',
              gl   => 'fix',
              gn   => 'fix',
              gu   => 'fix',
              gv   => 'fix',
              ha   => 'fix',
              he   => 'fix',
              hi   => 'fix',
              ho   => 'fix',
              hr   => 'fix',
              ht   => 'fix',
              hu   => 'fix',
              hy   => 'fix',
              hz   => 'fix',
              ia   => 'fix',
              id   => 'fix',
              ie   => 'fix',
              ig   => 'fix',
              ii   => 'fix',
              ik   => 'fix',
              io   => 'fix',
              is   => 'fix',
              it   => 'fix',
              iu   => 'fix',
              ja   => 'fix',
              jv   => 'fix',
              ka   => 'fix',
              kg   => 'fix',
              ki   => 'fix',
              kj   => 'fix',
              kk   => 'fix',
              kl   => 'fix',
              km   => 'fix',
              kn   => 'fix',
              ko   => 'fix',
              kr   => 'fix',
              ks   => 'fix',
              ku   => 'fix',
              kv   => 'fix',
              kw   => 'fix',
              ky   => 'fix',
              la   => 'fix',
              lb   => 'fix',
              lg   => 'fix',
              li   => 'fix',
              ln   => 'fix',
              lo   => 'fix',
              "lt" => 'fix',
              lu   => 'fix',
              lv   => 'fix',
              mg   => 'fix',
              mh   => 'fix',
              mi   => 'fix',
              mk   => 'fix',
              ml   => 'fix',
              mn   => 'fix',
              mo   => 'fix',
              mr   => 'fix',
              ms   => 'fix',
              mt   => 'fix',
              "my" => 'fix',
              na   => 'fix',
              nb   => 'fix',
              nd   => 'fix',
              "ne" => 'fix',
              ng   => 'fix',
              nl   => 'fix',
              nn   => 'fix',
              "no" => 'fix',
              nr   => 'fix',
              nv   => 'fix',
              ny   => 'fix',
              oc   => 'fix',
              oj   => 'fix',
              om   => 'fix',
              "or" => 'fix',
              os   => 'fix',
              pa   => 'fix',
              pi   => 'fix',
              pl   => 'fix',
              ps   => 'fix',
              pt   => 'fix',
              qu   => 'fix',
              rm   => 'fix',
              rn   => 'fix',
              ro   => 'fix',
              ru   => 'fix',
              rw   => 'fix',
              sa   => 'fix',
              sc   => 'fix',
              sd   => 'fix',
              se   => 'fix',
              sg   => 'fix',
              sh   => 'fix',
              si   => 'fix',
              sk   => 'fix',
              sl   => 'fix',
              sm   => 'fix',
              sn   => 'fix',
              so   => 'fix',
              sq   => 'fix',
              sr   => 'fix',
              ss   => 'fix',
              st   => 'fix',
              su   => 'fix',
              sv   => 'fix',
              sw   => 'fix',
              ta   => 'fix',
              te   => 'fix',
              tg   => 'fix',
              th   => 'fix',
              ti   => 'fix',
              tk   => 'fix',
              tl   => 'fix',
              tn   => 'fix',
              to   => 'fix',
              "tr" => 'fix',
              ts   => 'fix',
              tt   => 'fix',
              tw   => 'fix',
              ty   => 'fix',
              ug   => 'fix',
              uk   => 'fix',
              ur   => 'fix',
              uz   => 'fix',
              ve   => 'fix',
              vi   => 'fix',
              vo   => 'fix',
              wa   => 'fix',
              wo   => 'fix',
              xh   => 'fix',
              yi   => 'fix',
              yo   => 'fix',
              za   => 'fix',
              zh   => 'fix',
              zu   => 'fix',
            },
    MISC => {
              1        => {
                            descr => "rude or X-rated term (not displayed in educational software)",
                            id => 1,
                            kw => "X",
                          },
              11       => {
                            descr => "honorific or respectful (sonkeigo) language",
                            id => 11,
                            kw => "hon",
                          },
              12       => { descr => "humble (kenjougo) language", id => 12, kw => "hum" },
              13       => { descr => "idiomatic expression", id => 13, kw => "id" },
              14       => { descr => "manga slang", id => 14, kw => "m-sl" },
              15       => { descr => "male term or language", id => 15, kw => "male" },
              17       => { descr => "obsolete term", id => 17, kw => "obs" },
              18       => { descr => "obscure term", id => 18, kw => "obsc" },
              19       => { descr => "polite (teineigo) language", id => 19, kw => "pol" },
              2        => { descr => "abbreviation", id => 2, kw => "abbr" },
              20       => { descr => "rare", id => 20, kw => "rare" },
              21       => { descr => "slang", id => 21, kw => "sl" },
              22       => { descr => "word usually written using kana alone", id => 22, kw => "uk" },
              24       => { descr => "vulgar expression or word", id => 24, kw => "vulg" },
              25       => { descr => "sensitive", id => 25, kw => "sens" },
              26       => { descr => "poetical term", id => 26, kw => "poet" },
              3        => { descr => "archaism", id => 3, kw => "arch" },
              4        => { descr => "children's language", id => 4, kw => "chn" },
              5        => { descr => "colloquialism", id => 5, kw => "col" },
              6        => { descr => "derogatory", id => 6, kw => "derog" },
              7        => { descr => "exclusively kanji", id => 7, kw => "eK" },
              8        => { descr => "familiar language", id => 8, kw => "fam" },
              81       => { descr => "proverb", id => 81, kw => "proverb" },
              82       => { descr => "aphorism (pithy saying)", id => 82, kw => "aphorism" },
              83       => { descr => "quotation", id => 83, kw => "quote" },
              9        => { descr => "female term or language", id => 9, kw => "fem" },
              X        => 'fix',
              abbr     => 'fix',
              aphorism => 'fix',
              arch     => 'fix',
              chn      => 'fix',
              col      => 'fix',
              derog    => 'fix',
              eK       => 'fix',
              fam      => 'fix',
              fem      => 'fix',
              hon      => 'fix',
              hum      => 'fix',
              id       => 'fix',
              "m-sl"   => 'fix',
              male     => 'fix',
              obs      => 'fix',
              obsc     => 'fix',
              poet     => 'fix',
              pol      => 'fix',
              proverb  => 'fix',
              quote    => 'fix',
              rare     => 'fix',
              sens     => 'fix',
              sl       => 'fix',
              uk       => 'fix',
              vulg     => 'fix',
            },
    POS  => {
              1         => { descr => "adjective (keiyoushi)", id => 1, kw => "adj" },
              10        => { descr => "auxiliary adjective", id => 10, kw => "aux-adj" },
              11        => { descr => "auxiliary verb", id => 11, kw => "aux-v" },
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
              31        => { descr => "Godan verb with `bu' ending", id => 31, kw => "v5b" },
              32        => { descr => "Godan verb with `gu' ending", id => 32, kw => "v5g" },
              33        => { descr => "Godan verb with `ku' ending", id => 33, kw => "v5k" },
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
                             descr => "Ichidan verb - zuru verb (alternative form of -jiru verbs)",
                             id => 49,
                             kw => "vz",
                           },
              5         => { descr => "`taru' adjective", id => 5, kw => "adj-t" },
              50        => { descr => "transitive verb", id => 50, kw => "vt" },
              51        => { descr => "counter", id => 51, kw => "ctr" },
              52        => { descr => "irregular nu verb", id => 52, kw => "vn" },
              53        => {
                             descr => "Yondan verb with `ru' ending (archaic)",
                             id => 53,
                             kw => "v4r",
                           },
              55        => { descr => "Godan verb with `zu' ending", id => 55, kw => "v5z" },
              6         => { descr => "adverb (fukushi)", id => 6, kw => "adv" },
              8         => { descr => "adverb taking the `to' particle", id => 8, kw => "adv-to" },
              9         => { descr => "auxiliary", id => 9, kw => "aux" },
              adj       => 'fix',
              "adj-na"  => 'fix',
              "adj-no"  => 'fix',
              "adj-pn"  => 'fix',
              "adj-t"   => 'fix',
              adv       => 'fix',
              "adv-to"  => 'fix',
              aux       => 'fix',
              "aux-adj" => 'fix',
              "aux-v"   => 'fix',
              company   => 'fix',
              conj      => 'fix',
              ctr       => 'fix',
              "exp"     => 'fix',
              fem       => 'fix',
              given     => 'fix',
              "int"     => 'fix',
              masc      => 'fix',
              n         => 'fix',
              "n-adv"   => 'fix',
              "n-pref"  => 'fix',
              "n-suf"   => 'fix',
              "n-t"     => 'fix',
              num       => 'fix',
              person    => 'fix',
              place     => 'fix',
              pref      => 'fix',
              product   => 'fix',
              prt       => 'fix',
              station   => 'fix',
              suf       => 'fix',
              surname   => 'fix',
              unclass   => 'fix',
              v1        => 'fix',
              v4r       => 'fix',
              v5        => 'fix',
              v5aru     => 'fix',
              v5b       => 'fix',
              v5g       => 'fix',
              v5k       => 'fix',
              "v5k-s"   => 'fix',
              v5m       => 'fix',
              v5n       => 'fix',
              v5r       => 'fix',
              "v5r-i"   => 'fix',
              v5s       => 'fix',
              v5t       => 'fix',
              v5u       => 'fix',
              "v5u-s"   => 'fix',
              v5uru     => 'fix',
              v5z       => 'fix',
              vi        => 'fix',
              vk        => 'fix',
              vn        => 'fix',
              vs        => 'fix',
              "vs-i"    => 'fix',
              "vs-s"    => 'fix',
              vt        => 'fix',
              vz        => 'fix',
            },
    RINF => {
              1      => { descr => "gikun (meaning) reading", id => 1, kw => "gikun" },
              103    => { descr => "reading used only in names (nanori)", id => 103, kw => "name" },
              104    => { descr => "reading used as name of radical", id => 104, kw => "rad" },
              105    => { descr => "approved reading for jouyou kanji", id => 105, kw => "jouyou" },
              106    => { descr => "kun-yomi", id => 106, kw => "kun" },
              128    => { descr => "on-yomi", id => 128, kw => "on" },
              129    => { descr => "on-yomi, kan", id => 129, kw => "kan" },
              130    => { descr => "on-yomi, go", id => 130, kw => "go" },
              131    => { descr => "on-yomi, tou", id => 131, kw => "tou" },
              132    => { descr => "on-yomi, kan\\'you", id => 132, kw => "kanyou" },
              2      => { descr => "out-dated or obsolete kana usage", id => 2, kw => "ok" },
              3      => { descr => "word containing irregular kana usage", id => 3, kw => "ik" },
              4      => { descr => "word usually written using kanji alone", id => 4, kw => "uK" },
              gikun  => 'fix',
              go     => 'fix',
              ik     => 'fix',
              jouyou => 'fix',
              kan    => 'fix',
              kanyou => 'fix',
              kun    => 'fix',
              name   => 'fix',
              ok     => 'fix',
              on     => 'fix',
              rad    => 'fix',
              tou    => 'fix',
              uK     => 'fix',
            },
    STAT => {
              1 => { descr => "New", id => 1, kw => "N" },
              2 => { descr => "Active", id => 2, kw => "A" },
              4 => { descr => "Deleted", id => 4, kw => "D" },
              6 => { descr => "Rejected", id => 6, kw => "R" },
              A => 'fix',
              D => 'fix',
              N => 'fix',
              R => 'fix',
            },
    XREF => {
              1 => { descr => "Synonym", id => 1, kw => "syn" },
              2 => { descr => "Antonym", id => 2, kw => "ant" },
              3 => { descr => "See also", id => 3, kw => "see" },
              4 => { descr => "C.f.", id => 4, kw => "cf" },
              5 => { descr => "Usage example", id => 5, kw => "ex" },
              6 => { descr => "Uses", id => 6, kw => "uses" },
              7 => { descr => "Preferred", id => 7, kw => "pref" },
              8 => { descr => "Kanji variant", id => 8, kw => "kvar" },
              ant => 'fix',
              cf => 'fix',
              ex => 'fix',
              kvar => 'fix',
              pref => 'fix',
              see => 'fix',
              syn => 'fix',
              uses => 'fix',
            },
  };
  $a->{CINF}{busy_people} = $a->{CINF}{16};
  $a->{CINF}{crowley} = $a->{CINF}{14};
  $a->{CINF}{deroo} = $a->{CINF}{21};
  $a->{CINF}{four_corner} = $a->{CINF}{20};
  $a->{CINF}{gakken} = $a->{CINF}{6};
  $a->{CINF}{halpern_kkld} = $a->{CINF}{4};
  $a->{CINF}{halpern_njecd} = $a->{CINF}{3};
  $a->{CINF}{heisig} = $a->{CINF}{5};
  $a->{CINF}{henshall} = $a->{CINF}{10};
  $a->{CINF}{henshall3} = $a->{CINF}{28};
  $a->{CINF}{jf_cards} = $a->{CINF}{31};
  $a->{CINF}{jis208} = $a->{CINF}{25};
  $a->{CINF}{jis212} = $a->{CINF}{26};
  $a->{CINF}{jis213} = $a->{CINF}{27};
  $a->{CINF}{kanji_in_ctx} = $a->{CINF}{15};
  $a->{CINF}{kodansha_comp} = $a->{CINF}{17};
  $a->{CINF}{korean_h} = $a->{CINF}{29};
  $a->{CINF}{korean_r} = $a->{CINF}{30};
  $a->{CINF}{misclass} = $a->{CINF}{22};
  $a->{CINF}{moro} = $a->{CINF}{9};
  $a->{CINF}{nelson_c} = $a->{CINF}{1};
  $a->{CINF}{nelson_n} = $a->{CINF}{2};
  $a->{CINF}{nelson_rad} = $a->{CINF}{32};
  $a->{CINF}{oneill_kk} = $a->{CINF}{8};
  $a->{CINF}{oneill_names} = $a->{CINF}{7};
  $a->{CINF}{pinyin} = $a->{CINF}{23};
  $a->{CINF}{s_h} = $a->{CINF}{34};
  $a->{CINF}{sakade} = $a->{CINF}{12};
  $a->{CINF}{sh_desc} = $a->{CINF}{19};
  $a->{CINF}{sh_kk} = $a->{CINF}{11};
  $a->{CINF}{skip} = $a->{CINF}{18};
  $a->{CINF}{skip_mis} = $a->{CINF}{33};
  $a->{CINF}{strokes} = $a->{CINF}{24};
  $a->{CINF}{tutt_cards} = $a->{CINF}{13};
  $a->{DIAL}{ksb} = $a->{DIAL}{2};
  $a->{DIAL}{ktb} = $a->{DIAL}{3};
  $a->{DIAL}{kyb} = $a->{DIAL}{4};
  $a->{DIAL}{kyu} = $a->{DIAL}{9};
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
  $a->{GINF}{equ} = $a->{GINF}{1};
  $a->{GINF}{expl} = $a->{GINF}{4};
  $a->{GINF}{id} = $a->{GINF}{3};
  $a->{GINF}{lit} = $a->{GINF}{2};
  $a->{KINF}{ateji} = $a->{KINF}{5};
  $a->{KINF}{iK} = $a->{KINF}{1};
  $a->{KINF}{ik} = $a->{KINF}{4};
  $a->{KINF}{io} = $a->{KINF}{2};
  $a->{KINF}{oK} = $a->{KINF}{3};
  $a->{LANG}{aa} = $a->{LANG}{3};
  $a->{LANG}{ab} = $a->{LANG}{4};
  $a->{LANG}{ae} = $a->{LANG}{12};
  $a->{LANG}{af} = $a->{LANG}{5};
  $a->{LANG}{ain} = $a->{LANG}{2};
  $a->{LANG}{ak} = $a->{LANG}{6};
  $a->{LANG}{am} = $a->{LANG}{7};
  $a->{LANG}{an} = $a->{LANG}{9};
  $a->{LANG}{ar} = $a->{LANG}{8};
  $a->{LANG}{as} = $a->{LANG}{10};
  $a->{LANG}{av} = $a->{LANG}{11};
  $a->{LANG}{ay} = $a->{LANG}{13};
  $a->{LANG}{az} = $a->{LANG}{14};
  $a->{LANG}{ba} = $a->{LANG}{15};
  $a->{LANG}{be} = $a->{LANG}{17};
  $a->{LANG}{bg} = $a->{LANG}{23};
  $a->{LANG}{bi} = $a->{LANG}{19};
  $a->{LANG}{bm} = $a->{LANG}{16};
  $a->{LANG}{bn} = $a->{LANG}{18};
  $a->{LANG}{bo} = $a->{LANG}{20};
  $a->{LANG}{br} = $a->{LANG}{22};
  $a->{LANG}{bs} = $a->{LANG}{21};
  $a->{LANG}{ca} = $a->{LANG}{24};
  $a->{LANG}{ce} = $a->{LANG}{27};
  $a->{LANG}{ch} = $a->{LANG}{26};
  $a->{LANG}{co} = $a->{LANG}{31};
  $a->{LANG}{cr} = $a->{LANG}{32};
  $a->{LANG}{cs} = $a->{LANG}{25};
  $a->{LANG}{cu} = $a->{LANG}{28};
  $a->{LANG}{cv} = $a->{LANG}{29};
  $a->{LANG}{cy} = $a->{LANG}{33};
  $a->{LANG}{da} = $a->{LANG}{34};
  $a->{LANG}{de} = $a->{LANG}{35};
  $a->{LANG}{dv} = $a->{LANG}{36};
  $a->{LANG}{dz} = $a->{LANG}{37};
  $a->{LANG}{ee} = $a->{LANG}{42};
  $a->{LANG}{el} = $a->{LANG}{38};
  $a->{LANG}{en} = $a->{LANG}{1};
  $a->{LANG}{eo} = $a->{LANG}{39};
  $a->{LANG}{es} = $a->{LANG}{150};
  $a->{LANG}{et} = $a->{LANG}{40};
  $a->{LANG}{eu} = $a->{LANG}{41};
  $a->{LANG}{fa} = $a->{LANG}{44};
  $a->{LANG}{ff} = $a->{LANG}{49};
  $a->{LANG}{fi} = $a->{LANG}{46};
  $a->{LANG}{fj} = $a->{LANG}{45};
  $a->{LANG}{fo} = $a->{LANG}{43};
  $a->{LANG}{fr} = $a->{LANG}{47};
  $a->{LANG}{fy} = $a->{LANG}{48};
  $a->{LANG}{ga} = $a->{LANG}{51};
  $a->{LANG}{gd} = $a->{LANG}{50};
  $a->{LANG}{gl} = $a->{LANG}{52};
  $a->{LANG}{gn} = $a->{LANG}{54};
  $a->{LANG}{gu} = $a->{LANG}{55};
  $a->{LANG}{gv} = $a->{LANG}{53};
  $a->{LANG}{ha} = $a->{LANG}{57};
  $a->{LANG}{he} = $a->{LANG}{59};
  $a->{LANG}{hi} = $a->{LANG}{61};
  $a->{LANG}{ho} = $a->{LANG}{62};
  $a->{LANG}{hr} = $a->{LANG}{63};
  $a->{LANG}{ht} = $a->{LANG}{56};
  $a->{LANG}{hu} = $a->{LANG}{64};
  $a->{LANG}{hy} = $a->{LANG}{65};
  $a->{LANG}{hz} = $a->{LANG}{60};
  $a->{LANG}{ia} = $a->{LANG}{71};
  $a->{LANG}{id} = $a->{LANG}{72};
  $a->{LANG}{ie} = $a->{LANG}{70};
  $a->{LANG}{ig} = $a->{LANG}{66};
  $a->{LANG}{ii} = $a->{LANG}{68};
  $a->{LANG}{ik} = $a->{LANG}{73};
  $a->{LANG}{io} = $a->{LANG}{67};
  $a->{LANG}{is} = $a->{LANG}{74};
  $a->{LANG}{it} = $a->{LANG}{75};
  $a->{LANG}{iu} = $a->{LANG}{69};
  $a->{LANG}{ja} = $a->{LANG}{77};
  $a->{LANG}{jv} = $a->{LANG}{76};
  $a->{LANG}{ka} = $a->{LANG}{81};
  $a->{LANG}{kg} = $a->{LANG}{89};
  $a->{LANG}{ki} = $a->{LANG}{85};
  $a->{LANG}{kj} = $a->{LANG}{91};
  $a->{LANG}{kk} = $a->{LANG}{83};
  $a->{LANG}{kl} = $a->{LANG}{78};
  $a->{LANG}{km} = $a->{LANG}{84};
  $a->{LANG}{kn} = $a->{LANG}{79};
  $a->{LANG}{ko} = $a->{LANG}{90};
  $a->{LANG}{kr} = $a->{LANG}{82};
  $a->{LANG}{ks} = $a->{LANG}{80};
  $a->{LANG}{ku} = $a->{LANG}{92};
  $a->{LANG}{kv} = $a->{LANG}{88};
  $a->{LANG}{kw} = $a->{LANG}{30};
  $a->{LANG}{ky} = $a->{LANG}{87};
  $a->{LANG}{la} = $a->{LANG}{94};
  $a->{LANG}{lb} = $a->{LANG}{99};
  $a->{LANG}{lg} = $a->{LANG}{101};
  $a->{LANG}{li} = $a->{LANG}{96};
  $a->{LANG}{ln} = $a->{LANG}{97};
  $a->{LANG}{lo} = $a->{LANG}{93};
  $a->{LANG}{"lt"} = $a->{LANG}{98};
  $a->{LANG}{lu} = $a->{LANG}{100};
  $a->{LANG}{lv} = $a->{LANG}{95};
  $a->{LANG}{mg} = $a->{LANG}{106};
  $a->{LANG}{mh} = $a->{LANG}{102};
  $a->{LANG}{mi} = $a->{LANG}{110};
  $a->{LANG}{mk} = $a->{LANG}{105};
  $a->{LANG}{ml} = $a->{LANG}{103};
  $a->{LANG}{mn} = $a->{LANG}{109};
  $a->{LANG}{mo} = $a->{LANG}{108};
  $a->{LANG}{mr} = $a->{LANG}{104};
  $a->{LANG}{ms} = $a->{LANG}{111};
  $a->{LANG}{mt} = $a->{LANG}{107};
  $a->{LANG}{"my"} = $a->{LANG}{112};
  $a->{LANG}{na} = $a->{LANG}{113};
  $a->{LANG}{nb} = $a->{LANG}{121};
  $a->{LANG}{nd} = $a->{LANG}{116};
  $a->{LANG}{"ne"} = $a->{LANG}{118};
  $a->{LANG}{ng} = $a->{LANG}{117};
  $a->{LANG}{nl} = $a->{LANG}{119};
  $a->{LANG}{nn} = $a->{LANG}{120};
  $a->{LANG}{"no"} = $a->{LANG}{122};
  $a->{LANG}{nr} = $a->{LANG}{115};
  $a->{LANG}{nv} = $a->{LANG}{114};
  $a->{LANG}{ny} = $a->{LANG}{123};
  $a->{LANG}{oc} = $a->{LANG}{124};
  $a->{LANG}{oj} = $a->{LANG}{125};
  $a->{LANG}{om} = $a->{LANG}{127};
  $a->{LANG}{"or"} = $a->{LANG}{126};
  $a->{LANG}{os} = $a->{LANG}{128};
  $a->{LANG}{pa} = $a->{LANG}{129};
  $a->{LANG}{pi} = $a->{LANG}{130};
  $a->{LANG}{pl} = $a->{LANG}{131};
  $a->{LANG}{ps} = $a->{LANG}{133};
  $a->{LANG}{pt} = $a->{LANG}{132};
  $a->{LANG}{qu} = $a->{LANG}{134};
  $a->{LANG}{rm} = $a->{LANG}{135};
  $a->{LANG}{rn} = $a->{LANG}{137};
  $a->{LANG}{ro} = $a->{LANG}{136};
  $a->{LANG}{ru} = $a->{LANG}{138};
  $a->{LANG}{rw} = $a->{LANG}{86};
  $a->{LANG}{sa} = $a->{LANG}{140};
  $a->{LANG}{sc} = $a->{LANG}{152};
  $a->{LANG}{sd} = $a->{LANG}{147};
  $a->{LANG}{se} = $a->{LANG}{144};
  $a->{LANG}{sg} = $a->{LANG}{139};
  $a->{LANG}{sh} = $a->{LANG}{58};
  $a->{LANG}{si} = $a->{LANG}{141};
  $a->{LANG}{sk} = $a->{LANG}{142};
  $a->{LANG}{sl} = $a->{LANG}{143};
  $a->{LANG}{sm} = $a->{LANG}{145};
  $a->{LANG}{sn} = $a->{LANG}{146};
  $a->{LANG}{so} = $a->{LANG}{148};
  $a->{LANG}{sq} = $a->{LANG}{151};
  $a->{LANG}{sr} = $a->{LANG}{153};
  $a->{LANG}{ss} = $a->{LANG}{154};
  $a->{LANG}{st} = $a->{LANG}{149};
  $a->{LANG}{su} = $a->{LANG}{155};
  $a->{LANG}{sv} = $a->{LANG}{157};
  $a->{LANG}{sw} = $a->{LANG}{156};
  $a->{LANG}{ta} = $a->{LANG}{159};
  $a->{LANG}{te} = $a->{LANG}{161};
  $a->{LANG}{tg} = $a->{LANG}{162};
  $a->{LANG}{th} = $a->{LANG}{164};
  $a->{LANG}{ti} = $a->{LANG}{165};
  $a->{LANG}{tk} = $a->{LANG}{169};
  $a->{LANG}{tl} = $a->{LANG}{163};
  $a->{LANG}{tn} = $a->{LANG}{167};
  $a->{LANG}{to} = $a->{LANG}{166};
  $a->{LANG}{"tr"} = $a->{LANG}{170};
  $a->{LANG}{ts} = $a->{LANG}{168};
  $a->{LANG}{tt} = $a->{LANG}{160};
  $a->{LANG}{tw} = $a->{LANG}{171};
  $a->{LANG}{ty} = $a->{LANG}{158};
  $a->{LANG}{ug} = $a->{LANG}{172};
  $a->{LANG}{uk} = $a->{LANG}{173};
  $a->{LANG}{ur} = $a->{LANG}{174};
  $a->{LANG}{uz} = $a->{LANG}{175};
  $a->{LANG}{ve} = $a->{LANG}{176};
  $a->{LANG}{vi} = $a->{LANG}{177};
  $a->{LANG}{vo} = $a->{LANG}{178};
  $a->{LANG}{wa} = $a->{LANG}{179};
  $a->{LANG}{wo} = $a->{LANG}{180};
  $a->{LANG}{xh} = $a->{LANG}{181};
  $a->{LANG}{yi} = $a->{LANG}{182};
  $a->{LANG}{yo} = $a->{LANG}{183};
  $a->{LANG}{za} = $a->{LANG}{184};
  $a->{LANG}{zh} = $a->{LANG}{185};
  $a->{LANG}{zu} = $a->{LANG}{186};
  $a->{MISC}{X} = $a->{MISC}{1};
  $a->{MISC}{abbr} = $a->{MISC}{2};
  $a->{MISC}{aphorism} = $a->{MISC}{82};
  $a->{MISC}{arch} = $a->{MISC}{3};
  $a->{MISC}{chn} = $a->{MISC}{4};
  $a->{MISC}{col} = $a->{MISC}{5};
  $a->{MISC}{derog} = $a->{MISC}{6};
  $a->{MISC}{eK} = $a->{MISC}{7};
  $a->{MISC}{fam} = $a->{MISC}{8};
  $a->{MISC}{fem} = $a->{MISC}{9};
  $a->{MISC}{hon} = $a->{MISC}{11};
  $a->{MISC}{hum} = $a->{MISC}{12};
  $a->{MISC}{id} = $a->{MISC}{13};
  $a->{MISC}{"m-sl"} = $a->{MISC}{14};
  $a->{MISC}{male} = $a->{MISC}{15};
  $a->{MISC}{obs} = $a->{MISC}{17};
  $a->{MISC}{obsc} = $a->{MISC}{18};
  $a->{MISC}{poet} = $a->{MISC}{26};
  $a->{MISC}{pol} = $a->{MISC}{19};
  $a->{MISC}{proverb} = $a->{MISC}{81};
  $a->{MISC}{quote} = $a->{MISC}{83};
  $a->{MISC}{rare} = $a->{MISC}{20};
  $a->{MISC}{sens} = $a->{MISC}{25};
  $a->{MISC}{sl} = $a->{MISC}{21};
  $a->{MISC}{uk} = $a->{MISC}{22};
  $a->{MISC}{vulg} = $a->{MISC}{24};
  $a->{POS}{adj} = $a->{POS}{1};
  $a->{POS}{"adj-na"} = $a->{POS}{2};
  $a->{POS}{"adj-no"} = $a->{POS}{3};
  $a->{POS}{"adj-pn"} = $a->{POS}{4};
  $a->{POS}{"adj-t"} = $a->{POS}{5};
  $a->{POS}{adv} = $a->{POS}{6};
  $a->{POS}{"adv-to"} = $a->{POS}{8};
  $a->{POS}{aux} = $a->{POS}{9};
  $a->{POS}{"aux-adj"} = $a->{POS}{10};
  $a->{POS}{"aux-v"} = $a->{POS}{11};
  $a->{POS}{company} = $a->{POS}{184};
  $a->{POS}{conj} = $a->{POS}{12};
  $a->{POS}{ctr} = $a->{POS}{51};
  $a->{POS}{"exp"} = $a->{POS}{13};
  $a->{POS}{fem} = $a->{POS}{187};
  $a->{POS}{given} = $a->{POS}{189};
  $a->{POS}{"int"} = $a->{POS}{14};
  $a->{POS}{masc} = $a->{POS}{186};
  $a->{POS}{n} = $a->{POS}{17};
  $a->{POS}{"n-adv"} = $a->{POS}{18};
  $a->{POS}{"n-pref"} = $a->{POS}{20};
  $a->{POS}{"n-suf"} = $a->{POS}{19};
  $a->{POS}{"n-t"} = $a->{POS}{21};
  $a->{POS}{num} = $a->{POS}{24};
  $a->{POS}{person} = $a->{POS}{188};
  $a->{POS}{place} = $a->{POS}{182};
  $a->{POS}{pref} = $a->{POS}{25};
  $a->{POS}{product} = $a->{POS}{185};
  $a->{POS}{prt} = $a->{POS}{26};
  $a->{POS}{station} = $a->{POS}{190};
  $a->{POS}{suf} = $a->{POS}{27};
  $a->{POS}{surname} = $a->{POS}{181};
  $a->{POS}{unclass} = $a->{POS}{183};
  $a->{POS}{v1} = $a->{POS}{28};
  $a->{POS}{v4r} = $a->{POS}{53};
  $a->{POS}{v5} = $a->{POS}{29};
  $a->{POS}{v5aru} = $a->{POS}{30};
  $a->{POS}{v5b} = $a->{POS}{31};
  $a->{POS}{v5g} = $a->{POS}{32};
  $a->{POS}{v5k} = $a->{POS}{33};
  $a->{POS}{"v5k-s"} = $a->{POS}{34};
  $a->{POS}{v5m} = $a->{POS}{35};
  $a->{POS}{v5n} = $a->{POS}{36};
  $a->{POS}{v5r} = $a->{POS}{37};
  $a->{POS}{"v5r-i"} = $a->{POS}{38};
  $a->{POS}{v5s} = $a->{POS}{39};
  $a->{POS}{v5t} = $a->{POS}{40};
  $a->{POS}{v5u} = $a->{POS}{41};
  $a->{POS}{"v5u-s"} = $a->{POS}{42};
  $a->{POS}{v5uru} = $a->{POS}{43};
  $a->{POS}{v5z} = $a->{POS}{55};
  $a->{POS}{vi} = $a->{POS}{44};
  $a->{POS}{vk} = $a->{POS}{45};
  $a->{POS}{vn} = $a->{POS}{52};
  $a->{POS}{vs} = $a->{POS}{46};
  $a->{POS}{"vs-i"} = $a->{POS}{48};
  $a->{POS}{"vs-s"} = $a->{POS}{47};
  $a->{POS}{vt} = $a->{POS}{50};
  $a->{POS}{vz} = $a->{POS}{49};
  $a->{RINF}{gikun} = $a->{RINF}{1};
  $a->{RINF}{go} = $a->{RINF}{130};
  $a->{RINF}{ik} = $a->{RINF}{3};
  $a->{RINF}{jouyou} = $a->{RINF}{105};
  $a->{RINF}{kan} = $a->{RINF}{129};
  $a->{RINF}{kanyou} = $a->{RINF}{132};
  $a->{RINF}{kun} = $a->{RINF}{106};
  $a->{RINF}{name} = $a->{RINF}{103};
  $a->{RINF}{ok} = $a->{RINF}{2};
  $a->{RINF}{on} = $a->{RINF}{128};
  $a->{RINF}{rad} = $a->{RINF}{104};
  $a->{RINF}{tou} = $a->{RINF}{131};
  $a->{RINF}{uK} = $a->{RINF}{4};
  $a->{STAT}{A} = $a->{STAT}{2};
  $a->{STAT}{D} = $a->{STAT}{4};
  $a->{STAT}{N} = $a->{STAT}{1};
  $a->{STAT}{R} = $a->{STAT}{6};
  $a->{XREF}{ant} = $a->{XREF}{2};
  $a->{XREF}{cf} = $a->{XREF}{4};
  $a->{XREF}{ex} = $a->{XREF}{5};
  $a->{XREF}{kvar} = $a->{XREF}{8};
  $a->{XREF}{pref} = $a->{XREF}{7};
  $a->{XREF}{see} = $a->{XREF}{3};
  $a->{XREF}{syn} = $a->{XREF}{1};
  $a->{XREF}{uses} = $a->{XREF}{6};
  $a;
}; 

1;
