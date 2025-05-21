#!/bin/bash
# Combine fields to calucalte ARTM
# ARTM = TG

set -x
set -e

params=$1

if [ ! -f ${params} ]; then
    echo Error: parameter file $params not found, exiting! 
    exit
fi

## User settings
source $params

# Directories with files from step before (can be symlink)
INDIR=$scratchdir/s4_remapped
OUTDIR=$scratchdir/s7_artm

/bin/rm -r $OUTDIR
mkdir -p $OUTDIR

for ayear in `eval echo {${syear}..${eyear}..1}`; do
    echo $ayear

    for amon in 01 02 03 04 05 06 07 08 09 10 11 12; do
	echo $amon

	cdo merge ${INDIR}/TG_${ayear}-${amon}_${run}.nc ${OUTDIR}/ARTM_${ayear}-${amon}_${run}.nc

	# remove unused vars
	ncks -C -O -x -v lon,lat,lon_bnds,lat_bnds ${OUTDIR}/ARTM_${ayear}-${amon}_${run}.nc ${OUTDIR}/ARTM_${ayear}-${amon}_${run}.nc
    
	# change units +sanity 
	#ncrename -v TG,ARTM ${OUTDIR}/ARTM_${ayear}-${amon}_${run}.nc
	ncap2 -O -s 'ARTM=TG-273.16; where(ARTM<-273.16)ARTM=-273.16' ${OUTDIR}/ARTM_${ayear}-${amon}_${run}.nc ${OUTDIR}/ARTM_${ayear}-${amon}_${run}.nc

	# make axis
	ncecat -O -u time ${OUTDIR}/ARTM_${ayear}-${amon}_${run}.nc ${OUTDIR}/ARTM_${ayear}-${amon}_${run}.nc

    done

done
