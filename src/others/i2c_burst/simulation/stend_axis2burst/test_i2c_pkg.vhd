---------------------------------------------------------------------------------------------------
--
-- Title       : test_i2c_pkg.vhd
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
--	
-- Version     : 1.0			 
--
---------------------------------------------------------------------------------------------------
--
-- Description : Пакет для тестирования cl_i2c_burst
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

package test_i2c_pkg is		   
				   

	--! Инициализация теста	
	procedure test_i2c_init(
			path          : in string;  -- путь к файлам отчёта
			stend_name    : in string;  -- имя стенда
			test_id       : in integer    -- идентификатор теста
	);
		
	--! Завершение теста		
	procedure test_i2c_close;						
		
	-- Формирование сообщения с результатом теста
	procedure test_i2c_finish( error   : in integer );
	

	
	--! Программирование
	procedure test_i2c_data_input( 

				test_id				: in integer;
			signal	clk				: in std_logic;	-- тактовая частота загрузки
			
		
			signal	data_o			: out std_logic_vector( 31 downto 0 );
			signal	data_i			: in  std_logic_vector( 31 downto 0 );
			signal	data_we			: out  std_logic;
			signal	data_rd			: out  std_logic;
			
			signal	error			: out integer;		-- число обнаруженных ошибок
			signal	test_complete	: out std_logic		-- 1 - тест завершён
			
			
			
	);				 
	
	procedure test_i2c_sim( 

				test_id				: in integer;

			
			signal	scl_i			: in std_logic;
			signal	sda_i			: in std_logic;
			signal	sda_o			: out std_logic
			
	);	


end package	test_i2c_pkg;


package body test_i2c_pkg is
	
	FILE   log: text;
	shared variable cnt_ok, cnt_error: integer;
   
	
	FILE   		fl_data_in			: text;
	FILE   		fl_data_out			: text;
	FILE   		fl_data_gold		: text;

	
	
-- Инициализация теста	
procedure test_i2c_init(
    path          : in string;  -- путь к файлам отчёта
    stend_name    : in string;  -- имя стенда
    test_id       : in integer    -- идентификатор теста
) is
	constant fname : string:=path & stend_name & "_file_id_" & integer'image(test_id) & ".log";
    
begin
    
    file_open( log, fname, WRITE_MODE );
    cnt_ok:=0;
    cnt_error:=0;
    
end test_i2c_init;	

---- Завершение теста ----		
procedure test_i2c_close is		
begin					  	
	file_close( log ); 
end test_i2c_close;	


-- Формирование сообщения с результатом теста
procedure test_i2c_finish( error   : in integer )
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

end test_i2c_finish;	
--					  	

procedure write_reg( 
					data			: in std_logic_vector( 31 downto 0 );
			signal	clk				: in std_logic;	-- тактовая частота загрузки
			signal	data_o			: out std_logic_vector( 31 downto 0 );
			signal	data_we			: out  std_logic
		) is 
begin
	
	wait until rising_edge( clk );
	data_we <= '1' after 1 ns;
	data_o <= data after 1 ns;
	wait until rising_edge( clk );
	data_we <= '0' after 1 ns;
	
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	
	
end write_reg;	



procedure read_reg( 
					data			: out std_logic_vector( 31 downto 0 );
			signal	clk				: in  std_logic;	-- тактовая частота загрузки
			signal	data_i			: in  std_logic_vector( 31 downto 0 );
			signal	data_rd			: out std_logic
		) is 
begin
	
	wait until rising_edge( clk );
	data_rd <= '1' after 1 ns;
	data := data_i;
	wait until rising_edge( clk );
	data_rd <= '0' after 1 ns;
	
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	wait until rising_edge( clk );
	
	
end read_reg;	

	
--! Программирование
procedure test_i2c_data_input( 

				test_id				: in integer;

			signal	clk				: in std_logic;	-- тактовая частота загрузки
			
			signal	data_o			: out std_logic_vector( 31 downto 0 );
			signal	data_i			: in  std_logic_vector( 31 downto 0 );
			signal	data_we			: out  std_logic;
			signal	data_rd			: out  std_logic;
			
			signal	error			: out integer;		-- число обнаруженных ошибок
			signal	test_complete	: out std_logic		-- 1 - тест завершён
			
)  is

type	type_arr		is array( 4 downto 0 ) of std_logic_vector( 31 downto 0 );

variable	data_expect			: type_arr:=
(			 
		0   => x"12C0E1A2", 
		1   => x"12C0F2A3", 
		2   => x"12C0E3A5", 
		3   => x"12C0E4FF", 
		4   => x"12C0F5FF" 
);

variable	L				: line;

variable	cnt				: std_logic_vector( 31 downto 0 ):=x"0A000000";

variable	len				: integer:=10;
variable	len_pause		: integer:=4;
variable	pkg_index		: integer:=0;
variable	len_index		: integer:=0;

variable	dataw_cnt		: std_logic_vector( 3 downto 0 ):="0000";
variable	data			: std_logic_vector( 31 downto 0 );

variable	error_i			: integer:=0;

begin		
		data_o <= (others=>'0');
		data_we <= '0';	 
		data_rd <= '0';
	
		wait until rising_edge( clk );	   
		
--		write_reg( x"80018000", clk, data_o, data_we );
--		write_reg( x"C0A3C0A2", clk, data_o, data_we );
--		write_reg( x"C0A58004", clk, data_o, data_we );
--		write_reg( x"8007C006", clk, data_o, data_we );

		write_reg( x"00008000", clk, data_o, data_we );
		write_reg( x"00008001", clk, data_o, data_we );
		
		write_reg( x"0000C0A2", clk, data_o, data_we );
		write_reg( x"0000C0A3", clk, data_o, data_we );

		write_reg( x"00008004", clk, data_o, data_we );
		write_reg( x"0000C0A5", clk, data_o, data_we );

		write_reg( x"0000C006", clk, data_o, data_we );
		write_reg( x"00008007", clk, data_o, data_we );


		for ii in 0 to 4 loop
			loop
				read_reg( data, clk, data_i, data_rd );
				if( data( 11 downto 8 )/=dataw_cnt ) then
					dataw_cnt := dataw_cnt + 1;
					exit;
				end if;
			end loop;  
			
			if( data=data_expect(ii) ) then	
				fprint( output, L, "  %r   data: %r - Ok\n", fo(ii), fo(data) );
				fprint(    log, L, "  %r   data: %r - Ok\n", fo(ii), fo(data) );
			else
				fprint( output, L, "  %r   data: %r  expect: %r - ERROR\n", fo(ii), fo(data), fo(data_expect(ii)) );
				fprint(    log, L, "  %r   data: %r  expect: %r - ERROR\n", fo(ii), fo(data), fo(data_expect(ii)) );
				error_i:=error_i+1;
			end if;
			
			error <= error_i;
			
		end loop;

		loop
			read_reg( data, clk, data_i, data_rd );
			if( data( 14 )='0' ) then
				exit;
			end if;
		end loop;  
		
		write_reg( x"00000000", clk, data_o, data_we );
		
		test_complete <= '1';
		wait;
	
end test_i2c_data_input;	


procedure test_i2c_sim( 

				test_id				: in integer;

			
			signal	scl_i			: in std_logic;
			signal	sda_i			: in std_logic;
			signal	sda_o			: out std_logic
			
)  is

variable	data_i			: std_logic_vector( 8 downto 0 );
variable	data_o			: std_logic_vector( 8 downto 0 );
variable	cmd				: std_logic_vector( 7 downto 0 );

begin			  
	
	sda_o <= '1';
	wait until falling_edge( sda_i ) and scl_i='1';
	
	for ii in 0 to 8 loop				
		wait until falling_edge( scl_i );
		if( ii=8 ) then
			sda_o <= '0' after 1 ns;
		end if;
		wait until rising_edge( scl_i );
		data_i(8-ii):=sda_i;
	end loop;
	cmd := data_i( 8 downto 1 );
		
	
	
end  test_i2c_sim;
							


		   

end package	body test_i2c_pkg;
