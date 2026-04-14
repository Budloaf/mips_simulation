	-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY MIPS IS
	-- Output important signals to pins for easy display in Simulator
	PORT( reset, clock			:  IN 	STD_LOGIC; 
			PC							: OUT  	STD_LOGIC_VECTOR(9 DOWNTO 0);
			ALU_result_MEM_out,
			ALU_result_WB_out,
			read_data_1_out,
			read_data_2_out,
			Reg_write_data_out,
			--Mem_write_data_out,   	-- OVER PIN LIMIT
			--Mem_read_data_out,    	-- OVER PIN LIMIT
			Instruction_out		: OUT 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			RegDst_out,
			Branch_out,
			BranchNot_out,
			Jump_out,
			Flush_out,
			Stall_out,
			lw_Stall_out,
			MemRead_out,
			MemtoReg_out,
			Memwrite_out,
			ALUSrc_out,
			Regwrite_out,
			Zero_out,
			lw_sw_fwd_out			: OUT 	STD_LOGIC;
			reg_out_01,
			reg_out_02,
			reg_out_07 				: OUT 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			Opcode_out				: OUT 	STD_LOGIC_VECTOR(5 DOWNTO 0);
			ALUop_out,
			ALU_Asel_out,
			ALU_Bsel_out			: OUT 	STD_LOGIC_VECTOR(  1 DOWNTO 0 );
			
			--Imm_ext_out				: OUT 	STD_LOGIC_VECTOR(31 DOWNTO 0);	 -- equivalent to Sign_extend -- OVER PIN LIMIT
			
			cache_read_data_out	: OUT		STD_LOGIC_VECTOR(37 DOWNTO 0);
			cache_write_out		: OUT 	STD_LOGIC;
			hit_out					: OUT 	STD_LOGIC--;
			
			-- cache_000_out			: out std_logic_vector( 37 downto 0 );
			-- cache_001_out			: out std_logic_vector( 37 downto 0 );
			-- cache_010_out			: out std_logic_vector( 37 downto 0 );
			-- cache_011_out			: out std_logic_vector( 37 downto 0 );
			-- cache_100_out			: out std_logic_vector( 37 downto 0 );
			-- cache_101_out			: out std_logic_vector( 37 downto 0 );
			-- cache_110_out			: out std_logic_vector( 37 downto 0 );
			-- cache_111_out			: out std_logic_vector( 37 downto 0 )
			
			);
END MIPS;

ARCHITECTURE Structure OF MIPS IS

	COMPONENT IFETCH
		  PORT(
				Instruction				: OUT		STD_LOGIC_VECTOR(31 DOWNTO 0);
				PC_plus_4_out			: OUT		STD_LOGIC_VECTOR(9 DOWNTO 0);
				Add_result 				:  IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
				Branch 					:  IN 	STD_LOGIC;
				BranchNot				:  IN  	STD_LOGIC;
				Jump						:  IN		STD_LOGIC;
				Flush						: BUFFER STD_LOGIC;
				Stall						: BUFFER STD_LOGIC;
				lw_Stall					:	IN		STD_LOGIC;
				Zero 						:  IN 	STD_LOGIC;
				PC_out 					: OUT 	STD_LOGIC_VECTOR(9 DOWNTO 0);
				cache_read_data		: buffer std_logic_vector(37 downto 0);
				cache_write				: buffer std_logic;
				hit						: buffer	std_logic;
				-- cache_000				:	  out std_logic_vector( 37 downto 0 );
				-- cache_001				: 	  out std_logic_vector( 37 downto 0 );
				-- cache_010				: 	  out std_logic_vector( 37 downto 0 );
				-- cache_011				:    out std_logic_vector( 37 downto 0 );
				-- cache_100				:    out std_logic_vector( 37 downto 0 );
				-- cache_101				:    out std_logic_vector( 37 downto 0 );
				-- cache_110				:    out std_logic_vector( 37 downto 0 );
				-- cache_111				:    out std_logic_vector( 37 downto 0 );
				clock,reset 			:     IN STD_LOGIC);
	END COMPONENT; 
	
	COMPONENT IDECODE
 	     PORT(	read_data_1 		: 		OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
					read_data_2 		: 		OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
					Instruction			: 		 IN STD_LOGIC_VECTOR(31 DOWNTO 0);
					Inst_desired		:  	OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
					Mem_read_data		:      IN STD_LOGIC_VECTOR(31 DOWNTO 0);
					ALU_result_WB		: 		 IN STD_LOGIC_VECTOR(31 DOWNTO 0);
					Reg_write_data		:     OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
					RegWrite,
					MemtoReg 			: 		 IN STD_LOGIC;
					RegDst 				: 		 IN STD_LOGIC;
					lw_Stall				:		 IN STD_LOGIC;
					Zero					: 		OUT STD_LOGIC;
					Sign_extend			: 		OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
					reg_out_01,
					reg_out_02,
					reg_out_07			: OUT STD_LOGIC_VECTOR( 31 downto 0 );
					Add_Result 			: OUT	STD_LOGIC_VECTOR(  7 DOWNTO 0 );
					PC_plus_4			:  IN STD_LOGIC_VECTOR(  9 DOWNTO 0 );
					
					clock, reset		: IN 	STD_LOGIC
					);
	END COMPONENT;

	COMPONENT CONTROL
	     PORT( 	Instruction			:  IN		STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					Opcode 				:  IN 	STD_LOGIC_VECTOR(  5 DOWNTO 0 );
             	RegDst 				: OUT 	STD_LOGIC;
             	ALUSrc 				: OUT 	STD_LOGIC;
             	MemtoReg 			: OUT 	STD_LOGIC;
             	RegWrite 			: OUT 	STD_LOGIC;
             	MemRead 				: OUT 	STD_LOGIC;
             	MemWrite 			: OUT 	STD_LOGIC;
             	Branch 				: OUT 	STD_LOGIC;
					BranchNot			: OUT		STD_LOGIC;
					Jump					: OUT		STD_LOGIC;
					lw_Stall				: OUT		STD_LOGIC;
					lw_sw_fwd			: OUT		STD_LOGIC;
             	ALUop,
					ALU_Asel,
					ALU_Bsel				: OUT 	STD_LOGIC_VECTOR(  1 DOWNTO 0 );
					clock, reset		:  IN 		STD_LOGIC);
	END COMPONENT;

	COMPONENT  EXECUTE
		  PORT(	Read_data_1 		:  	IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					Read_data_2 		:  	IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					Sign_Extend	 		:  	IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					Function_opcode	:  	IN 	STD_LOGIC_VECTOR(  5 DOWNTO 0 );
					ALUOp,
					ALU_Asel,
					ALU_Bsel				:		IN 	STD_LOGIC_VECTOR(  1 DOWNTO 0 );
					ALUSrc 				:  	IN 	STD_LOGIC;
					ALU_result_MEM		: BUFFER		STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					ALU_result_WB		: 	  OUT		STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					Reg_write_data		: 		IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					Mem_write_data		: 	  OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					Mem_read_data		: 		IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
					clock, reset		:  	IN 	STD_LOGIC);
	END COMPONENT;


	COMPONENT DMEMORY
	     PORT(	Mem_read_data 			: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
					address 					:  IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
					Mem_write_data 		:  IN STD_LOGIC_VECTOR(31 DOWNTO 0);
					MemRead, Memwrite 	:  IN 	STD_LOGIC;
					lw_sw_fwd				:	IN 	STD_LOGIC;
					Clock,reset				:  IN 	STD_LOGIC);
	END COMPONENT;

	-- declare signals used to connect VHDL components
	SIGNAL PC_plus_4			: STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL PC_sig				: STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL read_data_1 		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL read_data_2 		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL Sign_Extend 		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL Add_result 		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL ALU_result_MEM,
			 ALU_result_WB		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL Mem_read_data		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL Reg_write_data	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL Mem_write_data	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ALUSrc 				: STD_LOGIC;
	SIGNAL Branch 				: STD_LOGIC;
	SIGNAL BranchNot			: STD_LOGIC;
	SIGNAL Jump					: STD_LOGIC;
	SIGNAL Flush				: STD_LOGIC;
	SIGNAL Stall				: STD_LOGIC;
	SIGNAL lw_Stall			: STD_LOGIC;
	SIGNAL RegDst 				: STD_LOGIC;
	SIGNAL Regwrite 			: STD_LOGIC;
	SIGNAL Zero 				: STD_LOGIC;
	SIGNAL lw_sw_fwd			: STD_LOGIC;
	SIGNAL MemWrite 			: STD_LOGIC;
	SIGNAL MemtoReg 			: STD_LOGIC;
	SIGNAL MemRead 			: STD_LOGIC;
	SIGNAL ALUop,
			 ALU_Asel,
			 ALU_Bsel				: STD_LOGIC_VECTOR(  1 DOWNTO 0 );
	SIGNAL Inst_desired, 	
			 Instruction			: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL OpCode 					: STD_LOGIC_VECTOR(  5 DOWNTO 0 );
	SIGNAL cache_read_data  	: STD_LOGIC_VECTOR( 37 DOWNTO 0 );
	SIGNAL cache_write			: STD_LOGIC;
	SIGNAL hit						: STD_LOGIC;
	-- signal cache_000				: std_logic_vector( 37 downto 0 );
	-- signal cache_001				: std_logic_vector( 37 downto 0 );
	-- signal cache_010				: std_logic_vector( 37 downto 0 );
	-- signal cache_011				: std_logic_vector( 37 downto 0 );
	-- signal cache_100				: std_logic_vector( 37 downto 0 );
	-- signal cache_101				: std_logic_vector( 37 downto 0 );
	-- signal cache_110				: std_logic_vector( 37 downto 0 );
	-- signal cache_111				: std_logic_vector( 37 downto 0 );
	
BEGIN
	-- copy important signals to output pins for easy 
	-- display in Simulator
	PC							<= PC_sig;
	Instruction_out 		<= Inst_desired; -- changed so that waveform makes more sense and displays Instruction we're executing no matter what
	--ALU_result_MEM_out 	<= ALU_result_MEM;
	--ALU_result_WB_out		<= ALU_result_WB;
	read_data_1_out 		<= read_data_1;
	read_data_2_out 		<= read_data_2;
	--Reg_write_data_out	<= Reg_write_data;
	--Mem_write_data_out 	<= Mem_write_data; 	-- OVER PIN LIMIT
	--Mem_read_data_out		<= Mem_read_data;		-- OVER PIN LIMIT
	Branch_out 				<= Branch;
	BranchNot_out			<= BranchNot;
	Jump_out					<= Jump;
	Flush_out				<= Flush;
	Stall_out				<= Stall;
	lw_Stall_out			<= lw_Stall;
	lw_sw_fwd_out			<= lw_sw_fwd;
	Zero_out 				<= Zero;
	RegWrite_out 			<= RegWrite;
	MemWrite_out 			<= MemWrite;	
	RegDst_out				<= RegDst;
	MemtoReg_out			<= MemtoReg;
	ALUOp_out				<= ALUOp;
	ALU_Asel_out			<= ALU_Asel;
	ALU_Bsel_out			<= ALU_Bsel;
	OpCode 					<= Inst_desired(31 DOWNTO 26);
	OpCode_out 				<= OpCode;
	MemRead_out				<= MemRead;
	-- Imm_ext_out				<= Sign_extend; -- OVER PIN LIMIT
	ALUSrc_out				<= ALUSrc;
	cache_read_data_out	<= cache_read_data;
	cache_write_out		<= cache_write;
	hit_out					<= hit;
	-- cache_000_out			<= cache_000;
	-- cache_001_out			<= cache_001;
	-- cache_010_out			<= cache_010;
	-- cache_011_out			<= cache_011;
	-- cache_100_out			<= cache_100;
	-- cache_101_out			<= cache_101;
	-- cache_110_out			<= cache_110;
	-- cache_111_out			<= cache_111;
	
	
					-- connect the 5 MIPS components   
  IFE : IFETCH
	PORT MAP (	Instruction 	=> Instruction,
					PC_plus_4_out	=> PC_plus_4,
					Add_result 		=> Add_result,
					Branch 			=> Branch,
					BranchNot		=> BranchNot, 
					Jump				=> Jump,
					Flush				=> Flush,
					Stall				=> Stall,
					lw_Stall			=>	lw_Stall,
					Zero 				=> Zero,
					PC_out 			=> PC_sig,
					cache_read_data=> cache_read_data,
					cache_write		=> cache_write,
					hit				=> hit,
					-- cache_000		=> cache_000,
					-- cache_001		=> cache_001,
					-- cache_010		=> cache_010,
					-- cache_011		=> cache_011,
					-- cache_100		=> cache_100,
					-- cache_101		=> cache_101,
					-- cache_110		=> cache_110,
					-- cache_111		=> cache_111,
					clock 			=> clock,  
					reset 			=> reset	);
	 
   ID : IDECODE
	PORT MAP (	read_data_1 	=> read_data_1,
					read_data_2 	=> read_data_2,
					Instruction		=> Instruction,
					Inst_desired	=> Inst_desired,
					Mem_read_data	=> Mem_read_data,
					ALU_result_WB	=> ALU_result_WB,
					Reg_write_data	=> Reg_write_data,
					RegWrite 		=> RegWrite,
					MemtoReg 		=> MemtoReg,
					RegDst 			=> RegDst,
					lw_Stall			=> lw_Stall,
					Zero				=> Zero,
					Sign_extend 	=> Sign_extend,
					reg_out_01		=> reg_out_01,
					reg_out_02		=> reg_out_02,
					reg_out_07		=> reg_out_07,
					PC_plus_4		=> PC_plus_4,
					Add_result		=> Add_result,
					
					clock 			=> clock,
					reset 			=> reset
					);


   CTL:   CONTROL
	PORT MAP ( 	Instruction		=> Inst_desired, -- changed so that control values also delay in the case of a lw_stall
					Opcode 			=> OpCode,
					RegDst 			=> RegDst,
					ALUSrc 			=> ALUSrc,
					MemtoReg 		=> MemtoReg,
					RegWrite 		=> RegWrite,
					MemRead 			=> MemRead,
					MemWrite 		=> MemWrite,
					Branch 			=> Branch,
					BranchNot		=> BranchNot, 
					Jump				=> Jump,
					lw_Stall			=> lw_Stall,
					lw_sw_fwd		=> lw_sw_fwd,
					ALUop 			=> ALUop,
					ALU_Asel			=> ALU_Asel,
					ALU_Bsel			=> ALU_Bsel,
					clock 			=> clock,
					reset 			=> reset );

   EXE:  EXECUTE
   PORT MAP (	Read_data_1 	=> read_data_1,
					Read_data_2 	=> read_data_2,
					Sign_extend 	=> Sign_extend,
					Function_opcode=> Inst_desired(5 DOWNTO 0),
					ALUOp 			=> ALUop,
					ALU_Asel			=> ALU_Asel,
					ALU_Bsel			=> ALU_Bsel,
					ALUSrc 			=> ALUSrc,
					ALU_result_MEM	=> ALU_result_MEM,
					ALU_result_WB  => ALU_result_WB,
					Reg_write_data	=> Reg_write_data,
					Mem_write_data => Mem_write_data,
					Mem_read_data	=> Mem_read_data,
					Clock				=> clock,
					Reset				=> reset);

   MEM:  DMEMORY
	PORT MAP (	Mem_read_data 	=> Mem_read_data,
					address 			=> ALU_Result_MEM (7 DOWNTO 0),
					Mem_write_data => Mem_write_data,
					MemRead 			=> MemRead, 
					Memwrite 		=> MemWrite,
					lw_sw_fwd		=> lw_sw_fwd,
					
					clock 			=> clock,  
					reset 			=> reset);
END Structure;

