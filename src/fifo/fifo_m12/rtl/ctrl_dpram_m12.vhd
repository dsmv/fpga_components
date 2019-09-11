-------------------------------------------------------------------------------
--
-- Title       : ctrl_dpram_m12
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@mail.ru
--
-- Version     : 1.1
--
-------------------------------------------------------------------------------
--
-- Description : Узел двухпортовой памяти с настраиваемыми параметрами 
--
-------------------------------------------------------------------------------
--
--  Version    1.1   28.06.2019
--				Зафиксировано исправление выхода данных
--			
-------------------------------------------------------------------------------
--
--  Version    1.0   29.01.2017
--				Создан по аналогии с ctrl_fifo_config.vhd
--			    https://github.com/capitanov/adc_configurator/blob/master/ctrl_fifo_config.vhd
--			
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package ctrl_dpram_m12_pkg is

component ctrl_dpram_m12 is
	generic(
		DATA_WIDTH	: in integer:=64;		-- ширина FIFO
		DATA_DEPTH	: in integer:=4096		-- размер FIFO 
	);
	port (
		clka		: in std_logic;
		wea			: in std_logic;
		addra		: in std_logic_vector(15 downto 0);
		dina		: in std_logic_vector(DATA_WIDTH-1 downto 0);
		clkb		: in std_logic;
		rstb		: in std_logic;			  
		enb			: IN std_logic;
		addrb		: in std_logic_vector(15 downto 0);
		doutb		: out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end component;

function get_adr_size( DATA_DEPTH	: in integer ) return integer;

end package;


package body ctrl_dpram_m12_pkg  is
	
function get_adr_size( DATA_DEPTH	: in integer ) return integer is

variable	ret	: integer:=0;

begin

	case( DATA_DEPTH ) is
		when 64		=> ret:=6;	
		when 128	=> ret:=7;	
		when 256	=> ret:=8;	
		when 512	=> ret:=9;	
		when 1024 	=> ret:=10;	
		when 2048	=> ret:=11;	
		when 4096	=> ret:=12;	
		when 8192	=> ret:=13;	
		when 16384	=> ret:=14;	
		when 32768	=> ret:=15;	
		when 65536	=> ret:=16;	
		
		when others =>
			assert FALSE report "DATA_DEPTH has incorrect value" severity FAILURE;
	end case;
	
	return ret;
	
end function;	
	
end package body;

library ieee;
use ieee.std_logic_1164.all;		 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.ctrl_dpram_m12_pkg.all;

entity ctrl_dpram_m12 is
	generic(
		DATA_WIDTH	: in integer:=64;		-- ширина FIFO
		DATA_DEPTH	: in integer:=4096		-- размер FIFO 
	);
	port (
		clka		: in std_logic;
		wea			: in std_logic;
		addra		: in std_logic_vector(15 downto 0);
		dina		: in std_logic_vector(DATA_WIDTH-1 downto 0);
		clkb		: in std_logic;
		rstb		: in std_logic;			  
		enb			: IN std_logic;
		addrb		: in std_logic_vector(15 downto 0);
		doutb		: out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end ctrl_dpram_m12;


architecture ctrl_dpram_m12 of ctrl_dpram_m12 is

type RAM is array (integer range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal Mem : RAM (0 to DATA_DEPTH-1);



constant	ADR_SIZE	: integer:= get_adr_size( DATA_DEPTH );

signal	data_o			: std_logic_vector(DATA_WIDTH-1 downto 0);

begin
	
pr_rd: process( clkb ) begin
	if( rising_edge( clkb ) ) then
			data_o <= Mem(conv_integer( addrb( ADR_SIZE-1 downto 0 ) ) );
	end if;
end process;

doutb <= data_o;

pr_wr: process( clka ) begin
	if( rising_edge( clka ) ) then
		if( wea='1' ) then
			Mem(conv_integer( addra( ADR_SIZE-1 downto 0 ) ) ) <= dina after 0.5 ns;
		end if;
	end if;
end process;

end ctrl_dpram_m12;
 