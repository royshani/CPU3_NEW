* top.vhd - enveloping module of the entire system. Contains the Control & Datapath modules. Functions as the mediator
with the TBs.

* aux_package.vhd - package defining all components and generic values used in the task.

* Control.vhd - enveloping module for the Control part of the CPU. Contains ControlLines.vhd & StateLogic.
- Recieves TB inputs - clk, sys_ena, sys_rst ;Datapath inputs - Opcode (IR module via Datapath) , ALU flags (ALU_main module via Datapath)
- Outputs control lines for current clock to the Datapath module & 'done' bit.

* StateLogic.vhd - sub-module of Control.vhd. implementation of the FSM, storing the current state (forwarded to the ControlLines module) and calculating
the next state to be stored.

* ControlLines.vhd - outputs the control lines to the Datapath module based on the current state fed from the StateLogic module.

* Datapath.vhd - the functional part of the CPU. Recieves the control lines from the Control module and TB signals (meant for loading/reading DataMem&ProgMem)
Contains the following sub-modules: ALU_main, bus_pour_tristate, DataMem, ProgMem, FA, GenericRegister, IR, PCLogic, RF.
Connects all the following sub-modules (as shown in pre3.pdf) with their relevant control lines and between themselves.

* DataMem.vhd, ProgMem.vhd - pre-defined files provided with the task. Serve as the Program Memory and Data Memory segments for the CPU. Both have control lines
directly controlled by the TB, alongside lines controlled by the Control module.

* RF.vhd - Register File module, pre-defined and provided with the task. Connects with the IR module (recieves register # to address within), the bus (receives/sends
data, sending is via bus_pour_tristate) and is controlled by control bits from the Control module.

* bus_pour_tristate.vhd - generic module used to connect the 5 outputs that can pour data onto the bus, and make sure only one source is pouring data onto the bus
at a time. Has a control bit enable or disabling bus access (when enabled - pour data ,when disabled - "pour" high-Z signal).

* ALU_main.vhd - pure-logic module, recieving 2 input vectors (from A register and the bus) to perform arithmatic/logical operations on them, outputting
the selected output (selected by 3-bit control from the Control unit) towards the C register.

* FA.vhd - full adder sub-module, used within ALU_Main (as part of a ripple-adder implementation) & PCLogic (Ripple-adder implementation).
* IR.vhd - Insturction Register module. Contains the current operation to be executed (received from ProgMem), and has the following outputs:
selected register - forwards the required register # to be operated upon (reading/writing) based on control line (2 bit vector);
opcode - 4 MSB bits of the insturction stored, sent to the Control module (affects which state the machine will be in);
2 Immediates, sign-extended, to be poured to the bus via tri_state modules, controlled by the control module.

* PCLogic.vhd - modules contains the current PC (register), and controlls how and when it is updated via control lines (options - reset = 0s vector, PC+1, PC+Imm [jump operations])
* GenericRegister.vhd - generic register module, used as Register A, Register C & 'MemIn [write address towards Data Memory), as depicted in the task's pdf.
