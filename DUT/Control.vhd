library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------------
entity Control is
generic( StateLength: integer:=5); -- 2^5 bits to describe states
port(	clk, rst, ena: in std_logic; -- fed from TB
		ALU_c, ALU_z, ALU_n: in std_logic; -- fed from ALU, through Top*(?)
		i_opcode: in std_logic_vector(3 downto 0); -- fed from IR, through Top*(?)
		--- control bits ---
		RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin: out std_logic; -- bus access
		RF_addr, PCsel: out std_logic_vector(1 downto 0);
		RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin: out std_logic; -- RF_rst to be used as global reset?
		ALU_op: out std_logic_vector(2 downto 0);
		status_bits: out std_logic_vector(12 downto 0) -- status bits, concatenated, including flags (MSBs, C,Z,N,status..)		
	);
end Control;
--------------------------------------------------------------
architecture ControlArch of Control is
	signal state : std_logic_vector(StateLength-1 downto 0); -- state vector signal within Control unit
	
begin
	---------------------- PORT MAP ----------------------
	mapStateLogic: StateLogic generic map(StateLength) port map (
		-- inputs --
		clk => clk, ena => ena, rst => rst,
		ALU_cflag => ALU_c,
		i_opcode => i_opcode,
		-- outputs --
		o_currentstate => state -- state vector
		);
	
	mapCtrlLinesModule : ControlLines generic map(StateLength) port map(
		-- inputs --
		clk => clk, rst => rst,
		i_state => state,
		i_opcode => i_opcode,
		alu_c => ALU_c, alu_z => ALU_z, alu_n => ALU_n, -- the current values of flags fed into ControlLines
		-- outputs --
		RF_out => RF_out, Data_Mem_out => Data_mem_out, Cout => Cout,
		Imm2_in => Imm2_in, Imm1_in => Imm1_in, IRin => IRin,
		RF_addr => RF_addr, PCsel => PCsel, RF_WregEn => RF_WregEn,
		RF_rst => RF_rst, Ain => Ain, Cin => Cin, Mem_in => Mem_in,
		Data_MemEn => Data_MemEn, Pcin => Pcin, 
		ALU_op => ALU_op,
		o_cflag => status_bits(12), o_zflag => status_bits(11), o_nflag => status_bits(10), status_bits => status_bits(9 downto 0)
		);
	------------------------------------------------------


end ControlArch;
