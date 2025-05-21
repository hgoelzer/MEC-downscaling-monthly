# Processing scripts for MEC downscaling

## To get started, edit ./setup.sh to your needs

./setup.sh produces a parameter file that has to be passed to the processing scripts.

## Run in this order

### activate python environment!
conda activate mec

### run scripts
setup.sh <br>
extract_variables.sh <param_file> <br>
process_raw_vector.py <param_file> <br>
convert_grid.sh <param_file> <br>
apply_vertical_interpolation.py <param_file> <br>
calc_SMB.sh <param_file> <br>
make_forcing_timeseries.sh <param_file> <br>
calc_ARTM.sh <param_file> <br>
make_artm_forcing_timeseries.sh <param_file> <br>


## Or run setup and then as batch file run_batch.sh
./setup/sh <br>
./run_batch.sh <param_file> <br>


### Set up parameters, input data and path environment
./setup.sh

### Extract 3d elevation class information (level,lat,lon) from column files 
./extract_variables.sh

### Make 3-dimensional variables 
./process_raw_vector.py

### Conversion to regional grid
./convert_grid.sh

### Run vertical interpolation
./apply_vertical_interpolation.py

### Combine components to get SMB
./calc_SMB.sh

### Make SMB time series forcing record
./make_forcing_timeseries.sh

### Combine components to get ARTM
./calc_ARTM.sh

### Make ARTM time series forcing record
./make_artm_forcing_timeseries.sh 


## Conda environment mec
conda create -n mec
conda activate mec
conda install -c conda-forge cdo nco netCDF4 scipy xarray
