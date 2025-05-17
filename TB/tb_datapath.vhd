library IEEE;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
--------------------------------------------------------------
entity tb_datapath is
	generic(tick : time := 50 ns;
			Dwidth : integer:= 16;
			Awidth : integer:=6;
			dept   : integer:=64);
end tb_datapath;
--------------------------------------------------------------
architecture tb_datapath_arch of tb_datapath is
	-- used for file operation --
	constant input_ProgData_loc : string(1 to 75) :=
	"C:\Users\ronny\OneDrive\Documents\VHDL Lab\Lab 3\datapath_code\ITCMinit.txt";
	constant input_DataMem_loc : string(1 to 75) :=
	"C:\Users\ronny\OneDrive\Documents\VHDL Lab\Lab 3\datapath_code\DTCMinit.txt";
	constant output_file_loc : string(1 to 78) :=
	"C:\Users\ronny\OneDrive\Documents\VHDL Lab\Lab 3\datapath_code\DTCMcontent.txt";
	signal done : boolean := false;
	signal gen : boolean := true; -- file reading trigger
	-- Datapath input (to write into from file) ports --
	signal clk : std_logic; -- TB --> datapath
	signal TBactive : std_logic;
	signal ProgMem_WriteData : std_logic_vector(Dwidth-1 downto 0); -- writing content into ProgMem
	signal ProgMem_WriteAddr : std_logic_vector(Awidth-1 downto 0); -- Address to write into in ProgMem
	signal ProgMem_EnWrite : std_logic; -- writing enable bit into ProgMem
	signal DataMem_WriteAddr : std_logic_vector(Awidth-1 downto 0); -- Address to write into in DataMem
	signal DataMem_WriteData : std_logic_vector(Dwidth-1 downto 0); -- writing content into DataMem
	signal DataMem_EnWrite : std_logic; -- writing enable bit into DataMem

	signal Control_BusAccess : std_logic_vector(4 downto 0); -- (RF_Out - Data_Mem_Out - Cout - Imm2_in - Imm1_in)
	signal Control_RF_addr,Control_PCsel : std_logic_vector(1 downto 0);
	signal Control_IRin,Control_RF_WregEn, Control_RF_rst, Control_Ain, Control_Cin, Control_Mem_in, Control_Data_MemEn, Control_Pcin : std_logic;
	signal Control_ALU_op : std_logic_vector(2 downto 0);
	-- Datapath output ports (used for writing into file) --
	signal Out_Op_code : std_logic_vector(3 downto 0); -- this is meant to go to Control unit. used as simulated 'done' for TB
	signal DataMem_ReadData : std_logic_vector(Dwidth-1 downto 0); -- Reading content from DataMem (towards output file)
	signal DataMem_ReadAddr	: std_logic_vector(Awidth-1 downto 0); -- Reading content from DataMem AT this address (data outputted to DataMem_ReadData)
	signal TB_ALU_flags : std_logic_vector(2 downto 0); -- flags meant to be sent to Control unit. (C-Z-N)

	signal data_done_reading : std_logic := '0';
	signal prog_done_reading : std_logic := '0';
	signal data_writing : std_logic := '0';
	signal data_line_counter : integer := 0;
	signal XXX : std_logic_vector(Dwidth-1 downto 0) := (others => 'X');
	--------------------------
begin
	mapDatapath: Datapath generic map(Dwidth,Awidth) port map(
												clk => clk,
												dataIn => ProgMem_WriteData,
												writeaddr => ProgMem_WriteAddr,
												prog_wren => ProgMem_EnWrite,
												TBactive => TBactive,
												data_writeaddr => DataMem_WriteAddr,
												data_writeData => DataMem_WriteData,
												data_wren => DataMem_EnWrite,
												data_readdata => DataMem_ReadData,
												data_readaddr => DataMem_ReadAddr,
												alu_c => TB_ALU_flags(2),
												alu_z => TB_ALU_flags(1),
												alu_n => TB_ALU_flags(0),
												o_opcode => Out_Op_code,
												RF_Out => Control_BusAccess(4),
												Data_mem_out => Control_BusAccess(3),
												Cout => Control_BusAccess(2),
												Imm2_in => Control_BusAccess(1),
												Imm1_in => Control_BusAccess(0),
												IRin => Control_IRin,
												RF_addr => Control_RF_addr,
												PCsel => Control_PCsel,
												RF_WregEN => Control_RF_WregEn,
												RF_rst => Control_RF_rst,
												Ain => Control_Ain,
												Cin => Control_Cin,
												Mem_in => Control_Mem_in,
												Data_MemEn => Control_Data_MemEn,
												Pcin => Control_Pcin,
												ALU_op => Control_ALU_op);
	-------------------------
	gen <= not gen after tick; -- file reading trigger
	
	clock_gen : process
        begin
		  clk <= '0';
		  wait for tick;
		  clk <= not clk;
		  wait for tick;
        end process;

	---------
	TBactive <= not (prog_done_reading and data_done_reading) or data_writing;
	---------
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
		variable LineCounter: integer := 0;
		
		begin
			wait until done;
			if data_line_counter > 0 then
				data_writing <= '1';
				wait until gen;
				loop
					DataMem_ReadAddr <= conv_std_logic_vector(LineCounter, DataMem_ReadAddr'length);
					LineCounter := LineCounter + 1;
					exit when (LineCounter = data_line_counter + 1);
					wait until gen;
					--if DataMem_ReadData = XXX then next;
					--end if;
					hwrite(L, DataMem_ReadData);
					writeline(output_file,L);
					report "LineCounter = " & to_string(LineCounter) severity note;
				end loop;
			end if;
				
			file_close(output_file);
			report "Finished writing to output file successfully" severity note;
			wait;
		end process;
	
	
	
	
	
	-------------------------


	start : process
	begin
		wait until prog_done_reading and data_done_reading;
		
		-- RST
		Control_BusAccess <= "00000"; -- RF_out, Data_Mem_Out, Cout, Imm2_in, Imm1_in
		Control_IRin <= '1';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '1';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '1';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- ld
		-- Fetch : IR <= PC ; PC <= PC + 1
		Control_BusAccess <= "00000";
		Control_IRin <= '1';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '1';
		Control_PCsel <= "10";
		wait until rising_edge(clk);
		-- Decode
		Control_BusAccess <= "00000";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- A <= Imm2
		Control_BusAccess <= "00010";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '1';
		Control_Cin <= '0';
		Control_ALU_op <= "000";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- C <= Imm2 + rb
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "10";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '1';
		Control_ALU_op <= "000";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- Read addr at Cout
		Control_BusAccess <= "00100";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- ra <= M[Imm2 + rb]
		Control_BusAccess <= "01000";
		Control_IRin <= '0';
		Control_RF_addr <= "01";
		Control_RF_WregEn <= '1';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		--
		-- ld
		-- Fetch : IR <= PC ; PC <= PC + 1
		Control_BusAccess <= "00000";
		Control_IRin <= '1';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '1';
		Control_PCsel <= "10";
		wait until rising_edge(clk);
		-- Decode
		Control_BusAccess <= "00000";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- A <= Imm2
		Control_BusAccess <= "00010";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '1';
		Control_Cin <= '0';
		Control_ALU_op <= "000";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- C <= Imm2 + rb
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "10";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '1';
		Control_ALU_op <= "000";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- Read addr at Cout
		Control_BusAccess <= "00100";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- ra <= M[Imm2 + rb]
		Control_BusAccess <= "01000";
		Control_IRin <= '0';
		Control_RF_addr <= "01";
		Control_RF_WregEn <= '1';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		--
		-- mv
		-- Fetch : IR <= PC ; PC <= PC + 1
		Control_BusAccess <= "00000";
		Control_IRin <= '1';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '1';
		Control_PCsel <= "10";
		wait until rising_edge(clk);
		-- Decode
		Control_BusAccess <= "00000";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- ra <= Imm1
		Control_BusAccess <= "00001";
		Control_IRin <= '0';
		Control_RF_addr <= "01";
		Control_RF_WregEn <= '1';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		--
		-- add
		-- Fetch : IR <= PC ; PC <= PC + 1
		Control_BusAccess <= "00000";
		Control_IRin <= '1';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '1';
		Control_PCsel <= "10";
		wait until rising_edge(clk);
		-- Decode
		Control_BusAccess <= "00000";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- A <= rb
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "10";
		Control_RF_WregEn <= '1';
		Control_RF_rst <= '0';
		Control_Ain <= '1';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- C <= A + rc
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "11";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '1';
		Control_ALU_op <= "000";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- ra <= C
		Control_BusAccess <= "00100";
		Control_IRin <= '0';
		Control_RF_addr <= "01";
		Control_RF_WregEn <= '1';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		--
		-- sub
		-- Fetch : IR <= PC ; PC <= PC + 1
		Control_BusAccess <= "00000";
		Control_IRin <= '1';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '1';
		Control_PCsel <= "10";
		wait until rising_edge(clk);
		-- Decode
		Control_BusAccess <= "00000";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- A <= rb
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "10";
		Control_RF_WregEn <= '1';
		Control_RF_rst <= '0';
		Control_Ain <= '1';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- C <= A - rc
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "11";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '1';
		Control_ALU_op <= "001";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- ra <= C
		Control_BusAccess <= "00100";
		Control_IRin <= '0';
		Control_RF_addr <= "01";
		Control_RF_WregEn <= '1';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		--
		-- st
		-- Fetch : IR <= PC ; PC <= PC + 1
		Control_BusAccess <= "00000";
		Control_IRin <= '1';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '1';
		Control_PCsel <= "10";
		wait until rising_edge(clk);
		-- Decode
		Control_BusAccess <= "00000";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- A <= Imm2
		Control_BusAccess <= "00010";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '1';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- C <= A + Imm2
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "10";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '1';
		Control_ALU_op <= "000";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- writeAddr <= C
		Control_BusAccess <= "00100";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '1';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- M[rb + Imm2] <= ra
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "01";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '1';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		--
		-- st
		-- Fetch : IR <= PC ; PC <= PC + 1
		Control_BusAccess <= "00000";
		Control_IRin <= '1';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '1';
		Control_PCsel <= "10";
		wait until rising_edge(clk);
		-- Decode
		Control_BusAccess <= "00000";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- A <= Imm2
		Control_BusAccess <= "00010";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '1';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- C <= A + Imm2
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "10";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '1';
		Control_ALU_op <= "000";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- writeAddr <= C
		Control_BusAccess <= "00100";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '1';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- M[rb + Imm2] <= ra
		Control_BusAccess <= "10000";
		Control_IRin <= '0';
		Control_RF_addr <= "01";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '1';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- done
		-- Fetch : IR <= PC ; PC <= PC + 1
		Control_BusAccess <= "00000";
		Control_IRin <= '1';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '1';
		Control_PCsel <= "10";
		wait until rising_edge(clk);
		-- Decode
		Control_BusAccess <= "00000";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		-- Done
		Control_BusAccess <= "00000";
		Control_IRin <= '0';
		Control_RF_addr <= "00";
		Control_RF_WregEn <= '0';
		Control_RF_rst <= '0';
		Control_Ain <= '0';
		Control_Cin <= '0';
		Control_ALU_op <= "111";
		Control_Mem_in <= '0';
		Control_Data_MemEn <= '0';
		Control_Pcin <= '0';
		Control_PCsel <= "00";
		wait until rising_edge(clk);
		done <= true;
		wait;
	end process;

end tb_datapath_arch;
