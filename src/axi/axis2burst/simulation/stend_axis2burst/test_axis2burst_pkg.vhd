---------------------------------------------------------------------------------------------------
--
-- Title       : test_axis2burst_pkg.vhd
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
--	
-- Version     : 1.0			 
--
---------------------------------------------------------------------------------------------------
--
-- Description : Пакет для тестирования cl_axis2burst
--
---------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;		
use ieee.std_logic_arith.all;  
use ieee.std_logic_signed.all;
use ieee.math_real.all;

use ieee.std_logic_textio.all;
use std.textio.all;	

library work;
use work.pck_fio.all;	

use work.axis_pkg.all;

package test_axis2burst_pkg is		   
				   

   function get_id_from_file( id : integer; fname	: in string ) return integer;
	
	--! Инициализация теста	
	procedure test_axis2burst_init(
			path          : in string;  -- путь к файлам отчёта
			stend_name    : in string;  -- имя стенда
			test_id       : in integer    -- идентификатор теста
	);
		
	--! Завершение теста		
	procedure test_axis2burst_close;						
		
	-- Формирование сообщения с результатом теста
	procedure test_axis2burst_finish( error   : in integer );
	

	
	--! Формирование данных АЦП
	procedure test_axis2burst_data_input( 

				test_id				: in integer;
			signal	clk				: in std_logic;	-- тактовая частота загрузки
			
			signal	s00_axis_m		: out M_AXIS_256_TYPE;
			signal	s00_tready		: in  std_logic
			
			
	);		
	
	--! Формирование выходного файла и сравнение с образцом
	procedure test_axis2burst_data_output( 
				test_id				: in integer;
			signal	clk				: in std_logic;	-- тактовая частота загрузки
			
			
			signal  m00_axis_m		: in  M_AXIS_256_TYPE;
			signal  m00_tready		: out std_logic;			
			
			signal	error			: out integer;		-- число обнаруженных ошибок
			signal	test_complete	: out std_logic		-- 1 - тест завершён
	);	
			
--	--! Установка соедин

end package	test_axis2burst_pkg;


package body test_axis2burst_pkg is
	
	FILE   log: text;
	shared variable cnt_ok, cnt_error: integer;
   
	
	FILE   		fl_data_in			: text;
	FILE   		fl_data_out			: text;
	FILE   		fl_data_gold		: text;

	
	
-- Инициализация теста	
procedure test_axis2burst_init(
    path          : in string;  -- путь к файлам отчёта
    stend_name    : in string;  -- имя стенда
    test_id       : in integer    -- идентификатор теста
) is
	constant fname : string:=path & stend_name & "_file_id_" & integer'image(test_id) & ".log";
    
begin
    
    file_open( log, fname, WRITE_MODE );
    cnt_ok:=0;
    cnt_error:=0;
    
end test_axis2burst_init;	

---- Завершение теста ----		
procedure test_axis2burst_close is		
begin					  	
	file_close( log ); 
end test_axis2burst_close;	


-- Формирование сообщения с результатом теста
procedure test_axis2burst_finish( error   : in integer )
is

variable    str            : line;         
variable    L              : line;         

begin

	fprint( output, L, "\nTest time:  %r \n", fo(now) );
	fprint(    log, L, "\nTest time:  %r \n", fo(now) );

    -- вывод в файл --
    writeline( log, str );        
    if( error=0 ) then
    write( str, string'("TEST PASSED" ));
    cnt_ok := cnt_ok + 1;
    else
    write( str, string'("TEST FAILED" ));
    cnt_error := cnt_error + 1;
    end if;
    writeline( log, str );    
    writeline( log, str );        
    
    -- вывод в консоль --
    writeline( output, str );        
    if( error=0 ) then
    write( str, string'("TEST PASSED" ));
    else
    write( str, string'("TEST FAILED" ));
    end if;
    writeline( output, str );    
    writeline( output, str );

end test_axis2burst_finish;	
							  
	
--! Формирование данных АЦП
procedure test_axis2burst_data_input( 

				test_id				: in integer;

			signal	clk				: in std_logic;	-- тактовая частота загрузки
			
			signal	s00_axis_m		: out M_AXIS_256_TYPE;
			signal	s00_tready		: in  std_logic
			
			
)  is



variable	L				: line;

variable	cnt				: std_logic_vector( 31 downto 0 ):=x"0A000000";

variable	len				: integer:=10;
variable	len_pause		: integer:=4;
variable	pkg_index		: integer:=0;
variable	len_index		: integer:=0;

begin		

		wait until rising_edge( clk );	   
	
		loop
			case( len_index ) is
				when 1 => len:=4;  len_pause:=12;
				when 2 => len:=4;  len_pause:=27;
				when 4 => len:=1;  len_pause:=1;
				when 5 => len:=15; len_pause:=4;
				when 7 => len:=2;  len_pause:=6;
				when 9 => len:=44;  len_pause:=1;
				when others => len:=5; len_pause:=1;
			end case;
			len_index:=len_index+1;
			if( len_index=10 ) then
				len_index:=0;
			end if;
			
			
			for ii in 0 to len-1 loop
				s00_axis_m.tdata( 255 downto 224 )<=cnt after 1 ns;
				s00_axis_m.tdata(  31 downto 0 )<=cnt after 1 ns;
				s00_axis_m.tdata( 223 downto 32 )<=(others=>'0') after 1 ns;
				s00_axis_m.tvalid <= '1' after 1 ns;
				wait until rising_edge( clk ) and s00_tready='1';
				cnt:=cnt+1;
			end loop;				   
			
			s00_axis_m.tdata( 255 downto 0 )<=(others=>'0') after 1 ns;
			s00_axis_m.tvalid <= '0' after 1 ns;
			
			for ii in 0 to len_pause-1 loop
				wait until rising_edge( clk );	
			end loop;
			
			pkg_index:=pkg_index+1;
		
		end loop;
		wait;
	
end test_axis2burst_data_input;	


	
--! Формирование выходного файла и сравнение с образцом
procedure test_axis2burst_data_output( 

				test_id				: in integer;

			signal	clk				: in std_logic;	-- тактовая частота загрузки
			
			
			signal  m00_axis_m		: in  M_AXIS_256_TYPE;
			signal  m00_tready		: out std_logic;			
			
			signal	error			: out integer;		-- число обнаруженных ошибок
			signal	test_complete	: out std_logic		-- 1 - тест завершён)  is

	) is
	
variable 	L 					: line;

variable	error_i				: integer:=0;
variable	cnt					: std_logic_vector( 31 downto 0 ):=x"0A000000";
variable	data_expect			: std_logic_vector( 255 downto 0 );
variable	data_i				: std_logic_vector( 255 downto 0 );

variable	len					: integer:=10;
variable	index_rd			: integer:=0;
variable	len_pause			: integer:=1;

variable	len_index			: integer:=0;
begin		
	
	test_complete <= '0';
	
	wait until rising_edge( clk );
	m00_tready <= '1' after 1 ns;
	
	loop									  
		
		case( len_index ) is
			when 0 => len:=10; len_pause:=1;
			when 2 => len:=1;  len_pause:=5;
			when 6 => len:=25; len_pause:=1;
			when 7 => len:=15; len_pause:=21;
			when others => null;
		end case;
		
		len_index := len_index+1;
		if( len_index=7 ) then
			len_index:=8;
		end if;
		
		for ii in 0 to len-1 loop
			wait until rising_edge( clk ) and m00_axis_m.tvalid='1';
			data_expect( 255 downto 224 ):=cnt;
			data_expect( 31 downto 0 ):=cnt;
			data_expect( 223 downto 32 ):=(others=>'0');
			data_i := m00_axis_m.tdata;					
			
			if( data_i/=data_expect ) then
				if( error_i<32 ) then
					fprint( output, L, " index=%5r  expect %r  receive %r  - ERROR\n", fo(index_rd), fo(data_expect), fo(data_i) );
					fprint(    log, L, " index=%5r  expect %r  receive %r  - ERROR\n", fo(index_rd), fo(data_expect), fo(data_i) );
				end if;
				error_i:=error_i+1;
			end if;
			index_rd := index_rd+1;
			cnt := cnt + 1;
		end loop;		
		m00_tready <= '0' after 1 ns;
			
		for ii in 0 to len_pause-1 loop
			wait until rising_edge( clk );
		end loop;
	
		error <= error_i;
		
		if( index_rd>2200 ) then
			exit;
		end if;
		
		m00_tready <= '1' after 1 ns;
		
	end loop;
	
	error <= error_i;
	
	test_complete <= '1' after 1 ns;
	wait;
	
	
end test_axis2burst_data_output;	



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

		   

end package	body test_axis2burst_pkg;
