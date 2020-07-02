#!/bin/bash --login
#SBATCH -J getens_c
#SBATCH -A gsd-fv3-dev
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./%x.o%j
#SBATCH -e ./%x.e%j

module load hpss

#hpssTop=/NCEPPROD/hpssprod/runhistory/
oldexp=pr4rn_1605
cdump=gdas
hpssTop=/5year/NCEPDEV/emc-global/emc.glopara/WCOSS_C/${oldexp}
heraTop=/scratch1/BMC/chem-var/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/dataSets/GFSSigio/ensemble/
heraTmp=${heraTop}/tmp

#dateS=2016052500
#dateE=2016053118
#dateS=2016052000
#dateE=2016052418
dateS=2016060600
dateE=2016060918
dateInc=6
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate

nanal=40

mkdir -p ${heraTmp}
/bin/rm -rf ${heraTmp}/*

dateL=${dateS}

while [ ${dateL} -le ${dateE} ]; do
    echo ${dateL}

    YY=`echo ${dateL} | cut -c1-4`
    MM=`echo ${dateL} | cut -c5-6`
    DD=`echo ${dateL} | cut -c7-8`
    HH=`echo ${dateL} | cut -c9-10`

    YM=${YY}${MM}
    YMD=${YY}${MM}${DD}

    heraDay=${heraTop}/${dateL}
    mkdir -p ${heraDay}
    cd ${heraTmp}

    hpssDay=${hpssTop}/

    #echo ${hpssDay}/gpfs_hps_nco_ops_com_gfs_prod_enkf.${YMD}_${HH}.anl.tar
    #htar -xvf ${hpssDay}/gpfs_hps_nco_ops_com_gfs_prod_enkf.${YMD}_${HH}.anl.tar "./*mem0[0-4]?.nemsio"

    hpssFile=${hpssDay}/${dateL}${cdump}.enkf.anl.tar
    echo ${hpssFile}

    #htar -xvf ${hpssFile} *_mem0[0-4]?
    hsi get ${hpssFile}
    tar -xvf ${dateL}${cdump}.enkf.anl.tar
if [[ $? -eq  0 ]]; then
    ianal=1
    while [ ${ianal} -le ${nanal} ]; do
       memDir=mem`printf %03i $ianal`
       heraMem=${heraDay}/${memDir}
       mkdir -p ${heraMem}
       echo ${heraMem}
       /bin/mv *_${memDir} ${heraMem}/
       ianal=$[$ianal+1]
    done

    status=$?
    if [[ $status -eq 0 ]]; then
       echo "Yes" > ${heraTop}/cycle-${dateL}.txt
       /bin/rm -rf ${heraTmp}/*
    else
       exit $status
    fi

    dateL=`${incdate} ${dateInc} ${dateL}`
else
    exit $?
fi
done

exit 0
