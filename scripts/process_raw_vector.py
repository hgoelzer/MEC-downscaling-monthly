#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
   DESCRIPTION: 
      This script extracts MEC output from the CLM vector output and stores it as
      a 3-dimensional variable in a subdirectory called 's2_gridded3d'. 

      The vertical interpolation will only happen after we regridded to the 
      target grid, and makes use of the actual MEC topography stored in variable TOPO_COL. 

   DATE: 
      May 2019 

   AUTHOR:
      Leo van Kampenhout
"""

import sys
import glob
import os, os.path
import shutil
from configparser import ConfigParser
import argparse

# Parsing command line argument: parameter filename 
parser = argparse.ArgumentParser()
parser.add_argument("paramsfile")
args = parser.parse_args()
params_filename=args.paramsfile
print(params_filename)

# Parsing config
config = ConfigParser()
with open(params_filename) as stream:
    config.read_string("[top]\n" + stream.read())  # append header
top = config['top']
run = top['run']
syear = top['syear']
eyear = top['eyear']
scratchdir = top['scratchdir']

## User settings

# Import libvector package from local directory tree
# git repo here: https://github.com/lvankampenhout/libvector/

# CHA: update path
sys.path.insert(0, "../libvector") 
from libvector import VectorMecVariable, vector2gridded3d 

# CHA: update case
#run = 'N1850frc2_SMB1' # 

# CHA: adapt this to select a subset of the time period
#slices = '0001', '0002' , '0003' , '0004' , '0005' , '0006' , '0007' , '0008' , '0009' , '0010' 
slices = [str(item).zfill(4) for item in range(int(syear),int(eyear)+1)]

mons = [str(item).zfill(2) for item in range(int(1),int(12)+1)]

print(slices)
# CHA: update path
#scrtachdir  = os.path.join('/cluster/work/users/heig/archive', run , 'lnd/hist') 

# output stream identifier. Vector data is typically 'h2'.
stream_tag  = 'h2' 

outdir   = os.path.join(scratchdir, 's2_gridded3d') 

# remove and recreate directory 
if os.path.exists(outdir):
   shutil.rmtree(outdir)    
if not os.path.exists(outdir):
   os.makedirs(outdir)

print(run)

varlist = []
#varlist += 'SNOW QSNOFRZ QSNOMELT QICE_MELT QSOIL TOPO_COL'.split()
varlist += 'SNOW QSNOFRZ QSNOMELT QICE_MELT QSOIL TOPO_COL TG TSA'.split()

# year loop
for slic in slices:
   print(slic)

   # month loop
   for amon in mons:
       print(amon)
       
       # var loop
       for varname in varlist:
      #fname_vector = os.path.join(scratchdir, 'lnd', 'proc', 'tseries', 'month_1', run + ".clm2." + stream_tag + "." + varname + "." + slic + ".nc")
           fname_vector = os.path.join(scratchdir, 's1_vector',  run + ".clm2." + stream_tag + "." + varname + "." + slic + "-" + amon + ".nc")
           print(fname_vector)

           if (not os.path.exists(fname_vector)):
               raise FileNotFoundError(fname_vector)

           outfile = os.path.join(outdir, varname+'_'+slic+"-"+amon+"_"+run+'.nc')

           if (not os.path.exists(outfile)):
               vmv = VectorMecVariable(varname, fname_vector) 
               vector2gridded3d(vmv, outfile) 
               print('wrote %s' % outfile)

           else:
               print('file exists, skipping %s' % outfile)

