library ieee;
use ieee.std_logic_1164.all;
-----------------------------------------------------------------
--this component exists to save time writing the same code in different modules
entity BidirPin is
	generic( Dwidth: integer:=16 );
	port(
			i_data: in std_logic_vector(Dwidth-1 downto 0);
			o_data: out std_logic_vector(Dwidth-1 downto 0);
			enable_out: in std_logic -- controls whether the data is poured out
	);
end BidirPin;
---------------------------------------------------------
architecture b_tristate of BidirPin is
begin 
	o_data <= i_data when enable_out='1' else (others => 'Z'); -- when enable=1, the input data is shortened to the output, else - high-z.

end b_tristate;

