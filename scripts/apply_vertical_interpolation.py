#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
projection of 3D gridded data to 2D using vertical interpolation
"""

import sys
import glob
import os, os.path
import shutil
#import subprocess 
import xarray as xr
import numpy as np
from netCDF4 import Dataset, default_fillvals
import elevationclasses as ec
from configparser import ConfigParser
import argparse

# Parsing command line argument: parameter filename 
parser = argparse.ArgumentParser()
parser.add_argument("paramsfile")
args = parser.parse_args()
params_filename=args.paramsfile
print(params_filename)

print(dir(ec))

# Parsing config
config = ConfigParser()
with open(params_filename) as stream:
    config.read_string("[top]\n" + stream.read())  # append header
top = config['top']
run = top['run']
scratchdir = top['scratchdir']

indir = scratchdir + '/' + 's3_regridded' 
outdir = scratchdir + '/' + 's4_remapped'
elev_file = top['elev_file'] 
elev_varname = top['elev_varname']


casenames = (run, )
indirs = (indir, )
outdirs = (outdir, )

print(casenames)
print(indirs)
print(outdirs)

# Target topography info
with Dataset(elev_file,'r') as fid:
   target_srf = fid.variables[elev_varname][:].squeeze() # Two dimensional

print(target_srf.shape)

######
# END OF USER SETTINGS
######

# remove and recreate directory 
if os.path.exists(outdir):
   shutil.rmtree(outdir)    
if not os.path.exists(outdir):
   os.makedirs(outdir)

#for varname in varlist:
for (casename, indir_var, outdir_var) in zip(casenames, indirs, outdirs):

   files = glob.glob(os.path.join(indir_var, '*.nc')) 
   files = sorted(files)

   print('INFO: processing directory %s' % indir_var)
   print('INFO: number of files: %d' % len(files))

   # Looking for TOPO_COL files
   for infile in files:
      ds = xr.open_dataset(infile)

      # find variable name from file contents
      varname = list(ds.data_vars)[-1]

      if (varname == 'TOPO_COL'):
          # use TOPO_COL for EC source surface
          ec_srf = ds['TOPO_COL'][:].squeeze()
          print('Found TOPO_COL file:',infile)
          found_topo_col = True
          #print(ec_srf.shape)
          
   ds.close()

   if (found_topo_col) :
   
       for infile in files:
          ds = xr.open_dataset(infile)

          # OPTION A
          # guess variable name from file contents
          varname = list(ds.data_vars)[-1]
    
          if (varname == 'TOPO_COL'):
             # do not downscale TOPO_COL itself, not really makes sense? 
             print('Skipping TOPO_COL file:',infile)
             ds.close()
             continue
    
          # OPTION B
          # guess variable name from filename
          basename = infile.split('/')[-1] # filename without path
          #varname = basename.split('_' + casename)[0]
          #varname = basename.split('_' + casename)[0]
    
          print('INFO: varname = %s' % varname)
          outfile = os.path.join(outdir_var, basename)
    
    #      if (os.path.exists(outfile)): 
    #         print("INFO: file exists, skipping: "+outfile)
    #         continue
    
    
    
          # template
          valout = ds[varname].sum(dim='lev', skipna=False, keep_attrs=True)
          valout.encoding = {'dtype': 'float32', '_FillValue': 9.96921e+36}
          valout = valout.squeeze(drop=True) # drop time dimension
    
          vals = ds[varname]
          vals = vals.squeeze(drop=True) # drop time dimension
    
          # 3d -> 2d interpolation
          # VERT_INTERP(points,topo,values,  valout)
          # real, intent(in) :: points(ny,nx)
          # real, intent(in) :: topo(nk,ny,nx), values(nk,ny,nx)
          out = xr.DataArray(ec.vert_interp(target_srf,ec_srf,vals.values))
          valout.values = out.values
    
          #print(vals.shape)
          #print(target_srf.shape)
          #print(ec_srf.shape)
          #print(valout.shape)
    
          ds.drop(varname)
          ds[varname] = valout
    
          #ds['target'] = (['y','x'],target_srf)
          #ds['source'] = (['lev','y','x'],ec_srf)
    
          #ds = ds.squeeze(drop=True) # drop time dimension
    
          #print(ds[varname])
          #ds[varname].encoding = {'dtype': 'float32', '_FillValue': 9.96921e+36}
          ds.to_netcdf(outfile,'w') #, encoding={'_FillValue': 9.96921e36})
    
          ds.close()
          print("INFO: written %s" % outfile)

   else:
      print("ERROR: No TOPO_COL file found. Nothing processed")
