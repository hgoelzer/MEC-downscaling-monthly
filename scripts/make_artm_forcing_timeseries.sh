#!/bin/bash
# Make an ARTM forcing time series

set -x
set -e

# Requires module nco
# Currently on fram
# module load NCO/4.7.9-intel-2018b

# User settings
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
# Directories with files from step before (can be symlink)
INDIR=$scratchdir/s7_artm
OUTDIR=$scratchdir/s8_timeseries_artm

/bin/rm -r $OUTDIR
mkdir -p ${OUTDIR} 

# Select variables to process
FILES=$(ls $INDIR/*nc)

# target file
OUTFILE=${OUTDIR}/artm_${syear}-${eyear}_${run}.nc
OUTFILE_ltm=${OUTDIR}/artm_ltm0_${syear}-${eyear}_${run}.nc
OUTFILE_ltmm=${OUTDIR}/artm_ltmm_${syear}-${eyear}_${run}.nc
OUTFILE_ltms=${OUTDIR}/artm_ltms_${syear}-${eyear}_${run}.nc

echo $FILES

# concat
ncrcat -O -v ARTM $FILES ${OUTFILE}

# Work in netcdf3 as a workaround of renaming problems 
ncks -O -h -3 ${OUTFILE} tmp.nc

# rename variables and dims
ncrename -v ARTM,artm tmp.nc 
ncrename -O -d x,x1 -d y,y1 tmp.nc 

# Make a time axis
ncap2 -O -v -s "time=array(${syear},1,\$time)" tmp.nc  ${OUTDIR}/time_${syear}-${eyear}.nc
ncks -A -v time ${OUTDIR}/time_${syear}-${eyear}.nc tmp.nc  

# Add diemsion variables
ncks -A -v x1,y1 x1y1_04km.nc tmp.nc

# Back to netcdf4
ncks -O -h -4 tmp.nc ${OUTFILE}
 
# Unit conversion ?
#ncap2 -O -s "artm=artm" ${OUTFILE} ${OUTFILE}
ncatted -h -a units,artm,o,c,"degree_Celsius" ${OUTFILE} 
ncatted -h -a coordinates,artm,d,, ${OUTFILE} 

# make long term mean
ncra -F -d time,1,-1 ${OUTFILE} ${OUTFILE_ltm}
# summertime ltm
ncra -O -F -d time,6,,12,3 ${OUTFILE} ${OUTFILE_ltms}
# monthly climatology
for month in  01 02 03 04 05 06 07 08 09 10 11 12; do
    ncra -F -d time,$month,,12 ${OUTFILE} temp$month.nc
done
ncrcat -h temp*nc ${OUTFILE_ltmm}
/bin/rm temp??.nc

### Masking
## create mask time series
#ncks -v artm -d time,0 output.nc artm_ref.nc
#cp artm_ref.nc  artm_ref2.nc
#ncrcat artm_ref.nc artm_ref2.nc artm0.nc
#for i in {1..119}; do  /bin/mv artm0.nc artm_ref2.nc; ncrcat artm_ref.nc artm_ref2.nc artm0.nc; done 
## add time axis 
#ncks -A -v time time_1850-1969.nc artm0.nc
#ncks -A -v artm_ref artm0.nc ${OUTFILE} 
#ncap2 -O -s "where (artm_ref==-2000) artm=-2000" ${OUTFILE} ${OUTFILE} 
#ncks -C -O -x -v artm_ref ${OUTFILE} ${OUTFILE} 
