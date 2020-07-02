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

# other variables
ntiles=${ntiles:-6}

export DATA=${DATA}/grp${ENSGRP}

mkdir -p $DATA && cd $DATA/

# do ensemble mean first
if [ $NMEM_AERO -gt 0 ]; then
if [ ${ENSGRP} -eq 1 ]; then
  export imem="0"
  for n in $(seq 1 6); do
    export itile=$n
    $JEDIUSH/run_seasBin_da2fcst_fgat.sh
  done

  export imem="-1"
  for n in $(seq 1 6); do
    export itile=$n
    $JEDIUSH/run_seasBin_da2fcst_fgat.sh
  done
fi
fi

###############################################################
# need to loop through ensemble members if necessary
if [ $NMEM_AERO -gt 0 ]; then
  #for mem0 in {1..$NMEM_AERO}; do
  for mem0 in {${ENSBEG}..${ENSEND}}; do
    export imem=$mem0
    # need to generate files for each tile 1-6
    for n in $(seq 1 6); do
        export itile=$n
	$JEDIUSH/run_seasBin_da2fcst_fgat.sh
    done
    err=$?
  done
fi

###############################################################
# Postprocessing
cd $pwd
[[ $mkdata = "YES" ]] && rm -rf $DATA

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
