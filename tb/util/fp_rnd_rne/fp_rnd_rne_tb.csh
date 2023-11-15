#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xsc ../tb/util/fp_rnd_rne/fp_rnd_rne_tb.c 
xvlog --sv -svlog ../tb/util/fp_rnd_rne/fp_rnd_rne_tb.sv ../src/util/fp_rnd_rne.sv ../src/util/clz_i8.sv
xelab work.fp_rnd_rne_tb -sv_lib dpi -R

cd ..
