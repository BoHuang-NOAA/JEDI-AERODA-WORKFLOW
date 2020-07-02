#!/bin/ksh
set -x

JEDIDir=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
WorkDir=${DATA:-$pwd/hofx_aod.$$}
RotDir=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
ObsDir=${COMIN_OBS:-./}
#validtime=${CDATE:-"2001010100"}
#nexttime=$($NDATE $assim_freq $CDATE)
validtime=$($NDATE -$assim_freq $CDATE)
nexttime=${CDATE}
cdump=${CDUMP:-"gdas"}
mem=${imem:-0}
case=${CASE:-C96}
#ObsDir=${ObsDir}/../
sensorID=${sensorID:-"Passing SensorID failed"}
#satID=`echo ${sensorID} | awk -F "_" '{print $NF}'`
satID="viirs"

griddir=${griddir-${HOMEgfs}/fix/fix_fv3}

#HOMEgfs=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow
#JEDIDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/build
#WorkDir=./hofx_aod
#RotDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/
#ObsDir=/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/AOT/thinned_C96
#validtime=2018041700
#nexttime=2018041706
#cdump=gdas
#mem=20
#case=C96
#griddir=${HOMEgfs}/fix/fix_fv3

#mkdir ${WorkDir}

nrm="/bin/rm -rf"
ncp="/bin/cp -r"
nln="/bin/ln -sf"

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

obsstr=${nexttime}
#obsfile=${ObsDir}"/"${obsstr}"/${satID}_aod_snpp."${obsstr}".nc"
#obsfile=${ObsDir}"/"${obsstr}"/nnr."${obsstr}".nc"
#obsfile=${ObsDir}"/nnr_${satID}."${obsstr}".nc"
obsfile=${ObsDir}/${satID}_aod_snpp.${obsstr}.nc


if [[ -e ${WorkDir}/aod_${satID}_obsin.nc ]]; then
   ${nrm} ${WorkDir}/aod_${satID}_obsin.nc
fi

${ncp} ${obsfile} ${WorkDir}/aod_${satID}_obsin.nc

outputdir=${RotDir}/${cdump}.${nyy}${nmm}${ndd}/${nhh}/${memdir}/obs

mkdir -p ${outputdir}

outobs=${outputdir}/aod_${satID}_hofx_3dvar_${obsstr}'.nc'

if [[ -e ${outobs} ]]; then
   ${nrm} ${outobs}
fi

${ncp} ${obsfile} ${outobs}
${nln} ${outobs} ${WorkDir}/aod_${satID}_obsout.nc


#setup the namelist in a dictionary
filetime=${nyy}${nmm}${ndd}.${nhh}0000
inputdir=${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART

cat << EOF > ${WorkDir}/fv3aod2obs.nl
&record_input
  input_grid_dir = "${griddir}/${case}"
  output_obs_dir = "${WorkDir}"
  fname_grid = "${case}_grid_spec.tile?.nc"
  fnameout_obs = "aod_${satID}_obsout.nc"
  input_obs_dir = "${WorkDir}"
  fname_fv3 = "${filetime}.fv_aod_${sensorID}.res.tile?.nc"
  input_fv3_dir = "${inputdir}"
  fnamein_obs = "aod_${satID}_obsin.nc"
/
EOF

