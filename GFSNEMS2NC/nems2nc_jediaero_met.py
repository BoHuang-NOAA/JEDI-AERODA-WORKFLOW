#!/usr/bin/env python
import subprocess
import os
import datetime
import multiprocessing

startdate = datetime.datetime(2016,6,6,0)
enddate = datetime.datetime(2016,6,9,18)
execcnvt = '/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow-clean/exec//nemsioatm2nc'
# NEMSIO file directory downloaded from grabGFSAna
nemsDir = '/scratch1/BMC/chem-var/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/dataSets/GFSSigio/'
#ncDir = '/scratch1/BMC/chem-var/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/dataSets/GFSNetCDF/'
ncDir = '/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/dataSets/ICs/L64/'
RootMP=nemsDir
RootMe=ncDir

nproc = multiprocessing.cpu_count()
nmems = 40

infiles = []
outfiles = []
nowdate = startdate

def run_convert(idx):
  #command = execcnvt+' '+infiles[idx]+' '+outfiles[idx] # uncompressed 
  command = execcnvt+' '+infiles[idx]+' '+outfiles[idx]+' 14 1' # compression like GFSv16
  print(command)
  err = subprocess.check_call(command, shell=True)
  print(command,err)

while nowdate <= enddate:
  
  infiles.append(RootMP+'/control/'+nowdate.strftime('%Y%m%d%H')+
                 #'/gdas.t'+nowdate.strftime('%H')+'z.atmanl.nemsio') 
                 '/gfnanl.gdas.'+nowdate.strftime('%Y%m%d%H')) 
  #outfiles.append(RootMe+'/control/'+nowdate.strftime('%Y%m%d%H')+'/gdas.t'+nowdate.strftime('%H')+'z.atmanl.nc') 
  outfiles.append(RootMe+'/'+nowdate.strftime('%Y%m%d%H')+'/control/gdas.t'+nowdate.strftime('%H')+'z.atmanl.nc') 
  try:
    #os.makedirs(RootMe+'/control/'+nowdate.strftime('%Y%m%d%H')+'/')
    os.makedirs(RootMe+'/'+nowdate.strftime('%Y%m%d%H')+'/control/')
  except:
    pass
  for mem in range(1,nmems+1):
    memstr = "mem{0:03d}".format(mem)
  
    infiles.append(RootMP+'/ensemble/'+nowdate.strftime('%Y%m%d%H')+'/'+memstr+
                   #'/gdas.t'+nowdate.strftime('%H')+'z.ratmanl.'+memstr+'.nemsio')
                    '/siganl_'+nowdate.strftime('%Y%m%d%H') + '_' + memstr) 
    #outfiles.append(RootMe+'/ensemble/'+nowdate.strftime('%Y%m%d%H')+'/'+memstr+'/gdas.t'+nowdate.strftime('%H')+'z.atmanl.nc') 
    outfiles.append(RootMe+'/'+nowdate.strftime('%Y%m%d%H')+'/ensemble/'+memstr+'/gdas.t'+nowdate.strftime('%H')+'z.atmanl.nc') 
    try:
      #os.makedirs(RootMe+'/ensemble/'+nowdate.strftime('%Y%m%d%H')+'/'+memstr+'/')
      os.makedirs(RootMe+'/'+nowdate.strftime('%Y%m%d%H')+'/ensemble/'+memstr+'/')
    except:
      pass
    
  nowdate = nowdate + datetime.timedelta(hours=6)

p = multiprocessing.Pool(nproc)
p.map(run_convert,range(0,len(infiles)))
p.close()
p.join()
