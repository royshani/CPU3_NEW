library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;

--------------------------------------------------------------
-- ControlUnit: Top-level controller for multi-cycle CPU
-- Connects FSM (StateLogic) and microcontrol generator (ControlLines)
--------------------------------------------------------------

entity ControlUnit is
    generic(StateLength : integer := 5);  -- Length of state vector (e.g., 5 bits for 32 states)
    port(
        -- Clock, Reset, Enable
        clk_i         : in std_logic;
        rst_i         : in std_logic;
        ena_i         : in std_logic;

        -- ALU status flags
        ALU_c_i       : in std_logic;  -- Carry
        ALU_z_i       : in std_logic;  -- Zero
        ALU_n_i       : in std_logic;  -- Negative
		done		  : out std_logic;
        -- Instruction opcode (from IR)
        i_opcode      : in std_logic_vector(3 downto 0);

        -- Datapath control signals
        DTCM_wr_o       : out std_logic;
		DTCM_addr_sel_o : out std_logic;		
		DTCM_addr_out_o : out std_logic;	
        DTCM_addr_in_o  : out std_logic;		
        DTCM_out_o      : out std_logic;
        ALU_op         : out std_logic_vector(2 downto 0); -- !!! needs to be change to ALUFN_o
        Ain_o           : out std_logic;
        RF_WregEn_o     : out std_logic;
        RF_out_o        : out std_logic;
		
		
		RF_addr_rd_o    : out std_logic_vector(1 downto 0);
        RF_addr_wr_o    : out std_logic_vector(1 downto 0);		
		IRin_o          : out std_logic;
		PCin          : out std_logic;
        PCsel         : out std_logic_vector(1 downto 0);
        Imm1_in_o       : out std_logic;
		Imm2_in_o       : out std_logic;

        -- Debug/Status output: concatenated flags and opcode status
        status_bits_o : out std_logic_vector(14 downto 0)
    );
end ControlUnit;

--------------------------------------------------------------
-- Architecture: Connects StateLogic and ControlLines modules
--------------------------------------------------------------

architecture ControlArch of ControlUnit is
    -- Internal signal for current FSM state
    signal state_r : std_logic_vector(StateLength-1 downto 0);
  signal DTCM_wr_i        : std_logic;
  signal DTCM_addr_sel_i  : std_logic;
  signal DTCM_addr_out_i  : std_logic;
  signal DTCM_addr_in_i   : std_logic;
  signal DTCM_out_i       : std_logic;

  signal RF_addr_rd_i     : std_logic_vector(1 downto 0);
  signal RF_addr_wr_i     : std_logic_vector(1 downto 0);

  signal IRin_i           : std_logic;

  
  signal Imm1_in_i        : std_logic;
  signal Imm2_in_i        : std_logic;


  signal Ain_i            : std_logic;
  signal RF_WregEn_i      : std_logic;
  signal RF_out_i         : std_logic;

  -- And if you want to collect flags/status in one bus:
  signal cflag_i          : std_logic;
  signal zflag_i          : std_logic;
  signal nflag_i          : std_logic;

  signal status_bits_i    : std_logic_vector(14 downto 0);
begin

    ----------------------------------------------------------
    -- FSM Instance: Generates current control state
    ----------------------------------------------------------
    StateLogic_inst: StateLogic
        generic map(StateLength)
        port map (
            clk_i           => clk_i,
            ena_i           => ena_i,
            rst_i           => rst_i,
            ALU_cflag_i     => ALU_c_i,
            i_opcode        => i_opcode,
            current_state_o => state_r
        );

    ----------------------------------------------------------
    -- Microcontroller Instance: Generates control signals
    -- based on current FSM state, opcode, and ALU flags
    ----------------------------------------------------------
    ControlLines_inst: ControlLines
        generic map(StateLength)
        port map (
            clk_i           => clk_i,
            rst_i           => rst_i,
			ena_i			=> ena_i,
            state_i         => state_r,
            i_opcode        => i_opcode,
            ALU_c_i         => ALU_c_i,
            ALU_z_i         => ALU_z_i,
            ALU_n_i         => ALU_n_i,
			done			=> done,
            -- Outputs to datapath
            DTCM_wr_o         => DTCM_wr_i,
            DTCM_addr_sel_o   => DTCM_addr_sel_i,
            DTCM_addr_out_o   => DTCM_addr_out_i,
            DTCM_addr_in_o    => DTCM_addr_in_i,
            DTCM_out_o        => DTCM_out_i,
            ALU_op           => ALU_op,
            Ain_o             => Ain_i,
            RF_WregEn_o       => RF_WregEn_i,
            RF_out_o          => RF_out_i,
            RF_addr_rd_o      => RF_addr_rd_i,
            RF_addr_wr_o      => RF_addr_wr_i,
            IRin_o            => IRin_i,
            PCin            => PCin,
            PCsel           => PCsel,
            Imm1_in_o         => Imm1_in_i,
            Imm2_in_o         => Imm2_in_i,

            -- Flags to status register
            status_bits_o   => status_bits_o(14 downto 0)
        );

end ControlArch;
