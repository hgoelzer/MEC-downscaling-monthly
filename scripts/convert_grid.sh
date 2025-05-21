#!/bin/bash
# Regrid to regional grid

# Needs module cdo
 
#set -x
set -e

params=$1

if [ ! -f ${params} ]; then
    echo Error: parameter file $params not found, exiting! 
    exit
fi

## User settings
source $params

# ln -s /cluster/work/users/heig/archive/N1850frc2_SMB1/lnd/hist/vregrid ./output
# ln -s /cluster/work/users/heig/archive/N1850frc2_SMB1/lnd/hist/vector2gridded3d ./input

# Directories with files from step before (can be symlink)
INDIR=$scratchdir/s2_gridded3d
OUTDIR=$scratchdir/s3_regridded

# clean up
/bin/rm -r $OUTDIR
mkdir -p $OUTDIR

# Select variables to process
FILES=$(ls $INDIR/*nc)
#FILES=$(ls $INDIR/QICE_19*nc) # specific variable
#FILES=$(ls $INDIR/QRUNOFF_19*nc) # specific variable
#FILES=$(ls $INDIR/TOPO_COL_timmean.nc) # specific file

echo $FILES

# Variable $FILES is a list, select first entry
set -- $FILES
FILE1=$1 

if [[ ${opt_fill} -eq 0 ]]; then
    # Pre-compute interpolation weights
    echo "# Don't fill missing values"
    cdo genbil,${grid_file} $FILE1 weights.nc

elif [[ ${opt_fill} -eq 1 ]]; then
    # extrapolate to fill missing values
    echo "# fill missing values with cdo fillmiss"
    cdo fillmiss $FILE1 filled_tmp.nc
    # Pre-compute interpolation weights
    cdo genbil,${grid_file} filled_tmp.nc  weights.nc

elif [[ ${opt_fill} -eq 2 ]]; then
    # extrapolate to fill missing values
    echo "# fill missing values with cdo fillmiss2"
    cdo fillmiss2,2 $FILE1 filled_tmp.nc
    # Pre-compute interpolation weights
    cdo genbil,${grid_file} filled_tmp.nc  weights.nc
fi

# Main loop
for FILE in $FILES; do
   FNAME=$(basename $FILE)
   NEWFILE=$OUTDIR/$FNAME
   echo $FILE
   if [[ ${opt_fill} -eq 0 ]]; then
       cdo --format nc4 -b F32 remap,${grid_file},weights.nc $FILE $NEWFILE

   elif [[ ${opt_fill} -eq 1 ]]; then
   # extrapolate to fill missing values
   cdo fillmiss $FILE filled_tmp.nc
   cdo --format nc4 -b F32 remap,${grid_file},weights.nc filled_tmp.nc $NEWFILE

   elif [[ ${opt_fill} -eq 2 ]]; then
   # extrapolate to fill missing values
   cdo fillmiss2,2 $FILE filled_tmp.nc
   # Remap directly
   #cdo remapbil,${grid_file} $FILE $NEWFILE
   cdo --format nc4 -b F32 remap,${grid_file},weights.nc filled_tmp.nc $NEWFILE

fi

done
