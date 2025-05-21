#!/bin/bash
# Combine fields to calucalte SMB
# SMB = SNOW + QSNOFRZ - QSNOMELT - QICE_MELT – QSOIL

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
OUTDIR=$scratchdir/s5_smb

/bin/rm -r $OUTDIR
mkdir -p $OUTDIR

for ayear in `eval echo {${syear}..${eyear}..1}`; do
    echo $ayear

    for amon in 01 02 03 04 05 06 07 08 09 10 11 12; do
	echo $amon


	cdo merge ${INDIR}/SNOW_${ayear}-${amon}_${run}.nc ${INDIR}/QSNOFRZ_${ayear}-${amon}_${run}.nc ${INDIR}/QSNOMELT_${ayear}-${amon}_${run}.nc ${INDIR}/QICE_MELT_${ayear}-${amon}_${run}.nc ${INDIR}/QSOIL_${ayear}-${amon}_${run}.nc  ${OUTDIR}/SMB_${ayear}-${amon}_${run}.nc

	# remove unused vars
	ncks -C -O -x -v lon,lat,lon_bnds,lat_bnds ${OUTDIR}/SMB_${ayear}-${amon}_${run}.nc ${OUTDIR}/SMB_${ayear}-${amon}_${run}.nc
    
	# add components 
	ncap2 -O -s "SMB=(SNOW+QSNOFRZ-QSNOMELT-QICE_MELT-QSOIL)" ${OUTDIR}/SMB_${ayear}-${amon}_${run}.nc ${OUTDIR}/SMB_${ayear}-${amon}_${run}.nc

	# make axis
	ncecat -O -u time ${OUTDIR}/SMB_${ayear}-${amon}_${run}.nc ${OUTDIR}/SMB_${ayear}-${amon}_${run}.nc

    done

done
