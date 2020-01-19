#!/bin/bash
#read in list in root directory formated as 
#resid segname target_res_name system_name
#eg
#1371  AP1     ARG G1371R
tempvmdc=$VMDNOCUDA 
tempvmdo=$VMDNOOPTIX 
export VMDNOCUDA=1 
export VMDNOOPTIX=1 

length=$(cat ../list | wc -l)
for i in $(seq 1 $length); 
do
	resid=$(cat ../list | sed  "$i q;d" | awk  '{print $1}'
	segname=$(cat ../list | sed  "$i q;d" | awk  '{print $2}'
	resname=$(cat ../list | sed  "$i q;d" | awk  '{print $3}'
	sysname=$(cat ../list | sed  "$i q;d" | awk  '{print $4}'

	vmd -dispdev text -e mutate_system.tcl
	# now do gromacs things
	echo -e "0\n1\n2\n0\nq" | gmx pdb2gmx -f build_files/mutated_system.pdb -p topol.top
done
export VMDNOCUDA=$tempvmdc
export VMDNOOPTIX=$tempvmdo 
