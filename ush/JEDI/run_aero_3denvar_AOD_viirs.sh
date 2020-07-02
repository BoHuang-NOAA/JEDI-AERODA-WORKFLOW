#!/bin/ksh
set -x

JEDIDir=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
WorkDir=${DATA:-$pwd/analysis.$$}
FixDir=${FIXjedi:-$HOMEgfs/fix/fix_jedi}
BumpDir=${FixDir}"/bump/"
#TemplateDir=
RotDir=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
ObsDir=${COMIN_OBS:-$COMIN}
ComIn_Ges=${COMIN_GES:-$COMIN}
ComIn_Ges_Ens=${COMIN_GES_ENS:-$COMIN_GES}
validtime=${CDATE:-"2001010100"}
bumptime=${validtime}
#validtime=
#bumptime=
prevtime=$($NDATE -$assim_freq $CDATE)
startwin=$($NDATE -3 $CDATE)
res1=${CASE:-"C384"} # no lower case
res=`echo "$res1" | tr '[:upper:]' '[:lower:]'`
cdump=${CDUMP:-"gdas"}
nmem=${NMEM_AERO:-"10"}

#HOMEgfs=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow
#JEDIDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/build
#WorkDir=./anal
#FixDir=$HOMEgfs/fix/fix_jedi
#BumpDir=${FixDir}"/bump/"
#RotDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/
#ObsDir=/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/AOT/thinned_C96/2018041706/
#ComIn_Ges=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data//gdas.20180417/00
#ComIn_Ges_Ens=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data//enkfgdas.20180417/00
#validtime=2018041706
#bumptime=${validtime}
#prevtime=2018041700
#startwin=2018041703
#res1=C96
#res=c96
#cdump=gdas
#nmem=20

ncp="/bin/cp -r"
nmv="/bin/mv -f"
nln="/bin/ln -sf"

mkdir -p ${WorkDir}

# define executable to run
jediexe=${JEDIDir}"/bin/fv3jedi_var.x"

# define yaml file to generate
yamlfile=${WorkDir}"/hyb-3dvar_gfs_aero.yaml"

# other vars for yaml
#nowstring=
#bumpstring=
obsstr=${validtime}
#startwinstr
#obsin_terra="./input/aod_nnr_terra_obs_"${obsstr}".nc4"
#obsout_terra="aod_nnr_terra_hofx_3dvar_"${obsstr}".nc4"
#obsin_aqua="./input/aod_nnr_aqua_obs_"${obsstr}".nc4"
#obsout_aqua="aod_nnr_aqua_hofx_3dvar_"${obsstr}".nc4"
obsin_viirs="./input/aod_viirs_obs_"${obsstr}".nc4"
obsout_viirs="aod_viirs_hofx_3dvar_"${obsstr}".nc4"

# generate memstrs based on number of members
imem=1
rm -rf ${WorkDir}/memtmp.info
filetype="        - filetype: gfs"
filetrcr="          filename_trcr: fv_tracer.res.nc"
filecplr="          filename_cplr: coupler.res"
while [ ${imem} -le ${nmem} ]; do
   memstr="mem`printf %03d ${imem}`"
   filemem="          datapath_tile: ./input/${memstr}/"
   echo "${filetype}" >> ${WorkDir}/memtmp.info
   echo "${filemem}" >> ${WorkDir}/memtmp.info
   echo "${filetrcr}" >> ${WorkDir}/memtmp.info
   echo "${filecplr}" >> ${WorkDir}/memtmp.info
   imem=$((imem+1))
done

members=`cat ${WorkDir}/memtmp.info`

# set date format
byy=$(echo $bumptime | cut -c1-4)
bmm=$(echo $bumptime | cut -c5-6)
bdd=$(echo $bumptime | cut -c7-8)
bhh=$(echo $bumptime | cut -c9-10)
locdatestr="${byy}-${bmm}-${bdd}T${bhh}:00:00Z"

vyy=$(echo $validtime | cut -c1-4)
vmm=$(echo $validtime | cut -c5-6)
vdd=$(echo $validtime | cut -c7-8)
vhh=$(echo $validtime | cut -c9-10)
datestr="${vyy}-${vmm}-${vdd}T${vhh}:00:00Z"

pyy=$(echo $prevtime | cut -c1-4)
pmm=$(echo $prevtime | cut -c5-6)
pdd=$(echo $prevtime | cut -c7-8)
phh=$(echo $prevtime | cut -c9-10)
prevtimestr="${pyy}-${pmm}-${pdd}T${phh}:00:00Z"

syy=$(echo $startwin | cut -c1-4)
smm=$(echo $startwin | cut -c5-6)
sdd=$(echo $startwin | cut -c7-8)
shh=$(echo $startwin | cut -c9-10)
startwindow="${syy}-${smm}-${sdd}T${shh}:00:00Z"


# create yaml file
cat << EOF > ${WorkDir}/hyb-3dvar_gfs_aero.yaml
cost_function:
  Jb:
    Background:
      state:
      - filetype: gfs
        datapath_tile: ./input/ensmean/
        filename_core: fv_core.res.nc
        filename_trcr: fv_tracer.res.nc
        filename_cplr: coupler.res
        variables: ["T","delp","sphum",
                    "sulf","bc1","bc2","oc1","oc2",
                    "dust1","dust2","dust3","dust4","dust5",
                    "seas1","seas2","seas3","seas4"]
    Covariance:
      covariance: hybrid
      static_weight: '0.01'
      ensemble_weight: '0.99'
      static:
        date: '${datestr}'
        covariance: FV3JEDIstatic
      ensemble:
        date: '${datestr}'
        variables: ["sulf","bc1","bc2","oc1","oc2",
                    "dust1","dust2","dust3","dust4","dust5",
                    "seas1","seas2","seas3","seas4"]
        members:
${members}

        localization:
          timeslots: ['${locdatestr}']
          variables: ["sulf","bc1","bc2","oc1","oc2",
                      "dust1","dust2","dust3","dust4","dust5",
                      "seas1","seas2","seas3","seas4"]
          localization: BUMP
          bump:
            prefix: ./bump/fv3jedi_bumpparameters_loc_gfs_aero 
            method: loc
            strategy: common
            load_nicas: 1
            mpicom: 2
            verbosity: main
  Jo:
    ObsTypes:
    - ObsSpace:
        name: Aod
        ObsDataIn:
          obsfile: ${obsin_viirs}
        ObsDataOut:
          obsfile: ${obsout_viirs}
        simulate:
          variables: [aerosol_optical_depth]
          channels: 4
      ObsOperator:
        name: Aod
        Absorbers: [H2O,O3]
        ObsOptions:
          Sensor_ID: v.viirs-m_npp
          EndianType: little_endian
          CoefficientPath: ./crtm/
          AerosolOption: aerosols_gocart_default
      Covariance:
        covariance: diagonal
  cost_type: 3D-Var
  variables: ["sulf","bc1","bc2","oc1","oc2",
              "dust1","dust2","dust3","dust4","dust5",
              "seas1","seas2","seas3","seas4"]
  window_begin: '${startwindow}'
  window_length: PT6H
  varchange: Analysis2Model
  filetype: gfs
  datapath_tile: ./input/ensmean/
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  filename_cplr: coupler.res
final:
  diagnostics:
    departures: oman
minimizer:
  algorithm: DRIPCG
model:
  name: 'FV3'
  nml_file: input_gfs.nml
  nml_file_pert: inputpert_4dvar.nml
  tstep: PT3H
  lm_do_dyn: 1
  lm_do_trb: 0
  lm_do_mst: 0
  variables: ["T","delp","sphum",
              "sulf","bc1","bc2","oc1","oc2",
              "dust1","dust2","dust3","dust4","dust5",
              "seas1","seas2","seas3","seas4"]
output:
  filetype: gfs
  datapath_tile: ./analysis/
  filename_core: hyb-3dvar-gfs_aero.fv_core.res.nc
  filename_trcr: hyb-3dvar-gfs_aero.fv_tracer.res.nc
  filename_cplr: hyb-3dvar-gfs_aero.coupler.res
  first: PT0H
  frequency: PT1H
resolution:
  nml_file_mpp: fmsmpp.nml
  nml_file: input_gfs.nml
  trc_file: field_table.input
  pathfile_akbk: ./input/akbk.nc
variational:
  iteration:
  - ninner: '10'
    gradient_norm_reduction: 1e-10
    test: 'on'
    resolution:
      nml_file: input_gfs.nml
      trc_file: field_table.input
      pathfile_akbk: ./input/akbk.nc
    diagnostics:
      departures: ombg
    linearmodel:
      varchange: 'Identity'
      name: 'FV3JEDIIdTLM'
      version: FV3JEDIIdTLM
      tstep: PT3H
      variables: ["sulf","bc1","bc2","oc1","oc2",
                  "dust1","dust2","dust3","dust4","dust5",
                  "seas1","seas2","seas3","seas4"]
  - ninner: '5'
    gradient_norm_reduction: 1e-10
    test: 'on'
    resolution:
      nml_file: input_gfs.nml
      trc_file: field_table.input
      pathfile_akbk: ./input/akbk.nc
    diagnostics:
      departures: ombg
    linearmodel:
      varchange: 'Identity'
      name: 'FV3JEDIIdTLM'
      version: FV3JEDIIdTLM
      tstep: PT3H
      variables: ["sulf","bc1","bc2","oc1","oc2",
                  "dust1","dust2","dust3","dust4","dust5",
                  "seas1","seas2","seas3","seas4"]
EOF


fv3dir=${JEDIDir}"/fv3-jedi/test/Data/fv3files/"
${nln} ${fv3dir}"/fmsmpp.nml" ${WorkDir}"/fmsmpp.nml"
${nln} ${fv3dir}"/input_gfs_"${res}".nml" ${WorkDir}"/input_gfs.nml"
${nln} ${fv3dir}"/field_table" ${WorkDir}"/field_table.input"
${nln} ${fv3dir}"/inputpert_4dvar.nml" ${WorkDir}"/inputpert_4dvar.nml"

inputdirin=${JEDIDir}"/fv3-jedi/test/Data/inputs/gfs_aero_c12/"
inputdirout=${WorkDir}"/input"
mkdir -p ${inputdirout}
${nln} ${inputdirin}"/akbk.nc" ${inputdirout}"/akbk.nc"

# link bump directory
${nln} ${BumpDir} ${WorkDir}/"bump"

# link observations
#obsfile=${ObsDir}"/viirs_aod_npp_"${obsstr}".nc"
#obsfile_terra=${ObsDir}"/nnr_terra."${obsstr}".nc"
#obsfile_aqua=${ObsDir}"/nnr_aqua."${obsstr}".nc"
#${nln} ${obsfile_terra} ${obsin_terra}
#${nln} ${obsfile_aqua} ${obsin_aqua}
obsfile_viirs=${ObsDir}/viirs_aod_snpp.${obsstr}.nc
${nln} ${obsfile_viirs} ${obsin_viirs}


analroot=${RotDir}"gdas."${vyy}${vmm}${vdd}"/"${vhh}"/"
mkdir -p ${analroot}

iproc=0
while [ ${iproc} -le 5 ]; do
   procstr=`printf %04d ${iproc}`
   #hofxout_terra=${analroot}"/aod_nnr_terra_hofx_3dvar_"${obsstr}"_"${procstr}".nc4"
   #hofx_terra=${WorkDir}"/aod_nnr_terra_hofx_3dvar_"${obsstr}"_"${procstr}".nc4"
   #${nln} ${hofxout_terra} ${hofx_terra}

   #hofxout_aqua=${analroot}"/aod_nnr_aqua_hofx_3dvar_"${obsstr}"_"${procstr}".nc4"
   #hofx_aqua=${WorkDir}"/aod_nnr_aqua_hofx_3dvar_"${obsstr}"_"${procstr}".nc4"
   #${nln} ${hofxout_aqua} ${hofx_aqua}

   hofxout_viirs=${analroot}"/aod_viirs_hofx_3dvar_"${obsstr}"_"${procstr}".nc4"
   hofx_aqua=${WorkDir}"/aod_viirs_3dvar_"${obsstr}"_"${procstr}".nc4"
   ${nln} ${hofxout_viirs} ${hofx_viirs}

   iproc=$((iproc+1))
done

# link deterministic or mean background
nowfilestr=${vyy}${vmm}${vdd}.${vhh}"0000"
gesroot=${RotDir}"/gdas."${pyy}${pmm}${pdd}"/"${phh}"/"
mkdir -p ${inputdirout}"/ensmean"
couplerin=${gesroot}"/RESTART/"${nowfilestr}".coupler.res.ges"
couplerges=${gesroot}"/RESTART/"${nowfilestr}".coupler.res.ges"
couplerout=${inputdirout}"/ensmean/coupler.res"
#${nmv} ${couplerin} ${couplerges}
${nln} ${couplerges} ${couplerout}

itile=1
while [ ${itile} -le 6 ]; do
   tilestr=`printf %1i $itile`

   tilefile="fv_tracer.res.tile"${tilestr}".nc"
   tilefilein=${gesroot}"/RESTART/"${nowfilestr}"."${tilefile}".ges"
   tilefileges=${gesroot}"/RESTART/"${nowfilestr}"."${tilefile}".ges"
   tilefileout=${inputdirout}"/ensmean/"${tilefile}
   #${ncp} ${tilefilein} ${tilefileges}
   ${nln} ${tilefileges} ${tilefileout}


   tilefile="fv_core.res.tile"${tilestr}".nc"
   tilefilein=${gesroot}"/RESTART/"${nowfilestr}"."${tilefile}".ges"
   tilefileges=${gesroot}"/RESTART/"${nowfilestr}"."${tilefile}".ges"
   tilefileout=${inputdirout}"/ensmean/"${tilefile}
   #${ncp} ${tilefilein} ${tilefileges}
   ${nln} ${tilefileges} ${tilefileout}

   itile=$((itile+1))
done

# link ensemble member backgrounds
ensgesroot=${RotDir}"/enkfgdas."${pyy}${pmm}${pdd}"/"${phh}"/"

imem=1
while [ ${imem} -le ${nmem} ]; do
    memstr="mem"`printf %03d $imem`
    mkdir -p ${inputdirout}"/"${memstr}
    couplerin=${ensgesroot}"/"${memstr}"/RESTART/"${nowfilestr}".coupler.res.ges"
    couplerges=${ensgesroot}"/"${memstr}"/RESTART/"${nowfilestr}".coupler.res.ges"
    couplerout=${inputdirout}"/"${memstr}"/coupler.res"
    #${ncp} ${couplerin} ${couplerges}
    ${nln} ${couplerin} ${couplerout}

    itile=1
    while [ ${itile} -le 6 ]; do
       tilestr=`printf %1i $itile`
    
       tilefile="fv_tracer.res.tile"${tilestr}".nc"
       tilefilein=${ensgesroot}"/"${memstr}"/RESTART/"${nowfilestr}"."${tilefile}".ges"
       tilefileges=${ensgesroot}"/"${memstr}"/RESTART/"${nowfilestr}"."${tilefile}".ges"
       tilefileout=${inputdirout}"/"${memstr}"/"${tilefile}
       #${ncp} ${tilefilein} ${tilefileges}
       ${nln} ${tilefileges} ${tilefileout}
    
       tilefile="fv_core.res.tile"${tilestr}".nc"
       tilefilein=${ensgesroot}"/"${memstr}"/RESTART/"${nowfilestr}"."${tilefile}".ges"
       tilefileges=${ensgesroot}"/"${memstr}"/RESTART/"${nowfilestr}"."${tilefile}".ges"
       tilefileout=${inputdirout}"/"${memstr}"/"${tilefile}
       #${ncp} ${tilefilein} ${tilefileges}
       ${nln} ${tilefileges} ${tilefileout}
    
       itile=$((itile+1))
    done
    imem=$((imem+1))
done

# link deterministic or mean analysis
analysisdir=${WorkDir}"/analysis"
mkdir -p ${analysisdir}
coupleranl=${gesroot}"/RESTART/"${nowfilestr}".coupler.res"
couplerwork=${analysisdir}"/"${nowfilestr}".hyb-3dvar-gfs_aero.coupler.res"
${nln} ${coupleranl} ${couplerwork}

itile=1
while [ ${itile} -le 6 ]; do
   tilestr=`printf %1i $itile`

   tilefile="fv_tracer.res.tile"${tilestr}".nc"
   tilefileanl=${gesroot}"/RESTART/"${nowfilestr}"."${tilefile}
   tilefilework=${analysisdir}"/"${nowfilestr}".hyb-3dvar-gfs_aero."${tilefile}
   ${nln} ${tilefileanl} ${tilefilework}

   tilefile="fv_core.res.tile"${tilestr}".nc"
   tilefileanl=${gesroot}"/RESTART/"${nowfilestr}"."${tilefile}
   tilefilework=${analysisdir}"/"${nowfilestr}".hyb-3dvar-gfs_aero."${tilefile}
   ${nln} ${tilefileanl} ${tilefilework}

   itile=$((itile+1))
done


#link executables
${nln} ${jediexe} ${WorkDir}"/fv3jedi_var.x"

# CRTM related things
#CRTMFix=${JEDIDir}"/fv3-jedi/test/Data/crtm/"
CRTMFix="${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/"
coeffs="AerosolCoeff.bin CloudCoeff.bin v.viirs-m_npp.SpcCoeff.bin v.viirs-m_npp.TauCoeff.bin"
#coeffs="AerosolCoeff.bin CloudCoeff.bin v.modis_terra.SpcCoeff.bin v.modis_terra.TauCoeff.bin v.modis_aqua.SpcCoeff.bin v.modis_aqua.TauCoeff.bin"
#coeffs="AerosolCoeff.bin CloudCoeff.bin"

mkdir -p ${WorkDir}"/crtm/"

#${nln} /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow/fix/jedi_crtm_fix_20200413/CRTM_fix/fix/SpcCoeff/Little_Endian/v.modis_terra.SpcCoeff.bin ${WorkDir}"/crtm/v.modis_terra.SpcCoeff.bin"
#${nln} /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow/fix/jedi_crtm_fix_20200413/CRTM_fix/fix/SpcCoeff/Little_Endian/v.modis_aqua.SpcCoeff.bin ${WorkDir}"/crtm/v.modis_aqua.SpcCoeff.bin"
#
#${nln} /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow/fix/jedi_crtm_fix_20200413/CRTM_fix/fix/TauCoeff/ODAS/Little_Endian/v.modis_terra.TauCoeff.bin ${WorkDir}"/crtm/v.modis_terra.TauCoeff.bin"
#${nln} /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow/fix/jedi_crtm_fix_20200413/CRTM_fix/fix/TauCoeff/ODAS/Little_Endian/v.modis_aqua.TauCoeff.bin ${WorkDir}"/crtm/v.modis_aqua.TauCoeff.bin"

for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}"/"${coeff} ${WorkDir}"/crtm/"${coeff}
done

# global additional files to link
coeffs=`ls ${CRTMFix}/NPOESS.* | awk -F "/" '{print $NF}'`
for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}"/"${coeff} ${WorkDir}"/crtm/"${coeff}
done

coeffs=`ls ${CRTMFix}/USGS.* | awk -F "/" '{print $NF}'`
for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}"/"${coeff} ${WorkDir}"/crtm/"${coeff}
done

coeffs=`ls ${CRTMFix}/FASTEM6.* | awk -F "/" '{print $NF}'`
for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}"/"${coeff} ${WorkDir}"/crtm/"${coeff}
done
