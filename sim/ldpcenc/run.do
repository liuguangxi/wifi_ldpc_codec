# To run this example, bring up the simulator and type the following at the prompt:
#     do run.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -c -do run.do
# (omit the "-c" to see the GUI while running from the shell)
# Remove the "quit -f" command from this file to view the results in the GUI.


onbreak {resume}

# Create the library.
if [file exists work] {
    vdel -all
}
vlib work

# Compile the sources.
vlog ../../rtl/ldpcenc/ldpcenc_cu.v
vlog ../../rtl/ldpcenc/ldpcenc_dpu.v
vlog ../../rtl/ldpcenc/ldpcenc_rcs.v
vlog ../../rtl/ldpcenc/ldpcenc_tbl.v
vlog ../../rtl/ldpcenc/ldpcenc.v
vlog ../../tb/ldpcenc/tb_ldpcenc.sv


# Simulate the design.
vsim -novopt -c tb_ldpcenc
run -all

quit -f
