-------------------------------------------------------------------------------
--
-- Title       : ctrl_retack_counter_m12
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@mail.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Узел перетактирования значения счётчика 
--				 Узел управления FIFO с ретрансмитом
--														 
--
-------------------------------------------------------------------------------
--
--  Version    1.0   29.01.2017
--			   Создан из ctrl_retack_counter; Изменено только название
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package ctrl_retack_counter_m12_pkg is

component ctrl_retack_counter_m12 is
	generic(
	  counter_width	: in integer	-- число разрядов счётчика
	);
	port(
	
		rst1		: in std_logic;		-- 1 - сброс, по такту clk1
		rst2		: in std_logic;		-- 1 - сброс, по такту clk2
	
		---- Вход данных --- -
		clk1		: in std_logic;
		data_in		: in std_logic_vector( counter_width-1 downto 0 );
		
		---- Выход данных ----
		clk2		: in std_logic;
		data_out	: out std_logic_vector( counter_width-1 downto 0 )
	
	);
end component;

end package;

library ieee;
use ieee.std_logic_1164.all;

entity ctrl_retack_counter_m12 is
	generic(
	  counter_width	: in integer	-- число разрядов счётчика
	);
	port(
	
		rst1		: in std_logic;		-- 1 - сброс, по такту clk1
		rst2		: in std_logic;		-- 1 - сброс, по такту clk2
	
		---- Вход данных --- -
		clk1		: in std_logic;
		data_in		: in std_logic_vector( counter_width-1 downto 0 );
		
		---- Выход данных ----
		clk2		: in std_logic;
		data_out	: out std_logic_vector( counter_width-1 downto 0 )
	
	);
end ctrl_retack_counter_m12;


architecture ctrl_retack_counter_m12 of ctrl_retack_counter_m12 is


signal	data		: std_logic_vector( counter_width-1 downto 0 );

signal	flag1		: std_logic;
signal	flag2		: std_logic;	
signal	flag1to2	: std_logic;
signal	flag2to1	: std_logic;

type st1_type is ( s0, s1, s2, s3 );
type st2_type is ( s0, s1, s2 );

signal	st1			: st1_type;
signal	st2			: st2_type;

begin



			
pr_st1: process( clk1 ) begin
	if( rising_edge( clk1 ) ) then
		case( st1 ) is
			when s0 => 
				data <= data_in after 1 ns;
				st1 <= s1 after 1 ns;
				flag1 <= '0' after 1 ns;
			
			when s1 =>					
				st1 <= s2 after 1 ns;
				flag1 <= '1' after 1 ns;
				
			when s2 =>
				flag1 <= '1' after 1 ns;
				if( flag2to1='1' ) then
					st1 <= s3 after 1 ns;
				end if;
				
			when s3 => 
				flag1 <= '0' after 1 ns;
				if( flag2to1='0' ) then
					st1 <= s0 after 1 ns;
				end if;
			when others => null;
		end case;
		
		if( rst1='1' ) then
			st1 <= s0 after 1 ns;
		end if;	 
	end if;
end process;

flag1to2 <= flag1 after 1 ns when rising_edge( clk2 );  
flag2to1 <= flag2 after 1 ns when rising_edge( clk1 );

pr_st2: process( clk2 ) begin
	if( rising_edge( clk2 ) ) then
		
		case( st2 ) is
			when s0 =>
				flag2 <= '0' after 1 ns;
				if( flag1to2='1' ) then
					st2 <= s1 after 1 ns;
				end if;
			when s1 =>						
				st2 <= s2 after 1 ns;
				data_out <= data after 1 ns;
				flag2 <= '1' after 1 ns;
				
			when s2 =>
				if( flag1to2='0' ) then
					st2 <= s0 after 1 ns;
				end if;
			when others => null;
		end case;
					
		
		if( rst2='1' ) then
			st2 <= s0 after 1 ns;
			data_out <= (others=>'0') after 1 ns;
		end if;
	
	end if;
end process;
	
end ctrl_retack_counter_m12;
	