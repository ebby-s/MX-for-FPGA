#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xsc ../tb/util/shift_rnd_rne/shift_rnd_rne_tb.c 
xvlog --sv -svlog ../tb/util/shift_rnd_rne/shift_rnd_rne_tb.sv ../src/util/rnd/shift_rnd_rne.sv
xelab work.shift_rnd_rne_tb -sv_lib dpi -R

cd ..
