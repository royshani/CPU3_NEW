library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--------------------------------------------------------------
entity GenericRegister is
generic( Dwidth: integer:=16); -- width of register
port( 	clk, ena, rst : in std_logic;
		i_in : in std_logic_vector(Dwidth-1 downto 0);
		o_out : out std_logic_vector(Dwidth-1 downto 0)
	);
end GenericRegister;
--------------------------------------------------------------
architecture RegArch of GenericRegister is
begin
	GenericReg: PROCESS (clk,ena,rst,i_in)
	BEGIN
		if rst = '1' then
			o_out <= (others => '0');
		elsif ena = '1' then
			if (clk'EVENT and clk='1') then
				o_out <= i_in;
			end if;
		end if;
	END PROCESS;
end RegArch;