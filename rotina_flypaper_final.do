* Rotina artigo Flypaper in Educ*
*Correções e analises do artigo *

*A 1º parte do artigo é referente a CP, depois disso que mexemos na base de proficiência*


********************************************************************************
*******             Organização da Base COTA PARTE                  ************
********************************************************************************


* Base Inicial é a Base no formato Bruto. Dela serão obtidas as demais bases.
clear all


use "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\Base Inicial.dta"
drop if ano==2018
merge m:m ano using "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\inf_dessa.dta"
gen id=_n
drop _merge
merge m:m id using "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\controls.dta"
drop _merge
drop in 2577


format %13.0g TransferênciasdoFUNDEB
format %13.0g cotapartefpm

merge m:m id using "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\valor_real_cp.dta"
drop _merge	

save "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\Base Inicial 2.dta", replace

* Construção das variáveis de resultado e controle iniciais
***********************************************************

* As variáveis de resultado serão:
* 1. Gasto Total Per Capita Relativo a 2008
* 2. Gasto em Educação Total Per Capita Relativo a 2008
* 3. Gasto em Educação Fundamental Per capita relativo a 2008.

******
* Seja G(t) uma variável de gasto no tempo t. Então, o Gasto Per capita relativo a 2008 é definido por:
* X(t)=(G(t)-G(2008))/pop08. 

* AS variáveis de controle serão: PIB pc relativo a 2008, transferencias FUNDEB per capita relativo a 2008, transferencias FPM pc relativa a 2008
* OBS: Outras variáveis de controle poderão ser adicionadas em exercícios de robustez

* Variável de Tratamento: 
* Transf_educ= Transferencia Relativa a cota parte do ICMS decorrente até 2008 do número de estudantes matriculados e após 2009 do IQE.

rename cotapartefpm fpm
rename TransferênciasdoFUNDEB fundeb

rename INDICEEDUCACAO iqe
rename INDICESAUDE iqs
rename INDICEMAMBIENTE iqm
destring SituaçãolimitesLRF, replace
rename SituaçãolimitesLRF situacao
rename Reeleição reeleicao



replace g_total= g_total/inf_dess
replace g_educ= g_educ/inf_dess
replace g_fund= g_fund/inf_dess
replace pib= pib/inf_dess
replace fpm= fpm/inf_dess
replace fundeb= fundeb/inf_dess
replace cp= cp/inf_dess
gen g_n_edu=g_total-g_educ

format %14.0g g_n_edu

save "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\Base Inicial 2.dta", replace



keep if ano==2008
drop ano Municipio  iqe iqs iqm Soma_Indices BaseCalculoReceitaICMSR ICMS25 DeduçãoFUNDEB situacao reeleicao inf_dess id pib fpm fundeb

save "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\base_08.dta", replace

rename pop pop08
rename g_total g_total08
rename g_n_edu g_n_edu08
rename g_educ g_educ08
rename g_fund g_fund08
rename cp cp08


*** Junção com base das escolas ***


save "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\base_08.dta", replace


clear all
use "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\Base Inicial 2.dta"
merge m:m cod_ibge using "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\base_08.dta"

drop _merge

gen g_total_x=(g_total-g_total08)/pop08
gen g_nao_ed_x=(g_n_edu-g_n_edu08)/pop08
gen g_educ_x=(g_educ-g_educ08)/pop08
gen g_fund_x=(g_fund-g_fund08)/pop08
gen cp_x=(cp-cp08)/pop08


keep if ano==2009




egen rank_cp_x = xtile (cp_x), nq(3)

tab rank_cp_x, m


*7 missing -> São Luís do Curu, São Benedito, Cariré, Palmácia, Uruburetama, Ibaretama, Groaíras
drop if  cod_ibge==2303105
drop if  cod_ibge==2310100
drop if  cod_ibge==2313807
drop if  cod_ibge==2312304
drop if  cod_ibge==2312601
drop if  cod_ibge==2304905
drop if  cod_ibge==2305266



drop pop-g_fund_x
drop ano Municipio

save  save "D:\GitHub\flypaper-\cp_x.dta", replace

********************************************************************************
****************************** SPAECE ALFA *************************************
********************************************************************************

********************************************************************************
*******             Organização Base ESCOLA PROFICÊNCIA             ************
********************************************************************************

clear all

*Base inicial que será usada no Formato bruto. 
use "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial.dta"



keep if ano== 2007
gen d_07 = 1

keep cod_escola d_07

merge m:m cod_escola using "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial.dta"
replace d_07 =0 if d_07 ==.

move cod_escola mun
move d_07 tdi_anos_iniciais


rename cod_mun cod_ibge

drop _merge
 
label variable d_07 "Escola que aparece em 2007 ao longo dos anos"

save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta", replace


*Criando o rank das escolas pela mediana* 
egen rank_med = xtile(prof_med), by(cod_ibge ano) nq(2)


label variable rank_med "rank mediana das escolas em cada ano"


save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta", replace

bysort ano: tab d_07 rank_med

keep if ano ==2007 

keep cod_escola rank_med

rename rank_med rank_07

tab rank_07

merge m:m cod_escola using "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"


move rank_07 rank_med
move cod_escola mun

label variable rank_07 "rank das escolas em 2007"

drop _merge


gen tratamento_med =.
replace tratamento_med =1 if rank_07 ==1
replace tratamento_med =0 if rank_07 ==2

tab tratamento ano, m

tab cod_ibge tratamento_med if ano==2007

** Diferentemente, da outra estimação, quando tinhamos municipios com menos de 4 escolas, agora, todos os municipios tem pelo menos 2 escolas, logo não excluimos nenhum municipio.**


label variable tratamento_med " Mediana inferior de 2007 ao longo dos anos"

gen it= ano*cod_ibge
label variable it "interação ano*municipio"


egen std_prof = std(prof_med)
move std_prof prof_med


areg std_prof i.ano tratamento , a(it) cl(cod_escola)


save "D:\GitHub\flypaper-\spaece_inicial_inter.dta", replace


********************************************************************************
*******             UNINDO BASE ESCOLA + BASE COTA PARTE            ************
********************************************************************************

clear all


use "D:\GitHub\flypaper-\spaece_inicial_inter.dta"

drop _merge

merge m:m cod_ibge using "D:\GitHub\flypaper-\cp_x.dta"

keep if _merge==3

drop _merge


tab ano rank_cp_x
tab tratamento rank_cp_x, m
bysort ano: tab tratamento rank_cp_x, m


* Criando ranks escola 
gen mtrat1=.
replace mtrat1 =1 if rank_07==1 & rank_cp_x==3
replace mtrat1 =0 if rank_07==1 & rank_cp_x==1

label variable mtrat1 " Mediana inferior escola + 3º tercil cp em relação ao 1º tercil cp"

gen mtrat2=.
replace mtrat2=1 if rank_07==2 & rank_cp_x==3
replace mtrat2=0 if rank_07==2 & rank_cp_x==1

label variable mtrat2 "Mediana superior + 3º tercil cp em relação ao 1º tercil cp"

save "D:\GitHub\flypaper-\spaece_inicial_inter.dta", replace


********************************************************************************
******************** Unindo base com gasto total, pib e fpm ********************
********************************************************************************
clear all 

use "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\Base I.dta"

keep if ano ==2008

gen g_totalpc08 = g_total08/pop08
gen pib_percapta08 = pib /pop08
gen fpm08 =fpm / pop

keep cod_ibge  g_totalpc08 pib_percapta08 fpm08

save "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\Base I.dta", replace

clear all

use "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"

merge m:m cod_ibge using "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\Base I.dta"


** Abaiara, Altaneira, Cariré, Groaíras, Ibaretama, Palmácia, São Benedito, São Luís do Curu, Uruburetama  foram exlcuidas por não ter dados **

keep if _merge ==3
drop _merge

save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta", replace

********************************************************************************
******************************** Ebalance **************************************
********************************************************************************

clear all

use "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"

keep if ano==2008

gen pos = mestrado + doutorado


keep cod_escola alfa_incompleto inter sufic desej especializacao pos  d_idade_1 d_idade_2 d_idade_3 d_idade_4 d_tp_sexo_1 d_tp_cor_branco  apr_1 apr_2 aban_1 aban_2  g_totalpc08 pib_percapta08 fpm08 

move pos d_idade_1

rename alfa_incompleto alfa_incompleto_08
rename inter inter_08
rename sufic sufic_08
rename desej desej_08
rename especializacao especializacao_08
rename pos pos_08
rename d_idade_1 d_idade_1_08
rename d_idade_2 d_idade_2_08
rename d_idade_3 d_idade_3_08
rename d_idade_4 d_idade_4_08
rename d_tp_sexo_1 d_tp_sexo_1_08
rename d_tp_cor_branco d_tp_cor_branco_08
rename apr_1 apr_1_08
rename apr_2 apr_2_08
rename aban_1 aban_1_08
rename aban_2 aban_2_08


merge m:m cod_escola using "D:\GitHub\flypaper-\spaece_inicial_inter.dta"

keep if _merge ==3

drop _merge


ebalance mtrat1 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

rename _webal _mwebal1


ebalance mtrat2 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

rename _webal _mwebal2


save "D:\GitHub\flypaper-\spaece_inicial_inter.dta", replace


********************************************************************************
****************************** SPAECE 5º ANO ***********************************
********************************************************************************

********************************************************************************
*******             Organização Base ESCOLA PROFICÊNCIA             ************
********************************************************************************


clear all

*Base inicial que será usada no Formato bruto. 
use "D:\Pedro\Tese Pedro\Flypaper\5_ano\5_ano_2008_2015.dta" 



keep if ano== 2008
gen d_08 = 1

keep cod_escola d_08

merge m:m cod_escola using "D:\Pedro\Tese Pedro\Flypaper\5_ano\5_ano_2008_2015.dta" 

replace d_08 =0 if d_08 ==.

move cod_escola mun
move d_08 tdi_anos_iniciais


rename cod_mun cod_ibge

drop _merge
 
label variable d_08 "Escola que aparece em 2008 ao longo dos anos"

save "D:\Pedro\Tese Pedro\Flypaper\5_ano\5_ano_2008_2015_1.dta", replace


*Criando o rank das escolas pela mediana* 

egen rank_med_mt = xtile(prof_mt), by(cod_ibge ano) nq(2)

egen rank_med_lp = xtile(prof_lp), by(cod_ibge ano) nq(2)

label variable rank_med_lp "rank mediana das escolas LP em cada ano"
label variable rank_med_mt "rank mediana das escolas MT em cada ano"


save "D:\Pedro\Tese Pedro\Flypaper\5_ano\5_ano_2008_2015_1.dta", replace

bysort ano: tab d_08 rank_med_lp 
bysort ano: tab d_08 rank_med_mt

keep if ano ==2008

keep cod_escola rank_med_lp rank_med_mt

rename rank_med_lp rank_08_lp
rename rank_med_mt rank_08_mt

tab rank_08_lp
tab rank_08_mt

merge m:m cod_escola using "D:\Pedro\Tese Pedro\Flypaper\5_ano\5_ano_2008_2015_1.dta"


move rank_08_lp rank_med_lp
move rank_08_mt rank_med_mt

move cod_escola mun

label variable rank_08_lp "rank das escolas em 2008 para LP"
label variable rank_08_mt "rank das escolas em 2008 para MT"

drop _merge


gen tratamento_med_lp =.
replace tratamento_med_lp =1 if rank_08_lp ==1
replace tratamento_med_lp =0 if rank_08_lp ==2

gen tratamento_med_mt =.
replace tratamento_med_mt =1 if rank_08_mt ==1
replace tratamento_med_mt =0 if rank_08_mt ==2


tab tratamento_med_lp ano, m
tab tratamento_med_mt ano, m

tab cod_ibge tratamento_med_lp if ano==2008
tab cod_ibge tratamento_med_mt if ano==2008


** Temos todos os municipios com pelo menos 2 escolas, o que possibilita o uso da mediana e a não exclusão de nenhum municipio **


label variable tratamento_med_lp " Mediana inferior de 2008 para LP 5º ano ao longo dos anos"
label variable tratamento_med_mt " Mediana inferior de 2008 para MT 5º ano ao longo dos anos"


gen it= ano*cod_ibge
label variable it "interação ano*municipio"

*** Resultados padronizados já estão disponiveis na base inicial, logo não precisamos padroniza-los**

areg std_prof_mt i.ano tratamento_med_mt , a(it) cl(cod_escola)

areg std_prof_lp i.ano tratamento_med_lp , a(it) cl(cod_escola)

save "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta", replace




********************************************************************************
*******             UNINDO BASE ESCOLA + BASE COTA PARTE            ************
********************************************************************************

clear all


use "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta"

merge m:m cod_ibge using "D:\GitHub\flypaper-\cp_x.dta"

keep if _merge==3

drop _merge

tab ano rank_cp_x
tab tratamento_med_lp rank_cp_x, m
tab tratamento_med_mt rank_cp_x, m
bysort ano: tab tratamento_med_lp rank_cp_x, m
bysort ano: tab tratamento_med_mt rank_cp_x, m


* Criando ranks escola 
gen mtrat1_lp=.
replace mtrat1_lp =1 if rank_08_lp==1 & rank_cp_x==3
replace mtrat1_lp =0 if rank_08_lp==1 & rank_cp_x==1

label variable mtrat1_lp " Mediana inferior escola LP + 3º tercil cp em relação ao 1º tercil cp"

gen mtrat2_lp=.
replace mtrat2_lp=1 if rank_08_lp==2 & rank_cp_x==3
replace mtrat2_lp=0 if rank_08_lp==2 & rank_cp_x==1

label variable mtrat2_lp "Mediana superior LP + 3º tercil cp em relação ao 1º tercil cp"


gen mtrat1_mt=.
replace mtrat1_mt =1 if rank_08_mt==1 & rank_cp_x==3
replace mtrat1_mt =0 if rank_08_mt==1 & rank_cp_x==1

label variable mtrat1_mt " Mediana inferior escola MT + 3º tercil cp em relação ao 1º tercil cp"

gen mtrat2_mt=.
replace mtrat2_mt=1 if rank_08_mt==2 & rank_cp_x==3
replace mtrat2_mt=0 if rank_08_mt==2 & rank_cp_x==1

label variable mtrat2_mt "Mediana superior MT + 3º tercil cp em relação ao 1º tercil cp"

save "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta", replace


********************************************************************************
******************** Unindo base com gasto total, pib e fpm ********************
********************************************************************************
clear all 

use "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta"

merge m:m cod_ibge using "D:\Pedro\Tese Pedro\Flypaper\flypaper-rafa\Base I.dta"


** Abaiara, Altaneira, Cariré, Groaíras, Ibaretama, Palmácia, São Benedito, São Luís do Curu, Uruburetama  foram exlcuidas por não ter dados **

keep if _merge ==3
drop _merge

save "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta", replace



********************************************************************************
******************************** Ebalance **************************************
********************************************************************************


clear all

use "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta"

keep if ano==2008

gen pos = mestrado + doutorado


keep cod_escola alfa_incompleto inter sufic desej especializacao pos  d_idade_1 d_idade_2 d_idade_3 d_idade_4 d_tp_sexo_1 d_tp_cor_branco  apr_1 apr_2 aban_1 aban_2  g_totalpc08 pib_percapta08 fpm08 


keep cod_escola _critico_mt _intermediario_mt _adequado_mt _critico_lp _intermediario_lp _adequado_lp especializacao pos d_idade_1 d_idade_2 d_idade_3 d_idade_4 d_tp_sexo_1 d_tp_cor_branco  apr_1 apr_2 apr_3 apr_3 apr_4 apr_5 aban_1 aban_2 aban_3 aban_4 aban_5 g_totalpc08 pib_percapta08 fpm08 

move pos d_idade_1

rename _critico_mt _critico_mt_08
rename _intermediario_mt _intermediario_mt_08
rename _adequado_mt _adequado_mt_08
rename _critico_lp _critico_lp_08
rename _intermediario_lp _intermediario_lp_08
rename _adequado_lp _adequado_lp_08
rename especializacao especializacao_08
rename pos pos_08
rename d_idade_1 d_idade_1_08
rename d_idade_2 d_idade_2_08
rename d_idade_3 d_idade_3_08
rename d_idade_4 d_idade_4_08
rename d_tp_sexo_1 d_tp_sexo_1_08
rename d_tp_cor_branco d_tp_cor_branco_08
rename apr_1 apr_1_08
rename apr_2 apr_2_08
rename apr_3 apr_3_08
rename apr_4 apr_4_08
rename apr_5 apr_5_08
rename aban_1 aban_1_08
rename aban_2 aban_2_08
rename aban_3 aban_3_08
rename aban_4 aban_4_08
rename aban_5 aban_5_08


merge m:m cod_escola using "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta"

keep if _merge ==3

drop _merge

* Ebalance Matemática*
ebalance mtrat1_mt _critico_mt_08 _intermediario_mt_08 _adequado_mt_08  especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 apr_3_08 apr_4_08 apr_5_08 aban_1_08 aban_2_08 aban_3_08 aban_4_08 aban_5_08  g_totalpc08 pib_percapta08 fpm08

rename _webal _mwebal1_mt


ebalance mtrat2_mt _critico_mt_08 _intermediario_mt_08 _adequado_mt_08  especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 apr_3_08 apr_4_08 apr_5_08 aban_1_08 aban_2_08 aban_3_08 aban_4_08 aban_5_08  g_totalpc08 pib_percapta08 fpm08

rename _webal _mwebal2_mt

* Ebalance Portugues*
ebalance mtrat1_lp _critico_lp_08 _intermediario_lp_08 _adequado_lp_08  especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 apr_3_08 apr_4_08 apr_5_08 aban_1_08 aban_2_08 aban_3_08 aban_4_08 aban_5_08  g_totalpc08 pib_percapta08 fpm08

rename _webal _mwebal1_lp


ebalance mtrat2_lp _critico_lp_08 _intermediario_lp_08 _adequado_lp_08  especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 apr_3_08 apr_4_08 apr_5_08 aban_1_08 aban_2_08 aban_3_08 aban_4_08 aban_5_08  g_totalpc08 pib_percapta08 fpm08

rename _webal _mwebal2_lp


save "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta", replace



********************************************************************************
******************************* Estimações *************************************
********************************************************************************
**** Estimações  ******
mkdir C:/results
cd C:/results


*** Drop nas escolas entrantes*
*drop if tratamento==.
*tab cod_escola, gen(cod_escola_i)


****************************** SPAECE ALFA *************************************
use "D:\GitHub\flypaper-\spaece_inicial_inter.dta"

areg std_prof i.ano mtrat1, a(it) cl(cod_escola)
outreg2 using resultados_alfa.xls, dec(3) replace
areg std_prof i.ano mtrat1 _mwebal1, a(it) cl(cod_escola)
outreg2 using resultados_alfa.xls, dec(3) append
areg std_prof i.ano mtrat1 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08, a(it) cl(cod_escola)
outreg2 using resultados_alfa.xls, dec(3) append



areg std_prof i.ano mtrat2, a(it)  cl(cod_escola)
outreg2 using resultados_alfa.xls, dec(3) append
areg std_prof i.ano mtrat2 _mwebal2, a(it) cl(cod_escola)
outreg2 using resultados_alfa.xls, dec(3) append
areg std_prof i.ano mtrat2 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08, a(it) cl(cod_escola)
outreg2 using resultados_alfa.xls, dec(3) append


****************************** SPAECE 5º ANO ***********************************
clear all 

use "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta"

areg std_prof_lp i.ano mtrat1_lp, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) replace
areg std_prof_lp i.ano mtrat1_lp _mwebal1_lp, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append
areg std_prof_lp i.ano mtrat1_lp _critico_lp_08 _intermediario_lp_08 _adequado_lp_08  especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 apr_3_08 apr_4_08 apr_5_08 aban_1_08 aban_2_08 aban_3_08 aban_4_08 aban_5_08  g_totalpc08 pib_percapta08 fpm08, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append

areg std_prof_lp i.ano mtrat2_lp, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append
areg std_prof_lp i.ano mtrat2_lp _mwebal2_lp, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append
areg std_prof_lp i.ano mtrat2_lp _critico_lp_08 _intermediario_lp_08 _adequado_lp_08  especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 apr_3_08 apr_4_08 apr_5_08 aban_1_08 aban_2_08 aban_3_08 aban_4_08 aban_5_08  g_totalpc08 pib_percapta08 fpm08, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append



areg std_prof_mt i.ano mtrat1_mt, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append
areg std_prof_mt i.ano mtrat1_mt _mwebal1_mt, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append
areg std_prof_mt i.ano mtrat1_mt _critico_mt_08 _intermediario_mt_08 _adequado_mt_08  especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 apr_3_08 apr_4_08 apr_5_08 aban_1_08 aban_2_08 aban_3_08 aban_4_08 aban_5_08  g_totalpc08 pib_percapta08 fpm08, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append

areg std_prof_mt i.ano mtrat2_mt, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append
areg std_prof_mt i.ano mtrat2_mt _mwebal2_mt, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append
areg std_prof_mt i.ano mtrat2_mt _critico_mt_08 _intermediario_mt_08 _adequado_mt_08  especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 apr_3_08 apr_4_08 apr_5_08 aban_1_08 aban_2_08 aban_3_08 aban_4_08 aban_5_08  g_totalpc08 pib_percapta08 fpm08, a(it) cl(cod_escola)
outreg2 using resultados_5_ano.xls, dec(3) append




********************************************************************************
*************************** Codigo para fazer tabelas **************************
******************************************************************************** 








********************************************************************************
***************************** Mecanismos ***************************************
********************************************************************************



****************************** SPAECE ALFA *************************************
clear all 

use "D:\GitHub\flypaper-\spaece_inicial_inter.dta"
















****************************** SPAECE 5º ANO ***********************************
clear all 

use "D:\GitHub\flypaper-\spaece_5_inicial_inter.dta"