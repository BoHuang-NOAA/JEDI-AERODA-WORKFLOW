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

### Config ensemble hxaod calculation
export ENSEND=$((NMEM_EFCSGRP * ENSGRP))
export ENSBEG=$((ENSEND - NMEM_EFCSGRP + 1))

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

# Base variables
CDATE=${CDATE:-"2001010100"}
CDUMP=${CDUMP:-"gdas"}
GDUMP=${GDUMP:-"gdas"}
export CASE=${CASE_ENKF:-"C96"}


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

# other variables
ntiles=${ntiles:-6}

export DATA=${DATA}/grp${ENSGRP}

mkdir -p $DATA && cd $DATA/

ndate1=${NDATE}
# hard coding some modules here...
source /apps/lmod/7.7.18/init/bash
module purge
module use -a /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/modules/
module load jedi-stack/intel-impi-18.0.5

#export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/jedi/build/fv3-bundle/lib"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/HxAod-Mariusz/JEDI-Bin-Mariusz/fv3-bundle_old/lib"

export NDATE=${ndate1}

# do ensemble mean
if [ ${ENSGRP} -eq 1 ]; then
   export imem="0"
   $JEDIUSH/enkf_hofx_AOD_modis_fgat.sh
   err=$?
   if [ $err != 0 ]; then
      exit $err
   fi

   export imem="-1"
   $JEDIUSH/enkf_hofx_AOD_modis_fgat.sh
   err=$?
   if [ $err != 0 ]; then
      exit $err
   fi
fi

###############################################################
# need to loop through ensemble members if necessary
if [ $NMEM_AERO -gt 0 ]; then
  for mem0 in {${ENSBEG}..${ENSEND}}; do
    export imem=$mem0
    $JEDIUSH/enkf_hofx_AOD_modis_fgat.sh
  done
fi

err=$?

###############################################################
# Postprocessing
cd $pwd
[[ $mkdata = "YES" ]] && rm -rf $DATA

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
