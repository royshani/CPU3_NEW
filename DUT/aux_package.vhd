library IEEE;
use ieee.std_logic_1164.all;

package aux_package is
---------------------------------------------------------	
	Component StateLogic is
		generic( StateLength: integer:=5); -- 2^5 bits to describe states
		port(	clk, ena, rst: in std_logic; -- coming from TB through top
				ALU_cflag : in std_logic;
				i_opcode : in std_logic_vector(3 downto 0);
				o_currentstate : out std_logic_vector(StateLength-1 downto 0)
			);
	end Component;
---------------------------------------------------------
	Component Control is
		generic( StateLength: integer:=5); -- 2^5 bits to describe states
		port(	clk, rst, ena: in std_logic; -- fed from TB
				ALU_c, ALU_z, ALU_n: in std_logic; -- fed from ALU, through Top*(?)
				i_opcode: in std_logic_vector(3 downto 0); -- fed from IR, through Top*(?)
				--- control bits ---
				RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin: out std_logic; -- bus access
				RF_addr, PCsel: out std_logic_vector(1 downto 0);
				RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin: out std_logic; -- RF_rst to be used as global reset?
				ALU_op: out std_logic_vector(2 downto 0);
				status_bits: out std_logic_vector(12 downto 0) -- status bits, concatenated, including flags (MSBs, C,Z,N,status..)		
			);
	end Component;
---------------------------------------------------------
	Component top IS
		generic( Dwidth: integer:=16;
				 Awidth: integer:=6;
				 dept: integer:=64;
				 StateLength: integer:=5);
		port(	clk, rst, ena: IN std_logic; -- fed from TB
				done: OUT std_logic_vector; -- DONE bit to TB

				dataIn: IN std_logic_vector(Dwidth-1 downto 0); -- write content into ProgMem, from TB through top
				writeaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into ProgMem, from TB through top
				prog_wren: IN std_logic; -- enable bit to write into ProgMem, from TB through top
				TBactive: IN std_logic; -- enable bit to write from TB instead of internally
				data_writeaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into DataMem, from TB through top
				data_writeData: IN std_logic_vector(Dwidth-1 downto 0); -- write data into DataMem, from TB through top
				data_wren: IN std_logic; -- enable bit to write into DataMem, from TB through top
				data_readdata: out std_logic_vector(Dwidth-1 downto 0); -- read data from DataMem, from TB through top
				data_readaddr: IN std_logic_vector(Awidth-1 downto 0) -- write address into DataMem, from TB through top
			); 
	END Component;
---------------------------------------------------------
	Component Datapath is
		generic( Dwidth: integer:=16;
				 Awidth: integer:=6;
				 dept: integer:=64);
		port(	clk: IN std_logic; -- from TB through TOP
				dataIn: IN std_logic_vector(Dwidth-1 downto 0); -- write content into ProgMem, from TB through top
				writeaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into ProgMem, from TB through top
				prog_wren: IN std_logic; -- enable bit to write into ProgMem, from TB through top
				TBactive: IN std_logic; -- Shown in page 4 diagram, from TB through top
				data_writeaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into DataMem, from TB through top
				data_writeData: IN std_logic_vector(Dwidth-1 downto 0); -- write data into DataMem, from TB through top
				data_wren: IN std_logic; -- enable bit to write into DataMem, from TB through top
				data_readdata: out std_logic_vector(Dwidth-1 downto 0); -- read data from DataMem, from TB through top
				data_readaddr: IN std_logic_vector(Awidth-1 downto 0); -- write address into DataMem, from TB through top
				-- Datapath --> Control through top--
				alu_c, alu_z, alu_n: out std_logic; -- current flags from ALU to Control through top
				o_opcode: out std_logic_vector(3 downto 0); -- Opcode from IR to Control through top
				-- Control --> Datapath through top (control bits) --
				RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin: IN std_logic;
				RF_addr, PCsel: IN std_logic_vector(1 downto 0);
				RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin: IN std_logic; -- RF_rst to be used as global reset?**
				ALU_op: IN std_logic_vector(2 downto 0)
			);
	end Component;
---------------------------------------------------------
	Component IR is
		generic( Dwidth: integer:=16); -- width of IR register
		port( clk, ena, rst: in std_logic; -- ena = IRin, rst = system_rst
			  ctrl_RFaddr: in std_logic_vector(1 downto 0);
			  i_IR_content: in std_logic_vector(Dwidth-1 downto 0);
			  o_OPCODE, o_addr : out std_logic_vector(3 downto 0); -- o_addr = output of RFaddr mux
			  o_signext1, o_signext2 : out std_logic_vector(Dwidth-1 downto 0);
			  o_imm_to_PC : out std_logic_vector(7 downto 0)
			);
	end Component;
---------------------------------------------------------
	Component GenericRegister is
		generic( Dwidth: integer:=16); -- width of register
		port( 	clk, ena, rst : in std_logic;
				i_in : in std_logic_vector(Dwidth-1 downto 0);
				o_out : out std_logic_vector(Dwidth-1 downto 0)
			);
	end Component;
---------------------------------------------------------
	Component ControlLines is
		generic( StateLength: integer:=5); -- 2^5 bits to describe states
		port(	clk, rst: in std_logic;
				i_state: in std_logic_vector(StateLength-1 downto 0);
				i_opcode: in std_logic_vector(3 downto 0);
				alu_c, alu_z, alu_n: in std_logic; -- flags from ALU unit
				-- control lines --
				RF_out, Data_mem_out, Cout, Imm2_in, Imm1_in, IRin: out std_logic;
				RF_addr, PCsel: out std_logic_vector(1 downto 0);
				RF_WregEn, RF_rst, Ain, Cin, Mem_in, Data_MemEn, Pcin: out std_logic; -- RF_rst to be used as global reset?
				ALU_op: out std_logic_vector(2 downto 0);
				-- status lines --
				o_cflag, o_zflag, o_nflag: out std_logic;
				status_bits : out std_logic_vector(9 downto 0) -- all status bits concatenated 
			);
	end Component;
---------------------------------------------------------
	Component PCLogic is
		generic( Awidth: integer:=6 ); -- 2^6=64. address of each line in the Data memory segement)
		port( clk, i_PCin : in std_logic;
			  i_PCsel : in std_logic_vector(1 downto 0);
			  i_IR_imm : in std_logic_vector(7 downto 0); -- VECTOR SIZE MAKES NO SENSE - ASK HANAN
			  o_currentPC : out std_logic_vector(Awidth-1 downto 0)
			);
	end Component;
---------------------------------------------------------
	Component ALU_main is
		generic( Dwidth: integer:=16); -- data witdh (16 bit register, same as RF width)
		port(	i_A, i_B: in std_logic_vector(Dwidth-1 downto 0); -- R[rb] = A, R[rc] = B ***
				i_ctrl: in std_logic_vector(2 downto 0); -- ALUOP control bits
				o_C: out std_logic_vector(Dwidth-1 downto 0);
				o_cflag, o_nflag, o_zflag: out std_logic
				);
	end Component;
---------------------------------------------------------
	Component bus_pour_tristate is
			generic( Dwidth: integer:=16 );
			port(
					i_data: in std_logic_vector(Dwidth-1 downto 0);
					o_data: out std_logic_vector(Dwidth-1 downto 0);
					enable_out: in std_logic -- controls whether the data is poured out
			);
	end Component;
---------------------------------------------------------
	Component ProgMem is
		generic( Dwidth: integer:=16;
				 Awidth: integer:=6; -- 2^6=64. address of each line in the Data memory segement
				 dept:   integer:=64); -- 'size' of the Data memory segement (amount of 'lines')
		port(	clk,memEn: in std_logic;	
				WmemData:	in std_logic_vector(Dwidth-1 downto 0);
				WmemAddr,RmemAddr:	
							in std_logic_vector(Awidth-1 downto 0);
				RmemData: 	out std_logic_vector(Dwidth-1 downto 0)
		);
	end Component;
---------------------------------------------------------
	Component dataMem is
		generic( Dwidth: integer:=16;
				 Awidth: integer:=6; -- 2^6=64. address of each line in the Data memory segement
				 dept:   integer:=64); -- 'size' of the Data memory segement (amount of 'lines')
		port(	clk,memEn: in std_logic;	
				WmemData:	in std_logic_vector(Dwidth-1 downto 0);
				WmemAddr,RmemAddr:	
							in std_logic_vector(Awidth-1 downto 0);
				RmemData: 	out std_logic_vector(Dwidth-1 downto 0)
		);
	end Component;
---------------------------------------------------------
	Component FA is
		port (xi, yi, cin: in std_logic;
				  s, cout: out std_logic);
	end Component;
---------------------------------------------------------
	Component RF is
		generic( Dwidth: integer:=16;
				 Awidth: integer:=4);
		port(	clk,rst,WregEn: in std_logic;	
				WregData:	in std_logic_vector(Dwidth-1 downto 0);
				WregAddr,RregAddr:	
							in std_logic_vector(Awidth-1 downto 0);
				RregData: 	out std_logic_vector(Dwidth-1 downto 0)
		);
	end Component;
---------------------------------------------------------

end package aux_package;