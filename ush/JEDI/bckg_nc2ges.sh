#!/bin/bash
# do hybrid observer.


dir1=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/workflow-clean-modis/dr-data/gdas.20160531/18/RESTART
#cd ${dir1}
#gesfiles=`ls *`
#for gesfile in ${gesfiles}
#do
#    echo ${gesfile}
#    mv ${gesfile} ${gesfile}.ges
#done

cd ${dir1}/..
mv gdas.t18z.atmf006.nc gdas.t18z.atmf006.nc.ges

nanals=20

if [ '1' == '1' ]; then

dir2=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/workflow-clean-modis/dr-data/enkfgdas.20160531/18

dir0=${dir2}/ensmean/RESTART
#cd ${dir0}
#gesfiles=`ls *`
#for gesfile in ${gesfiles}
#do
#    mv ${gesfile} ${gesfile}.ges
#done

cd ${dir0}/..
mv gdas.t18z.atmf006.nc gdas.t18z.atmf006.nc.ges

nanal=001
while [ ${nanal} -le ${nanals} ]; do
memdir=mem`printf %03d $nanal`
dir0=${dir2}/${memdir}/RESTART
#cd ${dir0}
#gesfiles=`ls *`
#for gesfile in ${gesfiles}
#do
#    mv ${gesfile} ${gesfile}.ges
#done

cd ${dir0}/..
mv gdas.t18z.atmf006.nc gdas.t18z.atmf006.nc.ges

nanal=$[$nanal+1]
done
fi

exit
