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
    @EXPORT   = qw($Kdws $KWGINF_equ $KWGINF_expl $KWGINF_id $KWGINF_lit $KWMISC_X $KWMISC_abbr $KWMISC_aphorism $KWMISC_arch $KWMISC_chn $KWMISC_col $KWMISC_derog $KWMISC_eK $KWMISC_fam $KWMISC_fem $KWMISC_hon $KWMISC_hum $KWMISC_id $KWMISC_m_sl $KWMISC_male $KWMISC_obs $KWMISC_obsc $KWMISC_poet $KWMISC_pol $KWMISC_proverb $KWMISC_quote $KWMISC_rare $KWMISC_sens $KWMISC_sl $KWMISC_uk $KWMISC_vulg $KWFREQ_gA $KWFREQ_gai $KWFREQ_ichi $KWFREQ_news $KWFREQ_nf $KWFREQ_spec $KWXREF_ant $KWXREF_cf $KWXREF_ex $KWXREF_kvar $KWXREF_pref $KWXREF_see $KWXREF_syn $KWXREF_uses $KWSTAT_A $KWSTAT_D $KWSTAT_N $KWSTAT_R $KWRINF_gikun $KWRINF_go $KWRINF_ik $KWRINF_jouyou $KWRINF_kan $KWRINF_kanyou $KWRINF_kun $KWRINF_name $KWRINF_ok $KWRINF_on $KWRINF_rad $KWRINF_tou $KWRINF_uK $KWKINF_ateji $KWKINF_iK $KWKINF_ik $KWKINF_io $KWKINF_oK $KWCINF_busy_people $KWCINF_crowley $KWCINF_deroo $KWCINF_four_corner $KWCINF_gakken $KWCINF_halpern_kkld $KWCINF_halpern_njecd $KWCINF_heisig $KWCINF_henshall $KWCINF_henshall3 $KWCINF_jf_cards $KWCINF_jis208 $KWCINF_jis212 $KWCINF_jis213 $KWCINF_kanji_in_ctx $KWCINF_kodansha_comp $KWCINF_korean_h $KWCINF_korean_r $KWCINF_misclass $KWCINF_moro $KWCINF_nelson_c $KWCINF_nelson_n $KWCINF_nelson_rad $KWCINF_oneill_kk $KWCINF_oneill_names $KWCINF_pinyin $KWCINF_s_h $KWCINF_sakade $KWCINF_sh_desc $KWCINF_sh_kk $KWCINF_skip $KWCINF_skip_mis $KWCINF_strokes $KWCINF_tutt_cards $KWFLD_Buddh $KWFLD_MA $KWFLD_comp $KWFLD_food $KWFLD_geom $KWFLD_ling $KWFLD_math $KWFLD_mil $KWFLD_physics $KWLANG_abk $KWLANG_ace $KWLANG_ach $KWLANG_ada $KWLANG_ady $KWLANG_afa $KWLANG_afh $KWLANG_afr $KWLANG_ain $KWLANG_aka $KWLANG_akk $KWLANG_alb $KWLANG_ale $KWLANG_alg $KWLANG_alt $KWLANG_amh $KWLANG_ang $KWLANG_anp $KWLANG_apa $KWLANG_ara $KWLANG_arc $KWLANG_arg $KWLANG_arm $KWLANG_arn $KWLANG_arp $KWLANG_art $KWLANG_arw $KWLANG_asm $KWLANG_ast $KWLANG_ath $KWLANG_aus $KWLANG_ava $KWLANG_ave $KWLANG_awa $KWLANG_aym $KWLANG_aze $KWLANG_bad $KWLANG_bai $KWLANG_bak $KWLANG_bal $KWLANG_bam $KWLANG_ban $KWLANG_baq $KWLANG_bas $KWLANG_bat $KWLANG_bej $KWLANG_bel $KWLANG_bem $KWLANG_ben $KWLANG_ber $KWLANG_bho $KWLANG_bih $KWLANG_bik $KWLANG_bin $KWLANG_bis $KWLANG_bla $KWLANG_bnt $KWLANG_bos $KWLANG_bra $KWLANG_bre $KWLANG_btk $KWLANG_bua $KWLANG_bug $KWLANG_bul $KWLANG_bur $KWLANG_byn $KWLANG_cad $KWLANG_cai $KWLANG_car $KWLANG_cat $KWLANG_cau $KWLANG_ceb $KWLANG_cel $KWLANG_cha $KWLANG_chb $KWLANG_che $KWLANG_chg $KWLANG_chi $KWLANG_chk $KWLANG_chm $KWLANG_chn $KWLANG_cho $KWLANG_chp $KWLANG_chr $KWLANG_chu $KWLANG_chv $KWLANG_chy $KWLANG_cmc $KWLANG_cop $KWLANG_cor $KWLANG_cos $KWLANG_cpe $KWLANG_cpf $KWLANG_cpp $KWLANG_cre $KWLANG_crh $KWLANG_crp $KWLANG_csb $KWLANG_cus $KWLANG_cze $KWLANG_dak $KWLANG_dan $KWLANG_dar $KWLANG_day $KWLANG_del $KWLANG_den $KWLANG_dgr $KWLANG_din $KWLANG_div $KWLANG_doi $KWLANG_dra $KWLANG_dsb $KWLANG_dua $KWLANG_dum $KWLANG_dut $KWLANG_dyu $KWLANG_dzo $KWLANG_efi $KWLANG_egy $KWLANG_eka $KWLANG_elx $KWLANG_eng $KWLANG_enm $KWLANG_epo $KWLANG_est $KWLANG_ewe $KWLANG_ewo $KWLANG_fan $KWLANG_fao $KWLANG_fat $KWLANG_fij $KWLANG_fil $KWLANG_fin $KWLANG_fiu $KWLANG_fon $KWLANG_fre $KWLANG_frm $KWLANG_fro $KWLANG_frr $KWLANG_frs $KWLANG_fry $KWLANG_ful $KWLANG_fur $KWLANG_gaa $KWLANG_gay $KWLANG_gba $KWLANG_gem $KWLANG_geo $KWLANG_ger $KWLANG_gez $KWLANG_gil $KWLANG_gla $KWLANG_gle $KWLANG_glg $KWLANG_glv $KWLANG_gmh $KWLANG_goh $KWLANG_gon $KWLANG_gor $KWLANG_got $KWLANG_grb $KWLANG_grc $KWLANG_gre $KWLANG_grn $KWLANG_gsw $KWLANG_guj $KWLANG_gwi $KWLANG_hai $KWLANG_hat $KWLANG_hau $KWLANG_haw $KWLANG_heb $KWLANG_her $KWLANG_hil $KWLANG_him $KWLANG_hin $KWLANG_hit $KWLANG_hmn $KWLANG_hmo $KWLANG_hsb $KWLANG_hun $KWLANG_hup $KWLANG_iba $KWLANG_ibo $KWLANG_ice $KWLANG_ido $KWLANG_iii $KWLANG_ijo $KWLANG_iku $KWLANG_ile $KWLANG_ilo $KWLANG_ina $KWLANG_inc $KWLANG_ind $KWLANG_ine $KWLANG_inh $KWLANG_ipk $KWLANG_ira $KWLANG_iro $KWLANG_ita $KWLANG_jav $KWLANG_jbo $KWLANG_jpn $KWLANG_jpr $KWLANG_jrb $KWLANG_kaa $KWLANG_kab $KWLANG_kac $KWLANG_kal $KWLANG_kam $KWLANG_kan $KWLANG_kar $KWLANG_kas $KWLANG_kau $KWLANG_kaw $KWLANG_kaz $KWLANG_kbd $KWLANG_kha $KWLANG_khi $KWLANG_khm $KWLANG_kho $KWLANG_kik $KWLANG_kin $KWLANG_kir $KWLANG_kmb $KWLANG_kok $KWLANG_kom $KWLANG_kon $KWLANG_kor $KWLANG_kos $KWLANG_kpe $KWLANG_krc $KWLANG_krl $KWLANG_kro $KWLANG_kru $KWLANG_kua $KWLANG_kum $KWLANG_kur $KWLANG_kut $KWLANG_lad $KWLANG_lah $KWLANG_lam $KWLANG_lao $KWLANG_lat $KWLANG_lav $KWLANG_lez $KWLANG_lim $KWLANG_lin $KWLANG_lit $KWLANG_lol $KWLANG_loz $KWLANG_ltz $KWLANG_lua $KWLANG_lub $KWLANG_lug $KWLANG_lui $KWLANG_lun $KWLANG_luo $KWLANG_lus $KWLANG_mac $KWLANG_mad $KWLANG_mag $KWLANG_mah $KWLANG_mai $KWLANG_mak $KWLANG_mal $KWLANG_man $KWLANG_mao $KWLANG_map $KWLANG_mar $KWLANG_mas $KWLANG_may $KWLANG_mdf $KWLANG_mdr $KWLANG_men $KWLANG_mga $KWLANG_mic $KWLANG_min $KWLANG_mis $KWLANG_mkh $KWLANG_mlg $KWLANG_mlt $KWLANG_mnc $KWLANG_mni $KWLANG_mno $KWLANG_moh $KWLANG_mol $KWLANG_mon $KWLANG_mos $KWLANG_mul $KWLANG_mun $KWLANG_mus $KWLANG_mwl $KWLANG_mwr $KWLANG_myn $KWLANG_myv $KWLANG_nah $KWLANG_nai $KWLANG_nap $KWLANG_nau $KWLANG_nav $KWLANG_nbl $KWLANG_nde $KWLANG_ndo $KWLANG_nds $KWLANG_nep $KWLANG_new $KWLANG_nia $KWLANG_nic $KWLANG_niu $KWLANG_nno $KWLANG_nob $KWLANG_nog $KWLANG_non $KWLANG_nor $KWLANG_nqo $KWLANG_nso $KWLANG_nub $KWLANG_nwc $KWLANG_nya $KWLANG_nym $KWLANG_nyn $KWLANG_nyo $KWLANG_nzi $KWLANG_oci $KWLANG_oji $KWLANG_ori $KWLANG_orm $KWLANG_osa $KWLANG_oss $KWLANG_ota $KWLANG_oto $KWLANG_paa $KWLANG_pag $KWLANG_pal $KWLANG_pam $KWLANG_pan $KWLANG_pap $KWLANG_pau $KWLANG_peo $KWLANG_per $KWLANG_phi $KWLANG_phn $KWLANG_pli $KWLANG_pol $KWLANG_pon $KWLANG_por $KWLANG_pra $KWLANG_pro $KWLANG_pus $KWLANG_que $KWLANG_raj $KWLANG_rap $KWLANG_rar $KWLANG_roa $KWLANG_roh $KWLANG_rom $KWLANG_rum $KWLANG_run $KWLANG_rup $KWLANG_rus $KWLANG_sad $KWLANG_sag $KWLANG_sah $KWLANG_sai $KWLANG_sal $KWLANG_sam $KWLANG_san $KWLANG_sas $KWLANG_sat $KWLANG_scc $KWLANG_scn $KWLANG_sco $KWLANG_scr $KWLANG_sel $KWLANG_sem $KWLANG_sga $KWLANG_sgn $KWLANG_shn $KWLANG_sid $KWLANG_sin $KWLANG_sio $KWLANG_sit $KWLANG_sla $KWLANG_slo $KWLANG_slv $KWLANG_sma $KWLANG_sme $KWLANG_smi $KWLANG_smj $KWLANG_smn $KWLANG_smo $KWLANG_sms $KWLANG_sna $KWLANG_snd $KWLANG_snk $KWLANG_sog $KWLANG_som $KWLANG_son $KWLANG_sot $KWLANG_spa $KWLANG_srd $KWLANG_srn $KWLANG_srr $KWLANG_ssa $KWLANG_ssw $KWLANG_suk $KWLANG_sun $KWLANG_sus $KWLANG_sux $KWLANG_swa $KWLANG_swe $KWLANG_syc $KWLANG_syr $KWLANG_tah $KWLANG_tai $KWLANG_tam $KWLANG_tat $KWLANG_tel $KWLANG_tem $KWLANG_ter $KWLANG_tet $KWLANG_tgk $KWLANG_tgl $KWLANG_tha $KWLANG_tib $KWLANG_tig $KWLANG_tir $KWLANG_tiv $KWLANG_tkl $KWLANG_tlh $KWLANG_tli $KWLANG_tmh $KWLANG_tog $KWLANG_ton $KWLANG_tpi $KWLANG_tsi $KWLANG_tsn $KWLANG_tso $KWLANG_tuk $KWLANG_tum $KWLANG_tup $KWLANG_tur $KWLANG_tut $KWLANG_tvl $KWLANG_twi $KWLANG_tyv $KWLANG_udm $KWLANG_uga $KWLANG_uig $KWLANG_ukr $KWLANG_umb $KWLANG_und $KWLANG_urd $KWLANG_uzb $KWLANG_vai $KWLANG_ven $KWLANG_vie $KWLANG_vol $KWLANG_vot $KWLANG_wak $KWLANG_wal $KWLANG_war $KWLANG_was $KWLANG_wel $KWLANG_wen $KWLANG_wln $KWLANG_wol $KWLANG_xal $KWLANG_xho $KWLANG_yao $KWLANG_yap $KWLANG_yid $KWLANG_yor $KWLANG_ypk $KWLANG_zap $KWLANG_zbl $KWLANG_zen $KWLANG_zha $KWLANG_znd $KWLANG_zul $KWLANG_zun $KWLANG_zxx $KWLANG_zza $KWDIAL_ksb $KWDIAL_ktb $KWDIAL_kyb $KWDIAL_kyu $KWDIAL_osb $KWDIAL_rkb $KWDIAL_std $KWDIAL_thb $KWDIAL_tsb $KWDIAL_tsug $KWPOS_adj $KWPOS_adj_f $KWPOS_adj_i $KWPOS_adj_na $KWPOS_adj_no $KWPOS_adj_pn $KWPOS_adj_t $KWPOS_adv $KWPOS_adv_to $KWPOS_aux $KWPOS_aux_adj $KWPOS_aux_v $KWPOS_company $KWPOS_conj $KWPOS_ctr $KWPOS_exp $KWPOS_fem $KWPOS_given $KWPOS_int $KWPOS_masc $KWPOS_n $KWPOS_n_adv $KWPOS_n_pref $KWPOS_n_suf $KWPOS_n_t $KWPOS_num $KWPOS_person $KWPOS_place $KWPOS_pref $KWPOS_product $KWPOS_prt $KWPOS_station $KWPOS_suf $KWPOS_surname $KWPOS_unclass $KWPOS_v1 $KWPOS_v4r $KWPOS_v5 $KWPOS_v5aru $KWPOS_v5b $KWPOS_v5g $KWPOS_v5k $KWPOS_v5k_s $KWPOS_v5m $KWPOS_v5n $KWPOS_v5r $KWPOS_v5r_i $KWPOS_v5s $KWPOS_v5t $KWPOS_v5u $KWPOS_v5u_s $KWPOS_v5uru $KWPOS_v5z $KWPOS_vi $KWPOS_vk $KWPOS_vn $KWPOS_vs $KWPOS_vs_i $KWPOS_vs_s $KWPOS_vt $KWPOS_vz); }

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
our($KWLANG_abk) = 2;
our($KWLANG_ace) = 3;
our($KWLANG_ach) = 4;
our($KWLANG_ada) = 5;
our($KWLANG_ady) = 6;
our($KWLANG_afa) = 7;
our($KWLANG_afh) = 8;
our($KWLANG_afr) = 9;
our($KWLANG_ain) = 10;
our($KWLANG_aka) = 11;
our($KWLANG_akk) = 12;
our($KWLANG_alb) = 13;
our($KWLANG_ale) = 14;
our($KWLANG_alg) = 15;
our($KWLANG_alt) = 16;
our($KWLANG_amh) = 17;
our($KWLANG_ang) = 18;
our($KWLANG_anp) = 19;
our($KWLANG_apa) = 20;
our($KWLANG_ara) = 21;
our($KWLANG_arc) = 22;
our($KWLANG_arg) = 23;
our($KWLANG_arm) = 24;
our($KWLANG_arn) = 25;
our($KWLANG_arp) = 26;
our($KWLANG_art) = 27;
our($KWLANG_arw) = 28;
our($KWLANG_asm) = 29;
our($KWLANG_ast) = 30;
our($KWLANG_ath) = 31;
our($KWLANG_aus) = 32;
our($KWLANG_ava) = 33;
our($KWLANG_ave) = 34;
our($KWLANG_awa) = 35;
our($KWLANG_aym) = 36;
our($KWLANG_aze) = 37;
our($KWLANG_bad) = 38;
our($KWLANG_bai) = 39;
our($KWLANG_bak) = 40;
our($KWLANG_bal) = 41;
our($KWLANG_bam) = 42;
our($KWLANG_ban) = 43;
our($KWLANG_baq) = 44;
our($KWLANG_bas) = 45;
our($KWLANG_bat) = 46;
our($KWLANG_bej) = 47;
our($KWLANG_bel) = 48;
our($KWLANG_bem) = 49;
our($KWLANG_ben) = 50;
our($KWLANG_ber) = 51;
our($KWLANG_bho) = 52;
our($KWLANG_bih) = 53;
our($KWLANG_bik) = 54;
our($KWLANG_bin) = 55;
our($KWLANG_bis) = 56;
our($KWLANG_bla) = 57;
our($KWLANG_bnt) = 58;
our($KWLANG_bos) = 59;
our($KWLANG_bra) = 60;
our($KWLANG_bre) = 61;
our($KWLANG_btk) = 62;
our($KWLANG_bua) = 63;
our($KWLANG_bug) = 64;
our($KWLANG_bul) = 65;
our($KWLANG_bur) = 66;
our($KWLANG_byn) = 67;
our($KWLANG_cad) = 68;
our($KWLANG_cai) = 69;
our($KWLANG_car) = 70;
our($KWLANG_cat) = 71;
our($KWLANG_cau) = 72;
our($KWLANG_ceb) = 73;
our($KWLANG_cel) = 74;
our($KWLANG_cha) = 75;
our($KWLANG_chb) = 76;
our($KWLANG_che) = 77;
our($KWLANG_chg) = 78;
our($KWLANG_chi) = 79;
our($KWLANG_chk) = 80;
our($KWLANG_chm) = 81;
our($KWLANG_chn) = 82;
our($KWLANG_cho) = 83;
our($KWLANG_chp) = 84;
our($KWLANG_chr) = 85;
our($KWLANG_chu) = 86;
our($KWLANG_chv) = 87;
our($KWLANG_chy) = 88;
our($KWLANG_cmc) = 89;
our($KWLANG_cop) = 90;
our($KWLANG_cor) = 91;
our($KWLANG_cos) = 92;
our($KWLANG_cpe) = 93;
our($KWLANG_cpf) = 94;
our($KWLANG_cpp) = 95;
our($KWLANG_cre) = 96;
our($KWLANG_crh) = 97;
our($KWLANG_crp) = 98;
our($KWLANG_csb) = 99;
our($KWLANG_cus) = 100;
our($KWLANG_cze) = 101;
our($KWLANG_dak) = 102;
our($KWLANG_dan) = 103;
our($KWLANG_dar) = 104;
our($KWLANG_day) = 105;
our($KWLANG_del) = 106;
our($KWLANG_den) = 107;
our($KWLANG_dgr) = 108;
our($KWLANG_din) = 109;
our($KWLANG_div) = 110;
our($KWLANG_doi) = 111;
our($KWLANG_dra) = 112;
our($KWLANG_dsb) = 113;
our($KWLANG_dua) = 114;
our($KWLANG_dum) = 115;
our($KWLANG_dut) = 116;
our($KWLANG_dyu) = 117;
our($KWLANG_dzo) = 118;
our($KWLANG_efi) = 119;
our($KWLANG_egy) = 120;
our($KWLANG_eka) = 121;
our($KWLANG_elx) = 122;
our($KWLANG_eng) = 1;
our($KWLANG_enm) = 124;
our($KWLANG_epo) = 125;
our($KWLANG_est) = 126;
our($KWLANG_ewe) = 127;
our($KWLANG_ewo) = 128;
our($KWLANG_fan) = 129;
our($KWLANG_fao) = 130;
our($KWLANG_fat) = 131;
our($KWLANG_fij) = 132;
our($KWLANG_fil) = 133;
our($KWLANG_fin) = 134;
our($KWLANG_fiu) = 135;
our($KWLANG_fon) = 136;
our($KWLANG_fre) = 137;
our($KWLANG_frm) = 138;
our($KWLANG_fro) = 139;
our($KWLANG_frr) = 140;
our($KWLANG_frs) = 141;
our($KWLANG_fry) = 142;
our($KWLANG_ful) = 143;
our($KWLANG_fur) = 144;
our($KWLANG_gaa) = 145;
our($KWLANG_gay) = 146;
our($KWLANG_gba) = 147;
our($KWLANG_gem) = 148;
our($KWLANG_geo) = 149;
our($KWLANG_ger) = 150;
our($KWLANG_gez) = 151;
our($KWLANG_gil) = 152;
our($KWLANG_gla) = 153;
our($KWLANG_gle) = 154;
our($KWLANG_glg) = 155;
our($KWLANG_glv) = 156;
our($KWLANG_gmh) = 157;
our($KWLANG_goh) = 158;
our($KWLANG_gon) = 159;
our($KWLANG_gor) = 160;
our($KWLANG_got) = 161;
our($KWLANG_grb) = 162;
our($KWLANG_grc) = 163;
our($KWLANG_gre) = 164;
our($KWLANG_grn) = 165;
our($KWLANG_gsw) = 166;
our($KWLANG_guj) = 167;
our($KWLANG_gwi) = 168;
our($KWLANG_hai) = 169;
our($KWLANG_hat) = 170;
our($KWLANG_hau) = 171;
our($KWLANG_haw) = 172;
our($KWLANG_heb) = 173;
our($KWLANG_her) = 174;
our($KWLANG_hil) = 175;
our($KWLANG_him) = 176;
our($KWLANG_hin) = 177;
our($KWLANG_hit) = 178;
our($KWLANG_hmn) = 179;
our($KWLANG_hmo) = 180;
our($KWLANG_hsb) = 181;
our($KWLANG_hun) = 182;
our($KWLANG_hup) = 183;
our($KWLANG_iba) = 184;
our($KWLANG_ibo) = 185;
our($KWLANG_ice) = 186;
our($KWLANG_ido) = 187;
our($KWLANG_iii) = 188;
our($KWLANG_ijo) = 189;
our($KWLANG_iku) = 190;
our($KWLANG_ile) = 191;
our($KWLANG_ilo) = 192;
our($KWLANG_ina) = 193;
our($KWLANG_inc) = 194;
our($KWLANG_ind) = 195;
our($KWLANG_ine) = 196;
our($KWLANG_inh) = 197;
our($KWLANG_ipk) = 198;
our($KWLANG_ira) = 199;
our($KWLANG_iro) = 200;
our($KWLANG_ita) = 201;
our($KWLANG_jav) = 202;
our($KWLANG_jbo) = 203;
our($KWLANG_jpn) = 204;
our($KWLANG_jpr) = 205;
our($KWLANG_jrb) = 206;
our($KWLANG_kaa) = 207;
our($KWLANG_kab) = 208;
our($KWLANG_kac) = 209;
our($KWLANG_kal) = 210;
our($KWLANG_kam) = 211;
our($KWLANG_kan) = 212;
our($KWLANG_kar) = 213;
our($KWLANG_kas) = 214;
our($KWLANG_kau) = 215;
our($KWLANG_kaw) = 216;
our($KWLANG_kaz) = 217;
our($KWLANG_kbd) = 218;
our($KWLANG_kha) = 219;
our($KWLANG_khi) = 220;
our($KWLANG_khm) = 221;
our($KWLANG_kho) = 222;
our($KWLANG_kik) = 223;
our($KWLANG_kin) = 224;
our($KWLANG_kir) = 225;
our($KWLANG_kmb) = 226;
our($KWLANG_kok) = 227;
our($KWLANG_kom) = 228;
our($KWLANG_kon) = 229;
our($KWLANG_kor) = 230;
our($KWLANG_kos) = 231;
our($KWLANG_kpe) = 232;
our($KWLANG_krc) = 233;
our($KWLANG_krl) = 234;
our($KWLANG_kro) = 235;
our($KWLANG_kru) = 236;
our($KWLANG_kua) = 237;
our($KWLANG_kum) = 238;
our($KWLANG_kur) = 239;
our($KWLANG_kut) = 240;
our($KWLANG_lad) = 241;
our($KWLANG_lah) = 242;
our($KWLANG_lam) = 243;
our($KWLANG_lao) = 244;
our($KWLANG_lat) = 245;
our($KWLANG_lav) = 246;
our($KWLANG_lez) = 247;
our($KWLANG_lim) = 248;
our($KWLANG_lin) = 249;
our($KWLANG_lit) = 250;
our($KWLANG_lol) = 251;
our($KWLANG_loz) = 252;
our($KWLANG_ltz) = 253;
our($KWLANG_lua) = 254;
our($KWLANG_lub) = 255;
our($KWLANG_lug) = 256;
our($KWLANG_lui) = 257;
our($KWLANG_lun) = 258;
our($KWLANG_luo) = 259;
our($KWLANG_lus) = 260;
our($KWLANG_mac) = 261;
our($KWLANG_mad) = 262;
our($KWLANG_mag) = 263;
our($KWLANG_mah) = 264;
our($KWLANG_mai) = 265;
our($KWLANG_mak) = 266;
our($KWLANG_mal) = 267;
our($KWLANG_man) = 268;
our($KWLANG_mao) = 269;
our($KWLANG_map) = 270;
our($KWLANG_mar) = 271;
our($KWLANG_mas) = 272;
our($KWLANG_may) = 273;
our($KWLANG_mdf) = 274;
our($KWLANG_mdr) = 275;
our($KWLANG_men) = 276;
our($KWLANG_mga) = 277;
our($KWLANG_mic) = 278;
our($KWLANG_min) = 279;
our($KWLANG_mis) = 280;
our($KWLANG_mkh) = 281;
our($KWLANG_mlg) = 282;
our($KWLANG_mlt) = 283;
our($KWLANG_mnc) = 284;
our($KWLANG_mni) = 285;
our($KWLANG_mno) = 286;
our($KWLANG_moh) = 287;
our($KWLANG_mol) = 288;
our($KWLANG_mon) = 289;
our($KWLANG_mos) = 290;
our($KWLANG_mul) = 291;
our($KWLANG_mun) = 292;
our($KWLANG_mus) = 293;
our($KWLANG_mwl) = 294;
our($KWLANG_mwr) = 295;
our($KWLANG_myn) = 296;
our($KWLANG_myv) = 297;
our($KWLANG_nah) = 298;
our($KWLANG_nai) = 299;
our($KWLANG_nap) = 300;
our($KWLANG_nau) = 301;
our($KWLANG_nav) = 302;
our($KWLANG_nbl) = 303;
our($KWLANG_nde) = 304;
our($KWLANG_ndo) = 305;
our($KWLANG_nds) = 306;
our($KWLANG_nep) = 307;
our($KWLANG_new) = 308;
our($KWLANG_nia) = 309;
our($KWLANG_nic) = 310;
our($KWLANG_niu) = 311;
our($KWLANG_nno) = 312;
our($KWLANG_nob) = 313;
our($KWLANG_nog) = 314;
our($KWLANG_non) = 315;
our($KWLANG_nor) = 316;
our($KWLANG_nqo) = 317;
our($KWLANG_nso) = 318;
our($KWLANG_nub) = 319;
our($KWLANG_nwc) = 320;
our($KWLANG_nya) = 321;
our($KWLANG_nym) = 322;
our($KWLANG_nyn) = 323;
our($KWLANG_nyo) = 324;
our($KWLANG_nzi) = 325;
our($KWLANG_oci) = 326;
our($KWLANG_oji) = 327;
our($KWLANG_ori) = 328;
our($KWLANG_orm) = 329;
our($KWLANG_osa) = 330;
our($KWLANG_oss) = 331;
our($KWLANG_ota) = 332;
our($KWLANG_oto) = 333;
our($KWLANG_paa) = 334;
our($KWLANG_pag) = 335;
our($KWLANG_pal) = 336;
our($KWLANG_pam) = 337;
our($KWLANG_pan) = 338;
our($KWLANG_pap) = 339;
our($KWLANG_pau) = 340;
our($KWLANG_peo) = 341;
our($KWLANG_per) = 342;
our($KWLANG_phi) = 343;
our($KWLANG_phn) = 344;
our($KWLANG_pli) = 345;
our($KWLANG_pol) = 346;
our($KWLANG_pon) = 347;
our($KWLANG_por) = 348;
our($KWLANG_pra) = 349;
our($KWLANG_pro) = 350;
our($KWLANG_pus) = 351;
our($KWLANG_que) = 353;
our($KWLANG_raj) = 354;
our($KWLANG_rap) = 355;
our($KWLANG_rar) = 356;
our($KWLANG_roa) = 357;
our($KWLANG_roh) = 358;
our($KWLANG_rom) = 359;
our($KWLANG_rum) = 360;
our($KWLANG_run) = 361;
our($KWLANG_rup) = 362;
our($KWLANG_rus) = 363;
our($KWLANG_sad) = 364;
our($KWLANG_sag) = 365;
our($KWLANG_sah) = 366;
our($KWLANG_sai) = 367;
our($KWLANG_sal) = 368;
our($KWLANG_sam) = 369;
our($KWLANG_san) = 370;
our($KWLANG_sas) = 371;
our($KWLANG_sat) = 372;
our($KWLANG_scc) = 373;
our($KWLANG_scn) = 374;
our($KWLANG_sco) = 375;
our($KWLANG_scr) = 376;
our($KWLANG_sel) = 377;
our($KWLANG_sem) = 378;
our($KWLANG_sga) = 379;
our($KWLANG_sgn) = 380;
our($KWLANG_shn) = 381;
our($KWLANG_sid) = 382;
our($KWLANG_sin) = 383;
our($KWLANG_sio) = 384;
our($KWLANG_sit) = 385;
our($KWLANG_sla) = 386;
our($KWLANG_slo) = 387;
our($KWLANG_slv) = 388;
our($KWLANG_sma) = 389;
our($KWLANG_sme) = 390;
our($KWLANG_smi) = 391;
our($KWLANG_smj) = 392;
our($KWLANG_smn) = 393;
our($KWLANG_smo) = 394;
our($KWLANG_sms) = 395;
our($KWLANG_sna) = 396;
our($KWLANG_snd) = 397;
our($KWLANG_snk) = 398;
our($KWLANG_sog) = 399;
our($KWLANG_som) = 400;
our($KWLANG_son) = 401;
our($KWLANG_sot) = 402;
our($KWLANG_spa) = 403;
our($KWLANG_srd) = 404;
our($KWLANG_srn) = 405;
our($KWLANG_srr) = 406;
our($KWLANG_ssa) = 407;
our($KWLANG_ssw) = 408;
our($KWLANG_suk) = 409;
our($KWLANG_sun) = 410;
our($KWLANG_sus) = 411;
our($KWLANG_sux) = 412;
our($KWLANG_swa) = 413;
our($KWLANG_swe) = 414;
our($KWLANG_syc) = 415;
our($KWLANG_syr) = 416;
our($KWLANG_tah) = 417;
our($KWLANG_tai) = 418;
our($KWLANG_tam) = 419;
our($KWLANG_tat) = 420;
our($KWLANG_tel) = 421;
our($KWLANG_tem) = 422;
our($KWLANG_ter) = 423;
our($KWLANG_tet) = 424;
our($KWLANG_tgk) = 425;
our($KWLANG_tgl) = 426;
our($KWLANG_tha) = 427;
our($KWLANG_tib) = 428;
our($KWLANG_tig) = 429;
our($KWLANG_tir) = 430;
our($KWLANG_tiv) = 431;
our($KWLANG_tkl) = 432;
our($KWLANG_tlh) = 433;
our($KWLANG_tli) = 434;
our($KWLANG_tmh) = 435;
our($KWLANG_tog) = 436;
our($KWLANG_ton) = 437;
our($KWLANG_tpi) = 438;
our($KWLANG_tsi) = 439;
our($KWLANG_tsn) = 440;
our($KWLANG_tso) = 441;
our($KWLANG_tuk) = 442;
our($KWLANG_tum) = 443;
our($KWLANG_tup) = 444;
our($KWLANG_tur) = 445;
our($KWLANG_tut) = 446;
our($KWLANG_tvl) = 447;
our($KWLANG_twi) = 448;
our($KWLANG_tyv) = 449;
our($KWLANG_udm) = 450;
our($KWLANG_uga) = 451;
our($KWLANG_uig) = 452;
our($KWLANG_ukr) = 453;
our($KWLANG_umb) = 454;
our($KWLANG_und) = 455;
our($KWLANG_urd) = 456;
our($KWLANG_uzb) = 457;
our($KWLANG_vai) = 458;
our($KWLANG_ven) = 459;
our($KWLANG_vie) = 460;
our($KWLANG_vol) = 461;
our($KWLANG_vot) = 462;
our($KWLANG_wak) = 463;
our($KWLANG_wal) = 464;
our($KWLANG_war) = 465;
our($KWLANG_was) = 466;
our($KWLANG_wel) = 467;
our($KWLANG_wen) = 468;
our($KWLANG_wln) = 469;
our($KWLANG_wol) = 470;
our($KWLANG_xal) = 471;
our($KWLANG_xho) = 472;
our($KWLANG_yao) = 473;
our($KWLANG_yap) = 474;
our($KWLANG_yid) = 475;
our($KWLANG_yor) = 476;
our($KWLANG_ypk) = 477;
our($KWLANG_zap) = 478;
our($KWLANG_zbl) = 479;
our($KWLANG_zen) = 480;
our($KWLANG_zha) = 481;
our($KWLANG_znd) = 482;
our($KWLANG_zul) = 483;
our($KWLANG_zun) = 484;
our($KWLANG_zxx) = 485;
our($KWLANG_zza) = 486;
our($KWDIAL_ksb) = 2;
our($KWDIAL_ktb) = 3;
our($KWDIAL_kyb) = 4;
our($KWDIAL_kyu) = 9;
our($KWDIAL_osb) = 5;
our($KWDIAL_rkb) = 10;
our($KWDIAL_std) = 1;
our($KWDIAL_thb) = 7;
our($KWDIAL_tsb) = 6;
our($KWDIAL_tsug) = 8;
our($KWPOS_adj) = 57;
our($KWPOS_adj_f) = 56;
our($KWPOS_adj_i) = 1;
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
              10 => { descr => "Ryukyu-ben", id => 10, kw => "rkb" },
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
              rkb => 'fix',
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
              1     => { descr => "English", id => 1, kw => "eng" },
              10    => { descr => "Ainu", id => 10, kw => "ain" },
              100   => { descr => "Cushitic (Other)", id => 100, kw => "cus" },
              101   => { descr => "Czech", id => 101, kw => "cze" },
              102   => { descr => "Dakota", id => 102, kw => "dak" },
              103   => { descr => "Danish", id => 103, kw => "dan" },
              104   => { descr => "Dargwa", id => 104, kw => "dar" },
              105   => { descr => "Land Dayak languages", id => 105, kw => "day" },
              106   => { descr => "Delaware", id => 106, kw => "del" },
              107   => { descr => "Slave (Athapascan)", id => 107, kw => "den" },
              108   => { descr => "Dogrib", id => 108, kw => "dgr" },
              109   => { descr => "Dinka", id => 109, kw => "din" },
              11    => { descr => "Akan", id => 11, kw => "aka" },
              110   => { descr => "Divehi; Dhivehi; Maldivian", id => 110, kw => "div" },
              111   => { descr => "Dogri", id => 111, kw => "doi" },
              112   => { descr => "Dravidian (Other)", id => 112, kw => "dra" },
              113   => { descr => "Lower Sorbian", id => 113, kw => "dsb" },
              114   => { descr => "Duala", id => 114, kw => "dua" },
              115   => { descr => "Dutch, Middle (ca.1050-1350)", id => 115, kw => "dum" },
              116   => { descr => "Dutch; Flemish", id => 116, kw => "dut" },
              117   => { descr => "Dyula", id => 117, kw => "dyu" },
              118   => { descr => "Dzongkha", id => 118, kw => "dzo" },
              119   => { descr => "Efik", id => 119, kw => "efi" },
              12    => { descr => "Akkadian", id => 12, kw => "akk" },
              120   => { descr => "Egyptian (Ancient)", id => 120, kw => "egy" },
              121   => { descr => "Ekajuk", id => 121, kw => "eka" },
              122   => { descr => "Elamite", id => 122, kw => "elx" },
              124   => { descr => "English, Middle (1100-1500)", id => 124, kw => "enm" },
              125   => { descr => "Esperanto", id => 125, kw => "epo" },
              126   => { descr => "Estonian", id => 126, kw => "est" },
              127   => { descr => "Ewe", id => 127, kw => "ewe" },
              128   => { descr => "Ewondo", id => 128, kw => "ewo" },
              129   => { descr => "Fang", id => 129, kw => "fan" },
              13    => { descr => "Albanian", id => 13, kw => "alb" },
              130   => { descr => "Faroese", id => 130, kw => "fao" },
              131   => { descr => "Fanti", id => 131, kw => "fat" },
              132   => { descr => "Fijian", id => 132, kw => "fij" },
              133   => { descr => "Filipino; Pilipino", id => 133, kw => "fil" },
              134   => { descr => "Finnish", id => 134, kw => "fin" },
              135   => { descr => "Finno-Ugrian (Other)", id => 135, kw => "fiu" },
              136   => { descr => "Fon", id => 136, kw => "fon" },
              137   => { descr => "French", id => 137, kw => "fre" },
              138   => { descr => "French, Middle (ca.1400-1600)", id => 138, kw => "frm" },
              139   => { descr => "French, Old (842-ca.1400)", id => 139, kw => "fro" },
              14    => { descr => "Aleut", id => 14, kw => "ale" },
              140   => { descr => "Northern Frisian", id => 140, kw => "frr" },
              141   => { descr => "Eastern Frisian", id => 141, kw => "frs" },
              142   => { descr => "Western Frisian", id => 142, kw => "fry" },
              143   => { descr => "Fulah", id => 143, kw => "ful" },
              144   => { descr => "Friulian", id => 144, kw => "fur" },
              145   => { descr => "Ga", id => 145, kw => "gaa" },
              146   => { descr => "Gayo", id => 146, kw => "gay" },
              147   => { descr => "Gbaya", id => 147, kw => "gba" },
              148   => { descr => "Germanic (Other)", id => 148, kw => "gem" },
              149   => { descr => "Georgian", id => 149, kw => "geo" },
              15    => { descr => "Algonquian languages", id => 15, kw => "alg" },
              150   => { descr => "German", id => 150, kw => "ger" },
              151   => { descr => "Geez", id => 151, kw => "gez" },
              152   => { descr => "Gilbertese", id => 152, kw => "gil" },
              153   => { descr => "Gaelic; Scottish Gaelic", id => 153, kw => "gla" },
              154   => { descr => "Irish", id => 154, kw => "gle" },
              155   => { descr => "Galician", id => 155, kw => "glg" },
              156   => { descr => "Manx", id => 156, kw => "glv" },
              157   => { descr => "German, Middle High (ca.1050-1500)", id => 157, kw => "gmh" },
              158   => { descr => "German, Old High (ca.750-1050)", id => 158, kw => "goh" },
              159   => { descr => "Gondi", id => 159, kw => "gon" },
              16    => { descr => "Southern Altai", id => 16, kw => "alt" },
              160   => { descr => "Gorontalo", id => 160, kw => "gor" },
              161   => { descr => "Gothic", id => 161, kw => "got" },
              162   => { descr => "Grebo", id => 162, kw => "grb" },
              163   => { descr => "Greek, Ancient (to 1453)", id => 163, kw => "grc" },
              164   => { descr => "Greek, Modern (1453-)", id => 164, kw => "gre" },
              165   => { descr => "Guarani", id => 165, kw => "grn" },
              166   => { descr => "Swiss German; Alemannic; Alsatian", id => 166, kw => "gsw" },
              167   => { descr => "Gujarati", id => 167, kw => "guj" },
              168   => { descr => "Gwich'in", id => 168, kw => "gwi" },
              169   => { descr => "Haida", id => 169, kw => "hai" },
              17    => { descr => "Amharic", id => 17, kw => "amh" },
              170   => { descr => "Haitian; Haitian Creole", id => 170, kw => "hat" },
              171   => { descr => "Hausa", id => 171, kw => "hau" },
              172   => { descr => "Hawaiian", id => 172, kw => "haw" },
              173   => { descr => "Hebrew", id => 173, kw => "heb" },
              174   => { descr => "Herero", id => 174, kw => "her" },
              175   => { descr => "Hiligaynon", id => 175, kw => "hil" },
              176   => { descr => "Himachali", id => 176, kw => "him" },
              177   => { descr => "Hindi", id => 177, kw => "hin" },
              178   => { descr => "Hittite", id => 178, kw => "hit" },
              179   => { descr => "Hmong", id => 179, kw => "hmn" },
              18    => { descr => "English, Old (ca.450-1100)", id => 18, kw => "ang" },
              180   => { descr => "Hiri Motu", id => 180, kw => "hmo" },
              181   => { descr => "Upper Sorbian", id => 181, kw => "hsb" },
              182   => { descr => "Hungarian", id => 182, kw => "hun" },
              183   => { descr => "Hupa", id => 183, kw => "hup" },
              184   => { descr => "Iban", id => 184, kw => "iba" },
              185   => { descr => "Igbo", id => 185, kw => "ibo" },
              186   => { descr => "Icelandic", id => 186, kw => "ice" },
              187   => { descr => "Ido", id => 187, kw => "ido" },
              188   => { descr => "Sichuan Yi; Nuosu", id => 188, kw => "iii" },
              189   => { descr => "Ijo languages", id => 189, kw => "ijo" },
              19    => { descr => "Angika", id => 19, kw => "anp" },
              190   => { descr => "Inuktitut", id => 190, kw => "iku" },
              191   => { descr => "Interlingue; Occidental", id => 191, kw => "ile" },
              192   => { descr => "Iloko", id => 192, kw => "ilo" },
              193   => {
                         descr => "Interlingua (International Auxiliary Language Association)",
                         id => 193,
                         kw => "ina",
                       },
              194   => { descr => "Indic (Other)", id => 194, kw => "inc" },
              195   => { descr => "Indonesian", id => 195, kw => "ind" },
              196   => { descr => "Indo-European (Other)", id => 196, kw => "ine" },
              197   => { descr => "Ingush", id => 197, kw => "inh" },
              198   => { descr => "Inupiaq", id => 198, kw => "ipk" },
              199   => { descr => "Iranian (Other)", id => 199, kw => "ira" },
              2     => { descr => "Abkhazian", id => 2, kw => "abk" },
              20    => { descr => "Apache languages", id => 20, kw => "apa" },
              200   => { descr => "Iroquoian languages", id => 200, kw => "iro" },
              201   => { descr => "Italian", id => 201, kw => "ita" },
              202   => { descr => "Javanese", id => 202, kw => "jav" },
              203   => { descr => "Lojban", id => 203, kw => "jbo" },
              204   => { descr => "Japanese", id => 204, kw => "jpn" },
              205   => { descr => "Judeo-Persian", id => 205, kw => "jpr" },
              206   => { descr => "Judeo-Arabic", id => 206, kw => "jrb" },
              207   => { descr => "Kara-Kalpak", id => 207, kw => "kaa" },
              208   => { descr => "Kabyle", id => 208, kw => "kab" },
              209   => { descr => "Kachin; Jingpho", id => 209, kw => "kac" },
              21    => { descr => "Arabic", id => 21, kw => "ara" },
              210   => { descr => "Kalaallisut; Greenlandic", id => 210, kw => "kal" },
              211   => { descr => "Kamba", id => 211, kw => "kam" },
              212   => { descr => "Kannada", id => 212, kw => "kan" },
              213   => { descr => "Karen languages", id => 213, kw => "kar" },
              214   => { descr => "Kashmiri", id => 214, kw => "kas" },
              215   => { descr => "Kanuri", id => 215, kw => "kau" },
              216   => { descr => "Kawi", id => 216, kw => "kaw" },
              217   => { descr => "Kazakh", id => 217, kw => "kaz" },
              218   => { descr => "Kabardian", id => 218, kw => "kbd" },
              219   => { descr => "Khasi", id => 219, kw => "kha" },
              22    => {
                         descr => "Official Aramaic (700-300 BCE); Imperial Aramaic (700-300 BCE)",
                         id => 22,
                         kw => "arc",
                       },
              220   => { descr => "Khoisan (Other)", id => 220, kw => "khi" },
              221   => { descr => "Central Khmer", id => 221, kw => "khm" },
              222   => { descr => "Khotanese", id => 222, kw => "kho" },
              223   => { descr => "Kikuyu; Gikuyu", id => 223, kw => "kik" },
              224   => { descr => "Kinyarwanda", id => 224, kw => "kin" },
              225   => { descr => "Kirghiz; Kyrgyz", id => 225, kw => "kir" },
              226   => { descr => "Kimbundu", id => 226, kw => "kmb" },
              227   => { descr => "Konkani", id => 227, kw => "kok" },
              228   => { descr => "Komi", id => 228, kw => "kom" },
              229   => { descr => "Kongo", id => 229, kw => "kon" },
              23    => { descr => "Aragonese", id => 23, kw => "arg" },
              230   => { descr => "Korean", id => 230, kw => "kor" },
              231   => { descr => "Kosraean", id => 231, kw => "kos" },
              232   => { descr => "Kpelle", id => 232, kw => "kpe" },
              233   => { descr => "Karachay-Balkar", id => 233, kw => "krc" },
              234   => { descr => "Karelian", id => 234, kw => "krl" },
              235   => { descr => "Kru languages", id => 235, kw => "kro" },
              236   => { descr => "Kurukh", id => 236, kw => "kru" },
              237   => { descr => "Kuanyama; Kwanyama", id => 237, kw => "kua" },
              238   => { descr => "Kumyk", id => 238, kw => "kum" },
              239   => { descr => "Kurdish", id => 239, kw => "kur" },
              24    => { descr => "Armenian", id => 24, kw => "arm" },
              240   => { descr => "Kutenai", id => 240, kw => "kut" },
              241   => { descr => "Ladino", id => 241, kw => "lad" },
              242   => { descr => "Lahnda", id => 242, kw => "lah" },
              243   => { descr => "Lamba", id => 243, kw => "lam" },
              244   => { descr => "Lao", id => 244, kw => "lao" },
              245   => { descr => "Latin", id => 245, kw => "lat" },
              246   => { descr => "Latvian", id => 246, kw => "lav" },
              247   => { descr => "Lezghian", id => 247, kw => "lez" },
              248   => { descr => "Limburgan; Limburger; Limburgish", id => 248, kw => "lim" },
              249   => { descr => "Lingala", id => 249, kw => "lin" },
              25    => { descr => "Mapudungun; Mapuche", id => 25, kw => "arn" },
              250   => { descr => "Lithuanian", id => 250, kw => "lit" },
              251   => { descr => "Mongo", id => 251, kw => "lol" },
              252   => { descr => "Lozi", id => 252, kw => "loz" },
              253   => { descr => "Luxembourgish; Letzeburgesch", id => 253, kw => "ltz" },
              254   => { descr => "Luba-Lulua", id => 254, kw => "lua" },
              255   => { descr => "Luba-Katanga", id => 255, kw => "lub" },
              256   => { descr => "Ganda", id => 256, kw => "lug" },
              257   => { descr => "Luiseno", id => 257, kw => "lui" },
              258   => { descr => "Lunda", id => 258, kw => "lun" },
              259   => { descr => "Luo (Kenya and Tanzania)", id => 259, kw => "luo" },
              26    => { descr => "Arapaho", id => 26, kw => "arp" },
              260   => { descr => "Lushai", id => 260, kw => "lus" },
              261   => { descr => "Macedonian", id => 261, kw => "mac" },
              262   => { descr => "Madurese", id => 262, kw => "mad" },
              263   => { descr => "Magahi", id => 263, kw => "mag" },
              264   => { descr => "Marshallese", id => 264, kw => "mah" },
              265   => { descr => "Maithili", id => 265, kw => "mai" },
              266   => { descr => "Makasar", id => 266, kw => "mak" },
              267   => { descr => "Malayalam", id => 267, kw => "mal" },
              268   => { descr => "Mandingo", id => 268, kw => "man" },
              269   => { descr => "Maori", id => 269, kw => "mao" },
              27    => { descr => "Artificial (Other)", id => 27, kw => "art" },
              270   => { descr => "Austronesian (Other)", id => 270, kw => "map" },
              271   => { descr => "Marathi", id => 271, kw => "mar" },
              272   => { descr => "Masai", id => 272, kw => "mas" },
              273   => { descr => "Malay", id => 273, kw => "may" },
              274   => { descr => "Moksha", id => 274, kw => "mdf" },
              275   => { descr => "Mandar", id => 275, kw => "mdr" },
              276   => { descr => "Mende", id => 276, kw => "men" },
              277   => { descr => "Irish, Middle (900-1200)", id => 277, kw => "mga" },
              278   => { descr => "Mi'kmaq; Micmac", id => 278, kw => "mic" },
              279   => { descr => "Minangkabau", id => 279, kw => "min" },
              28    => { descr => "Arawak", id => 28, kw => "arw" },
              280   => { descr => "Uncoded languages", id => 280, kw => "mis" },
              281   => { descr => "Mon-Khmer (Other)", id => 281, kw => "mkh" },
              282   => { descr => "Malagasy", id => 282, kw => "mlg" },
              283   => { descr => "Maltese", id => 283, kw => "mlt" },
              284   => { descr => "Manchu", id => 284, kw => "mnc" },
              285   => { descr => "Manipuri", id => 285, kw => "mni" },
              286   => { descr => "Manobo languages", id => 286, kw => "mno" },
              287   => { descr => "Mohawk", id => 287, kw => "moh" },
              288   => { descr => "Moldavian", id => 288, kw => "mol" },
              289   => { descr => "Mongolian", id => 289, kw => "mon" },
              29    => { descr => "Assamese", id => 29, kw => "asm" },
              290   => { descr => "Mossi", id => 290, kw => "mos" },
              291   => { descr => "Multiple languages", id => 291, kw => "mul" },
              292   => { descr => "Munda languages", id => 292, kw => "mun" },
              293   => { descr => "Creek", id => 293, kw => "mus" },
              294   => { descr => "Mirandese", id => 294, kw => "mwl" },
              295   => { descr => "Marwari", id => 295, kw => "mwr" },
              296   => { descr => "Mayan languages", id => 296, kw => "myn" },
              297   => { descr => "Erzya", id => 297, kw => "myv" },
              298   => { descr => "Nahuatl languages", id => 298, kw => "nah" },
              299   => { descr => "North American Indian", id => 299, kw => "nai" },
              3     => { descr => "Achinese", id => 3, kw => "ace" },
              30    => {
                         descr => "Asturian; Bable; Leonese; Asturleonese",
                         id => 30,
                         kw => "ast",
                       },
              300   => { descr => "Neapolitan", id => 300, kw => "nap" },
              301   => { descr => "Nauru", id => 301, kw => "nau" },
              302   => { descr => "Navajo; Navaho", id => 302, kw => "nav" },
              303   => { descr => "Ndebele, South; South Ndebele", id => 303, kw => "nbl" },
              304   => { descr => "Ndebele, North; North Ndebele", id => 304, kw => "nde" },
              305   => { descr => "Ndonga", id => 305, kw => "ndo" },
              306   => {
                         descr => "Low German; Low Saxon; German, Low; Saxon, Low",
                         id => 306,
                         kw => "nds",
                       },
              307   => { descr => "Nepali", id => 307, kw => "nep" },
              308   => { descr => "Nepal Bhasa; Newari", id => 308, kw => "new" },
              309   => { descr => "Nias", id => 309, kw => "nia" },
              31    => { descr => "Athapascan languages", id => 31, kw => "ath" },
              310   => { descr => "Niger-Kordofanian (Other)", id => 310, kw => "nic" },
              311   => { descr => "Niuean", id => 311, kw => "niu" },
              312   => {
                         descr => "Norwegian Nynorsk; Nynorsk, Norwegian",
                         id => 312,
                         kw => "nno",
                       },
              313   => {
                         descr => "Bokm\xC3\xA5l, Norwegian; Norwegian Bokm\xC3\xA5l",
                         id => 313,
                         kw => "nob",
                       },
              314   => { descr => "Nogai", id => 314, kw => "nog" },
              315   => { descr => "Norse, Old", id => 315, kw => "non" },
              316   => { descr => "Norwegian", id => 316, kw => "nor" },
              317   => { descr => "N'Ko", id => 317, kw => "nqo" },
              318   => { descr => "Pedi; Sepedi; Northern Sotho", id => 318, kw => "nso" },
              319   => { descr => "Nubian languages", id => 319, kw => "nub" },
              32    => { descr => "Australian languages", id => 32, kw => "aus" },
              320   => {
                         descr => "Classical Newari; Old Newari; Classical Nepal Bhasa",
                         id => 320,
                         kw => "nwc",
                       },
              321   => { descr => "Chichewa; Chewa; Nyanja", id => 321, kw => "nya" },
              322   => { descr => "Nyamwezi", id => 322, kw => "nym" },
              323   => { descr => "Nyankole", id => 323, kw => "nyn" },
              324   => { descr => "Nyoro", id => 324, kw => "nyo" },
              325   => { descr => "Nzima", id => 325, kw => "nzi" },
              326   => {
                         descr => "Occitan (post 1500); Proven\xC3\xA7al",
                         id => 326,
                         kw => "oci",
                       },
              327   => { descr => "Ojibwa", id => 327, kw => "oji" },
              328   => { descr => "Oriya", id => 328, kw => "ori" },
              329   => { descr => "Oromo", id => 329, kw => "orm" },
              33    => { descr => "Avaric", id => 33, kw => "ava" },
              330   => { descr => "Osage", id => 330, kw => "osa" },
              331   => { descr => "Ossetian; Ossetic", id => 331, kw => "oss" },
              332   => { descr => "Turkish, Ottoman (1500-1928)", id => 332, kw => "ota" },
              333   => { descr => "Otomian languages", id => 333, kw => "oto" },
              334   => { descr => "Papuan (Other)", id => 334, kw => "paa" },
              335   => { descr => "Pangasinan", id => 335, kw => "pag" },
              336   => { descr => "Pahlavi", id => 336, kw => "pal" },
              337   => { descr => "Pampanga; Kapampangan", id => 337, kw => "pam" },
              338   => { descr => "Panjabi; Punjabi", id => 338, kw => "pan" },
              339   => { descr => "Papiamento", id => 339, kw => "pap" },
              34    => { descr => "Avestan", id => 34, kw => "ave" },
              340   => { descr => "Palauan", id => 340, kw => "pau" },
              341   => { descr => "Persian, Old (ca.600-400 B.C.)", id => 341, kw => "peo" },
              342   => { descr => "Persian", id => 342, kw => "per" },
              343   => { descr => "Philippine (Other)", id => 343, kw => "phi" },
              344   => { descr => "Phoenician", id => 344, kw => "phn" },
              345   => { descr => "Pali", id => 345, kw => "pli" },
              346   => { descr => "Polish", id => 346, kw => "pol" },
              347   => { descr => "Pohnpeian", id => 347, kw => "pon" },
              348   => { descr => "Portuguese", id => 348, kw => "por" },
              349   => { descr => "Prakrit languages", id => 349, kw => "pra" },
              35    => { descr => "Awadhi", id => 35, kw => "awa" },
              350   => { descr => "Proven\xC3\xA7al, Old (to 1500)", id => 350, kw => "pro" },
              351   => { descr => "Pushto; Pashto", id => 351, kw => "pus" },
              353   => { descr => "Quechua", id => 353, kw => "que" },
              354   => { descr => "Rajasthani", id => 354, kw => "raj" },
              355   => { descr => "Rapanui", id => 355, kw => "rap" },
              356   => { descr => "Rarotongan; Cook Islands Maori", id => 356, kw => "rar" },
              357   => { descr => "Romance (Other)", id => 357, kw => "roa" },
              358   => { descr => "Romansh", id => 358, kw => "roh" },
              359   => { descr => "Romany", id => 359, kw => "rom" },
              36    => { descr => "Aymara", id => 36, kw => "aym" },
              360   => { descr => "Romanian", id => 360, kw => "rum" },
              361   => { descr => "Rundi", id => 361, kw => "run" },
              362   => {
                         descr => "Aromanian; Arumanian; Macedo-Romanian",
                         id => 362,
                         kw => "rup",
                       },
              363   => { descr => "Russian", id => 363, kw => "rus" },
              364   => { descr => "Sandawe", id => 364, kw => "sad" },
              365   => { descr => "Sango", id => 365, kw => "sag" },
              366   => { descr => "Yakut", id => 366, kw => "sah" },
              367   => { descr => "South American Indian (Other)", id => 367, kw => "sai" },
              368   => { descr => "Salishan languages", id => 368, kw => "sal" },
              369   => { descr => "Samaritan Aramaic", id => 369, kw => "sam" },
              37    => { descr => "Azerbaijani", id => 37, kw => "aze" },
              370   => { descr => "Sanskrit", id => 370, kw => "san" },
              371   => { descr => "Sasak", id => 371, kw => "sas" },
              372   => { descr => "Santali", id => 372, kw => "sat" },
              373   => { descr => "Serbian", id => 373, kw => "scc" },
              374   => { descr => "Sicilian", id => 374, kw => "scn" },
              375   => { descr => "Scots", id => 375, kw => "sco" },
              376   => { descr => "Croatian", id => 376, kw => "scr" },
              377   => { descr => "Selkup", id => 377, kw => "sel" },
              378   => { descr => "Semitic (Other)", id => 378, kw => "sem" },
              379   => { descr => "Irish, Old (to 900)", id => 379, kw => "sga" },
              38    => { descr => "Banda languages", id => 38, kw => "bad" },
              380   => { descr => "Sign Languages", id => 380, kw => "sgn" },
              381   => { descr => "Shan", id => 381, kw => "shn" },
              382   => { descr => "Sidamo", id => 382, kw => "sid" },
              383   => { descr => "Sinhala; Sinhalese", id => 383, kw => "sin" },
              384   => { descr => "Siouan languages", id => 384, kw => "sio" },
              385   => { descr => "Sino-Tibetan (Other)", id => 385, kw => "sit" },
              386   => { descr => "Slavic (Other)", id => 386, kw => "sla" },
              387   => { descr => "Slovak", id => 387, kw => "slo" },
              388   => { descr => "Slovenian", id => 388, kw => "slv" },
              389   => { descr => "Southern Sami", id => 389, kw => "sma" },
              39    => { descr => "Bamileke languages", id => 39, kw => "bai" },
              390   => { descr => "Northern Sami", id => 390, kw => "sme" },
              391   => { descr => "Sami languages (Other)", id => 391, kw => "smi" },
              392   => { descr => "Lule Sami", id => 392, kw => "smj" },
              393   => { descr => "Inari Sami", id => 393, kw => "smn" },
              394   => { descr => "Samoan", id => 394, kw => "smo" },
              395   => { descr => "Skolt Sami", id => 395, kw => "sms" },
              396   => { descr => "Shona", id => 396, kw => "sna" },
              397   => { descr => "Sindhi", id => 397, kw => "snd" },
              398   => { descr => "Soninke", id => 398, kw => "snk" },
              399   => { descr => "Sogdian", id => 399, kw => "sog" },
              4     => { descr => "Acoli", id => 4, kw => "ach" },
              40    => { descr => "Bashkir", id => 40, kw => "bak" },
              400   => { descr => "Somali", id => 400, kw => "som" },
              401   => { descr => "Songhai languages", id => 401, kw => "son" },
              402   => { descr => "Sotho, Southern", id => 402, kw => "sot" },
              403   => { descr => "Spanish; Castilian", id => 403, kw => "spa" },
              404   => { descr => "Sardinian", id => 404, kw => "srd" },
              405   => { descr => "Sranan Tongo", id => 405, kw => "srn" },
              406   => { descr => "Serer", id => 406, kw => "srr" },
              407   => { descr => "Nilo-Saharan (Other)", id => 407, kw => "ssa" },
              408   => { descr => "Swati", id => 408, kw => "ssw" },
              409   => { descr => "Sukuma", id => 409, kw => "suk" },
              41    => { descr => "Baluchi", id => 41, kw => "bal" },
              410   => { descr => "Sundanese", id => 410, kw => "sun" },
              411   => { descr => "Susu", id => 411, kw => "sus" },
              412   => { descr => "Sumerian", id => 412, kw => "sux" },
              413   => { descr => "Swahili", id => 413, kw => "swa" },
              414   => { descr => "Swedish", id => 414, kw => "swe" },
              415   => { descr => "Classical Syriac", id => 415, kw => "syc" },
              416   => { descr => "Syriac", id => 416, kw => "syr" },
              417   => { descr => "Tahitian", id => 417, kw => "tah" },
              418   => { descr => "Tai (Other)", id => 418, kw => "tai" },
              419   => { descr => "Tamil", id => 419, kw => "tam" },
              42    => { descr => "Bambara", id => 42, kw => "bam" },
              420   => { descr => "Tatar", id => 420, kw => "tat" },
              421   => { descr => "Telugu", id => 421, kw => "tel" },
              422   => { descr => "Timne", id => 422, kw => "tem" },
              423   => { descr => "Tereno", id => 423, kw => "ter" },
              424   => { descr => "Tetum", id => 424, kw => "tet" },
              425   => { descr => "Tajik", id => 425, kw => "tgk" },
              426   => { descr => "Tagalog", id => 426, kw => "tgl" },
              427   => { descr => "Thai", id => 427, kw => "tha" },
              428   => { descr => "Tibetan", id => 428, kw => "tib" },
              429   => { descr => "Tigre", id => 429, kw => "tig" },
              43    => { descr => "Balinese", id => 43, kw => "ban" },
              430   => { descr => "Tigrinya", id => 430, kw => "tir" },
              431   => { descr => "Tiv", id => 431, kw => "tiv" },
              432   => { descr => "Tokelau", id => 432, kw => "tkl" },
              433   => { descr => "Klingon; tlhIngan-Hol", id => 433, kw => "tlh" },
              434   => { descr => "Tlingit", id => 434, kw => "tli" },
              435   => { descr => "Tamashek", id => 435, kw => "tmh" },
              436   => { descr => "Tonga (Nyasa)", id => 436, kw => "tog" },
              437   => { descr => "Tonga (Tonga Islands)", id => 437, kw => "ton" },
              438   => { descr => "Tok Pisin", id => 438, kw => "tpi" },
              439   => { descr => "Tsimshian", id => 439, kw => "tsi" },
              44    => { descr => "Basque", id => 44, kw => "baq" },
              440   => { descr => "Tswana", id => 440, kw => "tsn" },
              441   => { descr => "Tsonga", id => 441, kw => "tso" },
              442   => { descr => "Turkmen", id => 442, kw => "tuk" },
              443   => { descr => "Tumbuka", id => 443, kw => "tum" },
              444   => { descr => "Tupi languages", id => 444, kw => "tup" },
              445   => { descr => "Turkish", id => 445, kw => "tur" },
              446   => { descr => "Altaic (Other)", id => 446, kw => "tut" },
              447   => { descr => "Tuvalu", id => 447, kw => "tvl" },
              448   => { descr => "Twi", id => 448, kw => "twi" },
              449   => { descr => "Tuvinian", id => 449, kw => "tyv" },
              45    => { descr => "Basa", id => 45, kw => "bas" },
              450   => { descr => "Udmurt", id => 450, kw => "udm" },
              451   => { descr => "Ugaritic", id => 451, kw => "uga" },
              452   => { descr => "Uighur; Uyghur", id => 452, kw => "uig" },
              453   => { descr => "Ukrainian", id => 453, kw => "ukr" },
              454   => { descr => "Umbundu", id => 454, kw => "umb" },
              455   => { descr => "Undetermined", id => 455, kw => "und" },
              456   => { descr => "Urdu", id => 456, kw => "urd" },
              457   => { descr => "Uzbek", id => 457, kw => "uzb" },
              458   => { descr => "Vai", id => 458, kw => "vai" },
              459   => { descr => "Venda", id => 459, kw => "ven" },
              46    => { descr => "Baltic (Other)", id => 46, kw => "bat" },
              460   => { descr => "Vietnamese", id => 460, kw => "vie" },
              461   => { descr => "Volap\xC3\xBCk", id => 461, kw => "vol" },
              462   => { descr => "Votic", id => 462, kw => "vot" },
              463   => { descr => "Wakashan languages", id => 463, kw => "wak" },
              464   => { descr => "Walamo", id => 464, kw => "wal" },
              465   => { descr => "Waray", id => 465, kw => "war" },
              466   => { descr => "Washo", id => 466, kw => "was" },
              467   => { descr => "Welsh", id => 467, kw => "wel" },
              468   => { descr => "Sorbian languages", id => 468, kw => "wen" },
              469   => { descr => "Walloon", id => 469, kw => "wln" },
              47    => { descr => "Beja; Bedawiyet", id => 47, kw => "bej" },
              470   => { descr => "Wolof", id => 470, kw => "wol" },
              471   => { descr => "Kalmyk; Oirat", id => 471, kw => "xal" },
              472   => { descr => "Xhosa", id => 472, kw => "xho" },
              473   => { descr => "Yao", id => 473, kw => "yao" },
              474   => { descr => "Yapese", id => 474, kw => "yap" },
              475   => { descr => "Yiddish", id => 475, kw => "yid" },
              476   => { descr => "Yoruba", id => 476, kw => "yor" },
              477   => { descr => "Yupik languages", id => 477, kw => "ypk" },
              478   => { descr => "Zapotec", id => 478, kw => "zap" },
              479   => { descr => "Blissymbols; Blissymbolics; Bliss", id => 479, kw => "zbl" },
              48    => { descr => "Belarusian", id => 48, kw => "bel" },
              480   => { descr => "Zenaga", id => 480, kw => "zen" },
              481   => { descr => "Zhuang; Chuang", id => 481, kw => "zha" },
              482   => { descr => "Zande languages", id => 482, kw => "znd" },
              483   => { descr => "Zulu", id => 483, kw => "zul" },
              484   => { descr => "Zuni", id => 484, kw => "zun" },
              485   => { descr => "No linguistic content", id => 485, kw => "zxx" },
              486   => {
                         descr => "Zaza; Dimili; Dimli; Kirdki; Kirmanjki; Zazaki",
                         id => 486,
                         kw => "zza",
                       },
              49    => { descr => "Bemba", id => 49, kw => "bem" },
              5     => { descr => "Adangme", id => 5, kw => "ada" },
              50    => { descr => "Bengali", id => 50, kw => "ben" },
              51    => { descr => "Berber (Other)", id => 51, kw => "ber" },
              52    => { descr => "Bhojpuri", id => 52, kw => "bho" },
              53    => { descr => "Bihari", id => 53, kw => "bih" },
              54    => { descr => "Bikol", id => 54, kw => "bik" },
              55    => { descr => "Bini; Edo", id => 55, kw => "bin" },
              56    => { descr => "Bislama", id => 56, kw => "bis" },
              57    => { descr => "Siksika", id => 57, kw => "bla" },
              58    => { descr => "Bantu (Other)", id => 58, kw => "bnt" },
              59    => { descr => "Bosnian", id => 59, kw => "bos" },
              6     => { descr => "Adyghe; Adygei", id => 6, kw => "ady" },
              60    => { descr => "Braj", id => 60, kw => "bra" },
              61    => { descr => "Breton", id => 61, kw => "bre" },
              62    => { descr => "Batak languages", id => 62, kw => "btk" },
              63    => { descr => "Buriat", id => 63, kw => "bua" },
              64    => { descr => "Buginese", id => 64, kw => "bug" },
              65    => { descr => "Bulgarian", id => 65, kw => "bul" },
              66    => { descr => "Burmese", id => 66, kw => "bur" },
              67    => { descr => "Blin; Bilin", id => 67, kw => "byn" },
              68    => { descr => "Caddo", id => 68, kw => "cad" },
              69    => { descr => "Central American Indian (Other)", id => 69, kw => "cai" },
              7     => { descr => "Afro-Asiatic (Other)", id => 7, kw => "afa" },
              70    => { descr => "Galibi Carib", id => 70, kw => "car" },
              71    => { descr => "Catalan; Valencian", id => 71, kw => "cat" },
              72    => { descr => "Caucasian (Other)", id => 72, kw => "cau" },
              73    => { descr => "Cebuano", id => 73, kw => "ceb" },
              74    => { descr => "Celtic (Other)", id => 74, kw => "cel" },
              75    => { descr => "Chamorro", id => 75, kw => "cha" },
              76    => { descr => "Chibcha", id => 76, kw => "chb" },
              77    => { descr => "Chechen", id => 77, kw => "che" },
              78    => { descr => "Chagatai", id => 78, kw => "chg" },
              79    => { descr => "Chinese", id => 79, kw => "chi" },
              8     => { descr => "Afrihili", id => 8, kw => "afh" },
              80    => { descr => "Chuukese", id => 80, kw => "chk" },
              81    => { descr => "Mari", id => 81, kw => "chm" },
              82    => { descr => "Chinook jargon", id => 82, kw => "chn" },
              83    => { descr => "Choctaw", id => 83, kw => "cho" },
              84    => { descr => "Chipewyan; Dene Suline", id => 84, kw => "chp" },
              85    => { descr => "Cherokee", id => 85, kw => "chr" },
              86    => {
                         descr => "Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic",
                         id => 86,
                         kw => "chu",
                       },
              87    => { descr => "Chuvash", id => 87, kw => "chv" },
              88    => { descr => "Cheyenne", id => 88, kw => "chy" },
              89    => { descr => "Chamic languages", id => 89, kw => "cmc" },
              9     => { descr => "Afrikaans", id => 9, kw => "afr" },
              90    => { descr => "Coptic", id => 90, kw => "cop" },
              91    => { descr => "Cornish", id => 91, kw => "cor" },
              92    => { descr => "Corsican", id => 92, kw => "cos" },
              93    => {
                         descr => "Creoles and pidgins, English based (Other)",
                         id => 93,
                         kw => "cpe",
                       },
              94    => {
                         descr => "Creoles and pidgins, French-based (Other)",
                         id => 94,
                         kw => "cpf",
                       },
              95    => {
                         descr => "Creoles and pidgins, Portuguese-based (Other)",
                         id => 95,
                         kw => "cpp",
                       },
              96    => { descr => "Cree", id => 96, kw => "cre" },
              97    => { descr => "Crimean Tatar; Crimean Turkish", id => 97, kw => "crh" },
              98    => { descr => "Creoles and pidgins (Other)", id => 98, kw => "crp" },
              99    => { descr => "Kashubian", id => 99, kw => "csb" },
              abk   => 'fix',
              ace   => 'fix',
              ach   => 'fix',
              ada   => 'fix',
              ady   => 'fix',
              afa   => 'fix',
              afh   => 'fix',
              afr   => 'fix',
              ain   => 'fix',
              aka   => 'fix',
              akk   => 'fix',
              alb   => 'fix',
              ale   => 'fix',
              alg   => 'fix',
              alt   => 'fix',
              amh   => 'fix',
              ang   => 'fix',
              anp   => 'fix',
              apa   => 'fix',
              ara   => 'fix',
              arc   => 'fix',
              arg   => 'fix',
              arm   => 'fix',
              arn   => 'fix',
              arp   => 'fix',
              art   => 'fix',
              arw   => 'fix',
              asm   => 'fix',
              ast   => 'fix',
              ath   => 'fix',
              aus   => 'fix',
              ava   => 'fix',
              ave   => 'fix',
              awa   => 'fix',
              aym   => 'fix',
              aze   => 'fix',
              bad   => 'fix',
              bai   => 'fix',
              bak   => 'fix',
              bal   => 'fix',
              bam   => 'fix',
              ban   => 'fix',
              baq   => 'fix',
              bas   => 'fix',
              bat   => 'fix',
              bej   => 'fix',
              bel   => 'fix',
              bem   => 'fix',
              ben   => 'fix',
              ber   => 'fix',
              bho   => 'fix',
              bih   => 'fix',
              bik   => 'fix',
              bin   => 'fix',
              bis   => 'fix',
              bla   => 'fix',
              bnt   => 'fix',
              bos   => 'fix',
              bra   => 'fix',
              bre   => 'fix',
              btk   => 'fix',
              bua   => 'fix',
              bug   => 'fix',
              bul   => 'fix',
              bur   => 'fix',
              byn   => 'fix',
              cad   => 'fix',
              cai   => 'fix',
              car   => 'fix',
              cat   => 'fix',
              cau   => 'fix',
              ceb   => 'fix',
              cel   => 'fix',
              cha   => 'fix',
              chb   => 'fix',
              che   => 'fix',
              chg   => 'fix',
              chi   => 'fix',
              chk   => 'fix',
              chm   => 'fix',
              chn   => 'fix',
              cho   => 'fix',
              chp   => 'fix',
              "chr" => 'fix',
              chu   => 'fix',
              chv   => 'fix',
              chy   => 'fix',
              cmc   => 'fix',
              cop   => 'fix',
              cor   => 'fix',
              "cos" => 'fix',
              cpe   => 'fix',
              cpf   => 'fix',
              cpp   => 'fix',
              cre   => 'fix',
              crh   => 'fix',
              crp   => 'fix',
              csb   => 'fix',
              cus   => 'fix',
              cze   => 'fix',
              dak   => 'fix',
              dan   => 'fix',
              dar   => 'fix',
              day   => 'fix',
              del   => 'fix',
              den   => 'fix',
              dgr   => 'fix',
              din   => 'fix',
              div   => 'fix',
              doi   => 'fix',
              dra   => 'fix',
              dsb   => 'fix',
              dua   => 'fix',
              dum   => 'fix',
              dut   => 'fix',
              dyu   => 'fix',
              dzo   => 'fix',
              efi   => 'fix',
              egy   => 'fix',
              eka   => 'fix',
              elx   => 'fix',
              eng   => 'fix',
              enm   => 'fix',
              epo   => 'fix',
              est   => 'fix',
              ewe   => 'fix',
              ewo   => 'fix',
              fan   => 'fix',
              fao   => 'fix',
              fat   => 'fix',
              fij   => 'fix',
              fil   => 'fix',
              fin   => 'fix',
              fiu   => 'fix',
              fon   => 'fix',
              fre   => 'fix',
              frm   => 'fix',
              fro   => 'fix',
              frr   => 'fix',
              frs   => 'fix',
              fry   => 'fix',
              ful   => 'fix',
              fur   => 'fix',
              gaa   => 'fix',
              gay   => 'fix',
              gba   => 'fix',
              gem   => 'fix',
              geo   => 'fix',
              ger   => 'fix',
              gez   => 'fix',
              gil   => 'fix',
              gla   => 'fix',
              gle   => 'fix',
              glg   => 'fix',
              glv   => 'fix',
              gmh   => 'fix',
              goh   => 'fix',
              gon   => 'fix',
              gor   => 'fix',
              got   => 'fix',
              grb   => 'fix',
              grc   => 'fix',
              gre   => 'fix',
              grn   => 'fix',
              gsw   => 'fix',
              guj   => 'fix',
              gwi   => 'fix',
              hai   => 'fix',
              hat   => 'fix',
              hau   => 'fix',
              haw   => 'fix',
              heb   => 'fix',
              her   => 'fix',
              hil   => 'fix',
              him   => 'fix',
              hin   => 'fix',
              hit   => 'fix',
              hmn   => 'fix',
              hmo   => 'fix',
              hsb   => 'fix',
              hun   => 'fix',
              hup   => 'fix',
              iba   => 'fix',
              ibo   => 'fix',
              ice   => 'fix',
              ido   => 'fix',
              iii   => 'fix',
              ijo   => 'fix',
              iku   => 'fix',
              ile   => 'fix',
              ilo   => 'fix',
              ina   => 'fix',
              inc   => 'fix',
              ind   => 'fix',
              ine   => 'fix',
              inh   => 'fix',
              ipk   => 'fix',
              ira   => 'fix',
              iro   => 'fix',
              ita   => 'fix',
              jav   => 'fix',
              jbo   => 'fix',
              jpn   => 'fix',
              jpr   => 'fix',
              jrb   => 'fix',
              kaa   => 'fix',
              kab   => 'fix',
              kac   => 'fix',
              kal   => 'fix',
              kam   => 'fix',
              kan   => 'fix',
              kar   => 'fix',
              kas   => 'fix',
              kau   => 'fix',
              kaw   => 'fix',
              kaz   => 'fix',
              kbd   => 'fix',
              kha   => 'fix',
              khi   => 'fix',
              khm   => 'fix',
              kho   => 'fix',
              kik   => 'fix',
              kin   => 'fix',
              kir   => 'fix',
              kmb   => 'fix',
              kok   => 'fix',
              kom   => 'fix',
              kon   => 'fix',
              kor   => 'fix',
              kos   => 'fix',
              kpe   => 'fix',
              krc   => 'fix',
              krl   => 'fix',
              kro   => 'fix',
              kru   => 'fix',
              kua   => 'fix',
              kum   => 'fix',
              kur   => 'fix',
              kut   => 'fix',
              lad   => 'fix',
              lah   => 'fix',
              lam   => 'fix',
              lao   => 'fix',
              lat   => 'fix',
              lav   => 'fix',
              lez   => 'fix',
              lim   => 'fix',
              lin   => 'fix',
              lit   => 'fix',
              lol   => 'fix',
              loz   => 'fix',
              ltz   => 'fix',
              lua   => 'fix',
              lub   => 'fix',
              lug   => 'fix',
              lui   => 'fix',
              lun   => 'fix',
              luo   => 'fix',
              lus   => 'fix',
              mac   => 'fix',
              mad   => 'fix',
              mag   => 'fix',
              mah   => 'fix',
              mai   => 'fix',
              mak   => 'fix',
              mal   => 'fix',
              man   => 'fix',
              mao   => 'fix',
              "map" => 'fix',
              mar   => 'fix',
              mas   => 'fix',
              may   => 'fix',
              mdf   => 'fix',
              mdr   => 'fix',
              men   => 'fix',
              mga   => 'fix',
              mic   => 'fix',
              min   => 'fix',
              mis   => 'fix',
              mkh   => 'fix',
              mlg   => 'fix',
              mlt   => 'fix',
              mnc   => 'fix',
              mni   => 'fix',
              mno   => 'fix',
              moh   => 'fix',
              mol   => 'fix',
              mon   => 'fix',
              mos   => 'fix',
              mul   => 'fix',
              mun   => 'fix',
              mus   => 'fix',
              mwl   => 'fix',
              mwr   => 'fix',
              myn   => 'fix',
              myv   => 'fix',
              nah   => 'fix',
              nai   => 'fix',
              nap   => 'fix',
              nau   => 'fix',
              nav   => 'fix',
              nbl   => 'fix',
              nde   => 'fix',
              ndo   => 'fix',
              nds   => 'fix',
              nep   => 'fix',
              new   => 'fix',
              nia   => 'fix',
              nic   => 'fix',
              niu   => 'fix',
              nno   => 'fix',
              nob   => 'fix',
              nog   => 'fix',
              non   => 'fix',
              nor   => 'fix',
              nqo   => 'fix',
              nso   => 'fix',
              nub   => 'fix',
              nwc   => 'fix',
              nya   => 'fix',
              nym   => 'fix',
              nyn   => 'fix',
              nyo   => 'fix',
              nzi   => 'fix',
              oci   => 'fix',
              oji   => 'fix',
              ori   => 'fix',
              orm   => 'fix',
              osa   => 'fix',
              oss   => 'fix',
              ota   => 'fix',
              oto   => 'fix',
              paa   => 'fix',
              pag   => 'fix',
              pal   => 'fix',
              pam   => 'fix',
              pan   => 'fix',
              pap   => 'fix',
              pau   => 'fix',
              peo   => 'fix',
              per   => 'fix',
              phi   => 'fix',
              phn   => 'fix',
              pli   => 'fix',
              pol   => 'fix',
              pon   => 'fix',
              por   => 'fix',
              pra   => 'fix',
              pro   => 'fix',
              pus   => 'fix',
              que   => 'fix',
              raj   => 'fix',
              rap   => 'fix',
              rar   => 'fix',
              roa   => 'fix',
              roh   => 'fix',
              rom   => 'fix',
              rum   => 'fix',
              run   => 'fix',
              rup   => 'fix',
              rus   => 'fix',
              sad   => 'fix',
              sag   => 'fix',
              sah   => 'fix',
              sai   => 'fix',
              sal   => 'fix',
              sam   => 'fix',
              san   => 'fix',
              sas   => 'fix',
              sat   => 'fix',
              scc   => 'fix',
              scn   => 'fix',
              sco   => 'fix',
              scr   => 'fix',
              sel   => 'fix',
              sem   => 'fix',
              sga   => 'fix',
              sgn   => 'fix',
              shn   => 'fix',
              sid   => 'fix',
              "sin" => 'fix',
              sio   => 'fix',
              sit   => 'fix',
              sla   => 'fix',
              slo   => 'fix',
              slv   => 'fix',
              sma   => 'fix',
              sme   => 'fix',
              smi   => 'fix',
              smj   => 'fix',
              smn   => 'fix',
              smo   => 'fix',
              sms   => 'fix',
              sna   => 'fix',
              snd   => 'fix',
              snk   => 'fix',
              sog   => 'fix',
              som   => 'fix',
              son   => 'fix',
              sot   => 'fix',
              spa   => 'fix',
              srd   => 'fix',
              srn   => 'fix',
              srr   => 'fix',
              ssa   => 'fix',
              ssw   => 'fix',
              suk   => 'fix',
              sun   => 'fix',
              sus   => 'fix',
              sux   => 'fix',
              swa   => 'fix',
              swe   => 'fix',
              syc   => 'fix',
              syr   => 'fix',
              tah   => 'fix',
              tai   => 'fix',
              tam   => 'fix',
              tat   => 'fix',
              tel   => 'fix',
              tem   => 'fix',
              ter   => 'fix',
              tet   => 'fix',
              tgk   => 'fix',
              tgl   => 'fix',
              tha   => 'fix',
              tib   => 'fix',
              tig   => 'fix',
              tir   => 'fix',
              tiv   => 'fix',
              tkl   => 'fix',
              tlh   => 'fix',
              tli   => 'fix',
              tmh   => 'fix',
              tog   => 'fix',
              ton   => 'fix',
              tpi   => 'fix',
              tsi   => 'fix',
              tsn   => 'fix',
              tso   => 'fix',
              tuk   => 'fix',
              tum   => 'fix',
              tup   => 'fix',
              tur   => 'fix',
              tut   => 'fix',
              tvl   => 'fix',
              twi   => 'fix',
              tyv   => 'fix',
              udm   => 'fix',
              uga   => 'fix',
              uig   => 'fix',
              ukr   => 'fix',
              umb   => 'fix',
              und   => 'fix',
              urd   => 'fix',
              uzb   => 'fix',
              vai   => 'fix',
              ven   => 'fix',
              vie   => 'fix',
              vol   => 'fix',
              vot   => 'fix',
              wak   => 'fix',
              wal   => 'fix',
              war   => 'fix',
              was   => 'fix',
              wel   => 'fix',
              wen   => 'fix',
              wln   => 'fix',
              wol   => 'fix',
              xal   => 'fix',
              xho   => 'fix',
              yao   => 'fix',
              yap   => 'fix',
              yid   => 'fix',
              yor   => 'fix',
              ypk   => 'fix',
              zap   => 'fix',
              zbl   => 'fix',
              zen   => 'fix',
              zha   => 'fix',
              znd   => 'fix',
              zul   => 'fix',
              zun   => 'fix',
              zxx   => 'fix',
              zza   => 'fix',
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
              1         => { descr => "adjective (keiyoushi)", id => 1, kw => "adj-i" },
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
              56        => { descr => "noun or verb acting prenominally", id => 56, kw => "adj-f" },
              57        => {
                             descr => "former adjective classification (being removed)",
                             id => 57,
                             kw => "adj",
                           },
              6         => { descr => "adverb (fukushi)", id => 6, kw => "adv" },
              8         => { descr => "adverb taking the `to' particle", id => 8, kw => "adv-to" },
              9         => { descr => "auxiliary", id => 9, kw => "aux" },
              adj       => 'fix',
              "adj-f"   => 'fix',
              "adj-i"   => 'fix',
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
  $a->{DIAL}{rkb} = $a->{DIAL}{10};
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
  $a->{LANG}{abk} = $a->{LANG}{2};
  $a->{LANG}{ace} = $a->{LANG}{3};
  $a->{LANG}{ach} = $a->{LANG}{4};
  $a->{LANG}{ada} = $a->{LANG}{5};
  $a->{LANG}{ady} = $a->{LANG}{6};
  $a->{LANG}{afa} = $a->{LANG}{7};
  $a->{LANG}{afh} = $a->{LANG}{8};
  $a->{LANG}{afr} = $a->{LANG}{9};
  $a->{LANG}{ain} = $a->{LANG}{10};
  $a->{LANG}{aka} = $a->{LANG}{11};
  $a->{LANG}{akk} = $a->{LANG}{12};
  $a->{LANG}{alb} = $a->{LANG}{13};
  $a->{LANG}{ale} = $a->{LANG}{14};
  $a->{LANG}{alg} = $a->{LANG}{15};
  $a->{LANG}{alt} = $a->{LANG}{16};
  $a->{LANG}{amh} = $a->{LANG}{17};
  $a->{LANG}{ang} = $a->{LANG}{18};
  $a->{LANG}{anp} = $a->{LANG}{19};
  $a->{LANG}{apa} = $a->{LANG}{20};
  $a->{LANG}{ara} = $a->{LANG}{21};
  $a->{LANG}{arc} = $a->{LANG}{22};
  $a->{LANG}{arg} = $a->{LANG}{23};
  $a->{LANG}{arm} = $a->{LANG}{24};
  $a->{LANG}{arn} = $a->{LANG}{25};
  $a->{LANG}{arp} = $a->{LANG}{26};
  $a->{LANG}{art} = $a->{LANG}{27};
  $a->{LANG}{arw} = $a->{LANG}{28};
  $a->{LANG}{asm} = $a->{LANG}{29};
  $a->{LANG}{ast} = $a->{LANG}{30};
  $a->{LANG}{ath} = $a->{LANG}{31};
  $a->{LANG}{aus} = $a->{LANG}{32};
  $a->{LANG}{ava} = $a->{LANG}{33};
  $a->{LANG}{ave} = $a->{LANG}{34};
  $a->{LANG}{awa} = $a->{LANG}{35};
  $a->{LANG}{aym} = $a->{LANG}{36};
  $a->{LANG}{aze} = $a->{LANG}{37};
  $a->{LANG}{bad} = $a->{LANG}{38};
  $a->{LANG}{bai} = $a->{LANG}{39};
  $a->{LANG}{bak} = $a->{LANG}{40};
  $a->{LANG}{bal} = $a->{LANG}{41};
  $a->{LANG}{bam} = $a->{LANG}{42};
  $a->{LANG}{ban} = $a->{LANG}{43};
  $a->{LANG}{baq} = $a->{LANG}{44};
  $a->{LANG}{bas} = $a->{LANG}{45};
  $a->{LANG}{bat} = $a->{LANG}{46};
  $a->{LANG}{bej} = $a->{LANG}{47};
  $a->{LANG}{bel} = $a->{LANG}{48};
  $a->{LANG}{bem} = $a->{LANG}{49};
  $a->{LANG}{ben} = $a->{LANG}{50};
  $a->{LANG}{ber} = $a->{LANG}{51};
  $a->{LANG}{bho} = $a->{LANG}{52};
  $a->{LANG}{bih} = $a->{LANG}{53};
  $a->{LANG}{bik} = $a->{LANG}{54};
  $a->{LANG}{bin} = $a->{LANG}{55};
  $a->{LANG}{bis} = $a->{LANG}{56};
  $a->{LANG}{bla} = $a->{LANG}{57};
  $a->{LANG}{bnt} = $a->{LANG}{58};
  $a->{LANG}{bos} = $a->{LANG}{59};
  $a->{LANG}{bra} = $a->{LANG}{60};
  $a->{LANG}{bre} = $a->{LANG}{61};
  $a->{LANG}{btk} = $a->{LANG}{62};
  $a->{LANG}{bua} = $a->{LANG}{63};
  $a->{LANG}{bug} = $a->{LANG}{64};
  $a->{LANG}{bul} = $a->{LANG}{65};
  $a->{LANG}{bur} = $a->{LANG}{66};
  $a->{LANG}{byn} = $a->{LANG}{67};
  $a->{LANG}{cad} = $a->{LANG}{68};
  $a->{LANG}{cai} = $a->{LANG}{69};
  $a->{LANG}{car} = $a->{LANG}{70};
  $a->{LANG}{cat} = $a->{LANG}{71};
  $a->{LANG}{cau} = $a->{LANG}{72};
  $a->{LANG}{ceb} = $a->{LANG}{73};
  $a->{LANG}{cel} = $a->{LANG}{74};
  $a->{LANG}{cha} = $a->{LANG}{75};
  $a->{LANG}{chb} = $a->{LANG}{76};
  $a->{LANG}{che} = $a->{LANG}{77};
  $a->{LANG}{chg} = $a->{LANG}{78};
  $a->{LANG}{chi} = $a->{LANG}{79};
  $a->{LANG}{chk} = $a->{LANG}{80};
  $a->{LANG}{chm} = $a->{LANG}{81};
  $a->{LANG}{chn} = $a->{LANG}{82};
  $a->{LANG}{cho} = $a->{LANG}{83};
  $a->{LANG}{chp} = $a->{LANG}{84};
  $a->{LANG}{"chr"} = $a->{LANG}{85};
  $a->{LANG}{chu} = $a->{LANG}{86};
  $a->{LANG}{chv} = $a->{LANG}{87};
  $a->{LANG}{chy} = $a->{LANG}{88};
  $a->{LANG}{cmc} = $a->{LANG}{89};
  $a->{LANG}{cop} = $a->{LANG}{90};
  $a->{LANG}{cor} = $a->{LANG}{91};
  $a->{LANG}{"cos"} = $a->{LANG}{92};
  $a->{LANG}{cpe} = $a->{LANG}{93};
  $a->{LANG}{cpf} = $a->{LANG}{94};
  $a->{LANG}{cpp} = $a->{LANG}{95};
  $a->{LANG}{cre} = $a->{LANG}{96};
  $a->{LANG}{crh} = $a->{LANG}{97};
  $a->{LANG}{crp} = $a->{LANG}{98};
  $a->{LANG}{csb} = $a->{LANG}{99};
  $a->{LANG}{cus} = $a->{LANG}{100};
  $a->{LANG}{cze} = $a->{LANG}{101};
  $a->{LANG}{dak} = $a->{LANG}{102};
  $a->{LANG}{dan} = $a->{LANG}{103};
  $a->{LANG}{dar} = $a->{LANG}{104};
  $a->{LANG}{day} = $a->{LANG}{105};
  $a->{LANG}{del} = $a->{LANG}{106};
  $a->{LANG}{den} = $a->{LANG}{107};
  $a->{LANG}{dgr} = $a->{LANG}{108};
  $a->{LANG}{din} = $a->{LANG}{109};
  $a->{LANG}{div} = $a->{LANG}{110};
  $a->{LANG}{doi} = $a->{LANG}{111};
  $a->{LANG}{dra} = $a->{LANG}{112};
  $a->{LANG}{dsb} = $a->{LANG}{113};
  $a->{LANG}{dua} = $a->{LANG}{114};
  $a->{LANG}{dum} = $a->{LANG}{115};
  $a->{LANG}{dut} = $a->{LANG}{116};
  $a->{LANG}{dyu} = $a->{LANG}{117};
  $a->{LANG}{dzo} = $a->{LANG}{118};
  $a->{LANG}{efi} = $a->{LANG}{119};
  $a->{LANG}{egy} = $a->{LANG}{120};
  $a->{LANG}{eka} = $a->{LANG}{121};
  $a->{LANG}{elx} = $a->{LANG}{122};
  $a->{LANG}{eng} = $a->{LANG}{1};
  $a->{LANG}{enm} = $a->{LANG}{124};
  $a->{LANG}{epo} = $a->{LANG}{125};
  $a->{LANG}{est} = $a->{LANG}{126};
  $a->{LANG}{ewe} = $a->{LANG}{127};
  $a->{LANG}{ewo} = $a->{LANG}{128};
  $a->{LANG}{fan} = $a->{LANG}{129};
  $a->{LANG}{fao} = $a->{LANG}{130};
  $a->{LANG}{fat} = $a->{LANG}{131};
  $a->{LANG}{fij} = $a->{LANG}{132};
  $a->{LANG}{fil} = $a->{LANG}{133};
  $a->{LANG}{fin} = $a->{LANG}{134};
  $a->{LANG}{fiu} = $a->{LANG}{135};
  $a->{LANG}{fon} = $a->{LANG}{136};
  $a->{LANG}{fre} = $a->{LANG}{137};
  $a->{LANG}{frm} = $a->{LANG}{138};
  $a->{LANG}{fro} = $a->{LANG}{139};
  $a->{LANG}{frr} = $a->{LANG}{140};
  $a->{LANG}{frs} = $a->{LANG}{141};
  $a->{LANG}{fry} = $a->{LANG}{142};
  $a->{LANG}{ful} = $a->{LANG}{143};
  $a->{LANG}{fur} = $a->{LANG}{144};
  $a->{LANG}{gaa} = $a->{LANG}{145};
  $a->{LANG}{gay} = $a->{LANG}{146};
  $a->{LANG}{gba} = $a->{LANG}{147};
  $a->{LANG}{gem} = $a->{LANG}{148};
  $a->{LANG}{geo} = $a->{LANG}{149};
  $a->{LANG}{ger} = $a->{LANG}{150};
  $a->{LANG}{gez} = $a->{LANG}{151};
  $a->{LANG}{gil} = $a->{LANG}{152};
  $a->{LANG}{gla} = $a->{LANG}{153};
  $a->{LANG}{gle} = $a->{LANG}{154};
  $a->{LANG}{glg} = $a->{LANG}{155};
  $a->{LANG}{glv} = $a->{LANG}{156};
  $a->{LANG}{gmh} = $a->{LANG}{157};
  $a->{LANG}{goh} = $a->{LANG}{158};
  $a->{LANG}{gon} = $a->{LANG}{159};
  $a->{LANG}{gor} = $a->{LANG}{160};
  $a->{LANG}{got} = $a->{LANG}{161};
  $a->{LANG}{grb} = $a->{LANG}{162};
  $a->{LANG}{grc} = $a->{LANG}{163};
  $a->{LANG}{gre} = $a->{LANG}{164};
  $a->{LANG}{grn} = $a->{LANG}{165};
  $a->{LANG}{gsw} = $a->{LANG}{166};
  $a->{LANG}{guj} = $a->{LANG}{167};
  $a->{LANG}{gwi} = $a->{LANG}{168};
  $a->{LANG}{hai} = $a->{LANG}{169};
  $a->{LANG}{hat} = $a->{LANG}{170};
  $a->{LANG}{hau} = $a->{LANG}{171};
  $a->{LANG}{haw} = $a->{LANG}{172};
  $a->{LANG}{heb} = $a->{LANG}{173};
  $a->{LANG}{her} = $a->{LANG}{174};
  $a->{LANG}{hil} = $a->{LANG}{175};
  $a->{LANG}{him} = $a->{LANG}{176};
  $a->{LANG}{hin} = $a->{LANG}{177};
  $a->{LANG}{hit} = $a->{LANG}{178};
  $a->{LANG}{hmn} = $a->{LANG}{179};
  $a->{LANG}{hmo} = $a->{LANG}{180};
  $a->{LANG}{hsb} = $a->{LANG}{181};
  $a->{LANG}{hun} = $a->{LANG}{182};
  $a->{LANG}{hup} = $a->{LANG}{183};
  $a->{LANG}{iba} = $a->{LANG}{184};
  $a->{LANG}{ibo} = $a->{LANG}{185};
  $a->{LANG}{ice} = $a->{LANG}{186};
  $a->{LANG}{ido} = $a->{LANG}{187};
  $a->{LANG}{iii} = $a->{LANG}{188};
  $a->{LANG}{ijo} = $a->{LANG}{189};
  $a->{LANG}{iku} = $a->{LANG}{190};
  $a->{LANG}{ile} = $a->{LANG}{191};
  $a->{LANG}{ilo} = $a->{LANG}{192};
  $a->{LANG}{ina} = $a->{LANG}{193};
  $a->{LANG}{inc} = $a->{LANG}{194};
  $a->{LANG}{ind} = $a->{LANG}{195};
  $a->{LANG}{ine} = $a->{LANG}{196};
  $a->{LANG}{inh} = $a->{LANG}{197};
  $a->{LANG}{ipk} = $a->{LANG}{198};
  $a->{LANG}{ira} = $a->{LANG}{199};
  $a->{LANG}{iro} = $a->{LANG}{200};
  $a->{LANG}{ita} = $a->{LANG}{201};
  $a->{LANG}{jav} = $a->{LANG}{202};
  $a->{LANG}{jbo} = $a->{LANG}{203};
  $a->{LANG}{jpn} = $a->{LANG}{204};
  $a->{LANG}{jpr} = $a->{LANG}{205};
  $a->{LANG}{jrb} = $a->{LANG}{206};
  $a->{LANG}{kaa} = $a->{LANG}{207};
  $a->{LANG}{kab} = $a->{LANG}{208};
  $a->{LANG}{kac} = $a->{LANG}{209};
  $a->{LANG}{kal} = $a->{LANG}{210};
  $a->{LANG}{kam} = $a->{LANG}{211};
  $a->{LANG}{kan} = $a->{LANG}{212};
  $a->{LANG}{kar} = $a->{LANG}{213};
  $a->{LANG}{kas} = $a->{LANG}{214};
  $a->{LANG}{kau} = $a->{LANG}{215};
  $a->{LANG}{kaw} = $a->{LANG}{216};
  $a->{LANG}{kaz} = $a->{LANG}{217};
  $a->{LANG}{kbd} = $a->{LANG}{218};
  $a->{LANG}{kha} = $a->{LANG}{219};
  $a->{LANG}{khi} = $a->{LANG}{220};
  $a->{LANG}{khm} = $a->{LANG}{221};
  $a->{LANG}{kho} = $a->{LANG}{222};
  $a->{LANG}{kik} = $a->{LANG}{223};
  $a->{LANG}{kin} = $a->{LANG}{224};
  $a->{LANG}{kir} = $a->{LANG}{225};
  $a->{LANG}{kmb} = $a->{LANG}{226};
  $a->{LANG}{kok} = $a->{LANG}{227};
  $a->{LANG}{kom} = $a->{LANG}{228};
  $a->{LANG}{kon} = $a->{LANG}{229};
  $a->{LANG}{kor} = $a->{LANG}{230};
  $a->{LANG}{kos} = $a->{LANG}{231};
  $a->{LANG}{kpe} = $a->{LANG}{232};
  $a->{LANG}{krc} = $a->{LANG}{233};
  $a->{LANG}{krl} = $a->{LANG}{234};
  $a->{LANG}{kro} = $a->{LANG}{235};
  $a->{LANG}{kru} = $a->{LANG}{236};
  $a->{LANG}{kua} = $a->{LANG}{237};
  $a->{LANG}{kum} = $a->{LANG}{238};
  $a->{LANG}{kur} = $a->{LANG}{239};
  $a->{LANG}{kut} = $a->{LANG}{240};
  $a->{LANG}{lad} = $a->{LANG}{241};
  $a->{LANG}{lah} = $a->{LANG}{242};
  $a->{LANG}{lam} = $a->{LANG}{243};
  $a->{LANG}{lao} = $a->{LANG}{244};
  $a->{LANG}{lat} = $a->{LANG}{245};
  $a->{LANG}{lav} = $a->{LANG}{246};
  $a->{LANG}{lez} = $a->{LANG}{247};
  $a->{LANG}{lim} = $a->{LANG}{248};
  $a->{LANG}{lin} = $a->{LANG}{249};
  $a->{LANG}{lit} = $a->{LANG}{250};
  $a->{LANG}{lol} = $a->{LANG}{251};
  $a->{LANG}{loz} = $a->{LANG}{252};
  $a->{LANG}{ltz} = $a->{LANG}{253};
  $a->{LANG}{lua} = $a->{LANG}{254};
  $a->{LANG}{lub} = $a->{LANG}{255};
  $a->{LANG}{lug} = $a->{LANG}{256};
  $a->{LANG}{lui} = $a->{LANG}{257};
  $a->{LANG}{lun} = $a->{LANG}{258};
  $a->{LANG}{luo} = $a->{LANG}{259};
  $a->{LANG}{lus} = $a->{LANG}{260};
  $a->{LANG}{mac} = $a->{LANG}{261};
  $a->{LANG}{mad} = $a->{LANG}{262};
  $a->{LANG}{mag} = $a->{LANG}{263};
  $a->{LANG}{mah} = $a->{LANG}{264};
  $a->{LANG}{mai} = $a->{LANG}{265};
  $a->{LANG}{mak} = $a->{LANG}{266};
  $a->{LANG}{mal} = $a->{LANG}{267};
  $a->{LANG}{man} = $a->{LANG}{268};
  $a->{LANG}{mao} = $a->{LANG}{269};
  $a->{LANG}{"map"} = $a->{LANG}{270};
  $a->{LANG}{mar} = $a->{LANG}{271};
  $a->{LANG}{mas} = $a->{LANG}{272};
  $a->{LANG}{may} = $a->{LANG}{273};
  $a->{LANG}{mdf} = $a->{LANG}{274};
  $a->{LANG}{mdr} = $a->{LANG}{275};
  $a->{LANG}{men} = $a->{LANG}{276};
  $a->{LANG}{mga} = $a->{LANG}{277};
  $a->{LANG}{mic} = $a->{LANG}{278};
  $a->{LANG}{min} = $a->{LANG}{279};
  $a->{LANG}{mis} = $a->{LANG}{280};
  $a->{LANG}{mkh} = $a->{LANG}{281};
  $a->{LANG}{mlg} = $a->{LANG}{282};
  $a->{LANG}{mlt} = $a->{LANG}{283};
  $a->{LANG}{mnc} = $a->{LANG}{284};
  $a->{LANG}{mni} = $a->{LANG}{285};
  $a->{LANG}{mno} = $a->{LANG}{286};
  $a->{LANG}{moh} = $a->{LANG}{287};
  $a->{LANG}{mol} = $a->{LANG}{288};
  $a->{LANG}{mon} = $a->{LANG}{289};
  $a->{LANG}{mos} = $a->{LANG}{290};
  $a->{LANG}{mul} = $a->{LANG}{291};
  $a->{LANG}{mun} = $a->{LANG}{292};
  $a->{LANG}{mus} = $a->{LANG}{293};
  $a->{LANG}{mwl} = $a->{LANG}{294};
  $a->{LANG}{mwr} = $a->{LANG}{295};
  $a->{LANG}{myn} = $a->{LANG}{296};
  $a->{LANG}{myv} = $a->{LANG}{297};
  $a->{LANG}{nah} = $a->{LANG}{298};
  $a->{LANG}{nai} = $a->{LANG}{299};
  $a->{LANG}{nap} = $a->{LANG}{300};
  $a->{LANG}{nau} = $a->{LANG}{301};
  $a->{LANG}{nav} = $a->{LANG}{302};
  $a->{LANG}{nbl} = $a->{LANG}{303};
  $a->{LANG}{nde} = $a->{LANG}{304};
  $a->{LANG}{ndo} = $a->{LANG}{305};
  $a->{LANG}{nds} = $a->{LANG}{306};
  $a->{LANG}{nep} = $a->{LANG}{307};
  $a->{LANG}{new} = $a->{LANG}{308};
  $a->{LANG}{nia} = $a->{LANG}{309};
  $a->{LANG}{nic} = $a->{LANG}{310};
  $a->{LANG}{niu} = $a->{LANG}{311};
  $a->{LANG}{nno} = $a->{LANG}{312};
  $a->{LANG}{nob} = $a->{LANG}{313};
  $a->{LANG}{nog} = $a->{LANG}{314};
  $a->{LANG}{non} = $a->{LANG}{315};
  $a->{LANG}{nor} = $a->{LANG}{316};
  $a->{LANG}{nqo} = $a->{LANG}{317};
  $a->{LANG}{nso} = $a->{LANG}{318};
  $a->{LANG}{nub} = $a->{LANG}{319};
  $a->{LANG}{nwc} = $a->{LANG}{320};
  $a->{LANG}{nya} = $a->{LANG}{321};
  $a->{LANG}{nym} = $a->{LANG}{322};
  $a->{LANG}{nyn} = $a->{LANG}{323};
  $a->{LANG}{nyo} = $a->{LANG}{324};
  $a->{LANG}{nzi} = $a->{LANG}{325};
  $a->{LANG}{oci} = $a->{LANG}{326};
  $a->{LANG}{oji} = $a->{LANG}{327};
  $a->{LANG}{ori} = $a->{LANG}{328};
  $a->{LANG}{orm} = $a->{LANG}{329};
  $a->{LANG}{osa} = $a->{LANG}{330};
  $a->{LANG}{oss} = $a->{LANG}{331};
  $a->{LANG}{ota} = $a->{LANG}{332};
  $a->{LANG}{oto} = $a->{LANG}{333};
  $a->{LANG}{paa} = $a->{LANG}{334};
  $a->{LANG}{pag} = $a->{LANG}{335};
  $a->{LANG}{pal} = $a->{LANG}{336};
  $a->{LANG}{pam} = $a->{LANG}{337};
  $a->{LANG}{pan} = $a->{LANG}{338};
  $a->{LANG}{pap} = $a->{LANG}{339};
  $a->{LANG}{pau} = $a->{LANG}{340};
  $a->{LANG}{peo} = $a->{LANG}{341};
  $a->{LANG}{per} = $a->{LANG}{342};
  $a->{LANG}{phi} = $a->{LANG}{343};
  $a->{LANG}{phn} = $a->{LANG}{344};
  $a->{LANG}{pli} = $a->{LANG}{345};
  $a->{LANG}{pol} = $a->{LANG}{346};
  $a->{LANG}{pon} = $a->{LANG}{347};
  $a->{LANG}{por} = $a->{LANG}{348};
  $a->{LANG}{pra} = $a->{LANG}{349};
  $a->{LANG}{pro} = $a->{LANG}{350};
  $a->{LANG}{pus} = $a->{LANG}{351};
  $a->{LANG}{que} = $a->{LANG}{353};
  $a->{LANG}{raj} = $a->{LANG}{354};
  $a->{LANG}{rap} = $a->{LANG}{355};
  $a->{LANG}{rar} = $a->{LANG}{356};
  $a->{LANG}{roa} = $a->{LANG}{357};
  $a->{LANG}{roh} = $a->{LANG}{358};
  $a->{LANG}{rom} = $a->{LANG}{359};
  $a->{LANG}{rum} = $a->{LANG}{360};
  $a->{LANG}{run} = $a->{LANG}{361};
  $a->{LANG}{rup} = $a->{LANG}{362};
  $a->{LANG}{rus} = $a->{LANG}{363};
  $a->{LANG}{sad} = $a->{LANG}{364};
  $a->{LANG}{sag} = $a->{LANG}{365};
  $a->{LANG}{sah} = $a->{LANG}{366};
  $a->{LANG}{sai} = $a->{LANG}{367};
  $a->{LANG}{sal} = $a->{LANG}{368};
  $a->{LANG}{sam} = $a->{LANG}{369};
  $a->{LANG}{san} = $a->{LANG}{370};
  $a->{LANG}{sas} = $a->{LANG}{371};
  $a->{LANG}{sat} = $a->{LANG}{372};
  $a->{LANG}{scc} = $a->{LANG}{373};
  $a->{LANG}{scn} = $a->{LANG}{374};
  $a->{LANG}{sco} = $a->{LANG}{375};
  $a->{LANG}{scr} = $a->{LANG}{376};
  $a->{LANG}{sel} = $a->{LANG}{377};
  $a->{LANG}{sem} = $a->{LANG}{378};
  $a->{LANG}{sga} = $a->{LANG}{379};
  $a->{LANG}{sgn} = $a->{LANG}{380};
  $a->{LANG}{shn} = $a->{LANG}{381};
  $a->{LANG}{sid} = $a->{LANG}{382};
  $a->{LANG}{"sin"} = $a->{LANG}{383};
  $a->{LANG}{sio} = $a->{LANG}{384};
  $a->{LANG}{sit} = $a->{LANG}{385};
  $a->{LANG}{sla} = $a->{LANG}{386};
  $a->{LANG}{slo} = $a->{LANG}{387};
  $a->{LANG}{slv} = $a->{LANG}{388};
  $a->{LANG}{sma} = $a->{LANG}{389};
  $a->{LANG}{sme} = $a->{LANG}{390};
  $a->{LANG}{smi} = $a->{LANG}{391};
  $a->{LANG}{smj} = $a->{LANG}{392};
  $a->{LANG}{smn} = $a->{LANG}{393};
  $a->{LANG}{smo} = $a->{LANG}{394};
  $a->{LANG}{sms} = $a->{LANG}{395};
  $a->{LANG}{sna} = $a->{LANG}{396};
  $a->{LANG}{snd} = $a->{LANG}{397};
  $a->{LANG}{snk} = $a->{LANG}{398};
  $a->{LANG}{sog} = $a->{LANG}{399};
  $a->{LANG}{som} = $a->{LANG}{400};
  $a->{LANG}{son} = $a->{LANG}{401};
  $a->{LANG}{sot} = $a->{LANG}{402};
  $a->{LANG}{spa} = $a->{LANG}{403};
  $a->{LANG}{srd} = $a->{LANG}{404};
  $a->{LANG}{srn} = $a->{LANG}{405};
  $a->{LANG}{srr} = $a->{LANG}{406};
  $a->{LANG}{ssa} = $a->{LANG}{407};
  $a->{LANG}{ssw} = $a->{LANG}{408};
  $a->{LANG}{suk} = $a->{LANG}{409};
  $a->{LANG}{sun} = $a->{LANG}{410};
  $a->{LANG}{sus} = $a->{LANG}{411};
  $a->{LANG}{sux} = $a->{LANG}{412};
  $a->{LANG}{swa} = $a->{LANG}{413};
  $a->{LANG}{swe} = $a->{LANG}{414};
  $a->{LANG}{syc} = $a->{LANG}{415};
  $a->{LANG}{syr} = $a->{LANG}{416};
  $a->{LANG}{tah} = $a->{LANG}{417};
  $a->{LANG}{tai} = $a->{LANG}{418};
  $a->{LANG}{tam} = $a->{LANG}{419};
  $a->{LANG}{tat} = $a->{LANG}{420};
  $a->{LANG}{tel} = $a->{LANG}{421};
  $a->{LANG}{tem} = $a->{LANG}{422};
  $a->{LANG}{ter} = $a->{LANG}{423};
  $a->{LANG}{tet} = $a->{LANG}{424};
  $a->{LANG}{tgk} = $a->{LANG}{425};
  $a->{LANG}{tgl} = $a->{LANG}{426};
  $a->{LANG}{tha} = $a->{LANG}{427};
  $a->{LANG}{tib} = $a->{LANG}{428};
  $a->{LANG}{tig} = $a->{LANG}{429};
  $a->{LANG}{tir} = $a->{LANG}{430};
  $a->{LANG}{tiv} = $a->{LANG}{431};
  $a->{LANG}{tkl} = $a->{LANG}{432};
  $a->{LANG}{tlh} = $a->{LANG}{433};
  $a->{LANG}{tli} = $a->{LANG}{434};
  $a->{LANG}{tmh} = $a->{LANG}{435};
  $a->{LANG}{tog} = $a->{LANG}{436};
  $a->{LANG}{ton} = $a->{LANG}{437};
  $a->{LANG}{tpi} = $a->{LANG}{438};
  $a->{LANG}{tsi} = $a->{LANG}{439};
  $a->{LANG}{tsn} = $a->{LANG}{440};
  $a->{LANG}{tso} = $a->{LANG}{441};
  $a->{LANG}{tuk} = $a->{LANG}{442};
  $a->{LANG}{tum} = $a->{LANG}{443};
  $a->{LANG}{tup} = $a->{LANG}{444};
  $a->{LANG}{tur} = $a->{LANG}{445};
  $a->{LANG}{tut} = $a->{LANG}{446};
  $a->{LANG}{tvl} = $a->{LANG}{447};
  $a->{LANG}{twi} = $a->{LANG}{448};
  $a->{LANG}{tyv} = $a->{LANG}{449};
  $a->{LANG}{udm} = $a->{LANG}{450};
  $a->{LANG}{uga} = $a->{LANG}{451};
  $a->{LANG}{uig} = $a->{LANG}{452};
  $a->{LANG}{ukr} = $a->{LANG}{453};
  $a->{LANG}{umb} = $a->{LANG}{454};
  $a->{LANG}{und} = $a->{LANG}{455};
  $a->{LANG}{urd} = $a->{LANG}{456};
  $a->{LANG}{uzb} = $a->{LANG}{457};
  $a->{LANG}{vai} = $a->{LANG}{458};
  $a->{LANG}{ven} = $a->{LANG}{459};
  $a->{LANG}{vie} = $a->{LANG}{460};
  $a->{LANG}{vol} = $a->{LANG}{461};
  $a->{LANG}{vot} = $a->{LANG}{462};
  $a->{LANG}{wak} = $a->{LANG}{463};
  $a->{LANG}{wal} = $a->{LANG}{464};
  $a->{LANG}{war} = $a->{LANG}{465};
  $a->{LANG}{was} = $a->{LANG}{466};
  $a->{LANG}{wel} = $a->{LANG}{467};
  $a->{LANG}{wen} = $a->{LANG}{468};
  $a->{LANG}{wln} = $a->{LANG}{469};
  $a->{LANG}{wol} = $a->{LANG}{470};
  $a->{LANG}{xal} = $a->{LANG}{471};
  $a->{LANG}{xho} = $a->{LANG}{472};
  $a->{LANG}{yao} = $a->{LANG}{473};
  $a->{LANG}{yap} = $a->{LANG}{474};
  $a->{LANG}{yid} = $a->{LANG}{475};
  $a->{LANG}{yor} = $a->{LANG}{476};
  $a->{LANG}{ypk} = $a->{LANG}{477};
  $a->{LANG}{zap} = $a->{LANG}{478};
  $a->{LANG}{zbl} = $a->{LANG}{479};
  $a->{LANG}{zen} = $a->{LANG}{480};
  $a->{LANG}{zha} = $a->{LANG}{481};
  $a->{LANG}{znd} = $a->{LANG}{482};
  $a->{LANG}{zul} = $a->{LANG}{483};
  $a->{LANG}{zun} = $a->{LANG}{484};
  $a->{LANG}{zxx} = $a->{LANG}{485};
  $a->{LANG}{zza} = $a->{LANG}{486};
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
  $a->{POS}{adj} = $a->{POS}{57};
  $a->{POS}{"adj-f"} = $a->{POS}{56};
  $a->{POS}{"adj-i"} = $a->{POS}{1};
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
