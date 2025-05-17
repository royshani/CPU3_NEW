library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------------
entity Datapath is
generic( Dwidth: integer:=16;
		 Awidth: integer:=6;
		 dept: integer:=64);
port(	clk: IN std_logic; -- from TB through TOP
		dataIn: IN std_logic_vector(Dwidth-1 downto 0); -- write content into ProgMem, from TB through top
		writeaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into ProgMem, from TB through top
		prog_wren: IN std_logic; -- enable bit to write into ProgMem, from TB through top
		TBactive: IN std_logic; -- Shown in page 4 diagram, from TB through top
		data_writeaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into DataMem, from TB through top
		data_writeData: IN std_logic_vector(Dwidth-1 downto 0); -- write data into DataMem, from TB through top
		data_wren: IN std_logic; -- enable bit to write into DataMem, from TB through top
		data_readdata: out std_logic_vector(Dwidth-1 downto 0); -- read data from DataMem, from TB through top
		data_readaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into DataMem, from TB through top
		-- Datapath --> Control through top--
		alu_c, alu_z, alu_n: out std_logic; -- current flags from ALU to Control through top
		o_opcode: out std_logic_vector(3 downto 0); -- Opcode from IR to Control through top
		-- Control --> Datapath through top (control bits) --
		RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin: IN std_logic;
		RF_addr, PCsel: IN std_logic_vector(1 downto 0);
		RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin: IN std_logic; -- RF_rst - used as global reset (for registers)
		ALU_op: IN std_logic_vector(2 downto 0)
	);
end Datapath;
--------------------------------------------------------------
architecture DataArch of Datapath is
	signal RFaddrMuxRes : std_logic_vector(3 downto 0); -- RFaddr Mux output
	signal Tri_in_ext1, Tri_in_ext2 : std_logic_vector(Dwidth-1 downto 0); -- sig-extended Imm1 / Imm2
	signal imm_to_PC : std_logic_vector(7 downto 0); -- immediate from instruction, IR --> PCLogic
	signal ProgReadAddr : std_logic_vector(Awidth-1 downto 0); -- PC address, PCLOGIC --> ProgMem
	signal instruction_to_IR : std_logic_vector(Dwidth-1 downto 0); -- Instruction. ProgMem --> IR
	signal BusSignal : std_logic_vector(Dwidth-1 downto 0); -- the bus of the CPU
	signal Tri_in_RFData : std_logic_vector(Dwidth-1 downto 0); -- RF output to bus (through tri-state)
	signal reg_a_out : std_logic_vector(Dwidth-1 downto 0); -- output out of Reg_A
	signal reg_c_in : std_logic_vector(Dwidth-1 downto 0); -- output from ALU into Reg_C
	signal data_write_en_mux: std_logic; -- output of Mux between Data_MemEn & data_wren
	signal data_write_content_mux : std_logic_vector(Dwidth-1 downto 0); -- output of mux between bus & TB data_writeData
	signal Data_write_addr_mux : std_logic_vector(Awidth-1 downto 0); -- output of mux between D-FF & TB data_writeaddr
	signal Data_read_addr_mux : std_logic_vector(Awidth-1 downto 0); -- output of mux between bus & TB data_readaddr
	signal Tri_Data_mem_output : std_logic_vector(Dwidth-1 downto 0); -- output of DataMem, splitting to tri-state and TB data_readdata
	signal Tri_in_regC: std_logic_vector(Dwidth-1 downto 0); -- Register C output to bus (through tri-state)
	signal DFF_output_to_write_addr: std_logic_vector(Dwidth-1 downto 0); -- output of D-FF holding address to write into DataMem
begin

	---------------------- PORT MAPS ----------------------
	mapIR: IR generic map(Dwidth) port map (
		-- inputs --
		clk => clk, ena => IRin, rst => RF_rst,
		ctrl_RFaddr => RF_addr,
		i_IR_content => instruction_to_IR,
		-- outputs --
		o_OPCODE => o_opcode,
		o_addr => RFaddrMuxRes,
		o_signext1 => Tri_in_ext1, o_signext2 => Tri_in_ext2,
		o_imm_to_PC => imm_to_PC
		);
	
	mapProgMem: ProgMem generic map(Dwidth,Awidth,dept) port map(
		-- inputs --
		clk => clk, memEn => prog_wren, WmemData => dataIn,
		WmemAddr => writeaddr, RmemAddr => ProgReadAddr,
		-- outputs --
		RmemData => instruction_to_IR
		);
	
	mapPC: PCLogic generic map(Awidth) port map(
		-- inputs --
		clk => clk, i_PCin => Pcin, i_PCsel => PCsel,
		i_IR_imm => imm_to_PC,
		-- outputs --
		o_currentPC => ProgReadAddr
		);
	
	mapRegisterFile: RF port map(
		-- inputs --
		clk => clk, rst => RF_rst, WregEn => RF_WregEn,
		WregData => BusSignal, RregAddr => RFaddrMuxRes, WregAddr => RFaddrMuxRes,
		-- outputs --
		RregData => Tri_in_RFData
		);
	
	mapALU: ALU_main generic map(Dwidth) port map(
		reg_a_out, BusSignal, ALU_op, reg_c_in, alu_c, alu_n, alu_z);

	mapDataMem: dataMem generic map(Dwidth, Awidth, dept) port map(
		-- inputs --
		clk => clk, memEn => data_write_en_mux, WmemData => data_write_content_mux,
		WmemAddr => Data_write_addr_mux, RmemAddr => Data_read_addr_mux,
		-- outputs --
		RmemData => Tri_Data_mem_output
		);

	mapReg_A: GenericRegister generic map(Dwidth) port map(
		clk, Ain, RF_rst, BusSignal, reg_a_out);

	mapReg_C: GenericRegister generic map(Dwidth) port map(
		clk, Cin, RF_rst, reg_c_in, Tri_in_regC);
		
	mapMemIn_D_FF: GenericRegister generic map(Dwidth) port map(
		clk, Mem_in, RF_rst, BusSignal, DFF_output_to_write_addr);

	tristate_imm1: bus_pour_tristate generic map(Dwidth) port map(Tri_in_ext1, BusSignal, Imm1_in);
	tristate_imm2: bus_pour_tristate generic map(Dwidth) port map(Tri_in_ext2, BusSignal, Imm2_in);
	tristate_RF_data: bus_pour_tristate generic map(Dwidth) port map(Tri_in_RFData, BusSignal, RF_out);
	tristate_data_out: bus_pour_tristate generic map(Dwidth) port map(Tri_Data_mem_output, BusSignal, Data_mem_out);
	tristate_Cout: bus_pour_tristate generic map(Dwidth) port map (Tri_in_regC, BusSignal, Cout);
	-------------------------------------------------------
	data_readdata <= Tri_Data_mem_output; -- output of DataMem towards TB
	
	----------------- TB interaction MUXs -----------------
	data_write_en_mux <= Data_MemEn when TBactive='0' else data_wren;
	data_write_content_mux <= BusSignal when TBactive='0' else data_writeData;
	Data_write_addr_mux <= DFF_output_to_write_addr(Awidth-1 downto 0) when TBactive='0' else data_writeaddr;
	Data_read_addr_mux <= BusSignal(Awidth-1 downto 0) when TBactive='0' else data_readaddr;
	-------------------------------------------------------
	

end DataArch;
