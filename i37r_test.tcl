#
#separate template system into components, protein and not protein, make new psf mutate and then merge 

#make directory for temporary files if it doesn't exist

file mkdir build_files

#mol new ../final_wt_ionized_added_loops_no_ters_cter_modelled_use_this_gmx_ready.psf
#mol addfile ../final_wt_ionized_added_loops_no_ters_cter_modelled_use_this_gmx_ready.pdb

mol new ../final_wt_ionized_added_loops_no_ters_cter_modelled_use_this_gmx_ready.psf
mol addfile ../final_wt_ionized_added_loops_no_ters_cter_modelled_use_this_gmx_ready.pdb

set sel [atomselect top "protein"]
$sel writepsf build_files/prot.psf 
$sel writepdb build_files/prot.pdb 

set sel [atomselect top "not protein"]
$sel writepsf build_files/not_prot.psf
$sel writepdb build_files/not_prot.pdb

mol delete all 

package require mutator 
mutator -psf build_files/prot.psf -pdb build_files/prot.pdb -o build_files/mutated_prot -ressegname AP1 -resid 37 -mut ARG

#mol delete all
mol new build_files/mutated_prot.psf
mol addfile build_files/mutated_prot.pdb
set sel [atomselect top "name CA and protein"]
set segnames [lsort -unique [$sel get segname]]
foreach i segnames { 
	set sel [atomselect top "segname $i"]
	$sel writepsf build_files/$i.psf 
	$sel writepdb build_files/$i.pdb 
}
#we have to remake the psf file in case the termini of the protein was changed by the mutator plugin.

package require psfgen 
resetpsf 

# I don't have a license to distribute the topology so you will need to provide it 
topology PROTEINTOP
pdbalias atom ILE CD1 CD 

readpsf build_files/AP1.psf
coordpdb build_files/AP1.pdb
segment AP1 { 
	pdb build_files/AP1.pdb
	first NONE
	last NONE
}  
coordpdb build_files/AP1.pdb AP1


readpsf build_files/BP1.psf
coordpdb build_files/BP1.pdb
segment BP1 { 
	pdb build_files/BP1.pdb
	first NONE
	last NONE
}
coordpdb build_files/BP1.pdb BP1
guesscoord
regenerate angles dihedrals

writepdb build_files/mutated_prot.pdb
writepsf build_files/mutated_prot.psf

resetpsf

readpsf build_files/mutated_prot.psf 
readpsf build_files/not_prot.psf
coordpdb build_files/mutated_prot.pdb
coordpdb build_files/not_prot.pdb

writepsf build_files/mutated_system.psf
writepdb build_files/mutated_system.pdb


#psf finished now we need to remerge everything
#mol delete all 
#mol new build_files/mutated_prot.psf
#mol addfile build_files/mutated_prot.pdb
#
#set sel [atomselect top "all"]
#
#
#$sel writepsf 
## do ionization as normal  ## NB this method will assume that the termini added by gromacs will be overall neutral make sure when you add an extra charge if the termini is going to be 
package require autoionize
autoionize -psf build_files/mutated_system.psf -pdb build_files/mutated_system.pdb -neutralise -cation POT -anion CLA -o build_files/ionized
#

#now we have to re order everything so gromacs doesn't complain that our index groups aren't contiguous
mol delete all
mol new build_files/ionized.psf 
mol addfile build_files/ionized.pdb
set sel [atomselect top "ions"]
set names [$sel get name]
set names [ lsort -unique $names ]
foreach name $names {

	set ionsel [atomselect top "ion and name $name"] 
	$ionsel writepsf build_files/ions/$name.psf
	$ionsel writepdb build_files/ions/$name.pdb
}
mol delete all 

set sel [atomselect top "not ion"]
$sel writepsf build_files/not_ions.psf
$sel writepdb build_files/not_ions.pdb
resetpsf 
exit
