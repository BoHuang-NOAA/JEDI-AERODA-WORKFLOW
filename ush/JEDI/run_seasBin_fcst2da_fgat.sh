#!/bin/ksh
set -x

JEDIcrtm=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/
WorkDir=${DATA:-$pwd/hofx_aod.$$}
RotDir=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
validtime=${CDATE:-"2001010100"}
nexttime=$($NDATE $assim_freq $CDATE)
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

dir_tracer="${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART"

if [ ${FGAT3D} == "TRUE" -a ${FGAT3D_onlyCenter} != "TRUE" ]; then
    nexttimem3=$($NDATE -$assim_freq_half $nexttime) 
    nexttimep3=$($NDATE $assim_freq_half $nexttime) 
else
    nexttimem3=${nexttime}
    nexttimep3=${nexttime}
fi

nexttimetmp=${nexttimem3}
while [ ${nexttimetmp} -le ${nexttimep3} ]; do
	nyytmp=$(echo $nexttimetmp | cut -c1-4)
	nmmtmp=$(echo $nexttimetmp | cut -c5-6)
	nddtmp=$(echo $nexttimetmp | cut -c7-8)
	nhhtmp=$(echo $nexttimetmp | cut -c9-10)
	ndatestrtmp="${nyytmp}${nmmtmp}${nddtmp}.${nhhtmp}0000"

        fname_tracer="${ndatestrtmp}.fv_tracer.res.tile${itile}.nc.ges"
        fname_tracer_orig="${ndatestrtmp}.fv_tracer.res.tile${itile}.nc.ges_orig"
        /bin/cp -r ${dir_tracer}/${fname_tracer} ${dir_tracer}/${fname_tracer_orig}

        ncrename -O -v seas1,seas6 -v seas2,seas1 -v seas3,seas2 -v seas4,seas3 -v seas5,seas4 ${dir_tracer}/${fname_tracer} ${dir_tracer}/${fname_tracer}_tmp
        /bin/rm -rf ${dir_tracer}/${fname_tracer}
        ncrename -O -v seas6,seas5 ${dir_tracer}/${fname_tracer}_tmp ${dir_tracer}/${fname_tracer}
        /bin/rm -rf ${dir_tracer}/${fname_tracer}_tmp
	nexttimetmp=$($NDATE +$restart_interval $nexttimetmp)
done

exit $?
