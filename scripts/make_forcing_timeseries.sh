#!/bin/bash
# Make an SMB forcing tiem series

set -x
set -e

# Requires module nco
# Currently on fram
# module load NCO/4.7.9-intel-2018b

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
INDIR=$scratchdir/s5_smb
OUTDIR=$scratchdir/s6_timeseries

/bin/rm -r $OUTDIR
mkdir -p ${OUTDIR} 

# Select variables to process
FILES=$(ls $INDIR/*nc)

# target file
OUTFILE=${OUTDIR}/smb_${syear}-${eyear}_${run}.nc
OUTFILE_ltm=${OUTDIR}/smb_ltm0_${syear}-${eyear}_${run}.nc
OUTFILE_ltmm=${OUTDIR}/smb_ltmm_${syear}-${eyear}_${run}.nc
OUTFILE_ltms=${OUTDIR}/smb_ltms_${syear}-${eyear}_${run}.nc

echo $FILES

# concat
ncrcat -O -v SMB $FILES ${OUTFILE}

# Work in netcdf3 as a workaround of renaming problems 
ncks -O -h -3 ${OUTFILE} tmp.nc

# rename variables and dims
ncrename -v SMB,smb tmp.nc 
ncrename -O -d x,x1 -d y,y1 tmp.nc 

# Make a time axis
ncap2 -O -v -s "time=array(${syear},1,\$time)" tmp.nc  ${OUTDIR}/time_${syear}-${eyear}.nc
ncks -A -v time ${OUTDIR}/time_${syear}-${eyear}.nc tmp.nc  

# Add diemsion variables
ncks -A -v x1,y1 x1y1_04km.nc tmp.nc

# Back to netcdf4
ncks -O -h -4 tmp.nc ${OUTFILE}
 
# Unit conversion
ncap2 -O -s "smb=smb*31556926" ${OUTFILE} ${OUTFILE}
ncatted -h -a units,smb,o,c,"mm/yr water equivalent" ${OUTFILE} 
ncatted -h -a coordinates,smb,d,, ${OUTFILE} 

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
#ncks -v smb -d time,0 output.nc smb_ref.nc
#cp smb_ref.nc  smb_ref2.nc
#ncrcat smb_ref.nc smb_ref2.nc smb0.nc
#for i in {1..119}; do  /bin/mv smb0.nc smb_ref2.nc; ncrcat smb_ref.nc smb_ref2.nc smb0.nc; done 
## add time axis 
#ncks -A -v time time_1850-1969.nc smb0.nc
#ncks -A -v smb_ref smb0.nc ${OUTFILE} 
#ncap2 -O -s "where (smb_ref==-2000) smb=-2000" ${OUTFILE} ${OUTFILE} 
#ncks -C -O -x -v smb_ref ${OUTFILE} ${OUTFILE} 
