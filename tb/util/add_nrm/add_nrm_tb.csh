#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xvlog --sv -svlog ../tb/util/add_nrm/add_nrm_tb.sv ../src/util/arith/add_nrm.sv ../src/util/clz_int.sv
xelab work.add_nrm_tb -R

cd ..
