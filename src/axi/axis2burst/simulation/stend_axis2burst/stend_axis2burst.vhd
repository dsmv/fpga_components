-------------------------------------------------------------------------------
--
-- Title       : stend_axi2burst
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Стенд для проверки компонентов cl_axis2burst, cl_burst2axi2
--
-------------------------------------------------------------------------------
--
--	Version 1.0  11.09.2019  Dmitry Smekhov
--				 
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

use std.textio.all;
use std.textio;

use work.axis_pkg.all;
use work.test_axis2burst_pkg.all;


entity stend_axi2burst is
	generic(
	 	test_id             : in integer:=-1;	-- идентификатор теста
        stend_name          : in string:="stend_axi2burst";	-- имя стенда
        test_log            : in string:="../../../../../src/axi/axis2burst/simulation/log/"    -- путь к файлу отчёта
    );
end stend_axi2burst;

architecture Behavioral of stend_axi2burst is
	
constant fname_test_id	        : string:= test_log & "test_id.txt";
constant path                    : string:= test_log;
     --
function get_id_from_file( id : integer; fname	: in string ) return integer is

	FILE   		file_id		: text;
	variable	L			: line;		 
	variable	L1			: line;		 
	variable	ret			: integer;

begin
	
	if( id=-1 ) then
		file_open( file_id, fname, READ_MODE );
		readline( file_id, L );
		read( L, ret );
		file_close( file_id );
	else
		ret:=id;
	end if;
	
	return ret;
end function;

shared variable  gl_test_id 	: integer:=0;

signal	reset_p					: std_logic; -- reset		
signal	clk 					: std_logic:='0'; --! common clock dsp		
signal	start					: std_logic:='0'; --! 1 - start test
signal	test_complete			: std_logic:='0';
signal	error					: integer:=0;

		--- AXI Stream ---		
signal	s00_axis_m				: M_AXIS_256_TYPE:=M_AXIS_256_EMPTY;
signal	s00_tready				: std_logic:='0';
signal	m00_axis_m				: M_AXIS_256_TYPE:=M_AXIS_256_EMPTY;
signal	m00_tready				: std_logic:='0';
		
		--- AXI Burst Stream ---			 
signal	b00_axis_m				: M_AXIS_256U7_TYPE:=M_AXIS_256U7_EMPTY;
signal	b00_axis_s				: S_AXIS_256U1_TYPE:=S_AXIS_256U1_EMPTY;
		
begin
	
	     

clk <= not clk after 5 ns;

reset_p <= '1', '0' after 101 ns;

pr_input: process begin
	
	wait until rising_edge( clk ) and start='1';
	
    test_axis2burst_data_input( 
					test_id			=> gl_test_id,
                    clk				=> clk,
					s00_axis_m		=> s00_axis_m,
					s00_tready		=> s00_tready
					
    ); 	
    

end process;

   --
pr_data_output: process begin
	
	wait until rising_edge( clk ) and start='1';
	
	test_axis2burst_data_output( 
					test_id			=> gl_test_id,		  
					clk				=> clk,
					m00_axis_m		=> m00_axis_m,
					m00_tready		=> m00_tready,	
					error			=> error,
					test_complete	=> test_complete
);	

end process;


uut1: entity work.cl_axis2burst_256 
	port map(
		clk					=> clk,
		reset_p				=> reset_p,
		s00_axis_m			=> s00_axis_m,
		s00_tready			=> s00_tready,
		m00_axis_m			=> b00_axis_m,
		m00_axis_s			=> b00_axis_s
	); 
	
uut2: entity cl_burst2axis_256 
	port map(
		clk					=> clk,
		reset_p				=> reset_p,
		s00_axis_m			=> b00_axis_m,
		s00_axis_s			=> b00_axis_s,
		m00_axis_m			=> m00_axis_m,
		m00_tready			=> m00_tready	
	);
	
pr_main: process 

variable	test_id_z			: integer;
variable	data				: std_logic_vector( 31 downto 0 );
variable 	str 				: LINE;		-- pointer to string


variable	L					: LINE;


begin
	
    test_id_z:= get_id_from_file( test_id, fname_test_id ); 
	gl_test_id := test_id_z;
	
	
	test_axis2burst_init( path, stend_name, test_id_z );
	

	wait for 1 us;				
	wait until rising_edge( clk );	
	
	start <= '1' after 1 ns;		 
		
		
--	case( test_id_z ) is
--	
--	    when 20 => test_axis2burst_ddc( adm_cmd, adm_ret, 7);
--		
--		
--		when others => null;
--	end case;

	wait until rising_edge( test_complete );

	test_axis2burst_finish( error );
	test_axis2burst_close;
	wait;
	
end process;

end Behavioral;  