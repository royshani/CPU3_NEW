library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;
--------------------------------------------------------------
entity IR is
    generic(Dwidth : integer := 16); -- Instruction register width
    port(
        clk_i        : in std_logic;
        ena_i        : in std_logic;  -- enable = IRin
        rst_i        : in std_logic;  -- reset = system_rst
        RFaddr_rd_o  : in std_logic_vector(1 downto 0);
		RFaddr_wr_o  : in std_logic_vector(1 downto 0);
        IR_content_i  : in std_logic_vector(Dwidth-1 downto 0);
		addr_rd_o, addr_wr_o   : out std_logic_vector(3 downto 0);
        o_OPCODE      : out std_logic_vector(3 downto 0);
        signext1_o    : out std_logic_vector(Dwidth-1 downto 0);
        signext2_o    : out std_logic_vector(Dwidth-1 downto 0);
        imm_to_PC_o   : out std_logic_vector(7 downto 0)
    );
end IR;
--------------------------------------------------------------

architecture IRArch of IR is

    -- IR internal register
    signal IR_q : std_logic_vector(Dwidth-1 downto 0);

    -- Extracted fields
    signal ra_r, rb_r, rc_r       : std_logic_vector(3 downto 0);

    signal immShort_r             : std_logic_vector(3 downto 0);
    signal immLong_r              : std_logic_vector(7 downto 0);

begin

    -- Instruction register load logic
    InstructionReg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                IR_q <= (others => '0');
            elsif ena_i = '1' then
                IR_q <= IR_content_i;
            end if;
        end if;
    end process;

    -- Field extraction from IR register
    o_OPCODE     <= IR_q(15 downto 12);
    ra_r         <= IR_q(11 downto 8);
    rb_r         <= IR_q(7 downto 4);
    rc_r         <= IR_q(3 downto 0);
    immShort_r   <= IR_q(3 downto 0);
    immLong_r    <= IR_q(7 downto 0);
    imm_to_PC_o  <= IR_q(7 downto 0);

    -- Register File address selection
    with RFaddr_rd_o select -- choose which reg to read from
        addr_rd_o <= ra_r when "01",
                  rb_r when "10",
                  rc_r when "11",
                  "0000" when others;
				  
	with RFaddr_wr_o select -- choose which reg to write to
        addr_wr_o <= ra_r when "01",
                  rb_r when "10",
                  rc_r when "11",
                  "0000" when others;

    -- Sign-extension of 4-bit immediate
    signext2_o(3 downto 0) <= immShort_r;
    with immShort_r(3) select
        signext2_o(Dwidth-1 downto 4) <= (others => '1') when '1',
                                         (others => '0') when others;

    -- Sign-extension of 8-bit immediate
    signext1_o(7 downto 0) <= immLong_r;
    with immLong_r(7) select
        signext1_o(Dwidth-1 downto 8) <= (others => '1') when '1',
                                         (others => '0') when others;
end IRArch;