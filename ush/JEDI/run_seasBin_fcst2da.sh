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
elif [[ ${mem} -eq 0 ]]; then
   cdump="enkfgdas"
   memdir="ensmean"
elif [[ ${mem} -eq -1 ]]; then
   cdump="gdas"
   memdir=""
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

fname_tracer="${ndatestr}.fv_tracer.res.tile${itile}.nc.ges"
fname_tracer_orig="${ndatestr}.fv_tracer.res.tile${itile}.nc.ges_orig"
/bin/cp -r ${dir_tracer}/${fname_tracer} ${dir_tracer}/${fname_tracer_orig}

ncrename -O -v seas1,seas6 -v seas2,seas1 -v seas3,seas2 -v seas4,seas3 -v seas5,seas4 ${dir_tracer}/${fname_tracer} ${dir_tracer}/${fname_tracer}_tmp
/bin/rm -rf ${dir_tracer}/${fname_tracer}
ncrename -O -v seas6,seas5 ${dir_tracer}/${fname_tracer}_tmp ${dir_tracer}/${fname_tracer}
/bin/rm -rf ${dir_tracer}/${fname_tracer}_tmp
exit $?
