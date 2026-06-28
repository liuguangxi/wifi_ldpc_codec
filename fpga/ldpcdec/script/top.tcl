set DESIGN_TOP ldpcdec_core_wrapper
set_param general.maxThreads 8

create_project $DESIGN_TOP -part xcku5p-ffvb676-2-e

add_files ../../rtl/macro/xlnx_ram_sdp.v
add_files ../../rtl/macro/xlnx_ram_sp.v
add_files ../../rtl/ldpcdec/ldpcdec_calc_lq.v
add_files ../../rtl/ldpcdec/ldpcdec_calc_lq_vec.v
add_files ../../rtl/ldpcdec/ldpcdec_calc_pc.v
add_files ../../rtl/ldpcdec/ldpcdec_calc_vn_cn.v
add_files ../../rtl/ldpcdec/ldpcdec_calc_vn_cn_vec.v
add_files ../../rtl/ldpcdec/ldpcdec_dpu.v
add_files ../../rtl/ldpcdec/ldpcdec_main_cu.v
add_files ../../rtl/ldpcdec/ldpcdec_main_tbl.v
add_files ../../rtl/ldpcdec/ldpcdec_mem_out.v
add_files ../../rtl/ldpcdec/ldpcdec_mem_q.v
add_files ../../rtl/ldpcdec/ldpcdec_mem_r.v
add_files ../../rtl/ldpcdec/ldpcdec_mem_t.v
add_files ../../rtl/ldpcdec/ldpcdec_min_sel.v
add_files ../../rtl/ldpcdec/ldpcdec_min_sel_vec.v
add_files ../../rtl/ldpcdec/ldpcdec_out_cu.v
add_files ../../rtl/ldpcdec/ldpcdec_pc_tbl.v
add_files ../../rtl/ldpcdec/ldpcdec_rcs.v
add_files ../../rtl/ldpcdec/ldpcdec_vn_rcs_vec.v
add_files ../../rtl/ldpcdec/ldpcdec_core.v
add_files ../src/syn_harness.v
add_files ../src/ldpcdec_core_wrapper.v

read_xdc script/top.xdc

set_property include_dirs {../../rtl/ldpcdec} [current_fileset]

set_property top $DESIGN_TOP [current_fileset]
