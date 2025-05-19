onerror {resume}
add list -width 51 /tb_top/mapTop/mapControl/ControlLines_inst/Ain_o
add list /tb_top/mapTop/mapControl/ControlLines_inst/RF_out_o
add list /tb_top/mapTop/mapControl/ControlLines_inst/RF_addr_rd_o
add list /tb_top/mapTop/mapControl/ControlLines_inst/RF_addr_wr_o
add list /tb_top/mapTop/mapControl/ControlLines_inst/done
add list /tb_top/mapTop/mapControl/ControlLines_inst/bus_ctrl_r
add list /tb_top/mapTop/mapDatapath/DTCM_addr_out_i
add list /tb_top/mapTop/mapDatapath/DTCM_out_i
add list /tb_top/mapTop/mapDatapath/RF_out_o
add list /tb_top/mapTop/mapDatapath/RF_addr_rd_o
add list /tb_top/mapTop/mapDatapath/RF_addr_wr_o
add list /tb_top/mapTop/mapDatapath/bus_b_r
add list /tb_top/mapTop/mapDatapath/bus_a_r
add list /tb_top/mapTop/mapDatapath/reg_a_q
add list /tb_top/mapTop/mapDatapath/mapRegisterFile/RregData
add list /tb_top/mapTop/mapDatapath/mapRegisterFile/WregData
add list /tb_top/mapTop/mapDatapath/rf_data_r
add list /tb_top/mapTop/mapDatapath/addr_rd_o
add list /tb_top/mapTop/mapDatapath/addr_wr_o
add list /tb_top/mapTop/mapDatapath/bus_a_r
add list /tb_top/mapTop/mapControl/ControlLines_inst/Imm1_in
add list /tb_top/mapTop/mapControl/ControlLines_inst/Imm2_in
add list /tb_top/mapTop/mapControl/ControlLines_inst/bus_ctrl_r
add list /tb_top/mapTop/mapDatapath/Ain_i
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
