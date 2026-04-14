--  Execute module (implements the data ALU and Branch Address Adder  
--  for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY  Execute IS
	PORT(	Read_data_1 		:  	IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Read_data_2 		:  	IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Sign_extend 		:  	IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Function_opcode 	:  	IN 	STD_LOGIC_VECTOR(  5 DOWNTO 0 );
			ALUOp,
			ALU_Asel,
			ALU_Bsel				:		IN 	STD_LOGIC_VECTOR(  1 DOWNTO 0 );
			ALUSrc 				:  	IN 	STD_LOGIC;
			-- Zero signal now in idecode.vhd
			ALU_result_MEM		: BUFFER		STD_LOGIC_VECTOR( 31 DOWNTO 0 ); -- retain both ALU_result delayed by 1 and 2
			ALU_result_WB		:    OUT		STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Reg_write_data		: 		IN		STD_LOGIC_VECTOR( 31 DOWNTO 0 ); -- for MEM stage and WB stage, respectively.
			Mem_write_data		: 	  OUT		STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Mem_read_data		: 		IN		STD_LOGIC_VECTOR( 31 DOWNTO 0 ); -- for data hazard case when lw __ add 
			clock, reset		:  	IN 	STD_LOGIC
			);
END Execute;

ARCHITECTURE behavior OF Execute IS
SIGNAL Ainput, Binput, Binput_no_fwd : STD_LOGIC_VECTOR( 31 DOWNTO 0 ); 
-- Binput_no_fwd = output of ALUsrc mux & input of ALU_Bsel mux

SIGNAL ALU_output_mux			: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL ALU_ctl						: STD_LOGIC_VECTOR(  2 DOWNTO 0 );

-- input delays
SIGNAL Function_opcode_EX		: STD_LOGIC_VECTOR(  5 DOWNTO 0 );

-- output delays
SIGNAL ALU_result					: STD_LOGIC_VECTOR( 31 DOWNTO 0 );

BEGIN

	Binput_no_fwd <= Read_data_2 -- ALUsrc mux updated to have intermediate signal Binput_no_fwd
	WHEN ( ALUSrc = '0' )
  	ELSE  Sign_extend( 31 DOWNTO 0 ); 
						-- Generate ALU control bits
	ALU_ctl( 0 ) <= ( Function_opcode_EX( 0 ) OR Function_opcode_EX( 3 ) ) AND ALUOp( 1 );
	ALU_ctl( 1 ) <= ( NOT Function_opcode_EX( 2 ) ) OR (NOT ALUOp( 1 ) );
	ALU_ctl( 2 ) <= ( Function_opcode_EX( 1 ) AND ALUOp( 1 )) OR ALUOp( 0 );
    
						-- Select ALU output        
	ALU_result <= X"0000000" & B"000"  & ALU_output_mux( 31 ) 
		WHEN  ALU_ctl = "111" 
		ELSE  	ALU_output_mux( 31 DOWNTO 0 );
		
	-- Our branch hardware is in another castle (idecode.vhd)
	
PROCESS (ALU_Asel, ALU_Bsel, Ainput, Binput) -- process for the ALU_Asel and ALU_Bsel muxes
	BEGIN
	CASE ALU_Asel IS
		WHEN "00" 	=> Ainput <= Read_data_1;		-- no data forwarding
		WHEN "01" 	=> Ainput <= ALU_result_MEM;  -- 	data forwarding one ahead
		WHEN "10"	=> Ainput <= Reg_write_data;	-- 	data forwarding two ahead
		WHEN "11" 	=> Ainput <= Mem_read_data;	-- lw	data forwarding two ahead
		WHEN OTHERS => Ainput <= X"00000000";		-- should not happen other than initial meaningless data
	END CASE;
	
	CASE ALU_Bsel IS
		WHEN "00"	=> Binput <= Binput_no_fwd;		-- no data forwarding
		WHEN "01"	=> Binput <= ALU_result_MEM;	--		data forwarding one ahead
		WHEN "10"	=> Binput <= Reg_write_data;	-- 	data forwarding two ahead
		WHEN "11"   => Binput <= Mem_read_data;	--	lw data forwarding two ahead
		WHEN OTHERS => Binput <= X"00000000";		-- should not happen other than initial meaningless data
	END CASE;
END PROCESS;
	
PROCESS ( ALU_ctl, Ainput, Binput )
	BEGIN
					-- Select ALU operation
 	CASE ALU_ctl IS
						-- ALU performs ALUresult = A_input AND B_input
		WHEN "000" 	=>	ALU_output_mux 	<= Ainput AND Binput; 
						-- ALU performs ALUresult = A_input OR B_input
     	WHEN "001" 	=>	ALU_output_mux 	<= Ainput OR Binput;
						-- ALU performs ALUresult = A_input + B_input
	 	WHEN "010" 	=>	ALU_output_mux 	<= Ainput + Binput;
						-- ALU performs ?
 	 	WHEN "011" 	=>	ALU_output_mux <= X"00000000";
						-- ALU performs ?
 	 	WHEN "100" 	=>	ALU_output_mux 	<= X"00000000";
						-- ALU performs ?
 	 	WHEN "101" 	=>	ALU_output_mux 	<= X"00000000";
						-- ALU performs ALUresult = A_input -B_input
 	 	WHEN "110" 	=>	ALU_output_mux 	<= Ainput - Binput;
						-- ALU performs SLT
  	 	WHEN "111" 	=>	ALU_output_mux 	<= Ainput - Binput ;
 	 	WHEN OTHERS	=>	ALU_output_mux 	<= X"00000000" ;
  	END CASE;
  END PROCESS;
PROCESS
	BEGIN
		WAIT UNTIL ( clock'EVENT ) AND ( clock = '1' );
		-- input delays
		-- received in ID
		Function_opcode_EX <= Function_opcode;
		
		-- output delays
		ALU_result_MEM <= ALU_result;
		ALU_result_WB <= ALU_result_MEM;
		
		Mem_write_data <= read_data_2;

	END PROCESS;
END behavior;

