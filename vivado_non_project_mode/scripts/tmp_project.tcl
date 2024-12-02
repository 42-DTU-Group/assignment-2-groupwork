# The directory where all the scripts reside
set scriptDir [ file normalize $::env(SCRIPT_DIR) ]
# The directory where the source files reside
set srcDir [ file normalize $::env(SRC_DIR) ]
# The directory where the source files reside
set constraintsDir [ file normalize $::env(CONSTRAINTS_DIR) ]
# The directory for all the output, log files, etc.
set outputDir [ file normalize $::env(OUTPUT_DIR) ]
file mkdir $outputDir
file delete -force $outputDir/tmp_project
file mkdir $outputDir/tmp_project
# The topmost component from which the design is generated
set top $::env(TOP)
# The testbench component
set testbench $::env(TESTBENCH)

# There is no good way to control all the generated files, so we just cd into a directory instead...
cd "$outputDir/tmp_project"

create_project tmp_project
set_property top "$top" [current_fileset]
set_property top "$testbench" [get_filesets sim_1]
set_property target_language VHDL [current_project]
# Find the board part using either the GUI or on https://github.com/Xilinx/XilinxBoardStore
set_property part xc7a100tcsg324-1 [current_project]

source "$scriptDir/vhdl_files.tcl"

# foreach file [ glob -nocomplain "$srcDir/*.vhd*" ] {
foreach file $vhdl_files {
    read_vhdl "$srcDir/$file"
}
foreach file [ glob -nocomplain "$constraintsDir/*.xdc" ] {
    read_xdc "$file"
}
foreach file [ glob -nocomplain "$srcDir/*/*.xci" ] {
    read_ip "$file"
}

start_gui
