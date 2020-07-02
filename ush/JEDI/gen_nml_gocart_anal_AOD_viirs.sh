#!/bin/ksh
set -x

JEDIcrtm=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/
WorkDir=${DATA:-$pwd/hofx_aod.$$}
RotDir=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
#validtime=${CDATE:-"2001010100"}
validtime=$($NDATE -$assim_freq $CDATE)
nexttime=${CDATE}
cdump=${CDUMP:-"gdas"}
itile=${itile:-1}
mem=${imem:-0}
sensorID=${sensorID:-"Pass sensorID falied"};

#JEDIDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/build
#WorkDir=./hofx_aod
#RotDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/
#validtime=2018041700
#nexttime=2018041706
#cdump=gdas
#itile=6
#mem=20

mkdir ${WorkDir}

CRTMFix=${JEDIcrtm}

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

cat << EOF > ${WorkDir}/gocart_aod_fv3_mpi.nl
&record_input
  fname_core = "${ndatestr}.fv_core.res.tile${itile}.nc.ges"
  fname_aod = "${ndatestr}.fv_aod_${sensorID}.res.tile${itile}.nc"
  input_dir = "${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART"
  fname_tracer = "${ndatestr}.fv_tracer.res.tile${itile}.nc"
  output_dir = "${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART"
  fname_akbk = "${ndatestr}.fv_core.res.nc.ges"
/

&record_conf
  CoefficientPath = "${CRTMFix}"
  Sensor_ID = "${sensorID}"
  Absorbers = "H2O","O3"
  AerosolOption = "aerosols_gocart_default"
  channels = 4
  EndianType = "Big_Endian"
  Model = "CRTM"
/
EOF


