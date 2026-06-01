# Runtime arguments
set TESTFILE tc_random.txt


# Run simulation
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

vlog -f script/filelist.f

vsim -l run.log tb_ldpcenc_core +TESTFILE=$TESTFILE

run -all
