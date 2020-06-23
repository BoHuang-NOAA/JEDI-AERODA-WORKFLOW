#!/bin/ksh
set -x

WorkDir=${DATA:-$pwd/hofx_aod.$$}
RotDir=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
#validtime=${CDATE:-"2001010100"}
#nexttime=$($NDATE $assim_freq $CDATE)
validtime=$($NDATE -$assim_freq $CDATE)
nexttime=${CDATE}
cdump=${CDUMP:-"gdas"}
itile=${itile:-1}
mem=${imem:-0}
mkdir ${WorkDir}

if [[ ${mem} -gt 0 ]]; then
   cdump="enkfgdas"
   memdir="mem"`printf %03d $mem`
   restart_interval=${restart_interval_enkf}
elif [[ ${mem} -eq 0 ]]; then
   cdump="enkfgdas"
   memdir="ensmean"
   restart_interval=${restart_interval_enkf}
elif [[ ${mem} -eq -1 ]]; then
   cdump="gdas"
   memdir=""
   restart_interval=${restart_interval_cntl}
fi

vyy=$(echo $validtime | cut -c1-4)
vmm=$(echo $validtime | cut -c5-6)
vdd=$(echo $validtime | cut -c7-8)
vhh=$(echo $validtime | cut -c9-10)
vdatestr="${vyy}${vmm}${vdd}.${vhh}0000"

nyy=$(echo $nexttime | cut -c1-4)
nmm=$(echo $nexttime | cut -c5-6)
ndd=$(echo $nexttime | cut -c7-8)
nhh=$(echo $nexttime | cut -c9-10)
ndatestr="${nyy}${nmm}${ndd}.${nhh}0000"

dir_tracer="${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART"

fname_tracer_ges_orig="${ndatestr}.fv_tracer.res.tile${itile}.nc.ges_orig"
fname_tracer="${ndatestr}.fv_tracer.res.tile${itile}.nc"
fname_tracer_ges="${ndatestr}.fv_tracer.res.tile${itile}.nc.ges"

/bin/mv ${dir_tracer}/${fname_tracer_ges_orig} ${dir_tracer}/${fname_tracer_ges}

ncrename -O -v seas5,seas6 -v seas4,seas5 -v seas3,seas4 -v seas2,seas3 -v seas1,seas2 ${dir_tracer}/${fname_tracer} ${dir_tracer}/${fname_tracer}_tmp
/bin/rm -rf ${dir_tracer}/${fname_tracer}
ncrename -O -v seas6,seas1 ${dir_tracer}/${fname_tracer}_tmp ${dir_tracer}/${fname_tracer}
/bin/rm -rf ${dir_tracer}/${fname_tracer}_tmp


if [ ${FGAT3D} == "TRUE" -a ${FGAT3D_onlyCenter} != "TRUE" ]; then
   nexttimem3=$($NDATE -$assim_freq_half $nexttime)
   nexttimep3=$($NDATE $assim_freq_half $nexttime)

   nexttimetmp=${nexttimem3}
   while [ ${nexttimetmp} -le ${nexttimep3} ]; do
   if [ ${nexttimetmp} != ${nexttime} ]; then
	nyytmp=$(echo $nexttimetmp | cut -c1-4)
	nmmtmp=$(echo $nexttimetmp | cut -c5-6)
	nddtmp=$(echo $nexttimetmp | cut -c7-8)
	nhhtmp=$(echo $nexttimetmp | cut -c9-10)
	ndatestrtmp="${nyytmp}${nmmtmp}${nddtmp}.${nhhtmp}0000"

        fname_tracer_ges="${ndatestrtmp}.fv_tracer.res.tile${itile}.nc.ges"
        fname_tracer_ges_orig="${ndatestrtmp}.fv_tracer.res.tile${itile}.nc.ges_orig"

	/bin/mv ${dir_tracer}/${fname_tracer_ges_orig} ${dir_tracer}/${fname_tracer_ges}
   fi

	nexttimetmp=$($NDATE +$restart_interval $nexttimetmp)
   done
fi

exit $?
