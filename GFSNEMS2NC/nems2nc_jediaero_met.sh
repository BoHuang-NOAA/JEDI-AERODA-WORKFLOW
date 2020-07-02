#!/bin/bash
#SBATCH -J sig2nc_run 
#SBATCH -A wrf-chem
#SBATCH --open-mode=truncate
#SBATCH -o log.sig2nc
#SBATCH -e log.sig2nc
#SBATCH --nodes=1
#SBATCH -q batch 
#SBATCH -t 07:30:00

set -x

source /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow-clean//modulefiles//modulefile.ProdGSI.hera
python /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow-clean/nems2nc_jediaero_met.py

#python /scratch1/NCEPDEV/da/Cory.R.Martin/Scripts/FV3GFS-GSDChem/nems2nc_jediaero_met.py
