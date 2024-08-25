#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xsc ../tb/util/fp_rnd_nan_rne/fp_rnd_nan_rne_tb.c 
xvlog --sv -svlog ../tb/util/fp_rnd_nan_rne/fp_rnd_nan_rne_tb.sv ../src/util/rnd/fp_rnd_nan_rne.sv ../src/util/clz_int.sv
xelab work.fp_rnd_nan_rne_tb -sv_lib dpi -R

cd ..
