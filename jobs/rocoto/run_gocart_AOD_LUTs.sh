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
export BDATE=$($NDATE -3 $CDATE)
PDY=$(echo $CDATE | cut -c1-8)
cyc=$(echo $CDATE | cut -c9-10)
bPDY=$(echo $BDATE | cut -c1-8)
bcyc=$(echo $BDATE | cut -c9-10)

# Utilities
export NCP=${NCP:-"/bin/cp"}
export NMV=${NMV:-"/bin/mv"}
export NLN=${NLN:-"/bin/ln -sf"}
export ERRSCRIPT=${ERRSCRIPT:-'eval [[ $err = 0 ]]'}

export DATA=${DATA}/grp${ENSGRP}

mkdir -p $DATA && cd $DATA/

ndate1=${NDATE}
# hard coding some modules here...
source /apps/lmod/7.7.18/init/bash
module purge
module use -a /scratch1/NCEPDEV/jcsda/Ryan.Honeyager/jedi/modules/
module load jedi-stack/intel-impi-18.0.5
module load nco ncview ncl
module list
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20201202/build/lib/"

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

#first processror to process cntl and ensmean bckg/anal
if [ ${ENSGRP} -eq 1 ]; then
    testfile=${ROTDIR}/gdas.${gyy}${gmm}${gdd}/${ghh}/RESTART/${cprefix}.fv_tracer.res.tile1.nc.ges
    #testfile=${ROTDIR}/gdas.${gyy}${gmm}${gdd}/${ghh}/${cprefix}.fv_tracer.res.tile1.nc.ges
    if [ -s ${testfile} ]; then
       allfields=${allfields}" cntlbckg"
    fi

    testfile=${ROTDIR}/gdas.${gyy}${gmm}${gdd}/${ghh}/RESTART/${cprefix}.fv_tracer.res.tile1.nc
    #testfile=${ROTDIR}/gdas.${gyy}${gmm}${gdd}/${ghh}/${cprefix}.fv_tracer.res.tile1.nc
    if [ -s ${testfile} ]; then
       allfields=${allfields}" cntlanal"
    fi

    testfile=${ROTDIR}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/ensmean/RESTART/${cprefix}.fv_tracer.res.tile1.nc.ges
    #testfile=${ROTDIR}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/ensmean/${cprefix}.fv_tracer.res.tile1.nc.ges
    if [ -s ${testfile} ]; then
       allfields=${allfields}" ensmbckg"
    fi

    testfile=${ROTDIR}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/ensmean/RESTART/${cprefix}.fv_tracer.res.tile1.nc
    #testfile=${ROTDIR}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/ensmean/${cprefix}.fv_tracer.res.tile1.nc
    if [ -s ${testfile} ]; then
       allfields=${allfields}" ensmanal"
    fi
fi

# all processros combined to process all members
testfile=${ROTDIR}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/mem001/RESTART/${cprefix}.fv_tracer.res.tile1.nc.ges
#testfile=${ROTDIR}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/mem001/${cprefix}.fv_tracer.res.tile1.nc.ges
if [ -s ${testfile} ]; then
   allfields=${allfields}" emembckg"
fi

testfile=${ROTDIR}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/mem001/RESTART/${cprefix}.fv_tracer.res.tile1.nc
#testfile=${ROTDIR}/enkfgdas.${gyy}${gmm}${gdd}/${ghh}/mem001/${cprefix}.fv_tracer.res.tile1.nc
if [ -s ${testfile} ]; then
   allfields=${allfields}" ememanal"
fi

echo "allfields= "${allfields}


for ifield in ${allfields}; do
    if [ ${ifield} = "cntlbckg" -o ${ifield} = "cntlanal" ]; then
        enkfopt=""
    else
        enkfopt="enkf"
    fi

    if [ ${ifield} = "cntlbckg" -o ${ifield} = "cntlanal" ]; then
        memopt=""
    elif [ ${ifield} = "ensmbckg" -o ${ifield} = "ensmanal" ]; then
        memopt="ensmean"
    else
	memopt="mem"
    fi

    if [ ${ifield} = "cntlanal" -o ${ifield} = "ensmanal" -o ${ifield} = "ememanal" ]; then
       export trcr_suffix=""
    else
       export trcr_suffix=".ges"
    fi

    if [ ${ifield} = "emembckg" -o ${ifield} = "ememanal" ]; then
       for imem in {${ENSBEG}..${ENSEND}}; do
	   memstr=`printf %03d $imem`
           export gdatadir=${ROTDIR}/${enkfopt}gdas.${gyy}${gmm}${gdd}/${ghh}/${memopt}${memstr}/RESTART/
           #export gdatadir=${ROTDIR}/${enkfopt}gdas.${gyy}${gmm}${gdd}/${ghh}/${memopt}${memstr}/
           export hofxdir=${ROTDIR}/${enkfopt}gdas.${cyy}${cmm}${cdd}/${chh}/${memopt}${memstr}/obs
	   mkdir -p  ${hofxdir}
	   echo "Running run_hofx_nomodel_AOD_LUTs for "${ifield}-${trcr_suffix}
	   echo ${gdatadir}
	   echo ${hofxdir}
	   echo "Running run_hofx_nomodel_AOD_LUTs.sh"
           $JEDIUSH/run_hofx_nomodel_AOD_LUTs.sh
	   err1=$?
           
	   echo "Running run_AOD_LUTs_fv3grid.sh"
           $JEDIUSH/run_AOD_LUTs_fv3grid.sh
	   err2=$?

	   if [ $err1 -ne 0 -o $err2 -ne 0 ]; then
	      echo "run_hofx_nomodel_AOD_LUTs failed and exit"
	      echo ${gdatadir}
	      err=1
	      exit $err
	   else
	      /bin/rm -rf ${DATA}/*
	   fi
       done
    else
       export gdatadir=${ROTDIR}/${enkfopt}gdas.${gyy}${gmm}${gdd}/${ghh}/${memopt}/RESTART/
       #export gdatadir=${ROTDIR}/${enkfopt}gdas.${gyy}${gmm}${gdd}/${ghh}/${memopt}/
       export hofxdir=${ROTDIR}/${enkfopt}gdas.${cyy}${cmm}${cdd}/${chh}/${memopt}/obs
       mkdir -p ${hofxdir}
       echo "Running run_hofx_nomodel_AOD_LUTs for "${ifield}-${trcr_suffix}
       echo ${gdatadir}
       echo ${hofxdir}
       echo "Running run_hofx_nomodel_AOD_LUTs.sh"
       $JEDIUSH/run_hofx_nomodel_AOD_LUTs.sh
       err1=$?

       echo "Running run_AOD_LUTs_fv3grid.sh"
       $JEDIUSH/run_AOD_LUTs_fv3grid.sh
       err2=$?

       if [ $err1 -ne 0 -o $err2 -ne 0 ]; then
           echo "run_hofx_nomodel_AOD_LUTs failed and exit"
           echo ${gdatadir}
	   err=1
           exit $err
       else
           /bin/rm -rf ${DATA}/*
       fi
    fi
done

###############################################################
# Postprocessing
cd $pwd
#[[ $mkdata = "YES" ]] && rm -rf $DATA

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
