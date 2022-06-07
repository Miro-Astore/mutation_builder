#!/bin/bash
#read in list in root directory formated as 
#resid segname target_res_name system_name
#eg
#1371  AP1     ARG G1371R

list_file="../list"
template_pdb="../truncated_system_ready_for_mutation.pdb"
template_psf="../truncated_system_ready_for_mutation.psf"
topfile="toppar/top_all36_prot.rtf"

rm -r build_files 

tempvmdc=$VMDNOCUDA 
tempvmdo=$VMDNOOPTIX 
export VMDNOCUDA=1 
export VMDNOOPTIX=1 

length=$(cat $list_file | grep -v ^\s*$ | wc -l)
for i in $(seq 1 $length); 
do
	resid=$(cat $list_file | grep -v ^\s*$ | sed  "$i q;d" | awk  '{print $1}')
	segname=$(cat $list_file | grep -v ^\s*$ | sed  "$i q;d" | awk  '{print $2}')
	resname=$(cat $list_file | grep -v ^\s*$ | sed  "$i q;d" | awk  '{print $3}')
	sysname=$(cat $list_file | grep -v ^\s*$ | sed  "$i q;d" | awk  '{print $4}')
        echo $resid
        echo $segname
        echo $resname
        echo $sysname

	#need to make this more sensible, find out how to parse command line arguments to vmd
	cat mutate_system.tcl | sed "s^TEMPLATEPDB^$template_pdb^g" | sed "s^TEMPLATEPSF^$template_psf^g"  | sed "s^RESID^$resid^g" | sed "s^SEGNAME^$segname^g" | sed "s^MUT^$resname^g" | sed "s^OUTNAME^$sysname^g" | sed "s^TOPFILE^$topfile^g" > /tmp/mutate_system.tcl
	mkdir -p ../mutated_systems/$sysname 
	vmd -dispdev text -e /tmp/mutate_system.tcl
	cwd=$(pwd)
        cp build_files/mutated_system.pdb ../mutated_systems/$sysname/$sysname.pdb
        cp build_files/mutated_system.psf ../mutated_systems/$sysname/$sysname.psf

	cd ../mutated_systems/$sysname/
	# now do gromacs things
	echo -e "0\n2\n1\n0" | gmx pdb2gmx -f $sysname.pdb -p topol.top -ff charmm36-mar2019 -ter -water tip3p -o $sysname.gro
	gmx editconf -f $sysname.gro -o centered.gro -c yes 

	cd $cwd
done
export VMDNOCUDA=$tempvmdc
export VMDNOOPTIX=$tempvmdo 
