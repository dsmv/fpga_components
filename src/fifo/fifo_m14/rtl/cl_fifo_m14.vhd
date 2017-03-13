-------------------------------------------------------------------------------
--
-- Title       : cl_fifo_m14
-- Author      : Dmitry Smekhov	 
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : Узел FIFO с настройкой параметров:
--
--				 Настраиваются параметры:
--				  FIFO_WITH - ширина FIFO
--				  FIFO_SIZE - размер FIFO					
--				  FIFO_PAF  - уровень срабатывания флага PAF
--				  FIFO_PAE  - уровень срабатывания флага PAE
--
--
--				 Модификация 14 - для чтения используется data_cs=0
--
--							Поддерживаются два режима ретрансмита:
--								1. По выдаче всего содержимого памяти 
--									Вход rt_mode=1
--								2. В произвольный момент времени	
--									Вход rt=1
--									Переход на нулевой отсчёт произойдёт через
--									два такта после rt=1
--								 
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
		FIFO_WIDTH			: in integer:=64;		-- ширина FIFO
		FIFO_SIZE			: in integer:=4096;		-- размер FIFO 
		FIFO_PAF			: in integer:=16;		-- уровень срабатывания флага PAF  
		FIFO_PAE			: in integer:=544		-- уровень срабатывания флага PAE  
	);
	 port(				
	 	-- сброс
		 reset	 			: in std_logic;			-- 0 - сброс
		 
	 	-- запись
		 clk_wr 			: in std_logic;			-- тактовая частота
		 data_in 			: in std_logic_vector( FIFO_WIDTH-1 downto 0 ); -- данные
		 data_en			: in std_logic;			-- 1 - запись в fifo
		 flag_wr			: out bl_fifo_flag;		-- флаги fifo, синхронно с clk_wr
		 cnt_wr				: out std_logic_vector( 15 downto 0 ); -- счётчик слов
		 
		 -- чтение
		 clk_rd 			: in std_logic;			-- тактовая частота
		 data_out 			: out std_logic_vector( FIFO_WIDTH-1 downto 0 );   -- данные

		 data_cs			: in std_logic:='1';	-- 0 - чтение из fifo, данные на этом же такте
		 flag_rd			: out bl_fifo_flag;		-- флаги fifo, синхронно с clk_rd
		 cnt_rd				: out std_logic_vector( 15 downto 0 ); -- счётчик слов

		 
		 rt					: in std_logic:='0';	-- 1 - переход на начало в произвольный момент
		 rt_mode			: in std_logic:='0'		-- 1 - переход на начало после чтения всего содержимого FIFO
		 
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
		FIFO_WIDTH			: in integer:=64;		-- ширина FIFO
		FIFO_SIZE			: in integer:=4096;		-- размер FIFO 
		FIFO_PAF			: in integer:=16;		-- уровень срабатывания флага PAF  
		FIFO_PAE			: in integer:=544		-- уровень срабатывания флага PAE  
	);
	 port(				
	 	-- сброс
		 reset 				: in std_logic;			-- 0 - сброс
		 
	 	-- запись
		 clk_wr 			: in std_logic;			-- тактовая частота
		 data_in 			: in std_logic_vector( FIFO_WIDTH-1 downto 0 ); -- данные
		 data_en			: in std_logic;			-- 1 - запись в fifo
		 flag_wr			: out bl_fifo_flag;		-- флаги fifo, синхронно с clk_wr
		 cnt_wr				: out std_logic_vector( 15 downto 0 ); -- счётчик слов
		 
		 -- чтение
		 clk_rd 			: in std_logic;			-- тактовая частота
		 data_out 			: out std_logic_vector( FIFO_WIDTH-1 downto 0 );   -- данные

		 data_cs			: in std_logic:='1';	-- 0 - чтение из fifo, данные на этом же такте
		 flag_rd			: out bl_fifo_flag;		-- флаги fifo, синхронно с clk_rd
		 cnt_rd				: out std_logic_vector( 15 downto 0 ); -- счётчик слов
		 
		 rt					: in std_logic:='0';	-- 1 - переход на начало в произвольный момент
		 rt_mode			: in std_logic:='0'		-- 1 - переход на начало после чтения всего содержимого FIFO
		 
	    );

end cl_fifo_m14;


architecture cl_fifo_m14 of cl_fifo_m14 is

 component cl_fifo_control_m14 is
	generic (					 
		FIFO_SIZE			: in integer:=4096;		-- размер FIFO 
		FIFO_PAF			: in integer:=16;		-- уровень срабатывания флага PAF  
		FIFO_PAE			: in integer:=544		-- уровень срабатывания флага PAE  
	);	
	port(  
		reset			: in std_logic;		-- 0 - сброс
		
		wr_clk			: in std_logic;		-- тактовая частота	записи
		rd_clk			: in std_logic;		-- тактовая частота	чтения
		
		flag_wr			: out bl_fifo_flag;	-- флаги fifo, синхронно с clk_wr
		flag_rd			: out bl_fifo_flag;	-- флаги fifo, синхронно с clk_rd
		
		addra			: out std_logic_vector( 15 downto 0);	-- адрес записи
		addrb			: out std_logic_vector( 15 downto 0);	-- адрес чтеия	 
		
		cnt_wr			: out std_logic_vector( 15 downto 0 ); -- счётчик слов
		cnt_rd			: out std_logic_vector( 15 downto 0 ); -- счётчик слов		
		
		data_en			: in std_logic;		-- 1 - запись в fifo
		data_cs			: in std_logic;		-- 0 - чтение из fifo
		
		dout_we0		: out std_logic;	-- 1 - запись в выходной регистр 0
		dout_we1		: out std_logic;	-- 1 - запись в выходной регистр 1
		
		empty			: out std_logic;	-- 1 - FIFO пустое
		
		rt				: in std_logic;		-- 1 - переход на начало в произвольный момент
		rt_mode			: in std_logic		-- 1 - переход на начало после чтения всего содержимого FIFO
		);
		
end component;

signal	addra				: std_logic_vector( 15 downto 0 );
signal	addrb				: std_logic_vector( 15 downto 0 );
signal	rst					: std_logic;
signal	dout_we0			: std_logic;
signal	dout_we1			: std_logic;
signal	data_reg0			: std_logic_vector( FIFO_WIDTH-1 downto 0 );
signal	data_reg1			: std_logic_vector( FIFO_WIDTH-1 downto 0 );

signal	flag_wri			: bl_fifo_flag;		-- флаги fifo, синхронно с clk_wr
signal	dpram_wr			: std_logic;

begin
	  --
ctrl: cl_fifo_control_m14 
	generic map(
		FIFO_SIZE			=> FIFO_SIZE,	-- размер FIFO 
		FIFO_PAF			=> FIFO_PAF,	-- уровень срабатывания флага PAF  
		FIFO_PAE			=> FIFO_PAE		-- уровень срабатывания флага PAE  
	)
	port map(  
		reset			=> reset,			-- 1 - сброс
		
		wr_clk			=> clk_wr,			-- тактовая частота	записи
		rd_clk			=> clk_rd,			-- тактовая частота	чтения
		
		flag_wr			=> flag_wri,			-- флаги fifo, синхронно с clk_wr
		flag_rd			=> flag_rd,			-- флаги fifo, синхронно с clk_rd
		
		addra			=> addra,			-- адрес записи
		addrb			=> addrb,			-- адрес чтеия	 
		
		cnt_wr			=> cnt_wr,			-- счётчик слов
		cnt_rd			=> cnt_rd,			-- счётчик слов		
		
		data_en			=> data_en,			-- 1 - запись в fifo
		data_cs			=> data_cs,			-- 0 - чтение из fifo
		
		dout_we0		=> dout_we0,		-- 1 - запись в выходной регистр 0
		dout_we1		=> dout_we1,		-- 1 - запись в выходной регистр 1
		
		rt				=> rt,				-- 1 - переход на начало в произвольный момент
		rt_mode			=> rt_mode			-- 1 - переход на начало после чтения всего содержимого FIFO
		
		);
	


flag_wr <= flag_wri;

dpram_wr <= data_en and flag_wri.ff;

dpram: ctrl_dpram_m14 
	generic map(
		DATA_WIDTH	=> FIFO_WIDTH,		-- ширина FIFO
		DATA_DEPTH	=> FIFO_SIZE		-- размер FIFO 
	)
	port map(
		clka		=> clk_wr,
		wea			=> dpram_wr,
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
	end if;
end process;	
	

end cl_fifo_m14;
