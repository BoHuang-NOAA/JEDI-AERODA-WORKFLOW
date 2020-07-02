#!/bin/ksh
datestring=$analdate
datapath="$ANALDIR"
fgfileprefixes=${yyyymmdd}.${hh}0000
anlfileprefixes=${yyyymmdd}.${hh}0000.anal
analpertwtnh=0.85
analpertwtsh=0.85
analpertwttr=0.85
analpertwtnh_rtpp=0.0
analpertwtsh_rtpp=0.0
analpertwttr_rtpp=0.0
zhuberleft=1.e10
zhuberright=1.e10
huber=.false.
lupd_satbiasc=.false.
varqc=.false.
covinflatemax=1.e2
covinflatemin=1.0
pseudo_rh=.true.
corrlengthnh=2500
corrlengthsh=2500
corrlengthtr=2500
obtimelnh=1.e30
obtimelsh=1.e30
obtimeltr=1.e30
iassim_order=0
lnsigcutoffnh=1.25
lnsigcutoffsh=1.25
lnsigcutofftr=1.25
lnsigcutoffsatnh=2.00
lnsigcutoffsatsh=2.00
lnsigcutoffsattr=2.00
lnsigcutoffpsnh=1.25
lnsigcutoffpssh=1.25
lnsigcutoffpstr=1.25
simple_partition=.true.
nlons=0
nlats=0
smoothparm=-35
readin_localization=.false.
saterrfact=1.0
numiter=1
sprd_tol=1.e30
paoverpb_thresh=0.99
letkf_flag=.false.
use_qsatensmean=.false.
npefiles=5
lobsdiag_forenkf=.false.
netcdf_diag=.true.
reducedgrid=.false.
nlevs=$nlevs
nanals=$nanals
deterministic=.true.
write_spread_diag=.true.
fv3_native=.true.
sortinc=.true.
univaroz=.true.
univartracers=.true.
massbal_adjust=.false.
nhr_anal=$cycle_frequency
nhr_state=$cycle_frequency
use_gfs_nemsio=.false.
adp_anglebc=.true.
angord=4
newpc4pred=.false.
use_edges=.false.
emiss_bc=.false.
biasvar=-500
write_spread_diag=.true.
regional=.false.
fv3fixpath="${FIXDIR}/"
nx_res=${resx}
ny_res=${resy}
l_pres_add_saved=.false.
sattypes_aod1="aod_viirs"

