library IEEE;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use ieee.std_logic_textio.all;
USE work.aux_package.all;
USE ieee.numeric_std.all;
--------------------------------------------------------------
entity tb_top is
	generic(tick : time := 50 ns;
			Dwidth : integer:= 16;
			Awidth : integer:=6;
			dept   : integer:=64);
end tb_top;
--------------------------------------------------------------
architecture tb_top_arch of tb_top is
	-- used for file operation --
    constant input_ProgData_loc : string := "C:\intelFPGA\CPU3_NEW\files\ITCMinit.txt";
    constant input_DataMem_loc  : string := "C:\intelFPGA\CPU3_NEW\files\DTCMinit.txt";
    constant output_file_loc    : string := "C:\intelFPGA\CPU3_NEW\files\DTCMcontent.txt";
	
	signal so_done : std_logic;
	signal gen : boolean := false; -- file reading trigger
	-- Datapath input (to write into from file) ports --
	signal clk : std_logic; -- TB --> datapath
	signal ena : std_logic; -- meant for control, used for simulation purposes
	signal rst : std_logic;
	signal TBactive : std_logic;
	signal ITCM_tb_in : std_logic_vector(Dwidth-1 downto 0); -- writing content into ProgMem
	signal ITCM_tb_addr_in : std_logic_vector(Awidth-1 downto 0); -- Address to write into in ProgMem
	signal ITCM_tb_wr : std_logic; -- writing enable bit into ProgMem

	signal DTCM_tb_addr_in : std_logic_vector(Awidth-1 downto 0); -- Address to write into in DataMem
	signal DTCM_tb_in : std_logic_vector(Dwidth-1 downto 0); -- writing content into DataMem
	signal DTCM_tb_wr : std_logic; -- writing enable bit into DataMem

	-- Datapath output ports (used for writing into file) --
	signal DTCM_tb_out : std_logic_vector(Dwidth-1 downto 0); -- Reading content from DataMem (towards output file)
	signal DTCM_tb_addr_out	: std_logic_vector(Awidth-1 downto 0); -- Reading content from DataMem AT this address (data outputted to DTCM_tb_out)

	signal data_done_reading : std_logic := '0';
	signal prog_done_reading : std_logic := '0';
	signal data_writing : std_logic := '0';
	signal data_line_counter : integer := 0;
	signal XXX : std_logic_vector(Dwidth-1 downto 0) := (others => 'X');

	
	--------------------------
begin
	mapTop: top port map(
									clk_i 				=> clk,
									rst_i 				=> rst,
									ena_i 				=> ena,
									done_o 				=> so_done,
									ITCM_tb_in_i 		=> ITCM_tb_in,
									ITCM_tb_addr_in_i 	=> ITCM_tb_addr_in,
									ITCM_tb_wr_i 		=> ITCM_tb_wr,
									
									-- TB
									tb_active_i 		=> TBactive,
									DTCM_tb_out 		=> DTCM_tb_out,
									
									-- mux
									
									DTCM_tb_addr_in_i  => DTCM_tb_addr_in,
									DTCM_tb_in_i	   => DTCM_tb_in,
									DTCM_tb_wr_i	   => DTCM_tb_wr,
									DTCM_tb_addr_out_i   => DTCM_tb_addr_out
									


									);
	
	-------------------------
	gen <= not gen after tick; -- file reading trigger
	
	--------- Rst
	rst_system : process
	begin
	  rst <='1','0' after 100 ns;
	  wait;
	end process;
	
	clock_gen : process
        begin
		  clk <= '0';
		  wait for tick;
		  clk <= not clk;
		  wait for tick;
        end process;
	-------------------------
	ena <= prog_done_reading and data_done_reading;
	TBactive <= not (prog_done_reading and data_done_reading) or data_writing;
	-------------------------
	LoadData: process
		file DataMem_file : text open read_mode is input_DataMem_loc;
		variable L : line;
		variable good : boolean; -- to ignore comment lines
		variable LineCounter: integer := 0;
		variable contentToDataMem : std_logic_vector(15 downto 0); -- ^^
		
	begin
		wait for 100 ns;
		DTCM_tb_wr <= '1';
		wait until gen;
		-- Load data memory
		while not endfile(DataMem_file) loop
			readline(DataMem_file, L);
			hread (L, contentToDataMem,good);
			next when not good;
			DTCM_tb_in <= contentToDataMem;
			DTCM_tb_addr_in <= conv_std_logic_vector(LineCounter, DTCM_tb_addr_in'length);
			report "data write Address" severity note;
			report "[DataWriteAddr="& integer'image(to_integer(ieee.numeric_std.unsigned(DTCM_tb_addr_in))) &"]" severity note;
			report "[DataWriteData="& integer'image(to_integer(ieee.numeric_std.unsigned(DTCM_tb_in))) &"]" severity note;
			
			LineCounter := LineCounter + 1;
			
		wait until gen;
		end loop;
		DTCM_tb_wr <= '0';
		file_close(DataMem_file);
		report "finished loading ProgMem" severity note; -- this is read data??
		data_line_counter <= LineCounter;
		data_done_reading <= '1';
		wait;
	end process;
		
		
		
		
	LoadProgram: process
		file ProgData_file : text open read_mode is input_ProgData_loc;
		
		variable L : line;
		variable good : boolean; -- to ignore comment lines
		variable LineCounter2: integer := 0;
		variable UpCounter : integer;
		variable codeToProgMem : std_logic_vector(15 downto 0); -- content read from ProgData_file

	begin
		wait for 100 ns;
		ITCM_tb_wr <= '1'; -- enable writing to ProgMem
		wait until gen;
		-- Load program memory
		while not endfile (ProgData_file) loop
			readline(ProgData_file, L); -- read a line to L variable
			hread (L,codeToProgMem,good); -- read machine code from line
			next when not good; -- skip comment lines (in .txt.)			
			ITCM_tb_in <= codeToProgMem;
			ITCM_tb_addr_in <= conv_std_logic_vector(LineCounter2, ITCM_tb_addr_in'length);
			report "[ProgWriteAddr="& integer'image(to_integer(ieee.numeric_std.unsigned(ITCM_tb_addr_in))) &"]" severity note;
			report "[ProgWriteData="& integer'image(to_integer(ieee.numeric_std.unsigned(ITCM_tb_in))) &"]" severity note;
			LineCounter2 := LineCounter2 + 1;
			wait until gen;
			
		end loop;
		report "finished loading ProgMem" severity note; -- for debug purposes **
		file_close(ProgData_file);
		prog_done_reading <= '1';
		ITCM_tb_wr <= '0';
		wait;
	end process;
		


	WriteOut: process	
		file output_file : text open write_mode is output_file_loc;
		variable L : line;
		variable LineCounter: integer := 1;
		
		begin
			wait until so_done = '1';
			if data_line_counter > 0 then
				data_writing <= '1';
				loop
					DTCM_tb_addr_out <= conv_std_logic_vector(LineCounter, DTCM_tb_addr_out'length);
					LineCounter := LineCounter + 1;
					exit when (LineCounter = dept-1);
					wait until gen;
					if DTCM_tb_out = XXX then next;
					end if;
					hwrite(L, DTCM_tb_out);
					writeline(output_file,L);
				    --report "LineCounter = " & integer'image(to_integer(ieee.numeric_std.unsigned(LineCounter))) severity note;
					report "NIGGERRRRRRR       wrote line       BITCH" severity note;
				end loop;
			end if;
				
			file_close(output_file);
			report "Finished writing to output file successfully" severity note;
			wait;
		end process;

    -- Stop simulation after 4010 ns
    stop_simulation : process
    begin
        wait for 50000 ns;
        report "Simulation ended at 4010 ns" severity note;
        assert false report "Simulation ended" severity failure;
        wait;
    end process;

end tb_top_arch; 