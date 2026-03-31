#*****************************************************************************************
# create_project.tcl
# Recreates the mandelbrot-vga Vivado project
# Usage: cd [path/to/mandelbrot-vga] && source scripts/create_project.tcl
#*****************************************************************************************

set origin_dir [file normalize [file dirname [info script]]]
set proj_dir   [file normalize "$origin_dir/.."]
set _xil_proj_name_ "mandelbrot_vga"

# 1. Create project
create_project ${_xil_proj_name_} ./${_xil_proj_name_} -part xc7a35ticsg324-1L

set obj [current_project]
set_property -name "default_lib"        -value "xil_defaultlib" -objects $obj
set_property -name "target_language"    -value "Verilog"        -objects $obj
set_property -name "simulator_language" -value "Mixed"          -objects $obj
set_property -name "enable_vhdl_2008"   -value "1"              -objects $obj

# 2. Sources fileset
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

set files [list \
  [file normalize "$proj_dir/hdl/vga_axi_reader/vga_axi_reader.vhd"             ]\
  [file normalize "$proj_dir/hdl/vga_axi_reader/vga_axi_reader_wrapper.vhd"     ]\
  [file normalize "$proj_dir/hdl/mandelbrot_palette/mandelbrot_palette.vhd"      ]\
  [file normalize "$proj_dir/hdl/mandelbrot_iter/mandelbrot_iter.vhd"            ]\
  [file normalize "$proj_dir/hdl/mandelbrot_sequencer/mandelbrot_sequencer.vhd"  ]\
  [file normalize "$proj_dir/hdl/line_buffer_bram/line_buffer_bram.vhd"          ]\
  [file normalize "$proj_dir/hdl/vga_controller/vga_controller.vhd"              ]\
  [file normalize "$proj_dir/hdl/mandelbrot_master/mandelbrot_master.vhd"        ]\
  [file normalize "$proj_dir/hdl/mandelbrot_master/mandelbrot_master_wrapper.vhd"]\
]
import_files -fileset sources_1 $files

set_property -name "file_type" -value "VHDL 2008" -objects [get_files "*vga_axi_reader.vhd"]
set_property -name "file_type" -value "VHDL"      -objects [get_files "*vga_axi_reader_wrapper.vhd"]
set_property -name "file_type" -value "VHDL"      -objects [get_files "*mandelbrot_palette.vhd"]
set_property -name "file_type" -value "VHDL 2008" -objects [get_files "*mandelbrot_iter.vhd"]
set_property -name "file_type" -value "VHDL"      -objects [get_files "*mandelbrot_sequencer.vhd"]
set_property -name "file_type" -value "VHDL"      -objects [get_files "*line_buffer_bram.vhd"]
set_property -name "file_type" -value "VHDL"      -objects [get_files "*vga_controller.vhd"]
set_property -name "file_type" -value "VHDL 2008" -objects [get_files "*mandelbrot_master.vhd"]
set_property -name "file_type" -value "VHDL"      -objects [get_files "*mandelbrot_master_wrapper.vhd"]

# 3. Import clk_wiz IP
import_files -fileset sources_1 [file normalize "$proj_dir/ip/clk_wiz_0/clk_wiz_0.xci"]
set_property -name "synth_checkpoint_mode" -value "Singular" -objects [get_files "*clk_wiz_0.xci"]

# 4. Recreate block design
source "$origin_dir/mandebrot_vga_top.tcl"

# 5. Create Verilog wrapper
if { [get_property IS_LOCKED [get_files -norecurse mandebrot_vga_top.bd]] == 1 } {
  puts "WARNING: Block design is locked, skipping wrapper generation."
} else {
  set wrapper_path [make_wrapper -fileset sources_1 \
    -files [get_files -norecurse mandebrot_vga_top.bd] -top]
  add_files -norecurse -fileset sources_1 $wrapper_path
}

set_property -name "top"          -value "mandebrot_vga_top_wrapper" -objects [get_filesets sources_1]
set_property -name "top_auto_set" -value "0"                          -objects [get_filesets sources_1]

# 6. Constraints
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
import_files -fileset constrs_1 [file normalize "$proj_dir/constraints/arty_ddr3.xdc"]
set_property -name "target_constrs_file" -value [get_files *arty_ddr3.xdc] -objects [get_filesets constrs_1]

# 7. Simulation files
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

set files [list \
  [file normalize "$proj_dir/sim/tb_vga_axi_reader.vhd"      ]\
  [file normalize "$proj_dir/sim/tb_mandelbrot_master.vhd"    ]\
  [file normalize "$proj_dir/sim/tb_mandelbrot_sequencer.vhd" ]\
  [file normalize "$proj_dir/sim/tb_mandelbrot_iter.vhd"      ]\
  [file normalize "$proj_dir/sim/tb_mandelbrot_top.vhd"       ]\
  [file normalize "$proj_dir/sim/ddr3_model.sv"               ]\
  [file normalize "$proj_dir/sim/ddr3_model_parameters.vh"    ]\
  [file normalize "$proj_dir/sim/wiredly.v"                   ]\
]
import_files -fileset sim_1 $files

set_property -name "file_type" -value "VHDL 2008"      -objects [get_files "*tb_mandelbrot_iter.vhd"]
set_property -name "file_type" -value "SystemVerilog"   -objects [get_files "*ddr3_model.sv"]
set_property -name "file_type" -value "Verilog Header"  -objects [get_files "*ddr3_model_parameters.vh"]
set_property -name "file_type" -value "Verilog"         -objects [get_files "*wiredly.v"]

set_property -name "top"          -value "tb_vga_axi_reader" -objects [get_filesets sim_1]
set_property -name "top_auto_set" -value "0"                  -objects [get_filesets sim_1]

update_compile_order -fileset sources_1

puts "INFO: Project ${_xil_proj_name_} created successfully."
