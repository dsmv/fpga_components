-------------------------------------------------------------------------------
--
-- Title       : cl_fifo_m14
-- Author      : Dmitry Smekhov	 
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.1
--
-------------------------------------------------------------------------------
--
-- Description : ���� FIFO � ���������� ����������:
--
--				 ������������� ���������:
--				  FIFO_WITH - ������ FIFO
--				  FIFO_SIZE - ������ FIFO					
--				  FIFO_PAF  - ������� ������������ ����� PAF
--				  FIFO_PAE  - ������� ������������ ����� PAE
--
--
--				 ����������� 14 - ��� ������ ������������ data_cs=0
--
--							�������������� ��� ������ �����������:
--								1. �� ������ ����� ����������� ������ 
--									���� rt_mode=1
--								2. � ������������ ������ �������	
--									���� rt=1
--									������� �� ������� ������ ��������� �����
--									��� ����� ����� rt=1
--								 
--
-------------------------------------------------------------------------------
--
--  Version    1.1	02.10.2017
--
--              ������������ ������ �������� �� 256�
--			    �������� �������������� ������ data_inx, data_outx
--
-------------------------------------------------------------------------------
--
--  Version    1.0	14.03.2017
--			   
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use work.adm2_pkg.all;

package cl_fifo_m14_pkg is
	
component cl_fifo_m14 is   
	generic(
		FIFO_WIDTH			: in integer:=64;		-- ������ FIFO
		FIFO_SIZE			: in integer:=4096;	-- ������ FIFO 
		FIFO_PAF			: in integer:=16;		-- ������� ������������ ����� PAF  
		FIFO_PAE			: in integer:=544;		-- ������� ������������ ����� PAE
		is_data_inx         : in integer:=0         -- 1 - ����������� ��������������� ������� ������  
	);
	 port(				
	 	-- �����
		 reset	 			: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( FIFO_WIDTH-1 downto 0 ); -- ������
		 data_inx           : in std_logic:='0';    -- �������������� ������ ������       
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 18 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( FIFO_WIDTH-1 downto 0 );   -- ������
		 data_outx          : out std_logic;       -- �������������� ������ ������

		 data_cs			: in std_logic:='1';	-- 0 - ������ �� fifo, ������ �� ���� �� �����
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 18 downto 0 ); -- ������� ����

		 
		 rt					: in std_logic:='0';	-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic:='0'		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end component;

end package cl_fifo_m14_pkg;


library ieee;
use ieee.std_logic_1164.all;	 
use work.adm2_pkg.all;
use work.ctrl_dpram_m14_pkg.all;
--use work.cl_fifo_control_m14_pkg.all;


entity cl_fifo_m14 is		  
	generic(
    FIFO_WIDTH            : in integer:=64;        -- ������ FIFO
    FIFO_SIZE            : in integer:=4096;    -- ������ FIFO 
    FIFO_PAF            : in integer:=16;        -- ������� ������������ ����� PAF  
    FIFO_PAE            : in integer:=544;        -- ������� ������������ ����� PAE
    is_data_inx         : in integer:=0         -- 1 - ����������� ��������������� ������� ������  
);
 port(                
     -- �����
     reset                 : in std_logic;            -- 0 - �����
     
     -- ������
     clk_wr             : in std_logic;            -- �������� �������
     data_in             : in std_logic_vector( FIFO_WIDTH-1 downto 0 ); -- ������
     data_inx           : in std_logic:='0';    -- �������������� ������ ������       
     data_en            : in std_logic;            -- 1 - ������ � fifo
     flag_wr            : out bl_fifo_flag;        -- ����� fifo, ��������� � clk_wr
     cnt_wr                : out std_logic_vector( 18 downto 0 ); -- ������� ����
     
     -- ������
     clk_rd             : in std_logic;            -- �������� �������
     data_out             : out std_logic_vector( FIFO_WIDTH-1 downto 0 );   -- ������
     data_outx          : out std_logic;       -- �������������� ������ ������

     data_cs            : in std_logic:='1';    -- 0 - ������ �� fifo, ������ �� ���� �� �����
     flag_rd            : out bl_fifo_flag;        -- ����� fifo, ��������� � clk_rd
     cnt_rd                : out std_logic_vector( 18 downto 0 ); -- ������� ����

     
     rt                    : in std_logic:='0';    -- 1 - ������� �� ������ � ������������ ������
     rt_mode            : in std_logic:='0'        -- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
     
    );

end cl_fifo_m14;


architecture cl_fifo_m14 of cl_fifo_m14 is

constant FIFO_WIDTH_i       : integer:=FIFO_WIDTH + is_data_inx;

signal	addra				: std_logic_vector( 18 downto 0 );
signal	addrb				: std_logic_vector( 18 downto 0 );
signal	rst					: std_logic;
signal	dout_we0			: std_logic;
signal	dout_we1			: std_logic;
signal	data_reg0			: std_logic_vector( FIFO_WIDTH_i-1 downto 0 );
signal	data_reg1			: std_logic_vector( FIFO_WIDTH_i-1 downto 0 );
signal	data_in_i			: std_logic_vector( FIFO_WIDTH_i-1 downto 0 );

signal	flag_wri			: bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
signal	dpram_wr			: std_logic;

begin
	  --
ctrl: entity work.cl_fifo_control_m14 
	generic map(
		FIFO_SIZE			=> FIFO_SIZE,	-- ������ FIFO 
		FIFO_PAF			=> FIFO_PAF,	-- ������� ������������ ����� PAF  
		FIFO_PAE			=> FIFO_PAE		-- ������� ������������ ����� PAE  
	)
	port map(  
		reset			=> reset,			-- 1 - �����
		
		wr_clk			=> clk_wr,			-- �������� �������	������
		rd_clk			=> clk_rd,			-- �������� �������	������
		
		flag_wr			=> flag_wri,			-- ����� fifo, ��������� � clk_wr
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
	


flag_wr <= flag_wri;

dpram_wr <= data_en and flag_wri.ff;

data_in_i( FIFO_WIDTH-1 downto 0 ) <= data_in( FIFO_WIDTH-1 downto 0 );

gen_inx: if( is_data_inx=1 ) generate

data_in_i( FIFO_WIDTH_i-1 ) <= data_inx;

end generate;

dpram: ctrl_dpram_m14 
	generic map(
		DATA_WIDTH	=> FIFO_WIDTH_i,		-- ������ FIFO
		DATA_DEPTH	=> FIFO_SIZE		-- ������ FIFO 
	)
	port map(
		clka		=> clk_wr,
		wea			=> dpram_wr,
		addra		=> addra,
		dina		=> data_in_i,
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
			data_out <= data_reg0( FIFO_WIDTH-1 downto 0 ) after 1 ns;
		end if;
	end if;
end process;	

gen_data_outx: if( 	is_data_inx=1 ) generate

pr_dout_reg_x: process( clk_rd ) begin
	if( reset='0' ) then
		data_outx <= '0' after 1 ns;
	elsif( rising_edge( clk_rd ) ) then	
		if( dout_we1='1' ) then
			data_outx <= data_reg0( FIFO_WIDTH_i-1) after 1 ns;
		end if;
	end if;
end process;	


end generate;

end cl_fifo_m14;
