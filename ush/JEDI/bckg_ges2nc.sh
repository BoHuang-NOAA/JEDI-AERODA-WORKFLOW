#!/bin/bash

files=`ls *.ges`

for file in ${files}
do
    echo ${file}
    filenew=`echo ${file} | rev | cut -d. -f2- | rev` 
    /bin/cp ${file} ${filenew}
done

exit
