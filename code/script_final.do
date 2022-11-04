* Rotina artigo Flypaper na educação - Resultados para educação *
*Correções e analises do artigo *

*Definindo Global e diretorios

global path "D:\GitHub\artigo_educacao_ceara"
global output "$path\output"
global raw "$path\data\raw"
global clean "$path\data\clean"
mkdir output
cd $path


*A 1º parte do script é referente a CP, depois disso que mexemos na base de proficiência*

********************************************************************************
*******             Organização da Base COTA PARTE                  ************
********************************************************************************
* Base Inicial é a Base no formato Bruto. Dela serão obtidas as demais bases.
use "$raw\Base Inicial.dta" , clear

drop if ano==2018

merge m:m ano using "$raw\inf_dessa.dta"
gen id=_n
drop _merge
merge m:m id using "$raw\controls.dta"
drop if _merge ==2
drop _merge

format %13.0g TransferênciasdoFUNDEB
format %13.0g cotapartefpm


merge m:m id using "$raw\valor_real_cp.dta"
drop _merge	

save "$raw\Base Inicial 2.dta", replace


********************************************************************************
****** Construção das variáveis de resultado e controle iniciais ***************
********************************************************************************

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

*renomeando as variaveis
rename cotapartefpm fpm
rename TransferênciasdoFUNDEB fundeb
rename INDICEEDUCACAO iqe
rename INDICESAUDE iqs
rename INDICEMAMBIENTE iqm
destring SituaçãolimitesLRF, replace
rename SituaçãolimitesLRF situacao
rename Reeleição reeleicao

*Criando as novas variaveis
replace g_total= g_total/inf_dess
replace g_educ= g_educ/inf_dess
replace g_fund= g_fund/inf_dess
replace pib= pib/inf_dess
replace fpm= fpm/inf_dess
replace fundeb= fundeb/inf_dess
replace cp= cp/inf_dess
gen g_n_edu=g_total-g_educ

format %14.0g g_n_edu


save "$raw\Base Inicial 2.dta", replace



* Criando a base para 2008 (ano base para o modelo)


keep if ano==2008
keep cod_ibge pop g_total g_educ g_fund RLíquido cp g_n_edu

save "$raw\base_08.dta", replace

rename pop pop08
rename g_total g_total08
rename g_n_edu g_n_edu08
rename g_educ g_educ08
rename g_fund g_fund08
rename cp cp08

save "$raw\base_08.dta", replace

* Unindo com a base inicial 2
use "$raw\Base Inicial 2.dta", clear 
merge m:m cod_ibge using "$raw\base_08.dta"
drop _merge

* Criando novas variaveis a partir do modelo 
gen g_total_x=(g_total-g_total08)/pop08
gen g_nao_ed_x=(g_n_edu-g_n_edu08)/pop08
gen g_educ_x=(g_educ-g_educ08)/pop08
gen g_fund_x=(g_fund-g_fund08)/pop08
gen cp_x=(cp-cp08)/pop08

* Mantendo apenas para o ano de 2009 (inicial da CP)
keep if ano==2009

*Criando a variavel de tercil
egen rank_cp_x = xtile (cp_x), nq(3)

tab rank_cp_x, m

*7 missing -> São Luís do Curu, São Benedito, Cariré, Palmácia, Uruburetama, Ibaretama, Groaíras
drop if  cod_ibge==2303105 | cod_ibge==2310100 | cod_ibge==2313807| cod_ibge==2312304 |cod_ibge==2312601 | cod_ibge==2304905 |cod_ibge==2305266

drop pop-g_fund_x
drop ano Municipio

*Salvando a base da cota parte para ano de 2009

save "$clean\cp_x.dta", replace


********************************************************************************
*******             Organização Base ESCOLA PROFICÊNCIA             ************
****************************** SPAECE ALFA *************************************
********************************************************************************


use "$raw\spaece_inicial.dta", clear 


*Ficando com ano de 2007 e criando uma dummy para essas escolas 
keep if ano== 2007
gen d_07 = 1

*Ficando apenas com o codigo das escolas e a dummy 07
keep cod_escola d_07

*Unindo com a base inicial do spaece
merge m:m cod_escola using "$raw\spaece_inicial.dta"
drop _merge
*Mudando a variavel dummy para ficar com 0 
replace d_07 =0 if d_07 ==.

*Mudando a ordem das variaveis
move cod_escola mun
move d_07 tdi_anos_iniciais

*renomeando variaveis 
rename cod_mun cod_ibge
label variable d_07 "Escola que aparece em 2007 ao longo dos anos"

save "$raw\spaece_inicial_1.dta", replace


* Criando o Rank das escolsa pela mediana
egen rank_med = xtile(prof_med), by(cod_ibge ano) nq(2)
label variable rank_med "rank mediana das escolas em cada ano"

save "$raw\spaece_inicial_1.dta", replace

*bysort ano: tab d_07 rank_med

* Ficando apenas com o ano de 2007, codigo da escola e rank da mediana 
keep if ano ==2007 
keep cod_escola rank_med
rename rank_med rank_07

*tab rank_07

*Unindo com a base do spaece
merge m:m cod_escola using "$raw\spaece_inicial_1.dta"
drop _merge

*Ordenando e nomeando as variaveis
move rank_07 rank_med
move cod_escola mun
label variable rank_07 "rank das escolas em 2007"

*Definindo quem seram as escolas tratadas
gen tratamento_med =.
replace tratamento_med =1 if rank_07 ==1
replace tratamento_med =0 if rank_07 ==2

*tab tratamento ano, m
*tab cod_ibge tratamento_med if ano==2007
* Todos os os municipios tem pelo menos 2 escolas, logo não excluimos nenhum municipio.

*Nomeando as variaveis
label variable tratamento_med " Mediana inferior de 2007 ao longo dos anos"

*Criando a variveal de interacao ano*municipios
gen it= ano*cod_ibge
label variable it "interação ano*municipio"


*Padronizando a nota
egen std_prof = std(prof_med)
move std_prof prof_med


*areg std_prof i.ano tratamento , a(it) cl(cod_escola)

save "$clean\spaece_inter.dta", replace


********************************************************************************
*******             UNINDO BASE ESCOLA + BASE COTA PARTE            ************
********************************************************************************

use "$clean\spaece_inter.dta", clear

merge m:m cod_ibge using "$clean\cp_x.dta"
keep if _merge==3
drop _merge


*tab ano rank_cp_x
*tab tratamento rank_cp_x, m
*bysort ano: tab tratamento rank_cp_x, m


* Criando ranks escola 
gen mtrat1=.
replace mtrat1 =1 if rank_07==1 & rank_cp_x==3
replace mtrat1 =0 if rank_07==1 & rank_cp_x==1

label variable mtrat1 " Mediana inferior escola + 3º tercil cp em relação ao 1º tercil cp"

gen mtrat2=.
replace mtrat2=1 if rank_07==2 & rank_cp_x==3
replace mtrat2=0 if rank_07==2 & rank_cp_x==1

label variable mtrat2 "Mediana superior + 3º tercil cp em relação ao 1º tercil cp"

save "$clean\spaece_inter.dta", replace



********************************************************************************
******************** Unindo base com gasto total, pib e fpm ********************
********************************************************************************
use "$raw\Base I.dta" , clear

keep if ano ==2008

gen g_totalpc08 = g_total08/pop08
gen pib_percapta08 = pib /pop08
gen fpm08 =fpm / pop

keep cod_ibge  g_totalpc08 pib_percapta08 fpm08

save "$raw\Base I.dta", replace

use "$raw\spaece_inicial_1.dta", clear
merge m:m cod_ibge using "$raw\Base I.dta"
keep if _merge ==3
drop _merge

save "$raw\spaece_inicial_1.dta", replace




********************************************************************************
******************** Regressões e Balanceamento  *******************************
********************************************************************************


******************************** Ebalance **************************************

use "$raw\spaece_inicial_1.dta" , clear

*Ficando com ano 2008
keep if ano==2008

*Criando a variavel de pos
gen pos = mestrado + doutorado

*Selecionando as variaveis
keep cod_escola alfa_incompleto inter sufic desej especializacao pos  d_idade_1 d_idade_2 d_idade_3 d_idade_4 d_tp_sexo_1 d_tp_cor_branco  apr_1 apr_2 aban_1 aban_2  g_totalpc08 pib_percapta08 fpm08 

*Organizando a base
move pos d_idade_1

*Renomeando a base
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


*Unindo com a base intermediaria
merge m:m cod_escola using "$clean\spaece_inter.dta"
keep if _merge ==3
drop _merge



*Ebalance 
ebalance mtrat1 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

*Renomeando balanceamento
rename _webal _mwebal1


ebalance mtrat2 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08

*Renomeando balanceamento
rename _webal _mwebal2

save "$clean\spaece_inter.dta", replace



******************************* Estimações *************************************


use "$clean\spaece_inter.dta", clear


*mtrat1 - Mediana inferior escola + 3º tercil cp em relação ao 1º tercil cp
areg std_prof i.ano mtrat1, a(it) cl(cod_escola)
outreg2 using $output/resultados_alfa.xls, dec(3) replace
areg std_prof i.ano mtrat1 _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/resultados_alfa.xls, dec(3) append
areg std_prof i.ano mtrat1 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08, a(it) cl(cod_escola)
outreg2 using $output/resultados_alfa.xls, dec(3) append


*mtrat2 Mediana superior + 3º tercil cp em relação ao 1º tercil cp
areg std_prof i.ano mtrat2, a(it)  cl(cod_escola)
outreg2 using $output/resultados_alfa.xls, dec(3) append
areg std_prof i.ano mtrat2 _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/resultados_alfa.xls, dec(3) append
areg std_prof i.ano mtrat2 alfa_incompleto_08 inter_08 sufic_08 desej_08 especializacao_08 pos_08 d_idade_1_08 d_idade_2_08 d_idade_3_08 d_idade_4_08 d_tp_sexo_1_08 d_tp_cor_branco_08 apr_1_08 apr_2_08 aban_1_08 aban_2_08 g_totalpc08 pib_percapta08 fpm08, a(it) cl(cod_escola)
outreg2 using $output/resultados_alfa.xls, dec(3) append



* T Test entre mtrat 1 e mtrat 2 (todos os resultados mostram que rejeita-se o a H0 para médias iguais a 0)

*Regressão simples:
ttesti 10112 .536928 .3403192 10201 1.111506 .3761085, unequal
*Regressão webal
ttesti 8389 .327471 .3536916 8648 1.116276 .3934869, unequal
*Regressão covariadas
ttesti 8389 .4976237 .4397598 8648 1.631373 .51808, unequal



***************************** Mecanismos ***************************************
use "$clean\indicadores_inep.dta" , clear


*Criando o PCA para os indicadores do INEP
keep ano cod_escola ird adf_ai_1  adf_ai_3 adf_ai_5 atu_2 dsu_ai dur_2 icg ied_ai_3 

egen std_ird = std(ird)
egen std_adf_ai_1 = std (adf_ai_1)
egen std_adf_ai_3 = std (adf_ai_3)
egen std_adf_ai_5 = std (adf_ai_5)
egen std_atu_2 = std (atu_2)
egen std_dsu_ai = std (dsu_ai)
egen std_dur_2 = std (dur_2)
egen std_icg = std (icg)
egen std_ied_ai_3 = std (ied_ai_3)

keep ano cod_escola atu_2 dur_2 std_ird std_adf_ai_1 std_adf_ai_3 std_adf_ai_5 std_atu_2 std_dsu_ai std_dur_2 std_icg std_ied_ai_3

*Matriz correlacao
corr std_ird std_adf_ai_1 std_adf_ai_3 std_adf_ai_5 std_atu_2 std_dsu_ai std_dur_2 std_icg std_ied_ai_3

*Testes
factortest std_ird std_adf_ai_1 std_adf_ai_3 std_adf_ai_5 std_atu_2 std_dsu_ai std_dur_2 std_icg std_ied_ai_3
factor std_ird std_adf_ai_1 std_adf_ai_3 std_adf_ai_5 std_atu_2 std_dsu_ai std_dur_2 std_icg std_ied_ai_3
rotate
alpha std_ird std_adf_ai_1 std_adf_ai_3 std_adf_ai_5 std_atu_2 std_dsu_ai std_dur_2 std_icg std_ied_ai_3

loadingplot
scoreplot
screeplot, yline(1)

*PCA
pca std_ird std_adf_ai_1 std_adf_ai_3 std_adf_ai_5  std_dur_2 std_icg std_ied_ai_3

predict pca

sum pca

egen std_pca = std (pca)


merge m:m ano cod_escola using "$clean\spaece_inter.dta"

*Regressões

*IRD
areg std_ird  mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) replace 
areg std_ird  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append

*ADF -1
areg std_adf_ai_1  mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append
areg std_adf_ai_1  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append

*ADF -3
areg std_adf_ai_3  mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append
areg std_adf_ai_3  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append

*ADF -5
areg std_adf_ai_5  mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append
areg std_adf_ai_5  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append

*ICG
areg std_icg  mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append
areg std_icg  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append

*IED -3
areg std_ied_ai_3  mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append
areg std_ied_ai_3  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append

*ATU
areg atu_2  mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append
areg atu_2  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append

*DURACAO
areg dur_2  mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append
areg dur_2  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append

*DSU
areg std_dsu_ai  mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append
areg std_dsu_ai  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append

*PCA
areg std_pca mtrat1  _mwebal1, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append
areg std_pca  mtrat2  _mwebal2, a(it) cl(cod_escola)
outreg2 using $output/mecanismo_alfa.xls, dec(3) append




********************************************************************************

*SUR MODEL TO TEST THE COEFFICIENTS
qui reg std_prof i.ano mtrat1 _mwebal1 
estimates store m1
qui reg std_prof i.ano mtrat2 _mwebal2 
estimates store m2


suest m1 m2, cl(cod_escola)


test [m1_mean]mtrat1 - [m2_mean]mtrat2 =0


