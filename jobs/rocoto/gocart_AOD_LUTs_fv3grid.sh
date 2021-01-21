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

###############################################################
#  Set environment.
export VERBOSE=${VERBOSE:-"YES"}
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXECUTING $0 $* >&2
   set -x
fi

#  Directories.
pwd=$(pwd)
export NWPROD=${NWPROD:-$pwd}
export HOMEgfs=${HOMEgfs:-$NWPROD}
export HOMEjedi=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
export DATA=${DATA:-${DATAROOT}/hofx_aod.$$}
export COMIN=${COMIN:-$pwd}
export COMIN_OBS=${COMIN_OBS:-$COMIN}
export COMIN_GES=${COMIN_GES:-$COMIN}
export COMIN_GES_ENS=${COMIN_GES_ENS:-$COMIN_GES}
export COMIN_GES_OBS=${COMIN_GES_OBS:-$COMIN_GES}
export COMOUT=${COMOUT:-$COMIN}
export JEDIUSH=${JEDIUSH:-$HOMEgfs/ush/JEDI/}
export AODTYPE=${AODTYPE:-"VIIRS"}

# Base variables
CDATE=${CDATE:-"2001010100"}
CDUMP=${CDUMP:-"gdas"}
GDUMP=${GDUMP:-"gdas"}

# Derived base variables
GDATE=$($NDATE -$assim_freq $CDATE)
BDATE=$($NDATE -3 $CDATE)
PDY=$(echo $CDATE | cut -c1-8)
cyc=$(echo $CDATE | cut -c9-10)
bPDY=$(echo $BDATE | cut -c1-8)
bcyc=$(echo $BDATE | cut -c9-10)

# Utilities
export NCP=${NCP:-"/bin/cp"}
export NMV=${NMV:-"/bin/mv"}
export NLN=${NLN:-"/bin/ln -sf"}
export ERRSCRIPT=${ERRSCRIPT:-'eval [[ $err = 0 ]]'}

export AODEXEC=${AODEXEC:-${HOMEgfs}/exec/gocart_aod_fv3_mpi_LUTs.x}

# other variables
ntiles=${ntiles:-6}

export DATA=${DATA}/grp${ENSGRP}

mkdir -p $DATA && cd $DATA/

# link executables to working directory
$NLN $AODEXEC ./gocart_aod_fv3_mpi_LUTs.x
${NLN} ${HOMEjedi}/geos-aero/test/testinput/geosaod.rc ./geosaod.rc
${NLN} ${HOMEjedi}/geos-aero/test/testinput/Chem_MieRegistry.rc ./Chem_MieRegistry.rc
${NLN} ${HOMEjedi}/geos-aero/test/Data/*.nc ./

ndate1=${NDATE}
# hard coding some modules here...
module purge
module use -a /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/modules/
module load jedi-stack/intel-impi-18.0.5
module load nco ncview ncl
module list
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20201202/build/lib/"

### Determine sensor ID
if [ $AODTYPE = "VIIRS" ]; then
    sensorIDs="v.viirs-m_npp"
elif [ $AODTYPE = "MODIS" ]; then
    sensorIDs="v.modis_terra v.modis_aqua"
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi

### Determine cycle and bckg date
cyy=$(echo $CDATE | cut -c1-4)
cmm=$(echo $CDATE | cut -c5-6)
cdd=$(echo $CDATE | cut -c7-8)
chh=$(echo $CDATE | cut -c9-10)
cprefix="${cyy}${cmm}${cdd}.${chh}0000"

gyy=$(echo $GDATE | cut -c1-4)
gmm=$(echo $GDATE | cut -c5-6)
gdd=$(echo $GDATE | cut -c7-8)
ghh=$(echo $GDATE | cut -c9-10)
gprefix="${gyy}${gmm}${gdd}.${ghh}0000"

### Determine what to field to perform
allfields=""
testfile=${RotDir}/gdas.${gyy}${gmm}${gdd}/${ghh}/RESTART/${cprefix}.fv_tracer.res.tile1.nc.ges
if [ -s ${testfile} ]; then 
   allfields=${allfields}" cntlbckg"
fi

testfile=${RotDir}/gdas.${gyy}${gmm}${gdd}/${ghh}/RESTART/${cprefix}.fv_tracer.res.tile1.nc
if [ -s ${testfile} ]; then 
   allfields=${allfields}" cntlanal"
fi

testfile=${RotDir}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/ensmean/RESTART/${cprefix}.fv_tracer.res.tile1.nc.ges
if [ -s ${testfile} ]; then 
   allfields=${allfields}" ensmbckg"
fi

testfile=${RotDir}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/ensmean/RESTART/${cprefix}.fv_tracer.res.tile1.nc
if [ -s ${testfile} ]; then 
   allfields=${allfields}" ensmanal"
fi

### Loop all through allfields and sensorIDs
for isensorID in ${sensorIDs}; do
    
for ifield in ${allfields}; do
    if [ ${ifield} = "cntlbckg" -o ${ifield} = "cntlanal" ]; then
       fdirin=${RotDir}/gdas.${gyy}${gmm}${gdd}/${ghh}/RESTART/
       fdirout=${RotDir}/gdas.${gyy}${gmm}${gdd}/${ghh}/RESTART/
       mkdir -p ${fdirout}
    fi

    if [ ${ifield} = "ensmbckg" -o ${ifield} = "ensmanal" ]; then
       fdirin=${RotDir}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/ensmean/RESTART/
       fdirout=${RotDir}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/ensmean/RESTART/
       mkdir -p ${fdirout}
    fi
    
    fakbk=${cprefix}.fv_core.res.nc.ges
    for itile in $(seq 1 6); do
        fcore=${cprefix}.fv_core.res.tile${itile}.nc.ges
	if [ ${ifield} = "cntlanal" -o ${ifield} = "ensmanal" ]; then
           ftracer=${cprefix}.fv_tracer.res.tile${itile}.nc
	   faod=${cprefix}.fv_aod_LUTs.res.tile${itile}.nc
	else
           ftracer=${cprefix}.fv_tracer.res.tile${itile}.nc.ges
	   faod=${cprefix}.fv_aod_LUTs.res.tile${itile}.nc.ges
        fi

echo "########## Run fields "${ifield}"  in "${allfields}"##############"
echo ${fdirin}/${ftracer}
echo ${fdirout}/${faod}
cat << EOF > ${DATA}/gocart_aod_fv3_mpi.nl 	
&record_input
 input_dir = "${fdirin}"
 fname_akbk = "${fakbk}"
 fname_core = "${fcore}"
 fname_tracer = "${ftracer}"
 output_dir = "${fdirout}"
 fname_aod = "${faod}"
/
&record_model
 Model = "AodLUTs"
/
&record_conf_crtm
 AerosolOption = "aerosols_gocart_default"
 Absorbers = "H2O","O3"
 Sensor_ID = "${isensorID}"
 EndianType = "Big_Endian"
 CoefficientPath = ${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/
 Channels = 4
/
&record_conf_luts
 AerosolOption = "aerosols_gocart_merra_2"
 Wavelengths = 550.
 RCFile = "geosaod.rc"
/
EOF
        ${DATA}/gocart_aod_fv3_mpi.nl  
	srun --export=all ./gocart_aod_fv3_mpi_LUTs.x
	if [ $? -ne 0 ]; then
  	    echo "gocart_aod_fv3_mpi_LUTs failed an exit!!!"
   	    exit 1
	else
   	    /bin/rm -rf ${DATA}/gocart_aod_fv3_mpi.nl
	fi
        done # end for itile
done # end for ifield
done # end for isensorID
### 
###############################################################
# Postprocessing
cd $pwd
[[ $mkdata = "YES" ]] && rm -rf $DATA

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
