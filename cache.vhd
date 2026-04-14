library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity cache is
	port(	PC							:  in 	std_logic_vector(  9 downto 0 );
			Instruction				:	in		std_logic_vector( 31 downto 0 );
			Instruction_to_ID		: out 	std_logic_vector( 31 downto 0 );
			cache_read_data	 	: buffer	std_logic_vector( 37 downto 0 );
	   	cache_write			 	: buffer std_logic;
			hit						: buffer std_logic;
			cache_Stall				: buffer	std_logic;
         clock,reset				:  in 	std_logic
			);
end cache;

architecture behavior OF cache IS

signal index				: std_logic_vector(  2 downto 0 );
signal valid				: std_logic;
signal cache_tag			: std_logic_vector(  4 downto 0 );
signal PC_tag				: std_logic_vector(  4 downto 0 );
signal cache_write_data : std_logic_vector( 31 downto 0 );


begin
	cache_memory : altsyncram
	generic map  (
		operation_mode => "SINGLE_PORT",
		width_a => 38,
		widthad_a => 3,
		lpm_type => "altsyncram",
		outdata_reg_a => "UNREGISTERED",
		init_file => "cachememory.mif",
		intended_device_family => "Cyclone"
	)
	port map (
		wren_a	 	=> cache_write,			--  in
		clock0 		=> clock,					--  in
		address_a 	=> index,					--  in
		data_a(37)  => '1',
		data_a(36 downto 32) => PC_tag,
		data_a(31 downto 0) 		=> cache_write_data,		--  in
		q_a 			=> cache_read_data		-- out
		);
		
		-- data is read from cache every cycle
		-- data is written to cache when 
		
		PC_tag		<= PC(9 downto 5);
		index			<= PC(4 downto 2);
		valid 		<= cache_read_data(37);
		cache_tag 	<= cache_read_data(36 downto 32);
		--inst			<= cache_read_data(31 downto  0);
		
		hit <= '1' when PC_tag = cache_tag and valid = '1' else '0';
		
		cache_Stall <= '1' when hit = '0' else '0';
		
		process
			begin
				wait until (clock'event) and (clock = '1');
					cache_write <= cache_Stall; -- write to cache after stalling a cycle (on account of a miss)
					cache_write_data <= Instruction;
					
					if hit = '1' then 
						Instruction_to_ID <= cache_read_data(31 downto 0);
					else
						Instruction_to_ID <= X"00000000";
					end if;
		end process;
end behavior;
