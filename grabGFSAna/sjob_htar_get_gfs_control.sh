#!/bin/ksh --login
#SBATCH -J getgfs_c
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
heraTop=/scratch1/BMC/chem-var/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/dataSets/GFSSigio/control


#dateS=2016052500
#dateE=2016053118
dateS=2016060600
dateE=2016060918
dateInc=6
incdate=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate


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
    cd ${heraDay}

    hpssDay=${hpssTop}/

    #echo ${hpssDay}
    #echo ${hpssDay}/gpfs_hps_nco_ops_com_gfs_prod_gdas.${YMD}${HH}.tar
    #echo ${hpssDay}/com2_gfs_prod_gfs.${YMD}${HH}.anl.tar
    hpssFile=${hpssDay}/${YMD}${HH}${cdump}.tar
    atm=gfnanl.${cdump}.$dateL
    sfc=sfnanl.${cdump}.$dateL
    nst=nsnanl.${cdump}.$dateL

    htar -xvf ${hpssFile} ${atm}

    status=$?
    if [[ $status -eq 0 ]]; then
       echo "Yes" > ${heraTop}/cycle-${dateL}.txt
       #/bin/rm -rf ${heraTmp}/*
    else
       exit $status
    fi

    dateL=`${incdate} ${dateInc} ${dateL}`

done

exit 0
