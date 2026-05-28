onbreak {resume}

# Create the library
if [file exists work] {
    vdel -all
}
vlib work

# Compile the sources
vlog ../../rtl/ldpcenc/ldpcenc_cu.v
vlog ../../rtl/ldpcenc/ldpcenc_dpu.v
vlog ../../rtl/ldpcenc/ldpcenc_rcs.v
vlog ../../rtl/ldpcenc/ldpcenc_tbl.v
vlog ../../rtl/ldpcenc/ldpcenc.v
vlog ../../tb/ldpcenc/tb_ldpcenc.sv


# Simulate the design
vsim -l run.log tb_ldpcenc

run -all
