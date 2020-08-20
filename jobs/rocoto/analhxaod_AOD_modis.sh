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

#export AODEXEC=${AODEXEC:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec/gocart_aod_fv3_mpi.x}
#export HOFXEXEC=${HOFXEXEC:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec_hack/fv3aod2obs.x}
#export HOFXEXEC=${HOFXEXEC:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec/fv3aod2obs.x}
#export HOFXEXEC=${HOFXEXEC:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec/fv3aod2obs.x}

#export AODEXEC=${AODEXEC:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec_bo/gocart_aod_fv3_mpi.x}
#export HOFXEXEC=${HOFXEXEC:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/pagowski/exec_bo/fv3aod2obs.x}
export AODEXEC=${AODEXEC:-${HOMEgfs}/exec/gocart_aod_fv3_mpi.x}
export HOFXEXEC=${HOFXEXEC:-${HOMEgfs}/exec/fv3aod2obs.x}

# other variables
ntiles=${ntiles:-6}

export DATA=${DATA}/grp${ENSGRP}

mkdir -p $DATA && cd $DATA/

# link executables to working directory
$NLN $AODEXEC ./aod_fv3tile.x
$NLN $HOFXEXEC ./aod_ens_hofx.x

ndate1=${NDATE}
# hard coding some modules here...
module purge
#module use -a /scratch1/NCEPDEV/da/Daniel.Holdaway/opt/modulefiles
#module load apps/jedi/intel-19.0.5.281
module use -a /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/modules/
module load jedi-stack/intel-impi-18.0.5
module load nco ncview ncl
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/home/Mariusz.Pagowski/mapp_2018/libs/fortran-datetime/lib"
export NDATE=${ndate1}

# do deterministic first
# do we need this for this case? I think no
#export imem=0
## need to generate files for each tile 1-6
#for n in $(seq 1 6); do
#  # create namelist from Python script  
#  export itile=$n
#  $JEDIUSH/gen_nml_gocart_aod.py 
#  # run the executable
#  srun --export=all $AODEXEC
#done

sensors="v.modis_terra v.modis_aqua"
# do cntl analysis first
export CASE=${CASE:-"C96"}
export imem="-1"
for sensor in ${sensors}; do
    export sensorID=${sensor}
    for n in $(seq 1 6); do
        # create namelist from Python script  
        export itile=$n
        $JEDIUSH/gen_nml_gocart_anal_AOD_modis.sh
        cat gocart_aod_fv3_mpi.nl
        # run the executable
        srun --export=all ./aod_fv3tile.x 
    done
    # compute H(x) and put it in the obs files
    $JEDIUSH/setup_ens_aodhofx_anal_AOD_modis.sh
    ./aod_ens_hofx.x
    err=$?
    if [ ${err} != 0 ]; then
       exit ${err}
    fi
    /bin/rm -rf gocart_aod_fv3_mpi.nl fv3aod2obs.nl
done

# do ensemble mean analysis first
export CASE=${CASE_ENKF:-"C96"}
export imem="0"
for sensor in ${sensors}; do
    export sensorID=${sensor}
    for n in $(seq 1 6); do
        # create namelist from Python script  
        export itile=$n
        $JEDIUSH/gen_nml_gocart_anal_AOD_modis.sh
        cat gocart_aod_fv3_mpi.nl
        # run the executable
        srun --export=all ./aod_fv3tile.x 
    done
    # compute H(x) and put it in the obs files
    $JEDIUSH/setup_ens_aodhofx_anal_AOD_modis.sh
    ./aod_ens_hofx.x
    err=$?
    if [ ${err} != 0 ]; then
       exit ${err}
    fi
    /bin/rm -rf gocart_aod_fv3_mpi.nl fv3aod2obs.nl
done

err=$?

###############################################################
# need to loop through ensemble members if necessary
###############################################################
# Postprocessing
cd $pwd
[[ $mkdata = "YES" ]] && rm -rf $DATA

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
