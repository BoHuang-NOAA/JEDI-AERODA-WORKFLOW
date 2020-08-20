#!/bin/ksh
set -x

JEDIDir=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
JEDIcrtm=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
WorkDir=${DATA:-$pwd/hofx_aod.$$}
RotDir=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
ObsDir=${COMIN_OBS:-./}
validtime=${CDATE:-"2001010100"}
nexttime=$($NDATE $assim_freq $CDATE)
nexttimem3=$($NDATE -3 $nexttime)
nexttimep3=$($NDATE 3 $nexttime)
cdump=${CDUMP:-"gdas"}
itile=${itile:-1}
mem=${imem:-0}
fgatfixdir=${HOMEgfs}/fix/fix_fgat/
caseres=${CASE_ENKF:-C96}
resc=$(echo $caseres |cut -c2-5)
resx=$((resc+1))
resy=$((resc+1))
HOFXFGATEXEC=${JEDIDir}/bin/fv3jedi_hofx_nomodel.x
FieldDir=${JEDIDir}/fv3-jedi/test/Data/fieldsets/
FV3Dir=${JEDIDir}/fv3-jedi/test/Data/fv3files/
#sensorID=${sensorID:-"Pass sensorID falied"};

if [[ 0 -eq 1 ]]; then
HOMEgfs=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow/
#JEDIcrtm=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
JEDIcrtm=Data/Little_Endian/
WorkDir=./hofx_aod
#RotDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_C96_C96_M20_jedi3denvar_yesFRP_testBkgOutput_201606/dr-data/
RotDir=Data
#ObsDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/dataSets/NNR_AOD_Obs/2016Case/thinned_C192/
ObsDir=Data
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate 
validtime=2016060318
assim_freq=6
nexttime=$($NDATE $assim_freq $validtime)
nexttimem3=$($NDATE -$assim_freqhalf $nexttime)
nexttimep3=$($NDATE $assim_freqhalf $nexttime)
cdump="gdas"
itile=-1
mem=0
#cdump=gdas
#itile=6
#mem=20
fi

nrm="/bin/rm -rf"
ncp="/bin/cp -r"
nln="/bin/ln -sf"

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
#vdatestr="${vyy}${vmm}${vdd}.${vhh}0000"
vdatestr="${vyy}-${vmm}-${vdd}T${vhh}:00:00Z"

nyy=$(echo $nexttime | cut -c1-4)
nmm=$(echo $nexttime | cut -c5-6)
ndd=$(echo $nexttime | cut -c7-8)
nhh=$(echo $nexttime | cut -c9-10)
#ndatestr="${nyy}${nmm}${ndd}.${nhh}0000"
ndatestr="${nyy}-${nmm}-${ndd}T${nhh}:00:00Z"
ndatestr1="${nyy}${nmm}${ndd}.${nhh}0000"

nm3yy=$(echo $nexttimem3 | cut -c1-4)
nm3mm=$(echo $nexttimem3 | cut -c5-6)
nm3dd=$(echo $nexttimem3 | cut -c7-8)
nm3hh=$(echo $nexttimem3 | cut -c9-10)
#ndatestr="${nyy}${nmm}${ndd}.${nhh}0000"
nm3datestr="${nm3yy}-${nm3mm}-${nm3dd}T${nm3hh}:00:00Z"


cd ${WorkDir}
if [  -d "${WorkDir}/RESTART" ]; then
   $nrm ${WorkDir}/RESTART
fi

mkdir -p ${WorkDir}/RESTART
#$nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/*.fv_core.res.*nc.ges ${WorkDir}/RESTART/
#$nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/*.fv_tracer.res.*.nc.ges ${WorkDir}/RESTART/
#$nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/*.coupler.res.ges ${WorkDir}/RESTART/

inputdir=RESTART
outputdir=${RotDir}/${cdump}.${nyy}${nmm}${ndd}/${nhh}/${memdir}/obs
obsin_terra=${ObsDir}/nnr_terra.${nexttime}.nc
obsin_aqua=${ObsDir}/nnr_aqua.${nexttime}.nc
hofx_terra=${outputdir}/aod_nnr_terra_hofx_nomodel.nc4
hofx_aqua=${outputdir}/aod_nnr_aqua_hofx_nomodel.nc4


mkdir -p ${outputdir}

bkgfreq=${FGAT3D_freq}
rm -rf ${WorkDir}/bkgtmp.info

if [ ${FGAT3D} == "TRUE" -a  ${FGAT3D_onlyCenter} != "TRUE" ]; then
   bkgtimest=${nexttimem3}
   bkgtimeed=${nexttimep3}
else
   bkgtimest=${nexttime}
   bkgtimeed=${nexttime}
fi

while [ ${bkgtimest} -le ${bkgtimeed} ]; do
   bkgyy=$(echo $bkgtimest | cut -c1-4)
   bkgmm=$(echo $bkgtimest | cut -c5-6)
   bkgdd=$(echo $bkgtimest | cut -c7-8)
   bkghh=$(echo $bkgtimest | cut -c9-10)
   bkgdatestr="${bkgyy}-${bkgmm}-${bkgdd}T${bkghh}:00:00Z"
   bkgdatestr1="${bkgyy}${bkgmm}${bkgdd}.${bkghh}0000"

   $nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/${bkgdatestr1}.coupler.res.ges ${WorkDir}/RESTART/${bkgdatestr1}.coupler.res
   $nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/${bkgdatestr1}.fv_core.res.nc.ges ${WorkDir}/RESTART/${bkgdatestr1}.fv_core.res.nc
   itile=1
   while [[ $itile -le 6 ]]; do
       $nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/${bkgdatestr1}.fv_core.res.tile${itile}.nc.ges ${WorkDir}/RESTART/${bkgdatestr1}.fv_core.res.tile${itile}.nc
       $nln ${RotDir}/${cdump}.${vyy}${vmm}${vdd}/${vhh}/${memdir}/RESTART/${bkgdatestr1}.fv_tracer.res.tile${itile}.nc.ges ${WorkDir}/RESTART/${bkgdatestr1}.fv_tracer.res.tile${itile}.nc
       ((itile=itile+1))
   done
   
   echo "  - date: '${bkgdatestr}'" >> ${WorkDir}/bkgtmp.info
   echo "    filetype: gfs"        >> ${WorkDir}/bkgtmp.info
   echo "    datapath: ${inputdir}" >> ${WorkDir}/bkgtmp.info
   echo "    filename_core: ${bkgdatestr1}.fv_core.res.nc" >> ${WorkDir}/bkgtmp.info
   echo "    filename_trcr: ${bkgdatestr1}.fv_tracer.res.nc" >> ${WorkDir}/bkgtmp.info
   echo "    filename_cplr: ${bkgdatestr1}.coupler.res" >> ${WorkDir}/bkgtmp.info
   echo '    state variables: [T,DELP,sphum,sulf,bc1,bc2,oc1,oc2,dust1,dust2,dust3,dust4,dust5,seas1,seas2,seas3,seas4]' >> ${WorkDir}/bkgtmp.info
   bkgtimest=$($NDATE ${bkgfreq} $bkgtimest)
done

bkgfiles=`cat ${WorkDir}/bkgtmp.info`

rm -rf ${WorkDir}/enkf_hofx_AOD_modis_fgat.yaml
cat << EOF > ${WorkDir}/enkf_hofx_AOD_modis_fgat.yaml
window begin: '${nm3datestr}'
window length: PT6H
forecast length: PT1H
geometry:
  nml_file_mpp: ${FV3Dir}/fmsmpp.nml
  trc_file: ${FV3Dir}/field_table
  akbk: ${FV3Dir}/akbk64.nc4
  layout: [1,1]
  io_layout: [1,1]
  npx: ${resx}
  npy: ${resy}
  npz: 64
  ntiles: 6
  fieldsets:
    - fieldset: ${FieldDir}/dynamics.yaml
    - fieldset: ${FieldDir}/aerosols_gfs.yaml
    - fieldset: ${FieldDir}/ufo.yaml
forecasts:
  states:
${bkgfiles}
observations:
- obs space:
    name: Aod
    obsdatain:
      obsfile: ${obsin_terra}
    obsdataout:
      obsfile: ${hofx_terra}
    simulated variables: [aerosol_optical_depth]
    channels: 4
  obs operator:
    name: Aod
    Absorbers: [H2O,O3]
    obs options:
      Sensor_ID: v.modis_terra
      EndianType: little_endian
      CoefficientPath: ${CRTMFix}
      AerosolOption: aerosols_gocart_default
  obs error:
    covariance model: diagonal
- obs space:
    name: Aod
    obsdatain:
      obsfile: ${obsin_aqua}
    obsdataout:
      obsfile: ${hofx_aqua}
    simulated variables: [aerosol_optical_depth]
    channels: 4
  obs operator:
    name: Aod
    Absorbers: [H2O,O3]
    obs options:
      Sensor_ID: v.modis_aqua
      EndianType: little_endian
      CoefficientPath: ${CRTMFix}
      AerosolOption: aerosols_gocart_default
  obs error:
    covariance model: diagonal
prints:
  frequency: PT3H
EOF

srun --export=all -n 6 ${HOFXFGATEXEC} "${WorkDir}/enkf_hofx_AOD_modis_fgat.yaml" "${WorkDir}/enkf_hofx_AOD_modis_fgat_mem${imem}.run"

err=$?

echo "HBO"
echo $err

if [ $err == 0 ]; then
   itile=0
   while [[ $itile -le 5 ]]; do
       /bin/mv ${outputdir}/aod_nnr_terra_hofx_nomodel_000${itile}.nc4 ${outputdir}/aod_nnr_terra_hofx_nomodel_${nexttime}_000${itile}.nc4.ges 
       /bin/mv ${outputdir}/aod_nnr_aqua_hofx_nomodel_000${itile}.nc4 ${outputdir}/aod_nnr_aqua_hofx_nomodel_${nexttime}_000${itile}.nc4.ges 
       ((itile=itile+1))
   done
else
   exit ${err}
fi


exit 0


