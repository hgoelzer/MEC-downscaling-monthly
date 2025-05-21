#!/bin/bash
# Run processing chain
# provide parameter file in $1

params=$1

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    exit
fi

if [ ! -f ${params} ]; then
    echo Error: parameter file $params not found, exiting! 
    exit
fi

## extract to s1_vector
#./extract_variables.sh ${params}
## Process to s2_gridded3d
#./process_raw_vector.py ${params}
## convert to s3_regridded
#./convert_grid.sh ${params}    
## interpolate to s4_remapped
./apply_vertical_interpolation.py ${params}
### combine to s5_smb
#./calc_SMB.sh ${params}
### concat to s6_timeseries
#./make_forcing_timeseries.sh ${params}
### combine to s7_art
#./calc_ARTM.sh ${params}
## concat to s8_timeseries
#./make_artm_forcing_timeseries.sh ${params}    
#
