library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------
entity StateLogic is
generic( StateLength: integer:=5); -- 2^5 bits to describe states
port(	clk, ena, rst: in std_logic; -- coming from TB through top
		ALU_cflag : in std_logic;
		i_opcode : in std_logic_vector(3 downto 0);
		o_currentstate : out std_logic_vector(StateLength-1 downto 0)
	);
end StateLogic;
--------------------------------------------------------------
architecture StateArch of StateLogic is
	signal current_state, next_state : std_logic_vector(StateLength-1 downto 0);

begin
	o_currentstate <= current_state;
	
	NextStateMachine: PROCESS (ena,rst,current_state, next_state)
	variable current_state_var: integer range 0 to 31; -- range 0 to (2^5 -1) currently 0->19 in use.
	variable opcode_var: integer range 0 to 15; -- range 0 to 2^4 - 1
	BEGIN
	-- **Case argument refused to take in std_logic_vector, converting them into integers. used only for case argument
		current_state_var := conv_integer(current_state); -- convert state into type integer
		opcode_var := conv_integer(i_opcode);
			if rst = '1' then
				next_state <= (others => '0');
			else
				if ena = '1' then
					case (current_state_var) is
						when 1 =>
							next_state <= "10011"; -- NS = State 19 - Decode
						when 19 =>
							case (opcode_var) is
								when 7 => next_state <= "00011"; -- NS = State 3
								when 8|9 => next_state <= "00100"; -- NS = State 4
								when 12 => next_state <= "00101"; -- NS = State 5
								when 13|14 => next_state <= "00110"; -- NS = State 6
								when 15 => next_state <= "00111"; -- NS = State 7
								when 0|1|2|3|4 => next_state <= "00010"; -- NS = State 2
								when others => next_state <= "00001"; -- NS = State 1 (invalid input - send back to fetch)
							end case;
						when 2 =>
							case (opcode_var) is
								when 0 => next_state <= "01000"; -- NS = State 8
								when 1 => next_state <= "01001"; -- NS = State 9
								when 2 => next_state <= "01010"; -- NS = State 10
								when 3 => next_state <= "01011"; -- NS = State 11
								when 4 => next_state <= "01100"; -- NS = State 12
								when others => next_state <= "00001"; -- NS = State 1 (invalid input - send back to fetch)
							end case;
						when 6 =>
							next_state <= "01110"; -- NS = State 14
						when 7 =>
							next_state <= "00111"; -- NS = State 7 ('Done' state)
						when 8|9|10|11|12 =>
							next_state <= "01101"; -- NS = State 13
						when 14 =>
							case (opcode_var) is
								when 13 => next_state <= "10001"; -- NS = State 17
								when 14 => next_state <= "01111"; -- NS = State 15
								when others => next_state <= "00001"; -- NS = State 1 (invalid input - send back to fetch)
							end case;
						when 15 =>
							next_state <= "10000"; -- NS = State 16
						when 17 =>
							next_state <= "10010"; -- NS = State 18
						when others => -- * this includes states: 0,3,4,5,13,16,18
							next_state <= "00001"; -- NS = State 1
					end case;
				else next_state <= current_state; -- NS = current state
				end if;
			end if;

	END PROCESS;


	next_st_register: PROCESS (clk,next_state)
	BEGIN
		if rst = '1' then
			current_state <= (others => '0');
		elsif ena = '1' then
			if (clk'EVENT and clk='1') then
				current_state <= next_state;
			end if;
		end if;
	END PROCESS;

end StateArch;
