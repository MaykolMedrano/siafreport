*! siafreport:  
*! Version 1.0.0: 2020/10/03
*! Author: Maykol Medrano
*! Ministry of Education
*! maykolmedrano35@gmail.com
										
capture program drop siafreport
program define siafreport
syntax 	name(id="minedu"),[ ///
		filename(string)	///
		CACHEpath(string) ///
		FORMAT(string) ///
		CLEAR ///
		]

****************************************************************************

/*
#1. REVISA METADATA DE BASE SIAF
	#1.1. REGISTRA NOMBRE DE ARCHIVO
	#1.2. EXTRAE FECHA Y HORA DE ARCHIVO SIAF
	#1.3. VERIFICA ANNO VALIDO
#2. IMPORTA Y PREPARA DATA
#3. GENERA GRANDES ETIQUETAS
	#3.1. IDENTIFICA BOLSA UPP
	#3.2. GENERA ETIQUETAS
#4.	COLAPSA Y EXPORTA
	#4.1. COLAPSA BASE POR ETIQUETA + EJECUTORA Y EXPORTA OUTPUT
	#4.2. COLAPSA BASE POR ETIQUETA Y EXPORTA OUTPUT
#5. LLENA PLANTILLA
	#5.1. COPIA PLANTILLA A ARCHIVO CON FECHA DE SIAF
	#5.2. EXPORTA DATA A PLANTILLA
	#5.3. DUPLICA PLANTILLA PARA REPORTE (PPT)
*/

****************************************************************************
* Creamos folderes para los files
capture mkdir input
capture mkdir output
capture mkdir reportes
//********************************
//#1. REVISA METADATA DE BASE SIAF
//********************************

//#1.1. REGISTRA NOMBRE DE ARCHIVO
loc siaf_filename "`filename'" 

//#1.2. EXTRAE FECHA Y HORA DE SIAF

*Extrae datos
loc siaf_anho=substr("`siaf_filename'",-10,4)
loc siaf_mes=substr("`siaf_filename'",-13,2)
loc siaf_dia=substr("`siaf_filename'",-16,2)
loc siaf_hora=substr("`siaf_filename'",-5,2)
loc siaf_min=substr("`siaf_filename'",-2,2)

*Genera sello de fecha y hora
loc date_stamp="`siaf_anho'`siaf_mes'`siaf_dia'"
loc siaf_stamp="`siaf_anho'`siaf_mes'`siaf_dia'_`siaf_hora'`siaf_min'"

//#1.3. VERIFICA ANNO VALIDO
if "`siaf_anho'"!="2020" & "`siaf_anho'"!="2019" {
	di in red "Error: Este programa solo funciona para reportes de SIAF 2020 y 2019." ///
	" Verificar el nombre de archivo y la extensión."
	exit
}

di in green "Generando ReporteProgramacionV3_`date_stamp'..." 
//#1.4. DESCARGA FILES PARA REPORTE
loc url "https://github.com/MaykolMedrano/siafreport/raw/master"
qui copy "`url'/siafreport.xlsx"  "`c(pwd)'\reportes\ReporteProgramacionV3_`date_stamp'.xlsx", replace
qui copy "`c(pwd)'/`filename'.xlsx"  "`c(pwd)'/input/`filename'.xlsx", replace
capture confirm file "`c(pwd)'\reportes\siafreport_base.xlsx"
	if _rc!=0 {
	qui copy "`url'/siafreport.xlsx"  "`c(pwd)'\reportes\siafreport_base.xlsx", replace
	}
capture confirm file "`c(pwd)'\reportes\siafreport_base.pptx"
	if _rc!=0 {
	qui copy "`url'/siafreport.pptx"  "`c(pwd)'\reportes\siafreport_base.pptx", replace
	}
qui copy "`c(pwd)'\reportes\siafreport_base.pptx"  "`c(pwd)'\reportes\PROGRAMACIÓN_`date_stamp'.pptx", replace
capture confirm file "`c(pwd)'\Reportes.xlsm"
	if _rc!=0 {
	qui copy "`url'/Reportes.xlsm"  "`c(pwd)'\Reportes.xlsm", replace
	}

//**************************
//#2. IMPORTA Y PREPARA DATA
//**************************

*Importa reporte SIAF
qui import excel using "`siaf_filename'.xlsx", firstrow clear

*Reemplaza espacios con 0 en clasificador
qui replace clasificador=subinstr(clasificador," ","0",.)

*Extrae codigo de generica
qui gen cod_generica=real(substr(generica,1,1))

*Genera codigo de ejecutora
qui gen cod_ejecutora=real(substr(u_ejecutora,1,3))

*Rename devengado
qui rename mto_devenga_* mto_dev_*

*Genera certificado y devengado total
qui egen double mto_cert_tot=rowtotal(mto_cert_01 mto_cert_02 mto_cert_03 mto_cert_04 ///
	mto_cert_05 mto_cert_06 mto_cert_08 mto_cert_09 mto_cert_10 mto_cert_11 ///
	mto_cert_12)
qui egen double mto_dev_tot=rowtotal(mto_dev_01 mto_dev_02 mto_dev_03 mto_dev_04 ///
	mto_dev_05 mto_dev_06 mto_dev_08 mto_dev_09 mto_dev_10 mto_dev_11 ///
	mto_dev_12)
	

//****************************
//#3. GENERA GRANDES ETIQUETAS
//****************************

*#3.1. IDENTIFICA BOLSA UPP
if "`siaf_anho'"=="2020" {
	qui gen ind_bolsa=unidad_operativa=="UNIDAD DE PLANIFICACIÓN Y PRESUPUESTO" & sec_func!="0005"
}
if "`siaf_anho'"=="2019"{
	qui gen ind_bolsa=unidad_operativa=="UNIDAD DE PLANIFICACIÓN Y PRESUPUESTO" & sec_func!="0004"	
}

*#3.2. GENERA ETIQUETAS
qui gen etiqueta=.
*Remuneraciones y Pensiones
qui replace etiqueta=1 if (cod_generica==1 | cod_generica==2)
*CAS
qui replace etiqueta=2 if ///
	substr(clasificador,1,10)=="2.3.02.08."
*No-CAS
qui replace etiqueta=3 if ///
	(cod_generica==3 | cod_generica==4 | cod_generica==5 | cod_generica==7) & ///
	substr(clasificador,1,10)!="2.3.02.08." & ///
	clasificador!="2.5.03.01.01.01" & clasificador!="2.7.01.01.01.01"
*Proyecto
qui replace etiqueta=4 if cod_generica==6 & ///
	substr(producto_proyecto,1,1)=="2"
*Actividad
qui replace etiqueta=5 if cod_generica==6 & ///
	substr(producto_proyecto,1,1)=="3"
*Becas
qui replace etiqueta=6 if clasificador=="2.5.03.01.01.01" | clasificador=="2.7.01.01.01.01"
*Bolsa UPP
qui replace etiqueta=7 if ind_bolsa==1

lab def etiqueta ///
	1 "Remuneraciones y Pensiones" ///
	2 "CAS" ///
	3 "No CAS" ///
	4 "Proyecto" ///
	5 "Actividad" ///
	6 "Becas y Creditos (PRONABEC)" ///
	7 "Bolsa UPP"
lab val etiqueta etiqueta

qui drop if etiqueta==7

//**************************
//#4. LIMPIA LLAVE OPERATIVA
//**************************

qui tostring cod_ejecutora, gen(cod_ejecutora_str)
forval j=1/3 {
	qui replace cod_ejecutora_str="0"+cod_ejecutora_str if length(cod_ejecutora_str)<3
}

qui rename unidad_operativa nom_operativa
qui rename nombre_oficina nom_oficina

qui gen key_operativa= cod_ejecutora_str if cod_ejecutora_str!="024" & cod_ejecutora_str!="026"
qui replace key_operativa = cod_ejecutora_str + " - " + nom_operativa if cod_ejecutora_str =="024"| cod_ejecutora_str=="026"

local agrp "Á É Í Ó Ú á é í ó ú"
local bgrp "A E I O U a e i o u"
local n : word count `agrp'
forvalues i = 1/`n' {
	local a : word `i' of `agrp'
	local b : word `i' of `bgrp'
	qui replace key_operativa=upper(ustrtrim(strtrim(subinstr(key_operativa,"`a'","`b'",.))))
}

*Mueve duplicados (UE 024 y 026)
/*NOTA: OSEE esta registrada como UE 026, por lo que UE se mueve a 026.*/
/*NOTA: UPP esta registrada en UE 024 y 026, pero estamos excluyendo el monto
correspondiente a 026 de la base porque corresponde a transferencias
pendientes (bolsa).*/
qui replace key_operativa="024 - UNIDAD DE PLANIFICACION Y PRESUPUESTO" if key_operativa=="026 - UNIDAD DE PLANIFICACION Y PRESUPUESTO"
qui replace key_operativa="026 - UNIDAD DE ESTADISTICA" if key_operativa=="024 - UNIDAD DE ESTADISTICA"
qui replace key_operativa="026 - OFICINA DE DEFENSA NACIONAL Y DE GESTION DEL RIESGO DE DESASTRES" if key_operativa=="024 - OFICINA DE DEFENSA NACIONAL Y DE GESTION DEL RIESGO DE DESASTRES"
qui replace key_operativa="026 - OFICINA DE TECNOLOGIAS DE LA INFORMACION Y COMUNICACION" if key_operativa=="024 - OFICINA DE TECNOLOGIAS DE LA INFORMACION Y COMUNICACION"
qui replace key_operativa="024 - OFICINA GENERAL DE ADMINISTRACION" if key_operativa=="026 - OFICINA GENERAL DE ADMINISTRACION"
qui replace key_operativa="024 - OFICINA GENERAL DE COMUNICACIONES" if key_operativa=="026 - OFICINA GENERAL DE COMUNICACIONES"
qui replace key_operativa="024 - OFICINA GENERAL DE RECURSOS HUMANOS" if key_operativa=="026 - OFICINA GENERAL DE RECURSOS HUMANOS"
qui replace key_operativa="024 - DIRECCION GENERAL DE GESTION DESCENTRALIZADA" if key_operativa=="026 - DIRECCION GENERAL DE GESTION DESCENTRALIZADA"

//********************
//#5. COLAPSA Y GUARDA
//*********************
*#5.1. EJECUCION MENSUAL (OPERATIVA X ETIQUETON)
collapse (sum) mto_cert_* mto_dev_* mto_pim, by (etiqueta key_operativa) 
order key_operativa etiqueta
sort key_operativa etiqueta
format mto_* %16.0gc

*#5.2. EJECUCION MENSUAL (PLIEGO X ETIQUETON)
collapse (sum) mto_cert_* mto_dev_* mto_pim, by(etiqueta)

*#5.3. DUPLICA PLANTILLA PARA REPORTE (PPT)
qui export excel using "`c(pwd)'\reportes\ReporteProgramacionV3_`date_stamp'.xlsx", sheet("Input") sheetreplace firstrow(variables)
qui save "`c(pwd)'\output\siaf_etiqueta_pliego_`date_stamp'", replace

* MENSAJES
di in green "ReporteProgramacionV3_`date_stamp' generado exitosamente."
di as smcl  "Haga clic para abrir el archivo: {browse "`"Reportes.xlsm}"'"
di as smcl  "Copie las siguientes rutas al archivo Reportes.xlsm y actualize reporte."
di as smcl 	"Ruta 1: ""{text:`c(pwd)'\reportes\PROGRAMACIÓN_`date_stamp'.pptx}"
di as smcl 	"Ruta 2: ""{text:`c(pwd)'\reportes\siafreport_base.xlsx}"
di as smcl 	"Ruta 3: ""{text:`c(pwd)'\reportes\ReporteProgramacionV3_`date_stamp'.xlsx}"
di as smcl 	"{text:*Su archivo `siaf_filename'.xlsx se ha movido al folder input.}"
end
