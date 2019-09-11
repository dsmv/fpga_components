-------------------------------------------------------------------------------
--
-- Title       : axis_pkg
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : 	ќпределение типов дл€ шины AXIS
--
--
-------------------------------------------------------------------------------
--
--  Version 1.0    21.10.2018  Dmitry Smekhov
--                —оздан из axi_pkg
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;


package	axis_pkg is

--- Ўина AXIS 16 ---
type M_AXIS_16_TYPE is record
	tdata			: std_logic_vector( 15 downto 0 );
	tvalid			: std_logic;
	tlast			: std_logic;
end record;

--- Ўина AXIS 24 ---
type M_AXIS_24_TYPE is record
	tdata			: std_logic_vector( 23 downto 0 );
	tvalid			: std_logic;
	tlast			: std_logic;
end record;


--- Ўина AXIS 32 ---
type M_AXIS_32_TYPE is record
	tdata			: std_logic_vector( 31 downto 0 );
	tvalid			: std_logic;
	tlast			: std_logic;
end record;



--- Ўина AXIS 48 ---
type M_AXIS_48_TYPE is record
	tdata			: std_logic_vector( 47 downto 0 );
	tvalid			: std_logic;
	tlast			: std_logic;
end record;

--- Ўина AXIS 64 ---
type M_AXIS_64_TYPE is record
	tdata			: std_logic_vector( 63 downto 0 );
	tvalid			: std_logic;
	tlast			: std_logic;
end record;



--- Ўина AXIS 128 ---
type M_AXIS_128_TYPE is record
	tdata			: std_logic_vector( 127 downto 0 );
	tvalid			: std_logic;
	tlast			: std_logic;
end record;

--- Ўина AXIS 256 ---
type M_AXIS_256_TYPE is record
	tdata			: std_logic_vector( 255 downto 0 );
	tvalid			: std_logic;
	tlast			: std_logic;
end record;

constant  M_AXIS_256_EMPTY	: M_AXIS_256_TYPE:=( tdata=>(others=>'0'), others=>'0');

--- Ўина AXIS 256 ---
type M_AXIS_256U7_TYPE is record
	tdata			: std_logic_vector( 255 downto 0 );
	tvalid			: std_logic;
	tlast			: std_logic;
	tuser			: std_logic_vector( 3 downto 0 );
						-- 0: tvalid - повтор сигнала tvalid
						-- 1: tvalid - повтор сигнала tvalid
						-- 2: tvalid - повтор сигнала tvalid
						-- 3: tvalid - повтор сигнала tvalid

end record;

constant	M_AXIS_256U7_EMPTY : M_AXIS_256U7_TYPE:=( tdata=>(others=>'0'), tuser=>(others=>'0'), others=>'0');

--- Ўина AXIS 256 ---
type S_AXIS_256U1_TYPE is record
	tuser			: std_logic_vector( 0 downto 0 );  -- назначение определ€етс€ пользователем, дл€ AXIS_BURST: 1 - разрешение передачи восьми слов.
	tready			: std_logic;
end record;

constant	S_AXIS_256U1_EMPTY	: S_AXIS_256U1_TYPE:=(tuser=>(others=>'0'), others=>'0'); 	



end package;

