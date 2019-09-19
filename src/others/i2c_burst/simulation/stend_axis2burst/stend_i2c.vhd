-------------------------------------------------------------------------------
--
-- Title       : stend_i2c
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Стенд для проверки компонентов cl_i2c_burst
--
-------------------------------------------------------------------------------
--
--	Version 1.0  14.09.2019  Dmitry Smekhov
--				 
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;

use std.textio.all;
use std.textio;


use work.test_i2c_pkg.all;


entity stend_i2c is
	generic(
	 	test_id             : in integer:=-1;	-- идентификатор теста
        stend_name          : in string:="stend_i2c";	-- имя стенда
        test_log            : in string:="src/others/i2c_burst/simulation/log/"    -- путь к файлу отчёта
    );
end stend_i2c;

architecture Behavioral of stend_i2c is
	
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


signal	reset				: std_logic;	-- 0 - сброс
signal	clk					: std_logic:='0';
signal	clkx				: std_logic:='0';
signal	data_o				: std_logic_vector( 31 downto 0 );
signal	data_i				: std_logic_vector( 31 downto 0 );
signal	data_we				: std_logic:='0';
signal	data_rd				: std_logic:='0';
signal	scl_o				: std_logic;
signal	sda_o				: std_logic;
signal	sda_i				: std_logic;
signal	i2c_req				: std_logic;
signal	i2c_ack				: std_logic:='0';   
signal	start				: std_logic:='0';		
signal	test_complete		: std_logic:='0';
signal	error				: integer:=0;		   
signal	tsda_o				: std_logic;

begin
	
	     

clk <= not clk after 5 ns;
clkx <= not clkx after 401 ns;

reset <= '0', '1' after 101 ns;

i2c_ack <= i2c_req after 221 ns;

pr_input: process begin
	
	wait until rising_edge( clk ) and start='1';
	
	test_i2c_data_input( 

			test_id			=> gl_test_id,

			clk				=> clk,
							
			data_o			=> data_i,
			data_i			=> data_o,
			data_we			=> data_we,
			data_rd			=> data_rd,
			
			error			=> error,			-- число обнаруженных ошибок
			test_complete	=> test_complete	-- 1 - тест завершён
			
	);
				

    

end process;

   --
pr_data_output: process begin
	
	wait until rising_edge( clk ) and start='1';
	
	test_i2c_sim( 

				test_id				=> gl_test_id,

			
				scl_i			=> scl_o,
				sda_i			=> sda_i,
				sda_o			=> tsda_o 
			);


end process;

sda_i <= tsda_o and sda_o;

uut: entity work.cl_i2c_burst 	   
	port map(
		reset				=> reset,
		clk					=> clk,
		clkx				=> clkx,
							   			
		data_o				=> data_o,
		data_i				=> data_i,
		data_we				=> data_we,	  
		data_rd				=> data_rd,
							   			
		scl_o				=> scl_o,
		sda_o				=> sda_o,
		sda_i				=> sda_i,
		i2c_req				=> i2c_req,
		i2c_ack				=> i2c_ack		
	
	);			
	


pr_main: process 

variable	test_id_z			: integer;
variable	data				: std_logic_vector( 31 downto 0 );
variable 	str 				: LINE;		-- pointer to string


variable	L					: LINE;


begin
	
    test_id_z:= get_id_from_file( test_id, fname_test_id ); 
	gl_test_id := test_id_z;
	
	
	test_i2c_init( path, stend_name, test_id_z );
	

	wait for 1 us;				
	wait until rising_edge( clk );	
	
	start <= '1' after 1 ns;		 
		
		
--	case( test_id_z ) is
--	
--	    when 20 => test_i2c_xxx( adm_cmd, adm_ret, 7);
--		
--		
--		when others => null;
--	end case;

	wait until rising_edge( test_complete );

	test_i2c_finish( error );
	test_i2c_close;
	wait;
	
end process;

end Behavioral;  