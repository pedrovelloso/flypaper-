* Flypaper in Educ*
/*
Coletando as  informações do SPAECE alfa disponiveis em:
https://www.seduc.ce.gov.br/resultado-spaece-alfa/ ,
bem como os microdados disponiblizados do anos de 20007 a 2015, disponivel em:
http://inep.gov.br/microdados & http://portal.inep.gov.br/indicadores-educacionais

*/

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


egen rank = xtile(prof_med), by(cod_ibge ano) nq(4)

label variable rank "rank das escolas em cada ano"

save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta", replace

bysort ano: tab d_07 rank

keep if ano ==2007 

keep cod_escola rank

rename rank rank_07

tab rank_07

merge m:m cod_escola using "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"

move rank_07 rank
move cod_escola mun

label variable rank_07 "rank das escolas em 2007"

drop _merge



gen tratamento =.
replace tratamento =1 if rank_07 ==1
replace tratamento =0 if rank_07 ==2
replace tratamento =0 if rank_07 ==3
replace tratamento =0 if rank_07 ==4

tab tratamento ano, m

*Abaibara e Altaneira com menos de 4 escolas em 2007

drop if cod_ibge== 2300101
drop if cod_ibge== 2300606

label variable tratamento "1º quartil de 2007 ao longo dos anos"


gen it= ano*cod_ibge
label variable it "interação ano*municipio"

egen std_prof = std(prof_med)
move std_prof prof_med


areg std_prof i.ano tratamento , a(it) cl(cod_escola)


save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta", replace


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

save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\cp_x.dta", replace


********************************************************************************
*******             UNINDO BASE ESCOLA + BASE COTA PARTE            ************
********************************************************************************


clear all


use "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"


merge m:m cod_ibge using "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\cp_x.dta"

keep if _merge ==3

drop _merge

tab ano rank_cp_x
tab tratamento rank_cp_x, m
bysort ano: tab tratamento rank_cp_x, m

* Criando ranks escola 
set matsize 11000



gen trat1=.
replace trat1 =1 if rank_07==1 & rank_cp_x==3
replace trat1 =0 if rank_07==1 & rank_cp_x==1

label variable trat1 " 1º quartil escola + 3º tercil cp em relação ao 1º tercil cp"

gen trat2=.
replace trat2=1 if rank_07==2 & rank_cp_x==3
replace trat2=0 if rank_07==2 & rank_cp_x==1

label variable trat2 "2º quartil escola + 3º tercil cp em relação ao 1º tercil cp"

gen trat3=.
replace trat3=1 if rank_07==3 & rank_cp_x==3
replace trat3=0 if rank_07==3 & rank_cp_x==1
 
label variable trat3 "3º quartil escola + 3º tercil cp em relação ao 1º tercil cp"


gen trat4=.
replace trat4=1 if rank_07==4 & rank_cp_x==3
replace trat4=0 if rank_07==4 & rank_cp_x==1



label variable trat4 "4º quartil escola + 3º tercil cp em relação ao 1º tercil"

save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta", replace
********************************************************************




*** Drop nas escolas entrantes*
*drop if tratamento==.
*tab cod_escola, gen(cod_escola_i)

**** Estimações  ******
mkdir C:/results
cd C:/results


areg std_prof i.ano trat1, a(it) cl(cod_escola)
areg std_prof i.ano trat2, a(it)  cl(cod_escola)
areg std_prof i.ano trat3, a(it)  cl(cod_escola)
areg std_prof i.ano trat4, a(it)  cl(cod_escola)


areg std_prof i.ano trat1 i.cod_escola , a(it) 
areg std_prof i.ano trat2 i.cod_escola , a(it) 
areg std_prof i.ano trat3 i.cod_escola , a(it) 
areg std_prof i.ano trat4 i.cod_escola , a(it) 

outreg2 using tratamento.xls, append dec(3)

use "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"





/*
keep if ano ==2007

drop if aln_efetivo <=5

keep cod_escola

merge m:m cod_escola using "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"

keep if _merge ==3
drop _merge

bysort ano: tab aln_efetivo if aln_efetivo <=5


areg std_prof i.ano trat1, a(it) cl(cod_escola)
areg std_prof i.ano trat2, a(it)  cl(cod_escola)
areg std_prof i.ano trat3, a(it)  cl(cod_escola)
areg std_prof i.ano trat4, a(it)  cl(cod_escola)


areg std_prof i.ano trat1 i.cod_escola , a(it) 
areg std_prof i.ano trat2 i.cod_escola , a(it) 
areg std_prof i.ano trat3 i.cod_escola , a(it) 
areg std_prof i.ano trat4 i.cod_escola , a(it) 



clear all


use "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"


keep if ano ==2007

drop if aln_efetivo <=10

keep cod_escola

merge m:m cod_escola using "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"

keep if _merge ==3
drop _merge

bysort ano: tab aln_efetivo if aln_efetivo <=5


areg std_prof i.ano trat1, a(it) cl(cod_escola)
areg std_prof i.ano trat2, a(it)  cl(cod_escola)
areg std_prof i.ano trat3, a(it)  cl(cod_escola)
areg std_prof i.ano trat4, a(it)  cl(cod_escola)


areg std_prof i.ano trat1 i.cod_escola , a(it) 
areg std_prof i.ano trat2 i.cod_escola , a(it) 
areg std_prof i.ano trat3 i.cod_escola , a(it) 
areg std_prof i.ano trat4 i.cod_escola , a(it) 


*/


***** Unindo base com gasto total, pib e fpm ****

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


/*
Abaiara, Altaneira, Cariré, Groaíras, Ibaretama, Palmácia, São Benedito, São Luís do Curu, Uruburetama 

foram exlcuidas por não ter dados
*/

keep if _merge ==3


drop _merge


save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta", replace


********************************************************************************
clear all

use "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"


keep if ano==2008


gen pos = mestrado + doutorado



keep cod_escola alfa_incompleto inter sufic desej especializacao pos  d_idade_1 d_idade_2 d_idade_3 d_idade_4 d_tp_sexo_1 d_tp_cor_branco  apr_1 apr_2 aban_1 aban_2  g_totalpc08 pib_percapta08 fpm08 _webal1 _webal2 _webal3 _webal4

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


save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_2.dta", replace

clear all



use "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_1.dta"


merge m:m cod_escola using "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_2.dta"


*save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_3.dta", replace


ebalance trat1 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

rename _webal _webal1

ebalance trat2 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

rename _webal _webal2

ebalance trat3 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

rename _webal _webal3

ebalance trat4 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

rename _webal _webal4


save "D:\Pedro\Tese Pedro\Flypaper\Pareamento\censo\spaece_inicial_2.dta", replace

areg std_prof i.ano trat1 , a(it) cl(cod_escola)
outreg2 using tratamento.xls, dec(3) replace
areg std_prof i.ano trat1 _webal1, a(it) cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append
areg std_prof i.ano trat1 g_totalpc08- aban_2_08, a(it) cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append

areg std_prof i.ano trat2, a(it)  cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append
areg std_prof i.ano trat2 _webal2, a(it) cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append
areg std_prof i.ano trat2 g_totalpc08- aban_2_08, a(it) cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append

areg std_prof i.ano trat3, a(it)  cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append
areg std_prof i.ano trat3 _webal3, a(it) cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append
areg std_prof i.ano trat3 g_totalpc08- aban_2_08, a(it) cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append

areg std_prof i.ano trat4, a(it)  cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append
areg std_prof i.ano trat4 _webal4, a(it) cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append
areg std_prof i.ano trat4 g_totalpc08- aban_2_08, a(it) cl(cod_escola)
outreg2 using tratamento.xls, dec(3) append

********************************************************************************
egen mediana_cp_x = xtile (cp_x), nq(2)

tab mediana_cp_x

tab rank_07 mediana_cp_x

gen mtrat1=.
replace mtrat1 =1 if rank_07==1 & mediana_cp_x==2
replace mtrat1 =0 if rank_07==1 & mediana_cp_x==1


gen mtrat4=.
replace mtrat4=1 if rank_07==4 & mediana_cp_x==2
replace mtrat4=0 if rank_07==4 & mediana_cp_x==1


ebalance mtrat1 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

rename _webal _mwebal1


ebalance mtrat4  alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

rename _webal _mwebal4



areg std_prof i.ano mtrat1, a(it) cl(cod_escola)
outreg2 using median_cp.xls, dec(3) replace
areg std_prof i.ano mtrat1 _mwebal1, a(it)  cl(cod_escola)
outreg2 using median_cp.xls, dec(3) append
areg std_prof i.ano mtrat1 g_totalpc08- aban_2_08, a(it)  cl(cod_escola)
outreg2 using median_cp.xls, dec(3) append
areg std_prof i.ano mtrat4, a(it)  cl(cod_escola)
outreg2 using median_cp.xls, dec(3) append
areg std_prof i.ano mtrat4 _mwebal4, a(it) cl(cod_escola)
outreg2 using median_cp.xls, dec(3) append
areg std_prof i.ano mtrat4 g_totalpc08- aban_2_08, a(it) cl(cod_escola)
outreg2 using median_cp.xls, dec(3) append



********************************************************************************

use "C:\Users\Pedro Veloso\Documents\GitHub\flypaper-\spaece_inicial_3.dta" 


egen std_atu = std(atu)
egen std_duracao = std (duracao_)
egen std_dsu = std(dsu)


areg std_atu i.ano trat1, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) replace
areg std_atu i.ano trat1 _webal1, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_atu i.ano trat2, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_atu i.ano trat2 _webal2, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_atu i.ano trat3, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_atu i.ano trat3 _webal3, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_atu i.ano trat4, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_atu i.ano trat4 _webal4, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append



areg std_dsu i.ano trat1, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_dsu i.ano trat1 _webal1, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_dsu i.ano trat2, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_dsu i.ano trat2 _webal2, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_dsu i.ano trat3, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_dsu i.ano trat3 _webal3, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_dsu i.ano trat4, a(it) 
outreg2 using indicadores.xls, dec(3) append
areg std_dsu i.ano trat4 _webal4, a(it) 
outreg2 using indicadores.xls, dec(3) append



areg std_duracao i.ano trat1, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_duracao i.ano trat1 _webal1, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_duracao i.ano trat2, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_duracao i.ano trat2 _webal2, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_duracao i.ano trat3, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_duracao i.ano trat3 _webal3, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_duracao i.ano trat4, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append
areg std_duracao i.ano trat4 _webal4, a(it) cl(cod_escola)
outreg2 using indicadores.xls, dec(3) append




areg atu i.ano trat1, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) replace
areg atu i.ano trat1 _webal1, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg atu i.ano trat2, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg atu i.ano trat2 _webal2, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg atu i.ano trat3, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg atu i.ano trat3 _webal3, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg atu i.ano trat4, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg atu i.ano trat4 _webal4, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append


areg duracao_ i.ano trat1, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg duracao_ i.ano trat1 _webal1, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg duracao_ i.ano trat2, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg duracao_ i.ano trat2 _webal2, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg duracao_ i.ano trat3, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg duracao_ i.ano trat3 _webal3, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg duracao_ i.ano trat4, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg duracao_ i.ano trat4 _webal4, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append


areg dsu i.ano trat1, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg dsu i.ano trat1 _webal1, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg dsu i.ano trat2, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg dsu i.ano trat2 _webal2, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg dsu i.ano trat3, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg dsu i.ano trat3 _webal3, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg dsu i.ano trat4, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append
areg dsu i.ano trat4 _webal4, a(it) cl(cod_escola)
outreg2 using indicadores1.xls, dec(3) append

save "C:\Users\Pedro Veloso\Documents\GitHub\flypaper-\spaece_inicial_3.dta", replace 