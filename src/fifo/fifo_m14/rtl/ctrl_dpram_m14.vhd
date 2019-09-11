-------------------------------------------------------------------------------
--
-- Title       : ctrl_dpram_m14
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@mail.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Узел двухпортовой памяти с настраиваемыми параметрами 
--
-------------------------------------------------------------------------------
--
--  Version    1.1	02.10.2017
--
--              Максимальный размер увеличен до 256К
--
---------------------------------------------------------------------------------
--
--  Version    1.0   14.03.2017
--			
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package ctrl_dpram_m14_pkg is

component ctrl_dpram_m14 is
	generic(
		DATA_WIDTH	: in integer:=64;		-- ширина FIFO
		DATA_DEPTH	: in integer:=4096		-- размер FIFO 
	);
	port (
		clka		: in std_logic;
		wea			: in std_logic;
		addra		: in std_logic_vector(18 downto 0);
		dina		: in std_logic_vector(DATA_WIDTH-1 downto 0);
		clkb		: in std_logic;
		rstb		: in std_logic;			  
		enb			: IN std_logic;
		addrb		: in std_logic_vector(18 downto 0);
		doutb		: out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end component;

function get_adr_size( DATA_DEPTH	: in integer ) return integer;

end package;


package body ctrl_dpram_m14_pkg  is
	
function get_adr_size( DATA_DEPTH	: in integer ) return integer is

variable	ret	: integer:=0;

begin

	case( DATA_DEPTH ) is
		when 16		=> ret:=4;	
		when 32		=> ret:=5;	
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
		when 131072	=> ret:=17;	
		when 262144	=> ret:=18;			
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

use work.ctrl_dpram_m14_pkg.all;

entity ctrl_dpram_m14 is
	generic(
		DATA_WIDTH	: in integer:=64;		-- ширина FIFO
		DATA_DEPTH	: in integer:=4096		-- размер FIFO 
	);
	port (
		clka		: in std_logic;
		wea			: in std_logic;
		addra		: in std_logic_vector(18 downto 0);
		dina		: in std_logic_vector(DATA_WIDTH-1 downto 0);
		clkb		: in std_logic;
		rstb		: in std_logic;			  
		enb			: IN std_logic;
		addrb		: in std_logic_vector(18 downto 0);
		doutb		: out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end ctrl_dpram_m14;


architecture ctrl_dpram_m14 of ctrl_dpram_m14 is

type RAM is array (integer range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
signal Mem : RAM (0 to DATA_DEPTH-1);



constant	ADR_SIZE	: integer:= get_adr_size( DATA_DEPTH );

signal	data_o			: std_logic_vector(DATA_WIDTH-1 downto 0);
signal	enb_z			: std_logic;

signal	addrb_z			: std_logic_vector( 18 downto 0 );

begin
	
--pr_rd: process( clkb ) begin
--	if( rising_edge( clkb ) ) then
--		--if( enb='1' ) then
--			data_o <= Mem(conv_integer( addrb( ADR_SIZE-1 downto 0 ) ) );
--		--end if;
--	end if;
--end process;	

enb_z <= enb after 1 ns when rising_edge( clkb );
addrb_z <= addrb after 1 ns when rising_edge( clkb ) and enb='1';
data_o <= Mem(conv_integer( addrb_z( ADR_SIZE-1 downto 0 ) ) );

--doutb <= data_o after 0.5 ns when rising_edge( clkb );
doutb <= data_o;-- after 1 ns when enb='1';

pr_wr: process( clka ) begin
	if( rising_edge( clka ) ) then
		if( wea='1' ) then
			Mem(conv_integer( addra( ADR_SIZE-1 downto 0 ) ) ) <= dina after 0.5 ns;
		end if;
	end if;
end process;

end ctrl_dpram_m14;
 