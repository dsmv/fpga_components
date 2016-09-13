---------------------------------------------------------------------------------------------------
--
-- Title       : adm2_pkg
-- Author      : Dmitry Smekhov
-- Company     : Instrumental System
--
-- Version     : 2.2   
--
---------------------------------------------------------------------------------------------------
--
-- Description :  ����������� ����� ������ � ����� �������
--					
---------------------------------------------------------------------------------------------------
--					
--  Version 2.2  15.12.2011
--				 ��������� �������� ���� type_host2trd, type_trd2host
--
---------------------------------------------------------------------------------------------------
--					
--  Version 2.1  18.07.2007
--				 ��������� �������� ���� std_logic_array16x6
--
---------------------------------------------------------------------------------------------------
--					
--  Version 2.0  15.12.2006
--				 ��������� �������� ����� std_logic_array16x ...
--
---------------------------------------------------------------------------------------------------
--					
--  Version 1.4  17.06.2005
--				 ������� �������� �����������
--
---------------------------------------------------------------------------------------------------
--
--	Version 1.3  31.10.2003
--			   	 ��������� �������� ������� cl_fifo256x32_v2
--
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; 

package adm2_pkg is
	
type bl_cmd is record
	data_we			: std_logic; 	-- 1 - ������ � ������� DATA
	cmd_data_we		: std_logic;	-- 1 - ������ � ������� CMD_DATA
	status_cs		: std_logic;	-- 0 - ������ �� �������� STATUS
	data_cs			: std_logic;	-- 0 - ������ �� �������� DATA
	cmd_data_cs		: std_logic;	-- 0 - ������ �� �������� CMD_DATA
	cmd_adr_we		: std_logic;  	-- 1 - ������ � ������� ���������� ������
	adr				: std_logic_vector( 9 downto 0 ); -- ��������� �����
	data_oe			: std_logic;	-- 0 - ���������� ������ �������� DATA
	fifo_rd			: std_logic; 	-- 1 - ������ �� �������� DATA (������ ������ �������� �� ��������� �����)
	
end record;

type bl_drq is record
	en				: std_logic;	-- 1 - ���������� ������� DMA
	req				: std_logic;  	-- 1 - ������ �� ���������� ����� DMA
	ack				: std_logic;	-- 1 - ���������� ����� DMA
end record;	

type bl_trd_rom is array( 31 downto 0 ) of std_logic_vector( 15 downto 0 );

type bl_fifo_flag is record
	ef		: std_logic; 	-- 0 - FIFO ������
	pae		: std_logic;	-- 0 - FIFO ����� ������
	hf		: std_logic;	-- 0 - FIFO ��������� ���������� 
	paf		: std_logic;	-- 0 - FIFO ����� ������
	ff		: std_logic;	-- 0 - FIFO ������
	ovr		: std_logic;	-- 1 - ������ � ������ FIFO
	und		: std_logic;	-- 1 - ������ �� ������� FIFO
end record;	

type std_logic_array_16x128 is array (15 downto 0) of std_logic_vector(127 downto 0);
type std_logic_array_16x64 is array (15 downto 0) of std_logic_vector(63 downto 0);
type std_logic_array_16x16 is array (15 downto 0) of std_logic_vector(15 downto 0);
type std_logic_array_16x6  is array (15 downto 0) of std_logic_vector(6 downto 0);
type std_logic_array_16xbl_cmd is array (15 downto 0) of bl_cmd;
type std_logic_array_16xbl_drq is array (15 downto 0) of bl_drq;
type std_logic_array_16xbl_irq is array (15 downto 0) of std_logic;
type std_logic_array_16xbl_reset_fifo is array (15 downto 0) of std_logic;
type std_logic_array_16xbl_trd_rom is array (15 downto 0) of bl_trd_rom;
type std_logic_array_16x7 is array (15 downto 0) of std_logic_vector(6 downto 0);
type std_logic_array_16xbl_fifo_flag is array (15 downto 0) of bl_fifo_flag;

component ctrl_buft16 is
	port (
	t: in std_logic;
	i: in std_logic_vector(15 downto 0);
	o: out std_logic_vector(15 downto 0));
end component;	

component ctrl_buft32 is
	port (
	t: in std_logic;
	i: in std_logic_vector(31 downto 0);
	o: out std_logic_vector(31 downto 0));
end component;	

component ctrl_buft64 is
	port (
	t: in std_logic;
	i: in std_logic_vector(63 downto 0);
	o: out std_logic_vector(63 downto 0));
end component;	


type integer_array_x16	is array (15 downto 0) of integer;

type type_trd2host is record
	status			: std_logic_vector( 15 downto 0 );	--! ������� STATUS
	cmd_data		: std_logic_vector( 15 downto 0 );	--! ������ ���������
	data			: std_logic_vector( 127 downto 0 );	--! ������ �������� DATA 
	drq				: bl_drq;		--! ������ DMA
	irq				: std_logic;	--! ������ ����������
	fifo_rstp		: std_logic;	--! 1 - ����� FIFO 
end record;


type type_host2trd is record
	cmd				: bl_cmd;	--! ������� ��� ������� 
	cmd_data		: std_logic_vector( 15 downto 0 );		-- ���� ��� ������ � �������� 
	data			: std_logic_vector( 127 downto 0 );		-- ���� 128 �������� ��� ������ � ������� DATA 
end record;

type type_array_trd2host is array( 15 downto 0 ) of type_trd2host;
type type_array_host2trd is array( 15 downto 0 ) of type_host2trd;




end package;