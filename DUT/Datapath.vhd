library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

--------------------------------------------------------------
-- Datapath: Refactored with consistent signal naming (no Reg C)
--------------------------------------------------------------

entity Datapath is
    generic(
        Dwidth : integer := 16;
        Awidth : integer := 6;
        dept   : integer := 64
    );
    port(
        clk_i               : in std_logic;
		ena_i				: in std_logic;
		rst_i				: in std_logic;

		
        alu_c_o             : out std_logic;
        alu_z_o             : out std_logic;
        alu_n_o             : out std_logic;
        o_opcode            : out std_logic_vector(3 downto 0);

		-- control signals
        DTCM_wr_i       : in std_logic;
        DTCM_addr_sel_i : in std_logic;		
        DTCM_addr_out_i : in std_logic;	
        DTCM_addr_in_i  : in std_logic;		
        DTCM_out_i      : in std_logic;
        ALU_op         : in std_logic_vector(2 downto 0); 
        Ain_i           : in std_logic;
        RF_WregEn_i     : in std_logic;
        RF_out_i        : in std_logic;
        RF_addr_rd_i    : in std_logic_vector(1 downto 0);
        RF_addr_wr_i    : in std_logic_vector(1 downto 0);		
        IRin_i          : in std_logic;
        PCin          : in std_logic;
        PCsel         : in std_logic_vector(1 downto 0);
        Imm1_in_i       : in std_logic;
        Imm2_in_i       : in std_logic;

		-- TB inputs
		DTCM_tb_out    	    : out std_logic_vector(Dwidth-1 downto 0);
		tb_active_i         : in std_logic;
		DTCM_tb_addr_in_i   : in std_logic_vector(Awidth-1 downto 0);
		DTCM_tb_addr_out_i  : in std_logic_vector(Awidth-1 downto 0);
		DTCM_tb_wr_i        : in std_logic;
        DTCM_tb_in_i      	: in std_logic_vector(Dwidth-1 downto 0);
		ITCM_tb_in_i        : in std_logic_vector(Dwidth-1 downto 0);
        ITCM_tb_addr_in_i   : in std_logic_vector(Awidth-1 downto 0);
        ITCM_tb_wr_i        : in std_logic

    );
end Datapath;

architecture DataArc of Datapath is

    signal rf_addr_mux_r              : std_logic_vector(3 downto 0);
    signal imm1_ext_r, imm2_ext_r     : std_logic_vector(Dwidth-1 downto 0);
    signal imm_pc_r                   : std_logic_vector(7 downto 0);
    signal pc_addr_r                  : std_logic_vector(Awidth-1 downto 0);
    signal instr_r                    : std_logic_vector(Dwidth-1 downto 0);
    signal bus_a_r                    : std_logic_vector(Dwidth-1 downto 0);
    signal bus_b_r                    : std_logic_vector(Dwidth-1 downto 0);
    signal rf_data_r                  : std_logic_vector(Dwidth-1 downto 0);
    signal reg_a_q                    : std_logic_vector(Dwidth-1 downto 0);
    signal data_wr_en_mux_r           : std_logic;
    signal data_wr_data_mux_r         : std_logic_vector(Dwidth-1 downto 0);
    signal data_wr_addr_mux_r         : std_logic_vector(Awidth-1 downto 0);
	signal data_addr_out_mux_r 		  : std_logic_vector(Awidth-1 downto 0);
	signal data_addr_in_mux_r  		  : std_logic_vector(Awidth-1 downto 0);
    signal data_rd_addr_mux_r         : std_logic_vector(Awidth-1 downto 0);
	signal data_wr_addr_mux_q         : std_logic_vector(Awidth-1 downto 0);
	signal data_rd_addr_mux_q         : std_logic_vector(Awidth-1 downto 0);
    signal data_mem_out_r             : std_logic_vector(Dwidth-1 downto 0);
    signal mem_addr_dff_q             : std_logic_vector(Dwidth-1 downto 0);

begin

    -- IR
    mapIR: IR generic map(Dwidth) port map (
        clk_i         => clk_i,
        ena_i        => ena_i,
        rst_i         => rst_i,
        RFaddr_rd_i   => RF_addr_rd_i,
        RFaddr_wr_i   => RF_addr_wr_i,
        IR_content_i  => instr_r,
        o_opcode      => o_opcode,
        signext1_o    => imm1_ext_r,
        signext2_o    => imm2_ext_r,
        imm_to_PC_o   => imm_pc_r
    );

    -- Program Memory
    mapProgMem: ProgMem generic map(Dwidth, Awidth, dept) port map(
        clk => clk_i, memEn => ITCM_tb_wr_i, WmemData => ITCM_tb_in_i,
        WmemAddr => ITCM_tb_addr_in_i, RmemAddr => pc_addr_r,
        RmemData => instr_r
    );

    -- PC Logic
    mapPC: PCLogic generic map(Awidth) port map(
        clk_i => clk_i, i_PCin => PCin, i_PCsel => PCsel,
        IR_imm_i => imm_pc_r,
        currentPC_o => pc_addr_r
    );

    -- Register File
    mapRegisterFile: RF port map(
        clk => clk_i, rst => rst_i, WregEn => RF_WregEn_i,
        WregData => bus_a_r, RregAddr => rf_addr_mux_r, WregAddr => rf_addr_mux_r,
        RregData => rf_data_r
    );

    -- ALU (writes directly to bus A)
    mapALU: ALU_main generic map(Dwidth) port map(
        reg_a_q_i   => reg_a_q,
        reg_b_r_i   => bus_b_r,
        i_ctrl    	=> ALU_op,
		Ain_i		=> Ain_i,
        result_o    => bus_a_r,
        cflag_o     => alu_c_o,
        nflag_o     => alu_n_o,
        zflag_o     => alu_z_o
    );

    -- Register A
    mapReg_A: GenericRegister generic map(Dwidth) port map(
        clk_i   => clk_i,
        ena_i   => Ain_i,
        rst_i   => rst_i,
        d_i     => bus_a_r,
        q_o     => reg_a_q
    );

    -- Data Memory
    mapDataMem: dataMem generic map(Dwidth, Awidth, dept) port map(
        clk => clk_i, memEn => data_wr_en_mux_r, WmemData => data_wr_data_mux_r,
        WmemAddr => data_wr_addr_mux_r, RmemAddr => data_rd_addr_mux_r,
        RmemData => data_mem_out_r
    );

    -- DFF for memory address read
    mapMemIn_D_FF_rd: GenericRegister generic map(Awidth) port map(
        clk_i   => clk_i,
        ena_i   => DTCM_addr_out_i,
        rst_i   => rst_i,
        d_i     => data_addr_out_mux_r,
        q_o     => data_rd_addr_mux_q
    );
	-- DFF for memory address write
    mapMemIn_D_FF_wr: GenericRegister generic map(Awidth) port map(
        clk_i   => clk_i,
        ena_i   => DTCM_addr_in_i,
        rst_i   => rst_i,
        d_i     => data_addr_in_mux_r,
        q_o     => data_wr_addr_mux_q
    );

	-- Imm1
	tristate_imm1: BidirPin generic map(Dwidth) port map(
		i_data  => imm1_ext_r,
		enable_out    => Imm1_in_i,
		o_data => bus_b_r
	);

	-- Imm2
	tristate_imm2: BidirPin generic map(Dwidth) port map(
		i_data  => imm2_ext_r,
		enable_out    => Imm2_in_i,
		o_data => bus_b_r
	);

	-- Register File output
	tristate_RF_data: BidirPin generic map(Dwidth) port map(
		i_data  => rf_data_r,
		enable_out    => RF_out_i,
		o_data => bus_b_r
	);

	-- Data memory output
	tristate_data_out: BidirPin generic map(Dwidth) port map(
		i_data  => data_mem_out_r,
		enable_out    => DTCM_out_i,
		o_data => bus_b_r
	);
    -- Output to TB
    DTCM_tb_out <= data_mem_out_r;

    -- MUX logic for TB vs CPU memory control
    data_wr_en_mux_r      <= DTCM_wr_i when tb_active_i = '0' else DTCM_tb_wr_i;
    data_wr_data_mux_r    <= bus_b_r       when tb_active_i = '0' else DTCM_tb_in_i;
    data_wr_addr_mux_r    <= data_wr_addr_mux_q(Awidth-1 downto 0) when tb_active_i = '0' else DTCM_tb_addr_in_i;
    data_rd_addr_mux_r    <= data_rd_addr_mux_q(Awidth-1 downto 0) when tb_active_i = '0' else DTCM_tb_addr_out_i;
	data_addr_out_mux_r	  <= bus_a_r(Awidth-1 downto 0)	when DTCM_addr_sel_i = '0' else bus_b_r(Awidth-1 downto 0);
	data_addr_in_mux_r	  <= bus_a_r(Awidth-1 downto 0)	when DTCM_addr_sel_i = '0' else bus_b_r(Awidth-1 downto 0);
	

end DataArc;

