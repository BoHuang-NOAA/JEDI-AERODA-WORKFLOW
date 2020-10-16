#!/bin/ksh
set -x

JEDIDir=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
WorkDir=${DATA:-$pwd/analysis.$$}
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
endwin=$($NDATE 3 $CDATE)
res1=${CASE:-"C384"} # no lower case
res=`echo "$res1" | tr '[:upper:]' '[:lower:]'`
resc=$(echo $res1 |cut -c2-5)
resx=$((resc+1))
resy=$((resc+1))
BumpDir=${JEDIDir}/fv3-jedi/test/Data/bump/${CASE}/
FieldDir=${JEDIDir}/fv3-jedi/test/Data/fieldsets/
FV3Dir=${JEDIDir}/fv3-jedi/test/Data/fv3files/

cdump=${CDUMP:-"gdas"}
nmem=${NMEM_AERO:-"10"}
fgatfixdir=${HOMEgfs}/fix/fix_fgat/

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
jediexe=${JEDIDir}/bin/fv3jedi_var.x

# define yaml file to generate
yamlfile=${WorkDir}/hyb-3dvar_gfs_aero.yaml

# other vars for yaml
#nowstring=
#bumpstring=
obsstr=${validtime}
#startwinstr
obsin_terra=./input/aod_nnr_terra_obs_${obsstr}.nc4
obsout_terra=aod_nnr_terra_hofx_3dvar_${obsstr}.nc4
obsin_aqua=./input/aod_nnr_aqua_obs_${obsstr}.nc4
obsout_aqua=aod_nnr_aqua_hofx_3dvar_${obsstr}.nc4


# set date format
byy=$(echo $bumptime | cut -c1-4)
bmm=$(echo $bumptime | cut -c5-6)
bdd=$(echo $bumptime | cut -c7-8)
bhh=$(echo $bumptime | cut -c9-10)
locdatestr=${byy}-${bmm}-${bdd}T${bhh}:00:00Z

vyy=$(echo $validtime | cut -c1-4)
vmm=$(echo $validtime | cut -c5-6)
vdd=$(echo $validtime | cut -c7-8)
vhh=$(echo $validtime | cut -c9-10)
vdatestr=${vyy}-${vmm}-${vdd}T${vhh}:00:00Z
vdate_prefix=${vyy}${vmm}${vdd}.${vhh}0000

pyy=$(echo $prevtime | cut -c1-4)
pmm=$(echo $prevtime | cut -c5-6)
pdd=$(echo $prevtime | cut -c7-8)
phh=$(echo $prevtime | cut -c9-10)
prevtimestr=${pyy}-${pmm}-${pdd}T${phh}:00:00Z

syy=$(echo $startwin | cut -c1-4)
smm=$(echo $startwin | cut -c5-6)
sdd=$(echo $startwin | cut -c7-8)
shh=$(echo $startwin | cut -c9-10)
startwindow=${syy}-${smm}-${sdd}T${shh}:00:00Z

eyy=$(echo $endwin | cut -c1-4)
emm=$(echo $endwin | cut -c5-6)
edd=$(echo $endwin | cut -c7-8)
ehh=$(echo $endwin | cut -c9-10)
endwindow=${eyy}-${emm}-${edd}T${ehh}:00:00Z

# generate memstrs based on number of members
imem=1
rm -rf ${WorkDir}/memtmp.info
filetype="      - filetype: gfs"
filetrcr="        filename_trcr: ${vdate_prefix}.fv_tracer.res.nc"
filecore="        filename_core: ${vdate_prefix}.fv_core.res.nc"
filecplr="        filename_cplr: ${vdate_prefix}.coupler.res"
filevars1="        state variables: &aerovars [sulf,bc1,bc2,oc1,oc2,
                                    dust1,dust2,dust3,dust4,dust5,
                                    seas1,seas2,seas3,seas4]"
filevars="        state variables: *aerovars"

while [ ${imem} -le ${nmem} ]; do
   memstr="mem`printf %03d ${imem}`"
   filemem="        datapath: ./input/${memstr}/"
   echo "${filetype}" >> ${WorkDir}/memtmp.info
   if [ ${imem} -eq 1 ];then
      echo "${filevars1}" >> ${WorkDir}/memtmp.info
   else
      echo "${filevars}" >> ${WorkDir}/memtmp.info
   fi

   echo "${filemem}" >> ${WorkDir}/memtmp.info
   echo "${filecore}" >> ${WorkDir}/memtmp.info
   echo "${filetrcr}" >> ${WorkDir}/memtmp.info
   echo "${filecplr}" >> ${WorkDir}/memtmp.info
   imem=$((imem+1))
done

members=`cat ${WorkDir}/memtmp.info`


# create yaml file
cat << EOF > ${WorkDir}/hyb-3dvar_gfs_aero.yaml
cost function:
  background:
    filetype: gfs
    datapath: ./input/ensmean/
    filename_core: ${vdate_prefix}.fv_core.res.nc
    filename_trcr: ${vdate_prefix}.fv_tracer.res.nc
    filename_cplr: ${vdate_prefix}.coupler.res
    state variables: [T,DELP,sphum,
                      sulf,bc1,bc2,oc1,oc2,
                      dust1,dust2,dust3,dust4,dust5,
                      seas1,seas2,seas3,seas4]
  background error:
    covariance model: hybrid
    static weight: 0.01
    ensemble weight: 0.99
    static:
      date: '${vdatestr}'
      covariance model: FV3JEDIstatic
    ensemble:
      date: '${vdatestr}'
      members:
${members}
      localization:
        timeslots: ['${vdatestr}']
        localization variables: *aerovars
        localization method: BUMP
        bump:
          prefix: ./bump/fv3jedi_bumpparameters_loc_gfs_aero 
          method: loc
          strategy: common
          load_nicas: 1
          mpicom: 2
          verbosity: main
  observations:
  - obs space:
      name: Aod
      obsdatain:
        obsfile: ${obsin_terra}
      obsdataout:
        obsfile: ${obsout_terra}
      simulated variables: [aerosol_optical_depth]
      channels: 4
    obs operator:
      name: Aod
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: v.modis_terra
        EndianType: little_endian
        CoefficientPath: ./crtm/
        AerosolOption: aerosols_gocart_default
    obs error:
      covariance model: diagonal
  - obs space:
      name: Aod
      obsdatain:
        obsfile: ${obsin_aqua}
      obsdataout:
        obsfile: ${obsout_aqua}
      simulated variables: [aerosol_optical_depth]
      channels: 4
    obs operator:
      name: Aod
      Absorbers: [H2O,O3]
      obs options:
        Sensor_ID: v.modis_aqua
        EndianType: little_endian
        CoefficientPath: ./crtm/
        AerosolOption: aerosols_gocart_default
    obs error:
      covariance model: diagonal
  cost type: 4D-Var
  analysis variables: *aerovars 
  window begin: '${vdatestr}'
  window length: PT3H
  variable change: Analysis2Model
  filetype: gfs
  datapath: ./input/ensmean/
  filename_core: ${bkgdatestr}.fv_core.res.nc
  filename_trcr: ${bkgdatestr}.fv_tracer.res.nc
  filename_cplr: ${bkgdatestr}.coupler.res
  model:
    name: PSEUDO
    pseudo_type: gfs
    datapath: ./input/ensmean/
    filename_core: %yyyy%mm%dd.%hh%MM%ss.fv_core.res.nc
    filename_trcr: %yyyy%mm%dd.%hh%MM%ss.fv_tracer.res.nc
    filename_cplr: %yyyy%mm%dd.%hh%MM%ss.coupler.res
    tstep: PT1H
    model variables: [T,DELP,sphum,
                      sulf,bc1,bc2,oc1,oc2,
                      dust1,dust2,dust3,dust4,dust5,
                      seas1,seas2,seas3,seas4]
  geometry:
    nml_file_mpp: fmsmpp.nml
    trc_file: field_table.input
    akbk: ./input/akbk.nc
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
final:
  diagnostics:
    departures: oman
output:
  filetype: gfs
  datapath: ./analysis/
  filename_core: hyb-3dvar-gfs_aero.fv_core.res.nc
  filename_trcr: hyb-3dvar-gfs_aero.fv_tracer.res.nc
  filename_cplr: hyb-3dvar-gfs_aero.coupler.res
  first: PT0H
  frequency: PT1H
variational:
  minimizer:
    algorithm: DRIPCG
  iterations:
  - ninner: 10
    gradient norm reduction: 1e-10
    test: on
    geometry:
      trc_file: field_table.input
      akbk: ./input/akbk.nc
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
    diagnostics:
      departures: ombg
    linear model:
      variable change: Identity
      name: FV3JEDIIdTLM
      tstep: PT1H
      tlm variables: *aerovars
EOF


${nln} ${FV3Dir}/fmsmpp.nml ${WorkDir}/fmsmpp.nml
${nln} ${FV3Dir}/input_gfs_${res}.nml ${WorkDir}/input_gfs.nml
${nln} ${FV3Dir}/field_table ${WorkDir}/field_table.input
${nln} ${FV3Dir}/inputpert_4dvar.nml ${WorkDir}/inputpert_4dvar.nml

inputdirout=${WorkDir}/input
mkdir -p ${inputdirout}
${nln} ${FV3Dir}/akbk64.nc4 ${inputdirout}/akbk.nc

# link bump directory
mkdir -p ${WorkDir}/bump
${nln} ${BumpDir}/fv3jedi_bumpparameters_loc_gfs_aero*  ${WorkDir}/bump/ 
#${nln} ${BumpDir} ${WorkDir}/"bump"

# link observations
#obsfile=${ObsDir}"/viirs_aod_npp_"${obsstr}".nc"
obsfile_terra=${ObsDir}/nnr_terra.${obsstr}.nc
obsfile_aqua=${ObsDir}/nnr_aqua.${obsstr}.nc
${nln} ${obsfile_terra} ${obsin_terra}
${nln} ${obsfile_aqua} ${obsin_aqua}

analroot=${RotDir}gdas.${vyy}${vmm}${vdd}/${vhh}/
mkdir -p ${analroot}

iproc=0
while [ ${iproc} -le 5 ]; do
   procstr=`printf %04d ${iproc}`
   hofxout_terra=${analroot}/aod_nnr_terra_hofx_3dvar_${obsstr}_${procstr}.nc4
   hofx_terra=${WorkDir}/aod_nnr_terra_hofx_3dvar_${obsstr}_${procstr}.nc4
   ${nln} ${hofxout_terra} ${hofx_terra}

   hofxout_aqua=${analroot}/aod_nnr_aqua_hofx_3dvar_${obsstr}_${procstr}.nc4
   hofx_aqua=${WorkDir}/aod_nnr_aqua_hofx_3dvar_${obsstr}_${procstr}.nc4
   ${nln} ${hofxout_aqua} ${hofx_aqua}

   iproc=$((iproc+1))
done

# link deterministic or mean background
gesroot=${RotDir}/gdas.${pyy}${pmm}${pdd}/${phh}/
if [ ${FGAT3D_3DENVAR} == "TRUE" -a ${FGAT3D_3DENVAR_onlyCenter} != "TRUE" ]; then
   bkgtimest=${validtime}
   bkgtimeed=${endwin}
else
   bkgtimest=${validtime}
   bkgtimeed=${validtime}
fi
bkgfreq=${FGAT3D_3DENVAR_freq}
while [ ${bkgtimest} -le ${bkgtimeed} ]; do
    bkgyy=$(echo $bkgtimest | cut -c1-4)
    bkgmm=$(echo $bkgtimest | cut -c5-6)
    bkgdd=$(echo $bkgtimest | cut -c7-8)
    bkghh=$(echo $bkgtimest | cut -c9-10)
    bkgdatestr=${bkgyy}${bkgmm}${bkgdd}.${bkghh}0000

    mkdir -p ${inputdirout}/ensmean
    couplerin=${gesroot}/RESTART/${bkgdatestr}.coupler.res.ges
    couplerges=${gesroot}/RESTART/${bkgdatestr}.coupler.res.ges
    couplerout=${inputdirout}/ensmean/${bkgdatestr}.coupler.res
    #${nmv} ${couplerin} ${couplerges}
    ${nln} ${couplerges} ${couplerout}

    itile=1
    while [ ${itile} -le 6 ]; do
       tilestr=`printf %1i $itile`

       tilefile=${bkgdatestr}.fv_tracer.res.tile${tilestr}.nc
       tilefilein=${gesroot}/RESTART/${tilefile}.ges
       tilefileges=${gesroot}/RESTART/${tilefile}.ges
       tilefileout=${inputdirout}/ensmean/${tilefile}
       #${ncp} ${tilefilein} ${tilefileges}
       ${nln} ${tilefileges} ${tilefileout}


       tilefile=${bkgdatestr}.fv_core.res.tile${tilestr}.nc
       tilefilein=${gesroot}/RESTART/${tilefile}.ges
       tilefileges=${gesroot}/RESTART/${tilefile}.ges
       tilefileout=${inputdirout}/ensmean/${tilefile}
       #${ncp} ${tilefilein} ${tilefileges}
       ${nln} ${tilefileges} ${tilefileout}

       itile=$((itile+1))
    done
    bkgtimest=$($NDATE ${bkgfreq} $bkgtimest)
done

# link ensemble member backgrounds
ensgesroot=${RotDir}/enkfgdas.${pyy}${pmm}${pdd}/${phh}/
bkgdatestr=${vdate_prefix}
imem=1
while [ ${imem} -le ${nmem} ]; do
    memstr="mem"`printf %03d $imem`
    mkdir -p ${inputdirout}/${memstr}
    couplerin=${ensgesroot}/${memstr}/RESTART/${bkgdatestr}.coupler.res.ges
    couplerges=${ensgesroot}/${memstr}/RESTART/${bkgdatestr}.coupler.res.ges
    couplerout=${inputdirout}/${memstr}/${bkgdatestr}.coupler.res
    #${ncp} ${couplerin} ${couplerges}
    ${nln} ${couplerin} ${couplerout}

    itile=1
    while [ ${itile} -le 6 ]; do
       tilestr=`printf %1i $itile`
    
       tilefile=${bkgdatestr}.fv_tracer.res.tile${tilestr}.nc
       tilefilein=${ensgesroot}/${memstr}/RESTART/${tilefile}.ges
       tilefileges=${ensgesroot}/${memstr}/RESTART/${tilefile}.ges
       tilefileout=${inputdirout}/${memstr}/${tilefile}
       #${ncp} ${tilefilein} ${tilefileges}
       ${nln} ${tilefileges} ${tilefileout}
    
       tilefile=${bkgdatestr}.fv_core.res.tile${tilestr}.nc
       tilefilein=${ensgesroot}/${memstr}/RESTART/${tilefile}.ges
       tilefileges=${ensgesroot}/${memstr}/RESTART/${tilefile}.ges
       tilefileout=${inputdirout}/${memstr}/${tilefile}
       #${ncp} ${tilefilein} ${tilefileges}
       ${nln} ${tilefileges} ${tilefileout}
    
       itile=$((itile+1))
    done
    imem=$((imem+1))
done

# link deterministic or mean analysis
analysisdir=${WorkDir}/analysis
mkdir -p ${analysisdir}
coupleranl=${gesroot}/RESTART/${vdate_prefix}.coupler.res
couplerwork=${analysisdir}/${vdate_prefix}.hyb-3dvar-gfs_aero.coupler.res
${nln} ${coupleranl} ${couplerwork}

itile=1
while [ ${itile} -le 6 ]; do
   tilestr=`printf %1i $itile`

   tilefile=fv_tracer.res.tile${tilestr}.nc
   tilefileanl=${gesroot}/RESTART/${vdate_prefix}.${tilefile}
   tilefilework=${analysisdir}/${vdate_prefix}.hyb-3dvar-gfs_aero.${tilefile}
   ${nln} ${tilefileanl} ${tilefilework}

   tilefile=fv_core.res.tile${tilestr}.nc
   tilefileanl=${gesroot}/RESTART/${vdate_prefix}.${tilefile}
   tilefilework=${analysisdir}/${vdate_prefix}.hyb-3dvar-gfs_aero.${tilefile}
   ${nln} ${tilefileanl} ${tilefilework}

   itile=$((itile+1))
done


#link executables
${nln} ${jediexe} ${WorkDir}/fv3jedi_var.x

# CRTM related things
#CRTMFix=${JEDIDir}"/fv3-jedi/test/Data/crtm/"
CRTMFix=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
#coeffs="AerosolCoeff.bin CloudCoeff.bin v.viirs-m_npp.SpcCoeff.bin v.viirs-m_npp.TauCoeff.bin"
coeffs="AerosolCoeff.bin CloudCoeff.bin v.modis_terra.SpcCoeff.bin v.modis_terra.TauCoeff.bin v.modis_aqua.SpcCoeff.bin v.modis_aqua.TauCoeff.bin"

mkdir -p ${WorkDir}/crtm/

for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}/${coeff} ${WorkDir}/crtm/${coeff}
done

# global additional files to link
coeffs=`ls ${CRTMFix}/NPOESS.* | awk -F "/" '{print $NF}'`
for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}/${coeff} ${WorkDir}/crtm/${coeff}
done

coeffs=`ls ${CRTMFix}/USGS.* | awk -F "/" '{print $NF}'`
for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}/${coeff} ${WorkDir}/crtm/${coeff}
done

coeffs=`ls ${CRTMFix}/FASTEM6.* | awk -F "/" '{print $NF}'`
for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}/${coeff} ${WorkDir}/crtm/${coeff}
done
