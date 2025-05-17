library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.aux_package.all;
--------------------------------------------------------------
-- StateLogic: FSM controller that generates current control state
-- based on opcode, ALU flag, and enable/reset
--------------------------------------------------------------

entity StateLogic is
    generic(StateLength : integer := 5); -- 2⁵ = 32 states
    port(
        clk_i         : in std_logic;
        ena_i         : in std_logic;
        rst_i         : in std_logic;
        ALU_cflag_i   : in std_logic;
        i_opcode      : in std_logic_vector(3 downto 0);
        current_state_o : out std_logic_vector(StateLength-1 downto 0)
    );
end StateLogic;

architecture StateArch of StateLogic is

    -- Internal state registers
    signal current_state_q, next_state_r : std_logic_vector(StateLength-1 downto 0);

    -- Encoded states
    constant ST_IDLE         : std_logic_vector(StateLength-1 downto 0) := "00000";
    constant ST_FETCH        : std_logic_vector(StateLength-1 downto 0) := "00001";
    constant ST_RT           : std_logic_vector(StateLength-1 downto 0) := "00010";
    constant ST_JMP          : std_logic_vector(StateLength-1 downto 0) := "00011";
    constant ST_JC           : std_logic_vector(StateLength-1 downto 0) := "00100";
    constant ST_MOVE         : std_logic_vector(StateLength-1 downto 0) := "00101";
    constant ST_LD_OR_ST     : std_logic_vector(StateLength-1 downto 0) := "00110";
    constant ST_DONE         : std_logic_vector(StateLength-1 downto 0) := "00111";
    constant ST_ADD          : std_logic_vector(StateLength-1 downto 0) := "01000";
    constant ST_SUB          : std_logic_vector(StateLength-1 downto 0) := "01001";
    constant ST_AND          : std_logic_vector(StateLength-1 downto 0) := "01010";
    constant ST_OR           : std_logic_vector(StateLength-1 downto 0) := "01011";
    constant ST_XOR          : std_logic_vector(StateLength-1 downto 0) := "01100";
    constant ST_RT_FIN       : std_logic_vector(StateLength-1 downto 0) := "01101";
    constant ST_LD_ST_LOGIC  : std_logic_vector(StateLength-1 downto 0) := "01110";
    constant ST_ST1          : std_logic_vector(StateLength-1 downto 0) := "01111";
    constant ST_ST2          : std_logic_vector(StateLength-1 downto 0) := "10000";
    constant ST_LD1          : std_logic_vector(StateLength-1 downto 0) := "10001";
    constant ST_LD2          : std_logic_vector(StateLength-1 downto 0) := "10010";
    constant ST_DEC          : std_logic_vector(StateLength-1 downto 0) := "10011";

    -- Opcode decoding constants
    constant OP_ADD  : integer := 0;
    constant OP_SUB  : integer := 1;
    constant OP_AND  : integer := 2;
    constant OP_OR   : integer := 3;
    constant OP_XOR  : integer := 4;
    constant OP_JMP  : integer := 7;
    constant OP_JC   : integer := 8;
    constant OP_JNC  : integer := 9;
    constant OP_MOVE : integer := 12;
    constant OP_LD   : integer := 13;
    constant OP_ST   : integer := 14;
    constant OP_DONE : integer := 15;

begin

    -- Connect internal state to output
    current_state_o <= current_state_q;

    ----------------------------------------------------------
    -- Combinational next-state logic
    ----------------------------------------------------------
    NextStateMachine: process(ena_i, rst_i, current_state_q)
        variable current_state_v : integer range 0 to 31;
        variable opcode_v        : integer range 0 to 15;
    begin
        current_state_v := conv_integer(current_state_q);
        opcode_v := conv_integer(i_opcode);

        if rst_i = '1' then
            next_state_r <= ST_IDLE;

        elsif ena_i = '1' then
            case current_state_v is
                when 1 =>  -- FETCH
                    next_state_r <= ST_DEC;

                when 2 =>  -- RT
                    case opcode_v is
                        when OP_ADD  => next_state_r <= ST_ADD;
                        when OP_SUB  => next_state_r <= ST_SUB;
                        when OP_AND  => next_state_r <= ST_AND;
                        when OP_OR   => next_state_r <= ST_OR;
                        when OP_XOR  => next_state_r <= ST_XOR;
                        when others  => next_state_r <= ST_FETCH;
                    end case;

                when 6 =>  -- LD_OR_ST
                    next_state_r <= ST_LD_ST_LOGIC;

                when 7 =>  -- DONE
                    next_state_r <= ST_DONE;

                when 8 | 9 | 10 | 11 | 12 =>  -- ALU operations
                    next_state_r <= ST_RT_FIN;

                when 14 =>  -- LD/ST logic
                    case opcode_v is
                        when OP_LD => next_state_r <= ST_LD1;
                        when OP_ST => next_state_r <= ST_ST1;
                        when others => next_state_r <= ST_FETCH;
                    end case;

                when 15 =>  -- ST1
                    next_state_r <= ST_ST2;

                when 17 =>  -- LD1
                    next_state_r <= ST_LD2;

                when 19 =>  -- DEC
                    case opcode_v is
                        when OP_JMP            => next_state_r <= ST_JMP;
                        when OP_JC | OP_JNC    => next_state_r <= ST_JC;
                        when OP_MOVE           => next_state_r <= ST_MOVE;
                        when OP_LD | OP_ST     => next_state_r <= ST_LD_OR_ST;
                        when OP_DONE           => next_state_r <= ST_DONE;
                        when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_XOR => next_state_r <= ST_RT;
                        when others            => next_state_r <= ST_FETCH;
                    end case;

                when others =>
                    next_state_r <= ST_FETCH;
            end case;

        else
            next_state_r <= current_state_q; -- hold state
        end if;
    end process;

    ----------------------------------------------------------
    -- Synchronous state register
    ----------------------------------------------------------
    next_st_register: process(clk_i)
    begin
        if rst_i = '1' then
            current_state_q <= ST_IDLE;
        elsif ena_i = '1' and rising_edge(clk_i) then
            current_state_q <= next_state_r;
        end if;
    end process;

end StateArch;
