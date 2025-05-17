 library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------
entity ControlLines is
generic( StateLength: integer:=5); -- 2^5 bits to describe states
port(	clk, rst: in std_logic;
		i_state: in std_logic_vector(StateLength-1 downto 0);
		i_opcode: in std_logic_vector(3 downto 0);
		alu_c, alu_z, alu_n: in std_logic; -- flags from ALU unit
		-- control lines --
		RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin: out std_logic;
		RF_addr, PCsel: out std_logic_vector(1 downto 0);
		RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin: out std_logic; -- RF_rst to be used as global reset?
		ALU_op: out std_logic_vector(2 downto 0);
		-- status lines --
		o_cflag, o_zflag, o_nflag: out std_logic;
		status_bits : out std_logic_vector(9 downto 0) -- all status bits concatenated 
	);
end ControlLines;
--------------------------------------------------------------
architecture ctrlArch of ControlLines is
	signal bus_ctrl_vec : std_logic_vector(4 downto 0);
	signal almostout_flags : std_logic_vector(2 downto 0); -- (C,Z,N)
	signal concat_op_f : std_logic_vector(4 downto 0);
	
begin
	RF_out 		<= bus_ctrl_vec(4);
	Data_mem_out<= bus_ctrl_vec(3);
	Cout 		<= bus_ctrl_vec(2);
	Imm2_in	 	<= bus_ctrl_vec(1);
	Imm1_in 	<= bus_ctrl_vec(0);
	-- bus_ctrl_vec=(RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in)
	concat_op_f(4 downto 1) <= i_opcode;
	concat_op_f(0) <= almostout_flags(2);
	-- concat_op_f=(opcode, cflag)
	
	----- outputting content of flags register out -----
	o_cflag <= almostout_flags(2);
	o_zflag <= almostout_flags(1);
	o_nflag <= almostout_flags(0);
	----------------------------------------------------
	
	
	
	------- All control lines' names & size(default is 1): -------
	-- bus_ctrl_vec(5), IRin, RF_addr(2), RF_WregEn, RF_rst, Ain, Cin, ALU_op(3), Mem_in, ..
	-- .. Data_MemEn, Pcin, PCsel(2).
	--------------------------------------------------------------
	CtrlLogic: PROCESS (i_state,concat_op_f) -- sensitivity list? ****
	-- this process is a pure-logic process (writting with 'case' is easier than 'with-select')
	variable state_var: integer range 0 to 31;
	BEGIN
		state_var := conv_integer(i_state);
		case(state_var) is
			when 0 => -- state 0
				bus_ctrl_vec <= "00000";
				IRin <= '0';
				RF_rst <= '1';
				Data_MemEn <= '0';
				Pcin <= '1';
				PCsel <= "00";
				ALU_op <= "111";
			when 1 => -- state 1
				bus_ctrl_vec <= "00000";
				IRin <= '1';
				RF_addr <= "00";
				RF_WregEn <= '0';
				RF_rst <= '0';
				Data_MemEn <= '0';
				Pcin <= '1';
				PCsel <= "10";
				ALU_op <= "111";
			when 2 => -- state 2
				bus_ctrl_vec <= "10000";
				IRin <= '0';
				RF_addr <= "10";
				RF_WregEn <= '0';
				RF_rst <= '0';
				Ain <= '1';
				Data_MemEn <= '0';
				Pcin <= '0';
				ALU_op <= "111";
			when 3 => -- state 3
				RF_WregEn <= '0';
				Data_MemEn <= '0';
				Pcin <= '1';
				PCsel <= "01";
				ALU_op <= "111";
			when 4 => -- state 4
				RF_WregEn <= '0';
				Data_MemEn <= '0';
				--Pcin <= '1';
				ALU_op <= "111";
				case (concat_op_f) is -- (opcode(4), cflag - register content)
					when "10001" =>
						PCsel <= "01"; -- jump
						Pcin <= '1';
					when "10000" =>
						PCsel <= "10"; -- don't jump
						Pcin <= '0';
					when "10010" =>
						PCsel <= "01"; -- jump
						Pcin <= '1';
					when others => -- (meant for "10010") 
						PCsel <= "10"; -- don't jump
						Pcin <= '0';
				end case;
			when 5 => -- state 5
				bus_ctrl_vec <= "00001";
				RF_addr <= "01";
				RF_WregEn <= '1';
				RF_rst <= '0';
				Data_MemEn <= '0';
				Pcin <= '0';
				ALU_op <= "111";
			when 6 => -- state 6
				bus_ctrl_vec <= "00010";
				IRin <= '0';
				RF_WregEn <= '0';
				Ain <= '1';
				Data_MemEn <= '0';
				Pcin <= '0';
				ALU_op <= "111";
			when 7 => -- state 7 (done)
				IRin <= '0';
				Pcin <= '0';
				PCsel <= "00"; -- all not needed?*****
				ALU_op <= "111";
			when 8 => -- state 8
				bus_ctrl_vec <= "10000";
				IRin <= '0';
				RF_addr <= "11";
				RF_WregEn <= '0';
				RF_rst <= '0';
				Ain <= '0';
				Cin <= '1';
				ALU_op <= "000";
				Data_MemEn <= '0';
				Pcin <= '0';
			when 9 => -- state 9
				bus_ctrl_vec <= "10000";
				IRin <= '0';
				RF_addr <= "11";
				RF_WregEn <= '0';
				RF_rst <= '0';
				Ain <= '0';
				Cin <= '1';
				ALU_op <= "001";
				Data_MemEn <= '0';
				Pcin <= '0';
			when 10 => -- state 10
				bus_ctrl_vec <= "10000";
				IRin <= '0';
				RF_addr <= "11";
				RF_WregEn <= '0';
				RF_rst <= '0';
				Ain <= '0';
				Cin <= '1';
				ALU_op <= "010";
				Data_MemEn <= '0';
				Pcin <= '0';
			when 11 => -- state 11
				bus_ctrl_vec <= "10000";
				IRin <= '0';
				RF_addr <= "11";
				RF_WregEn <= '0';
				RF_rst <= '0';
				Ain <= '0';
				Cin <= '1';
				ALU_op <= "011";
				Data_MemEn <= '0';
				Pcin <= '0';
			when 12 => -- state 12
				bus_ctrl_vec <= "10000";
				IRin <= '0';
				RF_addr <= "11";
				RF_WregEn <= '0';
				RF_rst <= '0';
				Ain <= '0';
				Cin <= '1';
				ALU_op <= "100";
				Data_MemEn <= '0';
				Pcin <= '0';
			when 13 => -- state 13
				bus_ctrl_vec <= "00100";
				IRin <= '0';
				RF_addr <= "01";
				RF_WregEn <= '1';
				RF_rst <= '0';
				Cin <= '0';
				Data_MemEn <= '0';
				Pcin <= '0';
				ALU_op <= "111";
			when 14 => -- state 14
				bus_ctrl_vec <= "10000";
				IRin <= '0';
				RF_addr <= "10";
				RF_WregEn <= '0';
				RF_WregEn <= '0';
				Ain <= '0';
				Cin <= '1';
				ALU_op <= "000";
				Data_MemEn <= '0';
				Pcin <= '0';
			when 15 => -- state 15
				bus_ctrl_vec <= "00100";
				IRin <= '0';
				RF_WregEn <= '0';
				Cin <= '0';
				Mem_in <= '1';
				Data_MemEn <= '0';
				Pcin <= '0';
			when 16 => -- state 16
				bus_ctrl_vec <= "10000";
				IRin <= '0';
				RF_addr <= "01";
				RF_WregEn <= '0';
				RF_rst <= '0';
				Mem_in <= '0';
				Data_MemEn <= '1';
				Pcin <= '0';
				ALU_op <= "111";
			when 17 => -- state 17
				bus_ctrl_vec <= "00100";
				IRin <= '0';
				RF_WregEn <= '0';
				RF_rst <= '0';
				Cin <= '0';
				Data_MemEn <= '0';
				Pcin <= '0';
				ALU_op <= "111";
			when 18 => -- state 18
				bus_ctrl_vec <= "01000";
				IRin <= '0';
				RF_addr <= "01";
				RF_WregEn <= '1';
				RF_rst <= '0';
				Data_MemEn <= '0';
				Pcin <= '0';
				ALU_op <= "111";
			when 19 => -- state 19 (decode)
				bus_ctrl_vec <= "00000";
				RF_WregEn <= '0';
				IRin <= '0';
				Pcin <= '0';
				PCsel <= "00"; -- resetting all input lines that were on during state 1 (fetch)
				ALU_op <= "111";
			when others => 
			-- there are no other states (so far), so 'when others' is meaningless
				null;
		end case;
	
	END PROCESS;
	
	flags_register: PROCESS (clk, rst, alu_c, alu_z, alu_n) -- all relevant inputs
	variable state_var: integer range 0 to 31;
	BEGIN
		state_var := conv_integer(i_state);
		if rst = '1' then
			almostout_flags <= "000"; -- all flags to 0
		else
			if (clk'EVENT and clk='1') then
				case (state_var) is
					when 8|9 =>
						almostout_flags <= alu_c & alu_z & alu_n; -- save current values of all ALU flags
					when 10|11|12 =>
						almostout_flags(1 downto 0) <= alu_z & alu_n; -- save current values of Z,N ALU flags
					when others => -- others states should not impact stored flags' values
						null;
				end case;
			end if;
		end if;
	
	END PROCESS;

	with i_opcode select -- status bits mega-mux
		status_bits <= (9 => '1', others => '0') when "1100", -- mov
					   (8 => '1', others => '0') when "1111", -- done
					   (7 => '1', others => '0') when "0010", -- and
					   (6 => '1', others => '0') when "0011", -- or
					   (5 => '1', others => '0') when "0100", -- xor
					   (4 => '1', others => '0') when "1001", -- jnc
					   (3 => '1', others => '0') when "1000", -- jc
					   (2 => '1', others => '0') when "0111", -- jmp
					   (1 => '1', others => '0') when "0001", -- sub
					   (0 => '1', others => '0') when "0000", -- add
					   (others => '0') when others; -- this covers ld,st and everything new.

end ctrlArch;
