library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------
entity IR is
generic( Dwidth: integer:=16); -- width of IR register
port( clk, ena, rst: in std_logic; -- ena = IRin, rst = system_rst
	  ctrl_RFaddr: in std_logic_vector(1 downto 0);
	  i_IR_content: in std_logic_vector(Dwidth-1 downto 0);
	  o_OPCODE, o_addr : out std_logic_vector(3 downto 0); -- o_addr = output of RFaddr mux
	  o_signext1, o_signext2 : out std_logic_vector(Dwidth-1 downto 0);
	  o_imm_to_PC : out std_logic_vector(7 downto 0)
	);
end IR;
--------------------------------------------------------------
architecture IRArch of IR is

	signal ra,rb,rc : std_logic_vector(3 downto 0);
	signal immShort : std_logic_vector(3 downto 0); -- to signext2
	signal immLong : std_logic_vector(7 downto 0); -- to signext1
	signal IR_reg : std_logic_vector(Dwidth-1 downto 0); -- IR register

begin
	InstructionReg: PROCESS (clk,ena,i_IR_content,rst)
	BEGIN
		if rst = '1' then
			IR_reg <= (others => '0');
		elsif ena = '1' then -- reset is 0, check enable bit
			if (clk'EVENT and clk='1') then -- rising edge
				IR_reg <= i_IR_content;
			end if;
		else null; -- might be unneccesary
		end if;
		
	END PROCESS;
	
	-- splitting IR regsiter into different fields
	ra <= IR_reg(11 downto 8);
	rb <= IR_reg(7 downto 4);
	rc <= IR_reg(3 downto 0);
	o_OPCODE <= IR_reg(15 downto 12);
	immShort <= IR_reg(3 downto 0);
	immLong <= IR_reg(7 downto 0);
	o_imm_to_PC <= IR_reg(7 downto 0);
	
	-- RFaddr mux - controls which 4 bits are outputted towards the RF
	with ctrl_RFaddr select
		o_addr <= ra when "01",
				  rb when "10",
				  rc when "11",
				  "0000" when others;

	-- Sign extension logic
	o_signext2 (3 downto 0) <= immShort;
	with immShort(3) select
		o_signext2(Dwidth-1 downto 4) <= (others => '1') when '1',
							       (others => '0') when others;
	
	o_signext1(7 downto 0) <= immLong;
	with immLong(7) select
		o_signext1(Dwidth-1 downto 8) <= (others => '1') when '1',
										 (others => '0') when others;
	
	

end IRArch;
