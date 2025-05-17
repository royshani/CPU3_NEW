library IEEE;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use ieee.std_logic_textio.all;
USE work.aux_package.all;
USE ieee.numeric_std.all;

--------------------------------------------------------------
entity PCLogic is
    generic(Awidth : integer := 6); -- 2^6 = 64: Program memory address width
    port(
        clk_i        : in std_logic;
        i_PCin       : in std_logic;
        i_PCsel      : in std_logic_vector(1 downto 0);
        IR_imm_i     : in std_logic_vector(7 downto 0);
        currentPC_o  : out std_logic_vector(Awidth-1 downto 0)
    );
end PCLogic;
--------------------------------------------------------------
architecture PCArch of PCLogic is

    -- Synchronous register
    signal PC_q : std_logic_vector(7 downto 0);

    -- Combinational logic
    signal zero_vector_r   : std_logic_vector(7 downto 0);
    signal PC_plus1_r      : std_logic_vector(7 downto 0);
    signal PC_plusIR_r     : std_logic_vector(7 downto 0);
    signal next_PC_r       : std_logic_vector(7 downto 0);

    -- Wire connections
    signal carry_vector_w  : std_logic_vector(7 downto 0);

begin

    zero_vector_r <= (others => '0');
    currentPC_o <= PC_q(Awidth-1 downto 0);
    PC_plus1_r <= PC_q + 1;
	
	with i_PCsel select
		next_PC_r <= PC_plus1_r     when "10",
					 PC_plusIR_r    when "01",
					 zero_vector_r  when others;


    PC_reg_proc: process(clk_i,next_PC_r,i_PCin)
    begin
        if i_PCin = '1' then
			if rising_edge(clk_i) then

                PC_q <= next_PC_r;
				report "PCin_i = " & std_logic'image(i_PCin) severity note;
				report "i_PCsel = " & integer'image(to_integer(ieee.numeric_std.unsigned(i_PCsel))) severity note;				
				report "!!!! next PC updated" severity note;
            end if;
        end if;
    end process;

    -- Ripple Adder: PC_q + IR_imm_i
    FA0: FA port map (
        xi   => PC_q(0),
        yi   => IR_imm_i(0),
        cin  => '0',
        s    => PC_plusIR_r(0),
        cout => carry_vector_w(0)
    );

    FA_chain: for i in 1 to 7 generate
        FAi: FA port map (
            xi   => PC_q(i),
            yi   => IR_imm_i(i),
            cin  => carry_vector_w(i-1),
            s    => PC_plusIR_r(i),
            cout => carry_vector_w(i)
        );
    end generate;

end PCArch;
