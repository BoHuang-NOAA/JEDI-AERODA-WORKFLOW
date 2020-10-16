#!/bin/ksh
set -x

# get variables from NCEP/Rocoto workflow conventions
analdate=${CDATE}
yyyymmdd=${PDY}
hh=${cyc}
yyyymmddm=${gPDY}
hhm=${gcyc}
workdir=${DATA}/enkf_run
ENKFFIX=${ENKFFIX:-${FIXgfs}/fix_gsi/}
CASE=${CASE:-${CASE_ENKF}}
nlevs=64
aero_species=1

resc=$(echo $CASE |cut -c2-5)
export resx=${resc}
export resy=${resc}

if [[ $aero_species == 1 ]]
then
    aod_controlvar=.false.
else
    aod_controlvar=.true.
fi

# variables for running code
export enkf_threads=1
export mpitaskspernode=1
export OMP_NUM_THREADS=$enkf_threads
export OMP_STACKSIZE=256M
export nprocs=$SLURM_NTASKS

# misc vars/dirs because of time constraints
MEANEXECDIR=${HOMEgfs}/exec/
ENKFEXECDIR=${HOMEgfs}/exec/
cycle_frequency=6
fv3fixdir=${HOMEgfs}/fix/fix_fv3/
analdirpath="$workdir/analysis"

/bin/rm -rf $workdir
mkdir -p $workdir

# source namelist variables
source $JEDIUSH/enkf_nml_AOD_modis_fgat_ENKF_VL0.35.sh

$NLN $ENKFEXECDIR/enkf_fv3_fgat.x $workdir/.

cd $workdir

cat <<EOF > enkf.nml
&nam_enkf
datestring="$datestring",
datapath="$analdirpath",
fgfileprefixes="$fgfileprefixes",
anlfileprefixes="$anlfileprefixes",
analpertwtnh=$analpertwtnh,
analpertwtsh=$analpertwtsh,
analpertwttr=$analpertwttr,
analpertwtnh_rtpp=$nalpertwtnh_rtpp,
analpertwtsh_rtpp=$analpertwtsh_rtpp,
analpertwttr_rtpp=$analpertwttr_rtpp,
lupd_satbiasc=$lupd_satbiasc,
zhuberleft=$zhuberleft,
zhuberright=$zhuberright,
huber=$huber,
varqc=$varqc,
covinflatemax=$covinflatemax,
covinflatemin=$covinflatemin,
pseudo_rh=$pseudo_rh,
corrlengthnh=$corrlengthnh,
corrlengthsh=$corrlengthsh,
corrlengthtr=$corrlengthtr,
obtimelnh=$obtimelnh,
obtimelsh=$obtimelsh,
obtimeltr=$obtimeltr,
iassim_order=$iassim_order,
lnsigcutoffnh=$lnsigcutoffnh,
lnsigcutoffsh=$lnsigcutoffsh,
lnsigcutofftr=$lnsigcutofftr,
lnsigcutoffsatnh=$lnsigcutoffsatnh,
lnsigcutoffsatsh=$lnsigcutoffsatsh,
lnsigcutoffsattr=$lnsigcutoffsattr,
lnsigcutoffpsnh=$lnsigcutoffpsnh,
lnsigcutoffpssh=$lnsigcutoffpssh,
lnsigcutoffpstr=$lnsigcutoffpstr,
simple_partition=$simple_partition,
nlons=$nlons,
nlats=$nlats,
smoothparm=$smoothparm,
readin_localization=$readin_localization,
saterrfact=$saterrfact,
numiter=$numiter,
sprd_tol=$sprd_tol,
paoverpb_thresh=$paoverpb_thresh,
letkf_flag=$letkf_flag,
use_qsatensmean=$use_qsatensmean,
npefiles=$npefiles,
lobsdiag_forenkf=$lobsdiag_forenkf,
netcdf_diag=$netcdf_diag,
reducedgrid=$reducedgrid,
nlevs=$nlevs,
nanals=$NMEM_AERO,
deterministic=$deterministic,
write_spread_diag=.true.,
sortinc=$sortinc,
univaroz=$univaroz,
univartracers=$univartracers,
massbal_adjust=$massbal_adjust,
nhr_anal=$nhr_anal,
nhr_state=$nhr_state,
use_gfs_nemsio=$use_gfs_nemsio,
adp_anglebc=$adp_anglebc,
angord=$angord,
newpc4pred=$newpc4pred,
use_edges=$use_edges,
emiss_bc=$emiss_bc,
biasvar=$biasvar,
write_spread_diag=$write_spread_diag
fv3_native=$fv3_native
/
&END
&nam_wrf
/
&END
&nam_fv3
fv3fixpath="$fv3fixdir",
nx_res=$nx_res,
ny_res=$nx_res,
ntiles=6,
l_pres_add_saved=$l_pres_add_saved
/
&END
&satobs_enkf
/
&END
&ozobs_enkf
/
&END
&aodobs_enkf
sattypes_aod(1)=${sattypes_aod1}
sattypes_aod(2)=${sattypes_aod2}
/
&END
EOF

cat enkf.nml

$NLN $ENKFFIX/aeroinfo_aod.txt ./aeroinfo
$NLN $ENKFFIX/anavinfo_fv3_gocart_enkf ./anavinfo

charnanal="ensmean"
analdir=${workdir}/analysis/$PDY$cyc/$charnanal
if [[ ! -r ${analdir} ]]; then
    mkdir -p ${analdir}
fi

itile=0
while [[ $itile -le 5 ]]; do
    ${NLN} ${ROTDIR}/enkfgdas.${PDY}/${cyc}/${charnanal}/obs//aod_nnr_terra_hofx_nomodel_${PDY}${cyc}_000${itile}.nc4.ges ${analdir}/aod_nnr_terra_hofx_000${itile}.nc4
    ${NLN} ${ROTDIR}/enkfgdas.${PDY}/${cyc}/${charnanal}/obs//aod_nnr_aqua_hofx_nomodel_${PDY}${cyc}_000${itile}.nc4.ges ${analdir}/aod_nnr_aqua_hofx_000${itile}.nc4
    ((itile=itile+1))
done

# ensemble mean is already computed, need to link it
itile=1
while [[ $itile -le 6 ]]; do
  $NLN ${ROTDIR}/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_tracer.res.tile${itile}.nc.ges ${analdir}/${yyyymmdd}.${hh}0000.fv_tracer.res.tile${itile}.nc
  $NLN ${ROTDIR}/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_core.res.tile${itile}.nc.ges ${analdir}/${yyyymmdd}.${hh}0000.fv_core.res.tile${itile}.nc
  if [[ $itile == 1 ]]; then
    $NLN ${ROTDIR}/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_core.res.nc.ges ${analdir}/${yyyymmdd}.${hh}0000.fv_core.res.nc
    $NLN $ROTDIR/enkfgdas.${gPDY}/${gcyc}/mem001/RESTART/${yyyymmdd}.${hh}0000.coupler.res.ges ${analdir}/${yyyymmdd}.${hh}0000.coupler.res
  fi
  ((itile=itile+1))
done

########## run EnKF code ##########
nanal=1
while [[ $nanal -le $NMEM_AERO ]]; do
  if [[ $nanal -eq 0 ]]; then
    charnanal="ensmean"
  else
    charnanal="mem"`printf %03i $nanal`
  fi
  analdir=${workdir}/analysis/$PDY$cyc/$charnanal
  if [[ ! -r $analdir ]]; then
     mkdir -p $analdir
  fi
  itile=1
  while [[ $itile -le 6 ]]; do
    if [[ $itile == 1 ]]; then
       $NLN $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_core.res.nc.ges ${analdir}/${yyyymmdd}.${hh}0000.fv_core.res.nc
       $NLN $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.coupler.res.ges ${analdir}/${yyyymmdd}.${hh}0000.coupler.res
    fi
    $NLN $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_core.res.tile${itile}.nc.ges ${analdir}/${yyyymmdd}.${hh}0000.fv_core.res.tile${itile}.nc
    $NLN $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_srf_wnd.res.tile${itile}.nc.ges ${analdir}/${yyyymmdd}.${hh}0000.fv_srf_wnd.res.tile${itile}.nc
    $NLN $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.phy_data.tile${itile}.nc.ges ${analdir}/${yyyymmdd}.${hh}0000.phy_data.tile${itile}.nc
    $NLN $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.sfc_data.tile${itile}.nc.ges ${analdir}/${yyyymmdd}.${hh}0000.sfc_data.tile${itile}.nc
    $NLN $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_tracer.res.tile${itile}.nc.ges ${analdir}/${yyyymmdd}.${hh}0000.fv_tracer.res.tile${itile}.nc
    $NCP $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_tracer.res.tile${itile}.nc.ges $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_tracer.res.tile${itile}.nc
    $NLN $ROTDIR/enkfgdas.${gPDY}/${gcyc}/${charnanal}/RESTART/${yyyymmdd}.${hh}0000.fv_tracer.res.tile${itile}.nc ${analdir}/${yyyymmdd}.${hh}0000.anal.fv_tracer.res.tile${itile}.nc
    ((itile=itile+1))
  done
  itile=0
  while [[ $itile -le 5 ]]; do
      ${NLN} ${ROTDIR}/enkfgdas.${PDY}/${cyc}/${charnanal}/obs//aod_nnr_terra_hofx_nomodel_${PDY}${cyc}_000${itile}.nc4.ges ${analdir}/aod_nnr_terra_hofx_000${itile}.nc4
      ${NLN} ${ROTDIR}/enkfgdas.${PDY}/${cyc}/${charnanal}/obs//aod_nnr_aqua_hofx_nomodel_${PDY}${cyc}_000${itile}.nc4.ges ${analdir}/aod_nnr_aqua_hofx_000${itile}.nc4
      ((itile=itile+1))
  done

  ((nanal=nanal+1))
done

# load GSI module for enkf
source /apps/lmod/7.7.18/init/ksh
module purge
source $HOMEgfs/modulefiles/modulefile.ProdGSI.hera

srun -n $NMEM_AERO --export=all ./enkf_fv3_fgat.x
err=$?
 
ls -lh ${analdir}

exit $err
