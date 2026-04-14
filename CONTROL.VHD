		-- control module (implements MIPS control unit)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY control IS
   PORT(
	Instruction	:     IN	 	STD_LOGIC_VECTOR( 31 DOWNTO 0 ); -- This is Inst_desired, so that when lw_Stall causes a stall, the controls don't get wacky
	Opcode 		:     IN 		STD_LOGIC_VECTOR( 5  DOWNTO 0 );
	RegDst 		:    OUT 	STD_LOGIC;
	ALUSrc 		:    OUT 	STD_LOGIC;
	MemtoReg 	:    OUT 	STD_LOGIC;
	RegWrite 	:    OUT 	STD_LOGIC;
	MemRead 		: BUFFER 	STD_LOGIC;
	MemWrite 	:    OUT 	STD_LOGIC;
	Branch 		:    OUT 	STD_LOGIC;
	BranchNot	:    OUT		STD_LOGIC;
	Jump			:    OUT		STD_LOGIC;
	-- Flush, Stall, and Zero are other control signals used within a single stage (ID).
	-- They are found in ifetch and idecode files.
	lw_Stall		: BUFFER    STD_LOGIC;
	lw_sw_fwd	: 	  OUT 	STD_LOGIC;
	-- lw_Stall is used here, in ifetch.vhd, and in idecode.vhd (delayed by 1)
	ALUop,
	ALU_Asel,
	ALU_Bsel		: OUT 	STD_LOGIC_VECTOR(  1 DOWNTO 0 );
	clock, reset:  IN 	STD_LOGIC );

END control;

ARCHITECTURE behavior OF control IS
	SIGNAL  R_format_ID, R_format_EX, R_format_MEM, R_format_WB,
			  lw, sw, beq, bne, j	: STD_LOGIC;

	SIGNAL	ALUSrc_ID, ALUSrc_EX,
				lw_sw_fwd_ID, lw_sw_fwd_EX,
				MemRead_ID, MemRead_EX, MemRead_MEM,
				MemWrite_ID, MemWrite_EX, MemWrite_MEM,
				Jump_ID, Jump_EX, Jump_MEM,
				MemtoReg_ID, MemtoReg_EX, MemtoReg_MEM,
				RegWrite_ID, RegWrite_EX, RegWrite_MEM : STD_LOGIC;
			
	SIGNAL 	ALUOp_ID, ALUOp_EX,
				ALU_Asel_ID, 
				ALU_Bsel_ID			: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	

	SIGNAL rs_WB, rs_MEM, rs_EX, rs_ID,
			 rt_WB, rt_MEM, rt_EX, rt_ID,
			 rd_WB, rd_MEM, rd_EX, rd_ID	: STD_LOGIC_VECTOR (  4 DOWNTO 0 );
	
BEGIN           
				-- Code to generate control signals using opcode bits
	R_format_ID		<=  '1'  WHEN  Opcode =  "000000"  					ELSE '0';
	lw          	<=  '1'  WHEN  Opcode =  "100011"  					ELSE '0';
 	sw          	<=  '1'  WHEN  Opcode =  "101011"  					ELSE '0';
   beq         	<=  '1'  WHEN  Opcode =  "000100"  					ELSE '0';
	bne				<=  '1'  WHEN  Opcode =  "000101"  					ELSE '0';
	j					<=	 '1'	WHEN	Opcode =  "000010"  					ELSE '0';
  	RegDst	    	<=  R_format_ID;
 	ALUSrc_ID  		<=  lw OR sw;
	MemtoReg_ID 	<=  lw;
  	RegWrite_ID 	<=  (R_format_ID OR lw) AND (NOT lw_Stall);
  	MemRead_ID 		<=  lw;
   MemWrite_ID 	<=  sw  AND (NOT lw_Stall); 
 	Branch  	  	   <=  beq AND (NOT lw_Stall);
	BranchNot		<=  bne AND (NOT lw_Stall);
	Jump				<=	 j   AND (NOT lw_Stall);
	ALUOp_ID( 1 ) 	<=  R_format_ID;
	ALUOp_ID( 0 ) 	<=  beq OR bne;
	
	rs_ID <= Instruction(25 DOWNTO 21);
	rt_ID <= Instruction(20 DOWNTO 16);
	rd_ID <= Instruction(15 DOWNTO 11);

	PROCESS (  -- sensitivity list
	R_format_ID , rs_ID , rt_ID , rd_ID ,
	R_format_EX , rs_EX , rt_EX , rd_EX ,
	R_format_MEM, rs_MEM, rt_MEM, rd_MEM,
	R_format_WB , rs_WB , rt_WB , rd_WB
	) 
		BEGIN
		lw_Stall <= '0';
		lw_sw_fwd_ID <= '0';
		-- setting ALU_Asel_ID
		IF (j = '0') THEN
			IF (rs_ID /= "00000") THEN
				IF 	(rs_ID = rd_EX  AND  (R_format_ID = '1' OR MemRead_ID = '1') AND R_format_EX = '1') THEN -- One instruction  ago (   R-R or R-lw data hazard)
					ALU_Asel_ID <= "01";
				ELSIF (rs_ID = rt_EX  AND   MemRead_EX = '1') THEN -- One instruction  ago (  lw-R or lw-sw or lw-lw data hazard)
						lw_Stall <= '1';
				ELSIF (rs_ID = rd_MEM AND  R_format_ID = '1' AND R_format_MEM = '1') THEN -- Two instructions ago ( R-x-R data hazard) [lower priority]
						ALU_Asel_ID <= "10";
				ELSIF (rs_ID = rt_MEM AND      MemRead = '1') THEN -- Two instructions ago (lw-x-R or lw-x-lw or lw-x-sw data hazard) [lower priority]
					ALU_Asel_ID <= "11";
				ELSE 
					ALU_Asel_ID <= "00";	-- no forwarding
				END IF;
			ELSE ALU_Asel_ID <= "00"; -- rs is $zero, move on
			END IF;
			
			-- setting ALU_Bsel_ID
			IF (rt_ID /= "00000") THEN
				IF		(rt_ID = rd_EX  AND  (R_format_ID = '1') AND R_format_EX = '1') THEN -- One instruction  ago (   R-R data hazard, R-lw no hazard)
					ALU_Bsel_ID <= "01";
				ELSIF (rt_ID = rt_EX  AND   MemRead_EX = '1') THEN -- One instruction  ago (  lw-R or lw-sw data hazard)
					IF (R_format_ID = '1') THEN
						lw_Stall <= '1';
					ELSIF (sw = '1') THEN		-- lw/sw forwarding!
						lw_sw_fwd_ID <= '1';
					END IF;
				ELSIF	(rt_ID = rd_MEM AND R_format_ID = '1' AND R_format_MEM = '1') THEN -- Two instructions ago ( R-x-R data hazard) [lower priority])
					ALU_Bsel_ID <= "10";
				ELSIF (rt_ID = rt_MEM AND R_format_ID = '1' AND     MemRead = '1') THEN -- Two instructions ago (lw-x-R data hazard) [lower priority]
					ALU_Bsel_ID <= "11";
				ELSE
					ALU_Bsel_ID <= "00";	-- no forwarding
				END IF;
			ELSE ALU_Bsel_ID <= "00"; -- rt is $zero, move on
			END IF;
		END IF;
	END PROCESS;
	
	PROCESS
		BEGIN
			WAIT UNTIL ( clock'EVENT ) AND ( clock = '1' );
			-- RegDst, Branch, BranchNot, Jump are used in ID stage. No delay
			
			-- bypass ID stage
			ALUSrc 			<= 	ALUSrc_ID;
			ALUOp  			<= 	 ALUOp_ID;
			
			MemtoReg_EX 	<=  MemtoReg_ID;
			RegWrite_EX 	<=  RegWrite_ID;
			MemRead_EX 		<=   MemRead_ID;
			MemWrite_EX 	<=  MemWrite_ID;
			lw_sw_fwd_EX	<= lw_sw_fwd_ID;
			
			-- bypass EX stage
					
			MemtoReg_MEM 	<=  MemtoReg_EX; 	
			RegWrite_MEM 	<=  RegWrite_EX;
			lw_sw_fwd		<= lw_sw_fwd_EX;

			MemRead 			<=   MemRead_EX;
			MemWrite 		<=  MemWrite_EX;
			
			-- bypass MEM stage
			
			MemtoReg 		<= MemtoReg_MEM;
			RegWrite 		<= RegWrite_MEM;
			
			-- forwarding delays
			rs_EX			 <= rs_ID;
			rs_MEM 		 <= rs_EX;
			rs_WB 		 <= rs_MEM;
			
			rt_EX			 <= rt_ID;
			rt_MEM 		 <= rt_EX;
			rt_WB 		 <= rt_MEM;
			
			rd_EX			 <= rd_ID;
			rd_MEM		 <= rd_EX;
			rd_WB 		 <= rd_MEM;
			
			R_format_EX  <= R_format_ID;
			R_format_MEM <= R_format_EX;
			R_format_WB  <= R_format_MEM;
			
			ALU_Asel <= ALU_Asel_ID;
			ALU_Bsel <= ALU_Bsel_ID;
	END PROCESS;
 
   END behavior;


