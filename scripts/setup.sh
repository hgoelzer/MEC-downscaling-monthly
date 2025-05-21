#!/bin/bash
# Set up input files and directory structure

######### Basic setup

mec_dir=/nird/projects/NS8006K/MEC/MEC-downscaling-monthly

######### User input

run=N1850frc2G_f09_tn14_gl4_SMB1_cebi
syear=1820
eyear=1822
filedir=/datalake/NS9560K/users/heig/NorESM/archive/$run/lnd/hist # nird
scratchdir=/projects/NS9560K/users/heig/SMB/${run}_${syear}-${eyear}


# Target grid and elevation
grid_file=${mec_dir}/data/grid_CISM_GrIS_04000m.nc
elev_file=${mec_dir}/data/cism_topography.nc
elev_varname=topg

# Options
# fill missing values in gcm output. Needed in particular for low res model
# 0= no fill, 1=fill by bilinear interpolation, 2=fill by nearest neighbor 
opt_fill=1

###############

# Set up 
if [ -d ${scratchdir} ]; then
    echo Error: directory ${scratchdir} exists, exiting! 
    exit
else
    mkdir -p ${scratchdir}
fi

# Create param file
echo "# Generated params file" > ${scratchdir}/params.txt
echo "run="${run} >> ${scratchdir}/params.txt
echo "syear="${syear} >> ${scratchdir}/params.txt
echo "eyear="${eyear} >> ${scratchdir}/params.txt
echo "filedir="${filedir} >> ${scratchdir}/params.txt
echo "scratchdir="${scratchdir} >> ${scratchdir}/params.txt
echo "grid_file="${grid_file} >> ${scratchdir}/params.txt
echo "elev_file="${elev_file} >> ${scratchdir}/params.txt
echo "elev_varname="${elev_varname} >> ${scratchdir}/params.txt
echo "opt_fill="${opt_fill} >> ${scratchdir}/params.txt
cat ${scratchdir}/params.txt

# Create paths
mkdir -p ${scratchdir}/s1_vector
mkdir -p ${scratchdir}/s2_gridded3d
mkdir -p ${scratchdir}/s3_regridded
mkdir -p ${scratchdir}/s4_remapped
mkdir -p ${scratchdir}/s5_smb
mkdir -p ${scratchdir}/s6_timeseries
mkdir -p ${scratchdir}/s7_artm
mkdir -p ${scratchdir}/s8_timeseries_artm

#
echo parameter file: ${scratchdir}/params.txt

echo "Run with ./run_batch.sh ${scratchdir}/params.txt"
echo "!!! Remember python setup !!!"
echo "source ~/miniconda3/bin/activate base"
