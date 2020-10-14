# `siafreport` : Modulo de Stata para generar reportes de ejecución del gasto - MINEDU.

## Descripción

El presente modulo de Stata genera reportes de ejecución del gasto - MINEDU.

## Instalación

Copie el siguiente codigo en Stata y ejecute.

```
cap ado uninstall siafreport 
net install siafreport, from(https://github.com/MaykolMedrano/siafreport/raw/master/source/)
```

## Uso

Ingrese el nombre del archivo siaf de interes.

```stata
 siafreport minedu, filename(mpp_exporta_ejecucion_ue_001636_12_10_2020_14_42) clear
```

## Nota

Es necesario crear previamente un folder para ejecutar el comando.

- Mas información en el archivo de ayuda.
