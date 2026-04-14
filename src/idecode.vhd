LIBRARY IEEE; 			-- the MIPS computer)
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Idecode is
    generic (
        num_regs : integer := 32
    );
    port (
		read_data_1 		:    out std_logic_vector(31 downto 0);
      read_data_2 		:    out std_logic_vector(31 downto 0);
		Instruction			:  	in	std_logic_vector(31 downto 0); 
		Inst_desired		: buffer std_logic_vector(31 downto 0);
		Mem_read_data		:     in std_logic_vector(31 downto 0);
		ALU_result_WB		:     in std_logic_vector(31 downto 0);
		Reg_write_data		: 	  out std_logic_vector(31 downto 0);
		RegWrite 			:     in std_logic;
		MemtoReg				:     in	std_logic;
		RegDst				:     in	std_logic;
		lw_Stall				: 		in std_logic;
		Zero					: 	  out std_logic;
		Sign_extend			:    out std_logic_vector(31 downto 0);
		reg_out_01,
		reg_out_02, 
		reg_out_07			:    out std_logic_vector( 31 downto 0 );
		PC_plus_4			:  	in std_logic_vector(  9 downto 0 );
		Add_Result 			:    out	std_logic_vector(  7 DOWNTO 0 );

      clock, reset 		:     in std_logic
		); 
    	
end entity idecode;


architecture Behavioral of idecode is
    
	-- define the register array type and signals
	type reg_array is array (0 to num_regs-1) of std_logic_vector(31 downto 0);
	signal regs : reg_array;
	signal reg_a 						: std_logic_vector(  4 downto 0 ); -- five bit code to determine which register to output on read_data_1
	signal reg_b 						: std_logic_vector(  4 downto 0 ); -- five bit code to determine which register to output on read_data_2
	signal Instruction_immediate 	: std_logic_vector( 15 downto 0 ); -- 16-bit immediate value from instruction
	
	
	-- write-back signals
	signal write_register_address_ID,
			 write_register_address_EX,
			 write_register_address_MEM,
			 write_register_address_WB		: std_logic_vector(  4 downto 0 ); --binary value for register to write to (rs or rt determined by RegDst)
	signal write_data 	 				: std_logic_vector( 31 downto 0 ); --data to write to register file (ALU_result or Mem_read_data from memory determined by MemtoReg)

	signal 
			 write_reg_Rtype, 											  -- destination register if writing to rd	
			 write_reg_Itype	: std_logic_vector(  4 downto 0 ); -- destination register if writing to rt		
	
	signal 	read_data_1_ID,
				read_data_2_ID,
				Sign_extend_ID 		: std_logic_vector( 31 downto 0 );
				
	signal	lw_Stall_prev	: std_logic;
	signal  Instruction_prev	: std_logic_vector(31 downto 0);

begin
	reg_a 						<= Inst_desired( 25 downto 21 ); -- binary code for register output 1 (rs)
	reg_b 						<= Inst_desired( 20 downto 16 ); -- binary code for register output 2 (rt)
	write_reg_Rtype 			<= Inst_desired( 15 downto 11 ); -- binary code for destination register if R-type instruction (rd)
	write_reg_Itype	 		<= Inst_desired( 20 downto 16 ); -- binary code for destination register if R-type instruction (rt)
	Instruction_immediate 	<= Inst_desired( 15 downto  0 );  -- immediate portion of instruction
	
	Inst_desired <= Instruction_prev WHEN lw_Stall_prev = '1' ELSE Instruction (31 DOWNTO 0 ); 
	-- Allowing lw_Stall to cause the Instruction to be repeated.
		-- When lw_Stall is high, it causes the instruction to do nothing,
		-- so if it was high last cycle, we want to try the previous 
		-- instruction again, because it never got to execute.

	-- write destination is rd for Rtype, rt for Itype (determined by RegDst)
	write_register_address_ID <= write_reg_Rtype when RegDst = '1'
	else write_reg_Itype;
	
	-- For lw, result will come from memory, MemtoReg will be HIGH, else take the ALU_result
	write_data <= ALU_result_WB when MemtoReg = '0'
	else Mem_read_data;
	
	Reg_write_data <= write_data;
	-- Sign Extend 16-bits to 32-bits
   Sign_extend_ID <= X"0000" & Instruction_immediate
		WHEN Instruction_immediate(15) = '0'
		ELSE	X"FFFF" & Instruction_immediate;
	
	-- branch hardware moved from execute
	Add_result	<= PC_plus_4( 9 DOWNTO 2 ) +  Sign_extend_ID( 7 DOWNTO 0 ) - 1 ;
	
	-- data hazard detection
	read_data_1_ID <= write_data WHEN 
		( ( RegWrite = '1' ) AND ( write_register_address_WB = Inst_desired(25 DOWNTO 21) ) AND ( write_register_address_WB /= "00000" ) )
		-- case where rs is about to be written to (and rs is not $0)
	ELSE regs(conv_integer(reg_a));
	
	read_data_2_ID <= write_data WHEN
		( ( RegWrite = '1' ) AND ( write_register_address_WB = Inst_desired(20 DOWNTO 16) ) AND ( write_register_address_WB /= "00000" ) )
		--  case where rt is about to be written to (and rt is not $0)
	ELSE regs(conv_integer(reg_b));
	 
	-- zero control signal logic for branch
	Zero <= '1' WHEN  (read_data_1_ID = read_data_2_ID) ELSE '0';
	
	process(clock, reset)
    begin
        if reset = '1' then
            regs(0) <= (others => '0');  -- hardwire register zero to zero
            for i in 1 to num_regs-1 loop
                regs(i) <= std_logic_vector(to_unsigned(i, 32));
            end loop;
        elsif rising_edge(clock) then
		  
				-- signal delays (ID/EX/MEM)
				write_register_address_EX  <=  write_register_address_ID;
				write_register_address_MEM <=  write_register_address_EX;
				write_register_address_WB  <= write_register_address_MEM;
				
				lw_Stall_prev <= lw_Stall;
				Instruction_prev <= Instruction;
				-- output delays
				read_data_1 <= read_data_1_ID;
				read_data_2 <= read_data_2_ID;
				
				Sign_extend <= Sign_extend_ID;
				
            if RegWrite = '1' then
                if write_register_address_WB /= "00000" then  -- only allow writes to non-zero registers
                    regs(conv_integer(write_register_address_WB)) <= write_data;
                end if;
            end if;
        end if;  
    end process;
	 
	 reg_out_01 <= regs(1);
	 reg_out_02 <= regs(2);
	 reg_out_07 <= regs(7);
	 
end architecture Behavioral;
