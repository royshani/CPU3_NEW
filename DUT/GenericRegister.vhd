library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.aux_package.all;
--------------------------------------------------------------
entity GenericRegister is
    generic(Dwidth : integer := 16); -- width of register
    port(
        clk_i   : in std_logic;
        ena_i   : in std_logic;
        rst_i   : in std_logic;
        d_i     : in std_logic_vector(Dwidth-1 downto 0);
        q_o     : out std_logic_vector(Dwidth-1 downto 0)
    );
end GenericRegister;
--------------------------------------------------------------
architecture RegArch of GenericRegister is
begin
    GenericReg_proc: process(clk_i, ena_i, rst_i, d_i)
    begin
        if rst_i = '1' then
            q_o <= (others => '0');
        elsif ena_i = '1' then
            if rising_edge(clk_i) then
                q_o <= d_i;
            end if;
        end if;
    end process;
end RegArch;
