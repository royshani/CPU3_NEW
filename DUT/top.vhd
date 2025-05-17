LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
-------------------------------------
ENTITY top IS
generic( Dwidth: integer:=16;
		 Awidth: integer:=6;
		 dept: integer:=64;
		 StateLength: integer:=5);
port(	clk, rst, ena: IN std_logic; -- fed from TB
		done: OUT std_logic_vector(1 DOWNTO 0) := "00"; -- DONE bit to TB

		dataIn: IN std_logic_vector(Dwidth-1 downto 0); -- write content into ProgMem, from TB through top
		writeaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into ProgMem, from TB through top
		prog_wren: IN std_logic; -- enable bit to write into ProgMem, from TB through top
		TBactive: IN std_logic; -- enable bit to write from TB instead of internally
		data_writeaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into DataMem, from TB through top
		data_writeData: IN std_logic_vector(Dwidth-1 downto 0); -- write data into DataMem, from TB through top
		data_wren: IN std_logic; -- enable bit to write into DataMem, from TB through top
		data_readdata: out std_logic_vector(Dwidth-1 downto 0); -- read data from DataMem, from TB through top
		data_readaddr: IN std_logic_vector(Awidth-1 downto 0) -- write address into DataMem, from TB through top
	); 
END top;
------------- complete the top Architecture code --------------
ARCHITECTURE topArch OF top IS 
	------* ALL COMPONENT DECLERATIONS ARE WITHIN AUX_PACKAGE.VHD *------

	signal alu_c, alu_z, alu_n: std_logic; -- Datapath --> Control
	signal opcode: std_logic_vector(3 downto 0); -- Datapath --> Control
	signal RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin: std_logic; -- Control --> Datapath
	signal RF_addr, PCsel: std_logic_vector(1 downto 0); -- Control --> Datapath
	signal RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin: std_logic; -- Control --> Datapath
	signal ALU_op: std_logic_vector(2 downto 0); -- Control --> Datapath
	signal status_bits: std_logic_vector(12 downto 0);
BEGIN
------------ PORT MAP INITIATLIZATION ------------
	mapDatapath: Datapath generic map(Dwidth,Awidth,dept) port map (
		clk, DataIn, writeaddr, prog_wren, TBactive, data_writeaddr, data_writeData,
		data_wren, data_readdata, data_readaddr, alu_c, alu_z, alu_n, opcode,
		RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin, RF_addr, PCsel,
		RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin, ALU_op);
		
	mapControl: Control generic map(StateLength) port map(
	clk, rst, ena, alu_c, alu_z, alu_n, opcode,
	RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin, RF_addr, PCsel,
	RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin, ALU_op, status_bits); -- open = status bits [for now?]
	
	done(0) <= status_bits(8);
	
END topArch;

