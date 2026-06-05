set DESIGN_TOP ldpcenc_core_wrapper
set_param general.maxThreads 8

create_project $DESIGN_TOP -part xcku5p-ffvb676-2-e

add_files ../../rtl/ldpcenc/ldpcenc_cu.v
add_files ../../rtl/ldpcenc/ldpcenc_dpu.v
add_files ../../rtl/ldpcenc/ldpcenc_rcs.v
add_files ../../rtl/ldpcenc/ldpcenc_tbl.v
add_files ../../rtl/ldpcenc/ldpcenc_core.v
add_files ../src/syn_harness.v
add_files ../src/ldpcenc_core_wrapper.v

read_xdc script/top.xdc

set_property top $DESIGN_TOP [current_fileset]
