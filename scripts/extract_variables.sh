#!/bin/bash
# Extract column variables from archive
# Here, monthly files

# Requires module nco and cdo

params=$1

if [ ! -f ${params} ]; then
    echo Error: parameter file $params not found, exiting! 
    exit
fi

## User settings

source $params
#run=N1850frc2_SMB1
#syear=0001
#eyear=0002
#filedir=/luster/work/users/heig/archive/$run/lnd/hist
#scratchdir=/cluster/work/users/heig/archive/N1850frc2_SMB1/lnd/hist/SMB

###

#varlist="QICE"
#varlist="QSNOMELT"
#varlist="TOPO_COL"

# We need TOPO_COL to extract EC surface elevations
#varlist="QICE SNOW QSNOFRZ QSNOMELT QICE_MELT QSOIL TOPO_COL"
varlist="QICE SNOW QSNOFRZ QSNOMELT QICE_MELT QSOIL TOPO_COL TG TSA"

/bin/rm -r $scratchdir/s1_vector
mkdir -p $scratchdir/s1_vector

for i in `eval echo {${syear}..${eyear}..1}`; do
    year=$i
    echo "# Processing " $year

    for var in $varlist; do
	echo $var

	for amon in 01 02 03 04 05 06 07 08 09 10 11 12; do
	    echo $amon
	    ncks -O -v $var,lat,lon,cols1d_ixy,cols1d_jxy,cols1d_itype_lunit,cols1d_itype_col,pfts1d_ixy,pfts1d_jxy,pfts1d_itype_lunit,pfts1d_itype_col  $filedir/${run}.clm2.h2.${year}-${amon}.nc $scratchdir/s1_vector/${run}.clm2.h2.${var}.${year}-${amon}.nc 
	done
    done
done
