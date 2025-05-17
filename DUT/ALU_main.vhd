library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------
entity ALU_main is
generic( Dwidth: integer:=16); -- data witdh (16 bit register, same as RF width)
port(	i_A, i_B: in std_logic_vector(Dwidth-1 downto 0); -- R[rb] = A, R[rc] = B ***
		i_ctrl: in std_logic_vector(2 downto 0); -- ALUOP control bits
		o_C: out std_logic_vector(Dwidth-1 downto 0);
		o_cflag, o_nflag, o_zflag: out std_logic
		);

end ALU_main;
-------------------------------------------------------------------
-- PURE LOGIC ALU UNIT - BASED UPON LAB 1 ADDERSUB SUB-MODULE -----
-- NOTE: unused opcodes currently are set to ouput High-Z vector --
-------------------------------------------------------------------
architecture ALUarch of ALU_main is
	component FA is
		port (xi, yi, cin:in std_logic;
			      s, cout:out std_logic);
	end component;
	SIGNAL Ripple_reg, AdderSub_result : std_logic_vector(Dwidth-1 downto 0); -- inter-mediate FA connection
	SIGNAL cin : std_logic ; -- carry-in bit, used for subtraction
	SIGNAL manip_B : std_logic_vector(Dwidth-1 downto 0); -- actual input into the Ripple Adder
	SIGNAL ALU_almostout : std_logic_vector(Dwidth-1 downto 0);
	SIGNAL zero_signal: std_logic_vector(Dwidth-1 downto 0); -- used for comparison when calculating zflag **MIGHT ERROR OUT**
	signal inter_A,inter_B: std_logic_vector(Dwidth-1 downto 0); -- meant to bug-fix warnings on arith. oper. on unassigned values.
begin
	-- setting up inter-mediate signals --
	-- *BUG FIX* - warnings for arithmatic operations on undefined signals -- 
	inter_A <= i_A when (i_A(0)='1') else i_A when (i_A(0)='0') else zero_signal; -- if signal is not 'valid' - use zero signal instead
	inter_B <= i_B when (i_B(0)='1') else i_B when (i_B(0)='0') else zero_signal; -- same ^^
	--
	zero_signal <= (others => '0');
	manip_B <= not inter_B when (i_ctrl="001") else inter_B; -- NOT(B) when opcode=sub
	cin <= '1' when (i_ctrl="001") else '0'; -- cin=1 only when doing subtraction

	-- same Ripple Adder as seen in example from tutorials --
	MapFirstFA : FA port map (
			xi => manip_B(0),
			yi => inter_A(0),
			cin => cin,
			s => AdderSub_result(0),
			cout => Ripple_reg(0)
	);
	MapRestFA : for i in 1 to Dwidth-1 generate
		chain : FA port map (
			xi => manip_B(i),
			yi => inter_A(i),
			cin => Ripple_reg(i-1),
			s => AdderSub_result(i),
			cout => Ripple_reg(i)
		);
	end generate;


	---- flags and output MUXing ----
	with i_ctrl select
		ALU_almostout <= AdderSub_result when "000" | "001", -- ADD | SUB 
						i_A AND i_B when "010", -- AND
						i_A OR i_B when "011", -- OR
						i_A XOR i_B when "100", -- XOR
						(others => '0') when "101", -- unused opcode for now (5)
						(others => '0') when "110", -- unused opcode for now (6)
						(others => '0') when "111", -- unused - default ALU output when unused.
						(others => 'Z') when others; -- the rest of the OPCode cases are undefined
						-- WE ARE NEVER USING THE MSB FOR ANYTHING - CHECK WITH HANAN FOR NECCESITY -- 
	
	o_nflag <= ALU_almostout(Dwidth-1);
	o_zflag <= '1' when ALU_almostout = zero_signal else '0';
	o_cflag <= Ripple_reg(Dwidth-1) when (i_ctrl="000" or i_ctrl="001") else '0';
	o_C <= ALU_almostout;

end ALUarch;
