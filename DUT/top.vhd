LIBRARY ieee; -- Import IEEE standard logic library
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all; -- Import component declarations from aux_package

-------------------------------------
ENTITY top IS
-- Top-level entity for integrating Datapath and Control units

generic(
    Dwidth      : integer := 16; -- Data width
    Awidth      : integer := 6;  -- Address width (2^6 = 64 locations)
    dept        : integer := 64; -- Depth of memory
    StateLength : integer := 5   -- Number of bits to represent FSM states
);
port(
    clk_i              : in std_logic;  -- Clock signal fed from TB
    rst_i              : in std_logic;  -- Reset signal fed from TB
    ena_i              : in std_logic;  -- Enable signal for control unit fed from TB
    done_o             : out std_logic; -- Done flag to TB
	

		-- TB inputs
	DTCM_tb_out    	    : out std_logic_vector(Dwidth-1 downto 0);
	tb_active_i         : in std_logic:= '0';
	DTCM_tb_addr_in_i   : in std_logic_vector(Awidth-1 downto 0);
	DTCM_tb_wr_i        : in std_logic;
	DTCM_tb_addr_out_i  : in std_logic_vector(Awidth-1 downto 0);
	DTCM_tb_in_i      	: in std_logic_vector(Dwidth-1 downto 0);
	ITCM_tb_in_i        : in std_logic_vector(Dwidth-1 downto 0);
	ITCM_tb_addr_in_i   : in std_logic_vector(Awidth-1 downto 0);
	ITCM_tb_wr_i        : in std_logic
);
END top;

ARCHITECTURE topArch OF top IS 

    -- Signals from Datapath to Control (flags and opcode)
    signal alu_c_o, alu_z_o, alu_n_o : std_logic;                    -- ALU flags: carry, zero, negative
    signal opcode                  : std_logic_vector(3 downto 0); -- Opcode extracted from instruction

    -- Control signals sent to Datapath

	 signal DTCM_addr_sel_i  : std_logic;
	 signal DTCM_addr_out_i  : std_logic;
	 signal DTCM_addr_in_i   : std_logic;
	 signal DTCM_out_i       : std_logic;
	 signal DTCM_wr_i 		  : std_logic;
	 signal ALU_op          : std_logic_vector(2 downto 0);
	 signal Ain            : std_logic;
	 signal RF_WregEn_o      : std_logic;
	 signal RF_out_o         : std_logic;
	 signal RF_addr_rd_o     : std_logic_vector(1 downto 0);
	 signal RF_addr_wr_o     : std_logic_vector(1 downto 0);
	 signal IRin_i           : std_logic;
	 signal PCin           : std_logic;
	 signal PCsel          : std_logic_vector(1 downto 0);
	 signal Imm1_in        : std_logic;
	 signal Imm2_in        : std_logic;
	 signal status_bits_r    : std_logic_vector(14 downto 0);
	 signal done_r			  : std_logic;

BEGIN

    -- Datapath Instantiation
    mapDatapath: Datapath generic map(Dwidth, Awidth, dept) port map(
        clk_i              => clk_i,
        ena_i              => ena_i,
		rst_i              => rst_i,

        alu_c_o            => alu_c_o,
        alu_z_o            => alu_z_o,
        alu_n_o            => alu_n_o,
        o_opcode           => opcode,
		

		
        DTCM_wr_i          => DTCM_wr_i,
        DTCM_addr_sel_i    => DTCM_addr_sel_i,
        DTCM_addr_out_i    => DTCM_addr_out_i,
        DTCM_addr_in_i     => DTCM_addr_in_i,
        DTCM_out_i         => DTCM_out_i,
        ALU_op            => ALU_op,
        Ain              => Ain,
        RF_WregEn_o        => RF_WregEn_o,
        RF_out_o           => RF_out_o,
        RF_addr_rd_o       => RF_addr_rd_o,
        RF_addr_wr_o       => RF_addr_wr_o,
        IRin_i             => IRin_i,
        PCin             => PCin,
        PCsel            => PCsel,
        Imm1_in          => Imm1_in,
        Imm2_in          => Imm2_in,

        DTCM_tb_out        => DTCM_tb_out,
        tb_active_i        => tb_active_i,
        DTCM_tb_addr_in_i  => DTCM_tb_addr_in_i,
		DTCM_tb_addr_out_i => DTCM_tb_addr_out_i,
        DTCM_tb_wr_i       => DTCM_tb_wr_i,
        DTCM_tb_in_i       => DTCM_tb_in_i,
        ITCM_tb_in_i       => ITCM_tb_in_i,
        ITCM_tb_addr_in_i  => ITCM_tb_addr_in_i,
        ITCM_tb_wr_i       => ITCM_tb_wr_i
    );


    -- Control Unit Instantiation
    mapControl: ControlUnit generic map(StateLength) port map(
        clk_i              => clk_i,
        rst_i              => rst_i,
        ena_i              => ena_i,

        ALU_c_i            => alu_c_o,
        ALU_z_i            => alu_z_o,
        ALU_n_i            => alu_n_o,
        i_opcode           => opcode,
		done			   => done_r,
        DTCM_wr_o          => DTCM_wr_i,
        DTCM_addr_sel_o    => DTCM_addr_sel_i,
        DTCM_addr_out_o    => DTCM_addr_out_i,
        DTCM_addr_in_o     => DTCM_addr_in_i,
        DTCM_out_o         => DTCM_out_i,
        ALU_op            => ALU_op,
        Ain              => Ain,
        RF_WregEn_o        => RF_WregEn_o,
        RF_out_o           => RF_out_o,
        RF_addr_rd_o       => RF_addr_rd_o,
        RF_addr_wr_o       => RF_addr_wr_o,
        IRin_o             => IRin_i,
        PCin             => PCin,
        PCsel            => PCsel,
        Imm1_in          => Imm1_in,
        Imm2_in          => Imm2_in,


        status_bits_o      => status_bits_r(14 downto 0)
        
    );

	done_o <= done_r;
END topArch;