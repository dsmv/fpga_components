-------------------------------------------------------------------------------
--
-- Title       : cl_fifo1024x64_v7
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@mail.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : ���� FIFO 1024x64
--				 ����������� 7 - �������������� ��� ������ �����������:
--								1. �� ������ ����� ����������� ������ 
--									���� rt_mode=1
--								2. � ������������ ������ �������	
--									���� rt=1 
--									������� �� ������� ������ ��������� �����
--									��� ����� ����� rt=1
--								 
-------------------------------------------------------------------------------
--
--  Version    1.0	26.08.2010
--
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use work.adm2_pkg.all;

package cl_fifo1024x64_v7_pkg is
	
component cl_fifo1024x64_v7 is   
	 port(				
	 	-- �����
		 reset 				: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( 63 downto 0 ); -- ������
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 9 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( 63 downto 0 );   -- ������
		 data_cs			: in std_logic;			-- 0 - ������ �� fifo
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 9 downto 0 ); -- ������� ����
		 
		 rt					: in std_logic:='0';	-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic:='0'		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end component;

end package cl_fifo1024x64_v7_pkg;


library ieee;
use ieee.std_logic_1164.all;	 
use work.adm2_pkg.all;

entity cl_fifo1024x64_v7 is		  
	 port(				
	 	-- �����
		 reset 				: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( 63 downto 0 ); -- ������
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 9 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( 63 downto 0 );   -- ������
		 data_cs			: in std_logic;			-- 0 - ������ �� fifo
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 9 downto 0 ); -- ������� ����
		 
		 rt					: in std_logic:='0';	-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic:='0'		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end cl_fifo1024x64_v7;


architecture cl_fifo1024x64_v7 of cl_fifo1024x64_v7 is

function get_width( fifo_depth : in integer ) return integer is

variable ret	: integer:=8;
begin
	
	case( fifo_depth ) is
		when 0=>   ret:=8;			--256;
		when 1=>   ret:=9;			--512;
		when 2=>   ret:=10;			--1024;
		when 3=>   ret:=11;			--2048;
		when 4=>   ret:=12;			--4096;
		when 5=>   ret:=13;			--8192;
		when 6=>   ret:=14;			--16384;
		when 7=>   ret:=15;			--32768;
		when 8=>   ret:=16;			--65536;
		when others => ret:=8;
	end case;
		
	return ret;
end get_width;

function get_pae( fifo_depth : in integer ) return integer is

variable ret	: integer:=8;
begin
	
	case( fifo_depth ) is
		when 0=>   ret:=4;			--256;
		when 1=>   ret:=4;			--512;
		when 2=>   ret:=4;			--1024;
		when 3=>   ret:=4;			--2048;
		when 4=>   ret:=4;			--4096;
		when 5=>   ret:=4;			--1024;
		when 6=>   ret:=10;			--16384;
		when 7=>   ret:=10;			--32768;
		when 8=>   ret:=10;			--65536;
		when others => ret:=10;
	end case;
		
	return ret;
end get_pae;

		-- 0 - ������� 256 ����
		-- 1 - ������� 1024 ����
		-- 2 - ������� 1024 ����
		-- 3 - ������� 2048 ����				  
		-- 4 - ������� 4096 ����
		-- 5 - ������� 8192 ����
		-- 6 - ������� 16384 ����
		-- 7 - ������� 1024 ����
		-- 8 - ������� 65535 ����
constant	  fifo_depth : integer:=2;

constant	counter_width		:	integer:=get_width(fifo_depth);
constant	counter_pae			:	integer:=get_pae(fifo_depth);

signal		addra				: std_logic_vector( counter_width-1 downto 0 );
signal		addrb				: std_logic_vector( counter_width-1 downto 0 );
signal		rst					: std_logic;
signal		dout_we0			: std_logic;
signal		dout_we1			: std_logic;
signal		data_reg0			: std_logic_vector( 63 downto 0 );
signal		data_reg1			: std_logic_vector( 63 downto 0 );

component ctrl_dpram1024x64_v7 is
	port (
	clka: in std_logic;
	wea: in std_logic_vector(0 downto 0);
	addra: in std_logic_vector(9 downto 0);
	dina: in std_logic_vector(63 downto 0);
	clkb: in std_logic;
	rstb: in std_logic;			  
	enb: IN std_logic;
	addrb: in std_logic_vector(9 downto 0);
	doutb: out std_logic_vector(63 downto 0));
end component;

component cl_fifo_control_v7 is
	generic (					 
		counter_width		: in integer;
		counter_pae			: in integer
	
	);	
	port(  
		reset			: in std_logic;		-- 0 - �����
		
		wr_clk			: in std_logic;		-- �������� �������	������
		rd_clk			: in std_logic;		-- �������� �������	������
		
		flag_wr			: out bl_fifo_flag;	-- ����� fifo, ��������� � clk_wr
		flag_rd			: out bl_fifo_flag;	-- ����� fifo, ��������� � clk_rd
		
		addra			: out std_logic_vector( counter_width-1 downto 0);	-- ����� ������
		addrb			: out std_logic_vector( counter_width-1 downto 0);	-- ����� �����	 
		
		cnt_wr			: out std_logic_vector( counter_width-1 downto 0 ); -- ������� ����
		cnt_rd			: out std_logic_vector( counter_width-1 downto 0 ); -- ������� ����		
		
		data_en			: in std_logic;		-- 1 - ������ � fifo
		data_cs			: in std_logic;		-- 0 - ������ �� fifo
		
		dout_we0		: out std_logic;	-- 1 - ������ � �������� ������� 0
		dout_we1		: out std_logic;	-- 1 - ������ � �������� ������� 1
		
		rt				: in std_logic;		-- 1 - ������� �� ������ � ������������ ������
		rt_mode			: in std_logic		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		);
		
end component;	

begin					  
	
	
ctrl: cl_fifo_control_v7 
	generic map(
		counter_width		=> counter_width,
		counter_pae			=> counter_pae			
	)
	port map(  
		reset			=> reset,		-- 0 - �����
		
		wr_clk			=> clk_wr,			-- �������� �������	������
		rd_clk			=> clk_rd,			-- �������� �������	������
		
		flag_wr			=> flag_wr,			-- ����� fifo, ��������� � clk_wr
		flag_rd			=> flag_rd,			-- ����� fifo, ��������� � clk_rd
		
		addra			=> addra,			-- ����� ������
		addrb			=> addrb,			-- ����� �����	 
		
		cnt_wr			=> cnt_wr,			-- ������� ����
		cnt_rd			=> cnt_rd,			-- ������� ����		
		
		data_en			=> data_en,			-- 1 - ������ � fifo
		data_cs			=> data_cs,			-- 0 - ������ �� fifo
		
		dout_we0		=> dout_we0,		-- 1 - ������ � �������� ������� 0
		dout_we1		=> dout_we1,		-- 1 - ������ � �������� ������� 1
		
		rt				=> rt,				-- 1 - ������� �� ������ � ������������ ������
		rt_mode			=> rt_mode			-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		
		);
	
rst <= not reset;	

dpram: ctrl_dpram1024x64_v7 
	port map(
		clka		=> clk_wr,
		wea			=> (others=>'1'),
		addra		=> addra,
		dina		=> data_in,
		clkb		=> clk_rd,
		rstb		=> rst,	  
		enb			=> dout_we0,
		addrb		=> addrb,
		doutb		=> data_reg0
	);						   
	
pr_dout_reg: process( clk_rd ) begin
	if( reset='0' ) then
		data_out <= (others=>'0') after 1 ns;
	elsif( rising_edge( clk_rd ) ) then	
		if( dout_we1='1' ) then
			data_out <= data_reg0 after 1 ns;
		end if;
		
--		if( dout_we1='1' ) then
--			data_out <= data_reg1 after 1 ns;
--		end if;
	end if;
end process;

end cl_fifo1024x64_v7;
