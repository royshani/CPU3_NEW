library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------
entity PCLogic is
generic( Awidth: integer:=6 ); -- 2^6=64. address of each line in the Data memory segement)
port( clk, i_PCin : in std_logic;
	  i_PCsel : in std_logic_vector(1 downto 0);
	  i_IR_imm : in std_logic_vector(7 downto 0); -- VECTOR SIZE MAKES NO SENSE - ????
	  o_currentPC : out std_logic_vector(Awidth-1 downto 0)
	);
end PCLogic;
--------------------------------------------------------------
architecture PCArch of PCLogic is
	component FA is
		port (xi, yi, cin:in std_logic;
			      s, cout:out std_logic);
	end component;
	signal current_PC : std_logic_vector(7 downto 0); -- PC Register is the same size as IR input (8 bits),
														-- we only route the lowest 6 bits to ProgMem
	signal zero_vector,PC_plus1,PC_plusIR,next_PC : std_logic_vector(7 downto 0); -- same length as IR input (8 bits)
	signal carry_vec : std_logic_vector(7 downto 0); -- same length as IR input (8 bits)

BEGIN
	zero_vector <= (others => '0');
	o_currentPC <= current_PC(Awidth-1 downto 0); -- only outputting the lowest 6 bits to ProgMem
	PC_plus1 <= current_PC + 1;
	
	with i_PCsel select
		next_PC <= 	PC_plus1 when "10",
					PC_plusIR when "01",
					zero_vector when others;

	PC_reg: PROCESS (clk,next_PC,i_PCin)
	BEGIN
		if i_PCin = '1' then
			if (clk'EVENT and clk='1') then
				current_PC <= next_PC;
				report "!!!! next PC updated" severity note;
			end if;
		end if;
	
	END PROCESS;


	-- Ripple Adder to create PC + IR[7:0] --
	MapFirstFA : FA port map (
			xi => current_PC(0),
			yi => i_IR_imm(0),
			cin => '0',
			s => PC_plusIR(0),
			cout => carry_vec(0)
	);
	MapRestFA : for i in 1 to 7 generate
		chain : FA port map (
			xi => current_PC(i),
			yi => i_IR_imm(i),
			cin => carry_vec(i-1),
			s => PC_plusIR(i),
			cout => carry_vec(i)
		);
	end generate;

end PCArch;