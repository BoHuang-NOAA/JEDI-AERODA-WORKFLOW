This document describes steps of preparing,  setting-up and running this workflow of performing aerosol data 
assimilation of viirs and modis AOD observation on Hera machine 
--- Bo Huang (bo.huang@noaa.gov)
--- June 12 2020

(0) Notes
	(0.1) In this package, fix and exec dicrectories were linked to their corresponding directories at 
	/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow
	(0.2) All the hard linked files in the scripts/codes are available at Hera. 
	(0.3) Additional functions are under development and will be integrated into this package as along. The following 
	      steps introduce the general steps of preparing and setting up, running this workflow. 

(1) Prepare IC for the first cycle during the model spin-up
	(1.1) global-workflow-clean/getGFSIC
	(1.2) It grabs GFS control and ensemble analysis files at $CDATE (e.g., 2015121000 in your experiment) cycle 
	      from HPSS, and converts them to ${CASE_HIGH} for the control and ${CASE_ENKF} for the ensemble. These 
	      converted files will be sotred in enkfgdas.* and gdas.* directories. They have  six tiles at NETCDF 
	      format and will be used to initialize a cold-start run.
	(1.3) Depending on the analysis time, GFS analysis files are located at different pans/directories on HPSS. It 
	      is specified in the script. This script shall be able to detect the location automatically based on 
	      ${CDATE}. As for the ensemble analysis files, their name convention starts with either sanl* or siganl* 
	      that vary with analysis time. Please take a look at the files first and modify accordingly in the script 
	      if needed.

(2) Prepare GFS control and ensemble analysis files at NEMSIO format for Met increment calculation in the model spin-up 
    and DA cycling
	(2.1) global-workflow-clean/grabGFSAna
	(2.2) It downloads GFS control and ensemble analysis files at NEMSIO format from HPSS. These files will be first
	      converted to NETCDF format in (3) and used for Met increment calculation during the model spin-up and DA 
	      cycling.
	(2.3) As mentioned in (1.3), their location on HPSS varies with analysis time. Refer to the script in (1) for 
	      their location at a particular ${CDATE} and change $oldexp and $hpssTop in the scripts here accordingly. 
	      The ensemble analysis files have different name conventions as well at different analysis time (e.g., 
	      sanl* versus siganl*). Please take a look first and modify accordingly in the scripts.

(3) Convert GFS NEMSIO analysis files in (2) to NETCDF
	(3.1) global-workflow-clean/GFSNEMS2NC
	(3.2) Since GFS NEMSIO analysis files in (2) may have different names that vary with analysis time, modify 
	      accordingly in the python script. 
	(3.3) After running nems2nc_jediaero_met.sh, the generated files are organized as ${ICDIR}/$CDATE/control (ensemble) 
	      ($CDATE is the analysis cycle, ${ICDIR} defined in dr-work-modis/*.xml).

(4) Workflow for model spin-up and DA cycling
	(4.1) global-workflow-clean/dr-work-* (rocoto job flow)
		(4.1.a) dr-work-modis (dr-work-modis-enkfFGAT) for assimilation of MODIS AOD obs from aqua and terra satellites 
		        without (with) applying FGAT in the AOD hofx calculation in the EnVar and EnKF update.
		(4.1.b) dr-work-viirs (dr-work-viirs-enkfFGAT) for assimilation of VIIRS AOD obs from snpp satellites 
		        without (with) applying FGAT in the AOD hofx calculation in the EnVar and EnKF update.
	(4.2) it contains a a rocotol xml file (jedi-3denvar-aeroDA-modis.xml) and general configuration files (config.*).
		(4.2.a) In the beginning of *.xml file, it defines the cycling period and the directory for observations,		         
		        model, etc.
		(4.2.b) To set up your running directory, ${PSLOT}, ${TOPRUNDIR} need to be defined in *.xml file.
		(4.2.c) ${TOPICDIR}/ICs/L64 (${ICSDIR}) defines the path of the converted NetCDF analysis files of GFS 
		        control and esnemble in (3). Only ${TOPICDIR} needs to be defined in the *.xml file. To be 
			consistent with the scripts of the workflow, please refer the below example to rename/organize 
			the converted NetCDF analysis files in (3)
				/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/dataSets/ICs/L64/2016051118
		(4.2.d) ${TOPOBSDIR} defines the path of observations. 
		(4.4.e) ${HOMEgfs} gives the full path of this workflow package.
		(4.2.f) The following of the *.xml file defeine the step-by-step tasks including 
			(f1)  gdasprepmet and gdasensprepmet: converted  GFS NetCDF analyses files in (3) to resolutions
			          of a particular experiment for Met analysi increment calculation in f3.
			(f2)  gdasprepchem: prepare emission files for later control and ensemble forecasts in f8;
			(f3)  gdascalcinc and gdasenscalcinc: calculate the control and ensemble Met analysis increments;
			(f4)  gdasanal and gdaseupd: perform envar and enkf aerosol update;
			(f5)  gdasemeananl: calculate ensemble mean of aerosol analysis;
			(f6)  gdashxaodanl: calculate AOD hofx of control and ensemble mean aerosol analysis;
			(f7)  seasbinda2fcst: change the sea salt bin orders from the GOCART model (e.g., analysis files)			           
			          to FV3 model (e.g., backgorund files) for the following background forecast in f8;
			(f8)  gdasfcst and gdasefmn: run control and ensemble background forecasts;
			(f9)  gdasemean: calculate background ensemble emean;
                        (f10) seasbinfcst2da: change the sea salt bin orders from FV3 model to the GOCART model for the 
			          envar and enkf update in next cycle;
			(f11) gdashxaod: calculate AOD hofx of control and ensemble aerosol background;
			(f12) gdashxaodfgat: calculate FGAT AOD hofx of control and ensemble aerosol background which will 
			          be used in gdaseupd with FGAT in (f4);
			(f13) cleandata: clean up unnecessary data and backup to HPSS.

		(4.2.g) To configure your own experiment, please modify accordingly in the configuration files 
			(e.g., config.base, config.anal, etc). 
		(4.2.h) After ${PSLOT}, ${TOPRUNDIR} are defined in (4.2.b), create the directory and copy dr-work-modis
			directory as ${TOPRUNDIR}/${PSLOT}/dr-work.  
		(4.2.i) Create ${TOPRUNDIR}/${PSLOT}/dr-data, and copy the initial condition directory (e.g., enkfgdas.*
		        and gdas.* in (1)) there. This directory will be used to store the data of the cycling. 
		(4.2.g) About rococo job submission, please refer to the following website 
				https://github.com/christopherwharrop/rocoto/wiki/Documentation
	(4.3) The required scirpts for cycling are stored in global-workflow-clean/ush, scripts and required executables
	      are at global-workflow-clean/exec
	(4.4) To run free-forecast or spin-up without DA (e.g.,2015121000-2015123118), the same workflow applies by 
	      turning off gdasanal,gdaseupd, gdasemeananl, gdashxaodanl, seasbinda2fcst, seasbinfcst2da and gdashxaod, 
	      and modifying the dependency accordingly. 
