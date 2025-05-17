library IEEE;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
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
	constant input_ProgData_loc : string(1 to 75) :=
	"C:\Users\ronny\OneDrive\Documents\VHDL Lab\Lab 3\datapath_code\ITCMinit.txt";
	constant input_DataMem_loc : string(1 to 75) :=
	"C:\Users\ronny\OneDrive\Documents\VHDL Lab\Lab 3\datapath_code\DTCMinit.txt";
	constant output_file_loc : string(1 to 78) :=
	"C:\Users\ronny\OneDrive\Documents\VHDL Lab\Lab 3\datapath_code\DTCMcontent.txt";
	signal so_done : std_logic_vector(1 downto 0);
	signal gen : std_logic := '0'; -- file reading trigger
	-- Datapath input (to write into from file) ports --
	signal clk : std_logic; -- TB --> datapath
	signal ena : std_logic; -- meant for control, used for simulation purposes
	signal rst : std_logic;
	signal TBactive : std_logic;
	signal ProgMem_WriteData : std_logic_vector(Dwidth-1 downto 0); -- writing content into ProgMem
	signal ProgMem_WriteAddr : std_logic_vector(Awidth-1 downto 0); -- Address to write into in ProgMem
	signal ProgMem_EnWrite : std_logic; -- writing enable bit into ProgMem
	signal DataMem_EnMux : std_logic; -- mux control bit to direct TB/inner inputs to DataMem
	signal DataMem_WriteAddr : std_logic_vector(Awidth-1 downto 0); -- Address to write into in DataMem
	signal DataMem_WriteData : std_logic_vector(Dwidth-1 downto 0); -- writing content into DataMem
	signal DataMem_EnWrite : std_logic; -- writing enable bit into DataMem

	-- Datapath output ports (used for writing into file) --
	signal DataMem_ReadData : std_logic_vector(Dwidth-1 downto 0); -- Reading content from DataMem (towards output file)
	signal DataMem_ReadAddr	: std_logic_vector(Awidth-1 downto 0); -- Reading content from DataMem AT this address (data outputted to DataMem_ReadData)

	signal data_done_reading : std_logic := '0';
	signal prog_done_reading : std_logic := '0';
	signal data_writing : std_logic := '0';
	signal data_line_counter : integer := 0;
	signal XXX : std_logic_vector(Dwidth-1 downto 0) := (others => 'X');
	
	--------------------------
begin
	mapTop: top port map(
									clk => clk,
									rst => rst,
									ena => ena,
									done => so_done,
									dataIn => ProgMem_WriteData,
									writeaddr => ProgMem_WriteAddr,
									prog_wren => ProgMem_EnWrite,
									TBactive => TBactive,
									data_writeaddr => DataMem_WriteAddr,
									data_writeData => DataMem_WriteData,
									data_wren => DataMem_EnWrite,
									data_readdata => DataMem_ReadData,
									data_readaddr => DataMem_ReadAddr
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
	ReadData: process
		file DataMem_file : text open read_mode is input_DataMem_loc;
		variable L : line;
		variable good : boolean; -- to ignore comment lines
		variable LineCounter: integer := 0;
		variable contentToDataMem : bit_vector(15 downto 0); -- ^^
		
	begin
		wait for 100 ns;
		DataMem_EnWrite <= '1';
		wait until gen;
		-- Load data memory
		while not endfile(DataMem_file) loop
			readline(DataMem_file, L);
			hread (L, contentToDataMem,good);
			next when not good;
			DataMem_WriteData <= to_stdlogicvector(contentToDataMem);
			DataMem_WriteAddr <= conv_std_logic_vector(LineCounter, DataMem_WriteAddr'length);
			report "[DataWriteAddr="& to_string(DataMem_WriteAddr) &"]" severity note;
			report "[DataWriteData="& to_string(DataMem_WriteData) &"]" severity note;
			
			LineCounter := LineCounter + 1;
			
			wait until gen;
		end loop;
		DataMem_EnWrite <= '0';
		file_close(DataMem_file);
		report "finished loading ProgMem" severity note;
		data_line_counter <= LineCounter;
		data_done_reading <= '1';
		wait;
	end process;
		
		
		
		
	ReadProgram: process
		file ProgData_file : text open read_mode is input_ProgData_loc;
		
		variable L : line;
		variable good : boolean; -- to ignore comment lines
		variable LineCounter2: integer := 0;
		variable UpCounter : integer;
		variable codeToProgMem : bit_vector(15 downto 0); -- content read from ProgData_file

	begin
		wait for 100 ns;
		ProgMem_EnWrite <= '1'; -- enable writing to ProgMem
		wait until gen;
		-- Load program memory
		while not endfile (ProgData_file) loop
			readline(ProgData_file, L); -- read a line to L variable
			hread (L,codeToProgMem,good); -- read machine code from line
			next when not good; -- skip comment lines (in .txt.)

			
			ProgMem_WriteData <= to_stdlogicvector(codeToProgMem);
			ProgMem_WriteAddr <= conv_std_logic_vector(LineCounter2, ProgMem_WriteAddr'length);
			report "[ProgWriteAddr="& to_string(ProgMem_WriteAddr) &"]" severity note;
			report "[ProgWriteData="& to_string(ProgMem_WriteData) &"]" severity note;
			LineCounter2 := LineCounter2 + 1;
			wait until gen;
			
		end loop;
		report "finished loading ProgMem" severity note; -- for debug purposes **
		file_close(ProgData_file);
		prog_done_reading <= '1';
		ProgMem_EnWrite <= '0';
		wait;
	end process;
		


	WriteOut: process	
		file output_file : text open write_mode is output_file_loc;
		variable L : line;
		variable LineCounter: integer := 1;
		
		begin
			wait until so_done(0);
			if data_line_counter > 0 then
				data_writing <= '1';
				loop
					DataMem_ReadAddr <= conv_std_logic_vector(LineCounter, DataMem_ReadAddr'length);
					LineCounter := LineCounter + 1;
					exit when (LineCounter = dept-1);
					wait until gen;
					if DataMem_ReadData = XXX then next;
					end if;
					hwrite(L, DataMem_ReadData);
					writeline(output_file,L);
					report "LineCounter = " & to_string(LineCounter) severity note;
				end loop;
			end if;
				
			file_close(output_file);
			report "Finished writing to output file successfully" severity note;
			wait;
		end process;

end tb_top_arch;












