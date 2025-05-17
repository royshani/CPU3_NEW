library IEEE;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------------
entity tb_control is
	generic(tick : time := 50 ns;
			Dwidth : integer:= 16;
			Awidth : integer:=6;
			dept   : integer:=64);
end tb_control;
--------------------------------------------------------------
architecture tb_control_arch of tb_control is
	signal clk : std_logic;
	signal ena : std_logic;
	signal rst : std_logic;
	signal Cflag, Zflag, Nflag: std_logic;
	signal opcode: std_logic_vector(3 downto 0);
	signal RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin: std_logic; -- bus access
	signal RF_addr, PCsel: std_logic_vector(1 downto 0);
	signal RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin: std_logic; -- RF_rst to be used as global reset?
	signal ALU_op: std_logic_vector(2 downto 0);
	signal status_bits: std_logic_vector(12 downto 0);
	signal done : std_logic;
	--------------------------
begin
	mapControl: Control port map(
									clk => clk,
									rst => rst,
									ena => ena,
									ALU_c => Cflag,
									ALU_z => Zflag,
									ALU_n => Nflag,
									i_opcode => opcode,
									RF_out => RF_out,
									Data_mem_out => Data_mem_out,
									Cout => Cout,
									Imm2_in => Imm2_in,
									Imm1_in => Imm1_in,
									IRin => IRin,
									RF_addr => RF_addr,
									PCsel => PCsel,
									RF_WregEn => RF_WregEn,
									RF_rst => RF_rst,
									Ain => Ain,
									Cin => Cin,
									Mem_in => Mem_in,
									Data_MemEn => Data_MemEn,
									Pcin => Pcin,
									ALU_op => ALU_op,
									status_bits => status_bits
									);
	
	-------------------------
	clock_gen : process
        begin
		  clk <= '0';
		  wait for tick;
		  clk <= not clk;
		  wait for tick;
        end process;
	-------------------------
	rst <= '1', '0' after 100 ns;

	done <= status_bits(8);
	start: process
	variable rTypeCPI  : integer := 5 - 1;
	variable jTypeCPI  : integer := 3 - 1;
	variable i1TypeCPI : integer := 3 - 1;
	variable i2TypeCPI : integer := 6 - 1;
	
	begin
		wait for 100 ns;
		ena <= '1';
		Cflag <= '0';
		Zflag <= '0';
		Nflag <= '0';
		wait until clk;
		-- add
		opcode <= conv_std_logic_vector(0, 4);
		for i in 0 to rTypeCPI loop
			wait until clk;
		end loop;
		-- sub
		opcode <= conv_std_logic_vector(1, 4);
		for i in 0 to rTypeCPI loop
			wait until clk;
		end loop;
		-- and
		opcode <= conv_std_logic_vector(2, 4);
		for i in 0 to rTypeCPI loop
			wait until clk;
		end loop;
		-- or
		opcode <= conv_std_logic_vector(3, 4);
		for i in 0 to rTypeCPI loop
			wait until clk;
		end loop;
		-- xor
		opcode <= conv_std_logic_vector(4, 4);
		for i in 0 to rTypeCPI loop
			wait until clk;
		end loop;
		-- jmp
		opcode <= conv_std_logic_vector(7, 4);
		for i in 0 to jTypeCPI loop
			wait until clk;
		end loop;
		-- jc, c=0
		opcode <= conv_std_logic_vector(8, 4);
		for i in 0 to jTypeCPI loop
			wait until clk;
		end loop;
		-- jnc
		opcode <= conv_std_logic_vector(9, 4);
		for i in 0 to jTypeCPI loop
			wait until clk;
		end loop;
		-- mv
		opcode <= conv_std_logic_vector(12, 4);
		for i in 0 to i1TypeCPI loop
			wait until clk;
		end loop;
		-- ld
		opcode <= conv_std_logic_vector(13, 4);
		for i in 0 to i2TypeCPI loop
			wait until clk;
		end loop;
		-- st
		opcode <= conv_std_logic_vector(14, 4);
		for i in 0 to i2TypeCPI loop
			wait until clk;
		end loop;
		-- done
		opcode <= conv_std_logic_vector(15, 4);
		for i in 0 to i1TypeCPI loop
			wait until clk;
		end loop;
		wait;
		
	end process;
end tb_control_arch;












