## MEC-downscaling-monthly, Heiko Goelzer, 2025 (heig@norceresearch.no)
Collection of scripts to downscale monthly CLM MEC output to a high-resolution regional grid

See also yearly downscaling at 
https://github.com/hgoelzer/MEC-downscaling

Based on MEC-downscaling-example by Leo van Kampenhout
https://github.com/lvankampenhout/MEC-downscaling-example

Uses package libvector by Leo van Kampenhout
https://github.com/lvankampenhout/libvector

For step vertical_interpolation an optimized fortran code provided by Raymond Sellevold is used instead of the memory intensive python version.

SMB components are downscaled offline to a target grid. The offline downscaling follows a procedure, similar to the online downscaling used in CESM/NorESM to get SMB on the ice sheet scale. 
1. EC information is extracted from clm history output (requires specific namelist settings)
2. EC topography and variables of interest are bilinearly interpolated to the target grid. 
3. The variables of interest are vertically downscaled toward the target elevation by using the 3‐D fields from the previous steps. 
4. SMB is recombined from the downscaled components
SMB = SNOW + QSNOFRZ - QSNOMELT - QICE_MELT – QSOIL
All components in [mm/s] except QSNOFRZ [kg/m2/s], which boils down to mm/s

A version of these scripts has been used in the paper [Present‐Day Greenland Ice Sheet Climate and Surface Mass Balance in CESM2](doi.org/10.1029/2019JF005318) where it is called it "offline downscaling": 

This setup is prepared for use on fram or other SIGMA2 machines for NorESM

### Workflow in ./scripts

setup.sh <br>
extract_variables.sh <br>
process_raw_vector.py <br>
convert_grid.sh <br>
apply_vertical_interpolation.py <br>
calc_SMB.sh <br>


### Python environment

#### Conda setup following (https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html)

wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh <br>
bash Miniconda3-latest-Linux-x86_64.sh <br>
source /cluster/home/heig/miniconda3/bin/activate base (fram) <br>
source /nird/home/heig/miniconda3/bin/activate base (nird) <br>
conda config --set auto_activate_base false <br>

#### Setting up miniconda
conda install numpy <br>
conda install netCDF4 <br>
conda install scipy <br>
conda install xarray <br>


### Setup fortran program for vertical interpolation 
cd scripts <br>
pip3 install --user meson
pip3 install --user ninja
PATH=$PATH:~/.local/bin
python -m numpy.f2py -c elevationclasses.F90 -m elevationclasses --backend meson

### Shell environment (I use the conda install of these now)

module load CDO/1.9.5-intel-2018b <br>
module load NCO/4.7.9-intel-2018b <br>
module load ncview/2.1.7-intel-2018b <br>


### Interactive usage
#### Consider working in an interactive shell
srun --nodes=1 --time=00:30:00 --qos=devel --account=nn9252k --pty bash -i

#### Load Python environment
source /cluster/home/heig/miniconda3/bin/activate base (fram) <br>
source /nird/home/heig/miniconda3/bin/activate base (nird) <br>


