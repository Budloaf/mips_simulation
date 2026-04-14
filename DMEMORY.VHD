						--  Dmemory module (implements the data
						--  memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY dmemory IS
	PORT(	Mem_read_data 			: BUFFER STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	address 					:  IN 	STD_LOGIC_VECTOR(  7 DOWNTO 0 );
        	Mem_write_data 		:  IN    STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	   	MemRead, Memwrite 	:  IN 	STD_LOGIC;
			lw_sw_fwd				:  IN		STD_LOGIC;
         clock,reset				:  IN 	STD_LOGIC
			);
END dmemory;

ARCHITECTURE behavior OF dmemory IS

--  input delay signals
SIGNAL Mem_write_data_desired	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );

BEGIN
	Mem_write_data_desired <= Mem_read_data WHEN lw_sw_fwd = '1' ELSE Mem_write_data; 
	data_memory : altsyncram
	GENERIC MAP  (
		operation_mode => "SINGLE_PORT",
		width_a => 32,
		widthad_a => 8,
		lpm_type => "altsyncram",
		outdata_reg_a => "UNREGISTERED",
		init_file => "ProjectFinalmemory.mif",
		intended_device_family => "Cyclone"
	)
	PORT MAP (
		wren_a => memwrite, 			--  in
		clock0 => Clock,				--  in
		address_a => address,		--  in
		data_a => Mem_write_data_desired,	--  in
		q_a => Mem_read_data		-- out
		);
END behavior;

