#!/bin/ksh -x
###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
configs="base anal"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done


# Source machine runtime environment
. $BASE_ENV/${machine}.env anal 
status=$?
[[ $status -ne 0 ]] && exit $status

#Define local variable
JEDIDir=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
WorkDir=${DATA:-$DATAROOT/cnvtstate.$$}
#TemplateDir=
RotDir=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
validtime=${CDATE:-"2001010100"}
prevtime=$($NDATE -$assim_freq $CDATE)
cntlcase=${CASE:-"C384"} # no lower case
cntlres=`echo "$cntlcase" | tr '[:upper:]' '[:lower:]'`
cntlresc=$(echo $cntlres |cut -c2-5)
cntlresx=$((cntlresc+1))
cntlresy=$((cntlresc+1))
enscase=${CASE_ENKF:-"C96"} # no lower case
ensres=`echo "$enscase" | tr '[:upper:]' '[:lower:]'`
ensresc=$(echo $ensres |cut -c2-5)
ensresx=$((ensresc+1))
ensresy=$((ensresc+1))
BumpDir=${JEDIDir}/fv3-jedi/test/Data/bump/${CASE}/
FieldDir=${JEDIDir}/fv3-jedi/test/Data/fieldsets/
FV3Dir=${JEDIDir}/fv3-jedi/test/Data/fv3files/

cnvtexe=${JEDIDir}/bin/fv3jedi_convertstate.x

cdump=${CDUMP:-"gdas"}
nmem=${NMEM_AERO:-"10"}

ncp="/bin/cp -r"
nmv="/bin/mv -f"
nln="/bin/ln -sf"

mkdir -p ${WorkDir}


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

# Link files
${nln} ${FV3Dir}/fmsmpp.nml ${WorkDir}/fmsmpp.nml
${nln} ${FV3Dir}/field_table ${WorkDir}/field_table.input
${nln} ${FV3Dir}/akbk64.nc4 ${WorkDir}/akbk.nc
${nln} ${cnvtexe} ${WorkDir}/fv3jedi_convertstate.x

cntldir=${ROTDIR}/gdas.${pyy}${pmm}${pdd}/${phh}/RESTART
itile=1
while [ ${itile} -le 6 ]; do
    tilestr=`printf %1i $itile`
    tilefile=${vdate_prefix}.fv_tracer.res.tile${tilestr}.nc
    ${nln} ${cntldir}/${tilefile} ${WorkDir}/${tilefile}
    if [ $cntlcase != $enscase ]; then
	 tilefile1=${vdate_prefix}.${CASE_ENKF}.fv_tracer.res.tile${tilestr}.nc
	 ${nln} ${cntldir}/${tilefile1} ${WorkDir}/${tilefile1}
    fi       

    itile=$((itile+1))
done

coupfilein=${vdate_prefix}.coupler.res.ges
coupfileout=${vdate_prefix}.coupler.res
${nln} ${cntldir}/${coupfilein} ${WorkDir}/${coupfileout}

# define yaml file to generate

# create yaml file
cat << EOF > ${WorkDir}/fv3jedi_convertstate_gfs_aero.yaml
input geometry:
  nml_file_mpp: fmsmpp.nml
  trc_file: field_table.input
  akbk: ./akbk.nc
  layout: [1,1]
  io_layout: [1,1]
  npx: ${cntlresx}
  npy: ${cntlresy}
  npz: 64
  ntiles: 6
  fieldsets:
    - fieldset: ${FieldDir}/dynamics.yaml
    - fieldset: ${FieldDir}/aerosols_gfs.yaml
    - fieldset: ${FieldDir}/chemical_add_gfs.yaml
output geometry:
  trc_file: field_table.input
  akbk: ./akbk.nc
  layout: [1,1]
  io_layout: [1,1]
  npx: ${ensresx}
  npy: ${ensresy}
  npz: 64
  ntiles: 6
  fieldsets:
    - fieldset: ${FieldDir}/dynamics.yaml
    - fieldset: ${FieldDir}/aerosols_gfs.yaml
    - fieldset: ${FieldDir}/chemical_add_gfs.yaml
output variables: [bc1,bc2,oc1,oc2,
                   dust1,dust2,dust3,dust4,dust5,
                   seas1,seas2,seas3,seas4,seas5,
                   sulf,dms,msa,pp10,pp25,so2,
                   ice_wat,liq_wat,rainwat,snowwat,
                   sphum,o3mr,cld_amt,graupel]
states:
- input:
    filetype: gfs
    state variables: [bc1,bc2,oc1,oc2,
                      dust1,dust2,dust3,dust4,dust5,
                      seas1,seas2,seas3,seas4,seas5,
                      sulf,dms,msa,pp10,pp25,so2,
                      ice_wat,liq_wat,rainwat,snowwat,
                      sphum,o3mr,cld_amt,graupel]
    datapath: ./
    filename_trcr: ${vdate_prefix}.fv_tracer.res.nc
    filename_cplr: ${vdate_prefix}.coupler.res
  output:
    filetype: gfs
    datapath: ./
    filename_trcr: ${CASE_ENKF}.fv_tracer.res.nc
EOF


cd ${WorkDir}

if [ $cntlcase = $enscase ]; then
   err=0
else
    source /apps/lmod/7.7.18/init/ksh
    module purge
    module use -a /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/modules/
    module load jedi-stack/intel-impi-18.0.5
    module load nco ncview ncl
    module list
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20200817/build/lib/"

    srun --export=all -n6 fv3jedi_convertstate.x  fv3jedi_convertstate_gfs_aero.yaml fv3jedi_convertstate_gfs_aero.run
    err=$?
fi

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi

exit $err

