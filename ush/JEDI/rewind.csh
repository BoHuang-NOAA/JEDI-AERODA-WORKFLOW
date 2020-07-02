#!/bin/csh

module load rocoto/1.3.1
set currDir="/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/workflow-modis-fgat-onlyCenter/dr-work/"
set rocjob="workflow-modis-fgat-onlyCenter"

set incdate="/home/Bo.Huang/JEDI-2020/usefulScripts/incdate.sh"

set analdates='2016060312'
set analdatee='2016060400'

set tasks="gdasprepmet gdasprepchem gdascalcinc gdasanal gdaseupd gdasemeananl gdashxaodanl gdasfcst gdasemean cleandata"
set mtasks="gdasensprepmet gdasenscalcinc seasbinda2fcst gdasefmn seasbinfcst2da gdashxaod gdashxaodfgat"

set analdate=${analdates}

echo ${analdate}

while ($analdate <= ${analdatee})
   set ananame="${analdate}00"
   foreach task (${tasks})
       echo ${ananame}-${task}
       rocotorewind -w ${currDir}/${rocjob}.xml -d ${currDir}/${rocjob}.db -c ${ananame} -t ${task} 
   end
	
   foreach mtask (${mtasks})
       echo ${ananame}-${mtask}
       rocotorewind -w ${currDir}/${rocjob}.xml -d ${currDir}/${rocjob}.db -c ${ananame} -m ${mtask} 
   end

    set analdate=`$incdate $analdate 6`

end

echo "Completed successfully!!!"
exit
