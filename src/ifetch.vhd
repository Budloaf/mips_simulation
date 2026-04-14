-- Ifetch module (provides the PC and instruction 
--memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY Ifetch IS
	generic (
        cache_size : integer := 8
    );
	PORT(	SIGNAL Instruction 			: BUFFER		STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	SIGNAL PC_plus_4_out 		:    OUT		STD_LOGIC_VECTOR( 9 DOWNTO 0 );
        	SIGNAL Add_result 			:     IN 	STD_LOGIC_VECTOR( 7 DOWNTO 0 );
        	SIGNAL Branch 					:  	IN 	STD_LOGIC;
			SIGNAL BranchNot				:  	IN  	STD_LOGIC;
			SIGNAL Jump						:  	IN		STD_LOGIC;
			SIGNAL Flush					: BUFFER 	STD_LOGIC; -- brought to top-level for easy viewing
			SIGNAL Stall					: BUFFER 	STD_LOGIC; -- brought to top-level for easy viewing
			SIGNAL lw_Stall				:		IN		STD_LOGIC;
        	SIGNAL Zero 					:  	IN 	STD_LOGIC;
      	SIGNAL PC_out 					: 	  OUT		STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	-- cache {
			signal cache_read_data	 	: buffer	std_logic_vector( 37 downto 0 );
	   		signal cache_write			: buffer std_logic;
			signal hit					: buffer std_logic;
			
			-- cache contents for viewing
			-- signal cache_000				:	  out std_logic_vector( 37 downto 0 );
			-- signal cache_001				:	  out std_logic_vector( 37 downto 0 );
			-- signal cache_010				:	  out std_logic_vector( 37 downto 0 );
			-- signal cache_011				:	  out std_logic_vector( 37 downto 0 );
			-- signal cache_100				:	  out std_logic_vector( 37 downto 0 );
			-- signal cache_101				:	  out std_logic_vector( 37 downto 0 );
			-- signal cache_110				:	  out std_logic_vector( 37 downto 0 );
			-- signal cache_111				:	  out std_logic_vector( 37 downto 0 );
	-- }
        	SIGNAL clock, reset 			:  	IN 	STD_LOGIC);
END Ifetch;

ARCHITECTURE behavior OF Ifetch IS
	type cache_memory is array (0 to cache_size-1) of std_logic_vector(37 downto 0);
	signal cache : cache_memory;
	
	SIGNAL PC, PC_plus_4	 : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL next_PC, Mem_Addr, PCnonjump, PCjump : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL Instruction_from_IM	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	
	-- cache signals 
	signal index				: std_logic_vector(  2 downto 0 );
	signal valid				: std_logic;
	signal cache_tag			: std_logic_vector(  4 downto 0 );
	signal PC_tag				: std_logic_vector(  4 downto 0 );
	signal cache_write_data 	: std_logic_vector( 37 downto 0 );

BEGIN
						--ROM for Instruction Memory
inst_memory: altsyncram
	
	GENERIC MAP (
		operation_mode => "ROM",
		width_a => 32,
		widthad_a => 8,
		lpm_type => "altsyncram",
		outdata_reg_a => "UNREGISTERED",
		init_file => "ProjectFinalprogram.mif",
		intended_device_family => "Cyclone"
	)
	PORT MAP (
		clock0      => NOT clock, -- changed to be falling-edge triggered for timing
		address_a 	=> Mem_Addr, 
		q_a 		=> Instruction_from_IM -- changed to an internal signal which is used in most cases (see process statement)
		);
		
-- cache {
		PC_tag			 <= PC(9 downto 5); -- top 5 bits = tag
		index			 <= PC(4 downto 2); -- index is shared for PC and cache
		cache_write_data <= '1' & PC_tag & Instruction_from_IM; 
		-- when written, valid should be high
		-- 				 cache_tag is set according to current PC_tag
		-- 				 Instruction is taken from IM
		
		cache_read_data <= cache(conv_integer(index)); -- take out the corresponding indexed cache file
		
		valid 			<= cache_read_data(37); 		  -- valid bit is the first bit
		cache_tag 		<= cache_read_data(36 downto 32); -- cache_tag is the next five bits
		-- (31 downto 0) is used to send the Instruction through the pipeline
		
		hit <= '1' when PC_tag = cache_tag and valid = '1' else '0';
-- }
	-- Instructions always start on word address - not byte
		PC(1 DOWNTO 0) <= "00";
		-- copy output signals - allows read inside module
		PC_out 			<= PC;
		PC_plus_4_out 	<= PC_plus_4;
		-- send address to inst. memory address register
		Mem_Addr <= PC( 9 DOWNTO 2);
		-- Adder to increment PC by 4        
        PC_plus_4( 9 DOWNTO 2 )  <= PC( 9 DOWNTO 2 ) + 1;
     	PC_plus_4( 1 DOWNTO 0 )  <= "00";
						
	
	-- PCnonjump is next_PC unless jump
		PCnonjump <= X"00" WHEN Reset = '1' ELSE
			-- PCSrc
			Add_result  WHEN (	-- branch case
			(
			( Branch = '1' ) AND ( Zero = '1' )
			)
			OR
			(
			( BranchNot = '1') AND ( Zero = '0' )
			)
			) 
			ELSE 
				PC( 9 DOWNTO 2 ) WHEN (Stall = '1' OR lw_Stall = '1' OR hit = '0' ) -- let PC repeat on a stall or miss
			ELSE
				PC_plus_4( 9 DOWNTO 2 );			 -- set PC = PC + 4 otherwise

			
		PCjump ( 7 DOWNTO 0 ) <= Instruction( 7 DOWNTO 0 );
			
		Next_PC <= PCjump WHEN (Jump = '1')
				ELSE PCnonjump;
			
		-- Flush and Stall go high when beq/bne/j is in ID stage
		-- Both signals are dealt with here in ifetch.vhd, but they are bruoght to top level
		Flush <= '1' WHEN Branch = '1' OR BranchNot = '1' OR Jump = '1' OR hit = '0' 	ELSE '0'; -- flush on a miss
		Stall <= '1' WHEN Branch = '1' OR BranchNot = '1'     			 				ELSE '0';
		
			
	PROCESS
		BEGIN
			WAIT UNTIL ( clock'EVENT ) AND ( clock = '1' );
					if Reset = '1' then -- clear cache on a reset
						for i in 0 to cache_size-1 loop
							cache(i) <= "00" & X"000000000";
						end loop;
					end if;
					
					PC( 9 DOWNTO 2 ) <= next_PC;
					
					cache_write 		<= not (hit or cache_write);
					-- miss/wait
					-- miss/write
					-- hit/exec
					
					IF cache_write = '1' THEN
						cache(conv_integer(index)) <= cache_write_data; -- write data when cache_write is high
					END IF;
					
					-- Flush being high means hit is low
					IF (Flush = '1') OR (Reset = '1') THEN -- Flushing the Instruction when Flush is high or on a reset
						Instruction <= X"00000000";
						-- This approach was much more natural to me than driving all of the important signals low.
					ELSE
						-- only happens on a hit
						Instruction <= cache_read_data(31 downto 0);	-- Otherwise just let the Instruction come from cache
					END IF;
	END PROCESS;
	
	-- cache_000 <= cache(0);
	-- cache_001 <= cache(1);
	-- cache_010 <= cache(2);
	-- cache_011 <= cache(3);
	-- cache_100 <= cache(4);
	-- cache_101 <= cache(5);
	-- cache_110 <= cache(6);
	-- cache_111 <= cache(7);
	
END behavior;
