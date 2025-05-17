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
	signal clk 											: std_logic;
	signal ena 											: std_logic;
	signal rst 											: std_logic;
	signal Cflag, Zflag, Nflag							: std_logic;
	signal opcode										: std_logic_vector(3 downto 0);
	signal RF_out, DTCM_out, Imm2_in, Imm1_in, IRin		: std_logic; -- bus access
	signal RF_addr_rd, PCsel, RF_addr_wr				: std_logic_vector(1 downto 0);
	signal RF_WregEn, DTCM_addr_in, DTCM_wr_o, Pcin		: std_logic; 
	signal DTCM_addr_sel, Ain							: std_logic;	
	signal ALUFN										: std_logic_vector(2 downto 0);
	signal status_bits									: std_logic_vector(14 downto 0);
	signal done 										: std_logic;
	--------------------------
begin
	mapControl: ControlUnit port map(
									clk_i 							=> clk,
									rst_i 							=> rst,
									ena_i 							=> ena,
									ALU_c_i 						=> Cflag,
									ALU_z_i 						=> Zflag,
									ALU_n_i 						=> Nflag,
									done 							=> done,
									
									opcode_i 						=> opcode,
									DTCM_wr_o 						=> DTCM_wr_o,
									DTCM_addr_sel_o					=> DTCM_addr_sel,									
									RF_out_o 						=> RF_out,
									DTCM_out_o	 					=> DTCM_out,
								
									Imm2_in_o						=> Imm2_in,
									Imm1_in_o 						=> Imm1_in,
									IRin_o 							=> IRin,
									RF_addr_rd_o 					=> RF_addr_rd,
									RF_addr_wr_o 					=> RF_addr_wr,
									PCsel_o 						=> PCsel,
									RF_WregEn_o						=> RF_WregEn,
									Ain_o 							=> Ain,

									DTCM_addr_in_o 					=> DTCM_addr_in,

									Pcin_o							=> Pcin,
									ALUFN_o 						=> ALUFN,
									status_bits_o 					=> status_bits
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
		wait until rising_edge(clk);
		-- add
		opcode <= conv_std_logic_vector(0, 4);
		for i in 0 to rTypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- sub
		opcode <= conv_std_logic_vector(1, 4);
		for i in 0 to rTypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- and
		opcode <= conv_std_logic_vector(2, 4);
		for i in 0 to rTypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- or
		opcode <= conv_std_logic_vector(3, 4);
		for i in 0 to rTypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- xor
		opcode <= conv_std_logic_vector(4, 4);
		for i in 0 to rTypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- jmp
		opcode <= conv_std_logic_vector(7, 4);
		for i in 0 to jTypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- jc, c=0
		opcode <= conv_std_logic_vector(8, 4);
		for i in 0 to jTypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- jnc
		opcode <= conv_std_logic_vector(9, 4);
		for i in 0 to jTypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- mv
		opcode <= conv_std_logic_vector(12, 4);
		for i in 0 to i1TypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- ld
		opcode <= conv_std_logic_vector(13, 4);
		for i in 0 to i2TypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- st
		opcode <= conv_std_logic_vector(14, 4);
		for i in 0 to i2TypeCPI loop
			wait until rising_edge(clk);
		end loop;
		-- done
		opcode <= conv_std_logic_vector(15, 4);
		for i in 0 to i1TypeCPI loop
			wait until rising_edge(clk);
		end loop;
		wait;
		
	end process;
	    -- Stop simulation after 4010 ns
    stop_simulation : process
    begin
        wait for 8000 ns;
        report "Simulation ended at 4010 ns" severity note;
        assert false report "Simulation ended" severity failure;
        wait;
    end process;
end tb_control_arch;












