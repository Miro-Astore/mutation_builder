#
#separate template system into components, protein and not protein, make new psf mutate and then merge 

#make directory for temporary files if it doesn't exist

file mkdir build_files
file mkdir build_files/ions

#mol new ../final_wt_ionized_added_loops_no_ters_cter_modelled_use_this_gmx_ready.psf
#mol addfile ../final_wt_ionized_added_loops_no_ters_cter_modelled_use_this_gmx_ready.pdb

mol new TEMPLATEPSF
mol addfile TEMPLATEPDB

set sel [atomselect top "protein"]

$sel writepsf build_files/prot.psf 
$sel writepdb build_files/prot.pdb 
package require psfgen
foreach i $segnames { 
segment $i { 
	pdb build_files/$i.pdb
	first NONE
	last NONE
}  
coordpdb build_files/$i.pdb $i
}


#readpsf build_files/BP1.psf
#coordpdb build_files/BP1.pdb
guesscoord
regenerate angles dihedrals

writepdb build_files/mutated_prot.pdb
writepsf build_files/mutated_prot.psf


set sel [atomselect top "not protein"]
$sel set segname D
$sel set segid D

$sel writepsf build_files/not_prot.psf
$sel writepdb build_files/not_prot.pdb
mol delete all 

mol new build_files/not_prot.psf 
mol addfile build_files/not_prot.pdb 
set sel [atomselect top all]
set residue_list [lsort -uniq [ $sel get residue ]]
echo $residue_list
foreach res $residue_list {
    set res_sel [atomselect top "residue $res"]
    set temp_res [expr $res + 1]
    $res_sel set resid $temp_res
}

set sel [atomselect top all ]
$sel writepsf build_files/not_prot.psf
$sel writepdb build_files/not_prot.pdb

mol delete all 

package require mutator 
mutator -psf build_files/prot.psf -pdb build_files/prot.pdb -o build_files/mutated_prot -ressegname SEGNAME -resid RESID -mut MUT

#mol delete all
mol new build_files/mutated_prot.psf
mol addfile build_files/mutated_prot.pdb
set sel [atomselect top "name CA and protein"]
set segnames [lsort -unique [$sel get segname]]
foreach i $segnames { 
	set sel [atomselect top "segname $i"]
	$sel writepsf build_files/$i.psf 
	$sel writepdb build_files/$i.pdb 
}
#we have to remake the psf file in case the termini of the protein was changed by the mutator plugin.

package require psfgen 
resetpsf 

topology TOPFILE
pdbalias atom ILE CD1 CD 

#readpsf build_files/AP1.psf
#coordpdb build_files/AP1.pdb
foreach i $segnames { 
segment $i { 
	pdb build_files/$i.pdb
	first NONE
	last NONE
}  
coordpdb build_files/$i.pdb $i
}


#readpsf build_files/BP1.psf
#coordpdb build_files/BP1.pdb
guesscoord
regenerate angles dihedrals

writepdb build_files/mutated_prot.pdb
writepsf build_files/mutated_prot.psf

#writepsf OUTNAME.psf
#writepdb OUTNAME.pdb

resetpsf
topology toppar/top_all36_lipid.rtf
topology toppar/top_all36_cgenff.rtf
topology toppar/toppar_water_ions.str

segment D {
	pdb build_files/not_prot.pdb
	first NONE
	last NONE
}  
coordpdb build_files/not_prot.pdb D

guesscoord

regenerate angles dihedrals 

writepsf build_files/not_prot.psf
writepdb build_files/not_prot.pdb

resetpsf

readpsf build_files/mutated_prot.psf 
readpsf build_files/not_prot.psf

coordpdb build_files/mutated_prot.pdb
coordpdb build_files/not_prot.pdb

writepsf build_files/mutated_system.psf
writepdb build_files/mutated_system.pdb

resetpsf
mol delete all 
#gromacs likes different things in different chains so we write the ligands into different chains, starting with ions
#
mol new build_files/mutated_system.psf
mol addfile build_files/mutated_system.pdb waitfor all
set sel [atomselect top "chain D and ion"]
$sel set chain C 
$sel set segname C 
$sel set segid C 

set sel [atomselect top "chain D and lipid"]
$sel set chain D 
$sel set segname D 
$sel set segid D 


set sel [atomselect top "chain D and resname ATP"]
$sel set chain E 
$sel set segname E 
$sel set segid E 

set sel [atomselect top all]
$sel writepsf build_files/mutated_system.psf
$sel writepdb build_files/mutated_system.pdb


###psf finished now we need to remerge everything
###mol delete all 
###mol new build_files/mutated_prot.psf
###mol addfile build_files/mutated_prot.pdb
###
###set sel [atomselect top "all"]
###
###
###$sel writepsf 
#### do ionization as normal  ## NB this method will assume that the termini added by gromacs will be overall neutral make sure when you add an extra charge if the termini is going to be 
###package require autoionize
###autoionize -psf build_files/mutated_system.psf -pdb build_files/mutated_system.pdb -neutralize -cation POT -anion CLA -o build_files/ionized
###
##
###now we have to re order everything so gromacs doesn't complain that our index groups aren't contiguous
###we need to renumber the residues as well else they will still be out of order
##mol delete all
##mol new build_files/ionized.psf 
##mol addfile build_files/ionized.pdb
##set sel [atomselect top "segname \"ION.*\""]
##set names [$sel get name]
##set names [ lsort -unique $names ]
##set sel_not_ion [atomselect top "not segname \"ION.*\""]
##$sel_not_ion writepsf build_files/not_ions.psf
##$sel_not_ion writepdb build_files/not_ions.pdb
##puts $names
##set seed_id 1
##foreach name $names {
##	puts $name
##	mol delete all 
##	mol new build_files/ionized.psf 
##	mol addfile build_files/ionized.pdb
##	set ionsel [atomselect top "segname \"ION.*\" and name $name"] 
##	$ionsel set segname ION
##	$ionsel writepsf build_files/ions/$name.psf
##	$ionsel writepdb build_files/ions/$name.pdb
##	mol delete all 
##	mol new build_files/ions/$name.psf 
##	mol addfile build_files/ions/$name.pdb 
##	set sel [atomselect top "all"]
##	set residue_list [$sel get residue] 
##
##	#we need to get the starting point for the resid numbers else we will have overlaps and psfgen really doesn't like that 
##	#we need to start from index 1 nad not 0 because autoionize makes us start from 1 , this way we get the first non 1 element 
##	#ok none of that worked just number them from 1 and up 
##	#might want the magnesiums to be of a different segment but we'll see how we go 
##	#better plan is to keep them separate so we adjust teh selection test to be 'ION.*'
###	set seed_id [ $sel get resid ]
###	set seed_id [lsort -unique $seed_id]
###	set seed_id [lsort -integer $seed_id]
###	set seed_id [lindex $seed_id 1 ]
##
##	foreach id $residue_list { 
##		set sel_curr [atomselect top "residue $id"]
##		#$sel_curr set resid [expr $id + $seed_id]
##		$sel_curr set resid $seed_id
##		set seed_id [ expr $seed_id + 1 ]
##	}
##	set sel [atomselect top "ion and name $name"]
##	$sel writepdb build_files/ions/$name.pdb
##	$sel writepsf build_files/ions/$name.psf
##}
##resetpsf
##
##foreach name $names {
##	readpsf build_files/ions/$name.psf
##	coordpdb build_files/ions/$name.pdb 
##}
##writepsf build_files/ions.psf
##writepdb build_files/ions.pdb
##
##resetpsf 
## 
###re merging ions and non ions
##readpsf build_files/not_ions.psf
##readpsf build_files/ions.psf
##coordpdb build_files/not_ions.pdb
##coordpdb build_files/ions.pdb
##writepsf ../mutated_systems/OUTNAME/OUTNAME.psf
##writepdb ../mutated_systems/OUTNAME/OUTNAME.pdb
