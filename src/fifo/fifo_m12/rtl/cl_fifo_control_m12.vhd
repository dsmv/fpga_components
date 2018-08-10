-------------------------------------------------------------------------------
--
-- Title       : cl_fifo_control_m12
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.1
--
-------------------------------------------------------------------------------
--
-- Description : Узел управления FIFO с ретрансмитом
--														 
--
-------------------------------------------------------------------------------
--
--  Version    1.1	02.10.2017
--			   
--             Исправлена задержка выдачи данных
--             Данные появляются на второй такт от data_rd              
--
-------------------------------------------------------------------------------
--
--  Version    1.0   29.01.2017
--			   Создан из cl_fifo_control_v7 v1.1
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;	   

use work.adm2_pkg.all;

package cl_fifo_control_m12_pkg is

component cl_fifo_control_m12 is
	generic (					 
		FIFO_SIZE			: in integer:=4096;		-- размер FIFO 
		FIFO_PAF			: in integer:=16;		-- уровень срабатывания флага PAF  
		FIFO_PAE			: in integer:=544		-- уровень срабатывания флага PAE  
	);	
	port(  
		reset_p				: in std_logic;		-- 1 - сброс
		                	
		wr_clk				: in std_logic;		-- тактовая частота	записи
		rd_clk				: in std_logic;		-- тактовая частота	чтения
		                	
		flag_wr				: out bl_fifo_flag;	-- флаги fifo, синхронно с clk_wr
		flag_rd				: out bl_fifo_flag;	-- флаги fifo, синхронно с clk_rd
		                	
		addra				: out std_logic_vector( 15 downto 0);	-- адрес записи
		addrb				: out std_logic_vector( 15 downto 0);	-- адрес чтеия	 
		                	
		cnt_wr				: out std_logic_vector( 15 downto 0 ); -- счётчик слов
		cnt_rd				: out std_logic_vector( 15 downto 0 ); -- счётчик слов		
		                	
		data_en				: in std_logic;		-- 1 - запись в fifo
		data_rd				: in std_logic;		-- 1 - чтение из fifo
		                	
		dout_we0			: out std_logic;	-- 1 - запись в выходной регистр 0
		dout_we1			: out std_logic;	-- 1 - запись в выходной регистр 1
		                	
		empty				: out std_logic;	-- 1 - FIFO пустое
		                	
		rt					: in std_logic;		-- 1 - переход на начало в произвольный момент
		rt_mode				: in std_logic		-- 1 - переход на начало после чтения всего содержимого FIFO
		);              	
		
end component;

end package;

library ieee;
use ieee.std_logic_1164.all;	   
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.adm2_pkg.all;

use work.ctrl_retack_counter_m12_pkg.all;
use work.ctrl_dpram_m12_pkg.all;

entity cl_fifo_control_m12 is
	generic (					 
		FIFO_SIZE			: in integer:=4096;		-- размер FIFO 
		FIFO_PAF			: in integer:=16;		-- уровень срабатывания флага PAF  
		FIFO_PAE			: in integer:=544		-- уровень срабатывания флага PAE  
	);	
	port(  
		reset_p				: in std_logic;		-- 1 - сброс
		                	
		wr_clk				: in std_logic;		-- тактовая частота	записи
		rd_clk				: in std_logic;		-- тактовая частота	чтения
		                	
		flag_wr				: out bl_fifo_flag;	-- флаги fifo, синхронно с clk_wr
		flag_rd				: out bl_fifo_flag;	-- флаги fifo, синхронно с clk_rd
		                	
		addra				: out std_logic_vector( 15 downto 0);	-- адрес записи
		addrb				: out std_logic_vector( 15 downto 0);	-- адрес чтеия	 
		                	
		cnt_wr				: out std_logic_vector( 15 downto 0 ); -- счётчик слов
		cnt_rd				: out std_logic_vector( 15 downto 0 ); -- счётчик слов		
		                	
		data_en				: in std_logic;		-- 1 - запись в fifo
		data_rd				: in std_logic;		-- 1 - чтение из fifo
		                	
		dout_we0			: out std_logic;	-- 1 - запись в выходной регистр 0
		dout_we1			: out std_logic;	-- 1 - запись в выходной регистр 1
		                	
		empty				: out std_logic;	-- 1 - FIFO пустое
		                	
		rt					: in std_logic;		-- 1 - переход на начало в произвольный момент
		rt_mode				: in std_logic		-- 1 - переход на начало после чтения всего содержимого FIFO
		);              	
		
end cl_fifo_control_m12;		

architecture cl_fifo_control_m12 of cl_fifo_control_m12 is

constant  counter_width			: integer := get_adr_size( FIFO_SIZE );


--constant	CNT_ZERO			: std_logic_vector( counter_width-1 downto counter_pae ):=(others=>'0');
--constant	CNT_ONE				: std_logic_vector( counter_width-1 downto counter_pae ):=(others=>'1');

--- двойка добавляется на всякий случай ---
constant	CNT_PAF		: integer:=	FIFO_SIZE-FIFO_PAF-2;
constant	CNT_PAE		: integer:=	FIFO_PAE+2;


signal	rst1		: std_logic;
signal	rst2		: std_logic;

signal	w_full		: std_logic;
signal	r_full		: std_logic;

signal	w_empty		: std_logic;
signal	r_empty		: std_logic;

signal	w_adr		: std_logic_vector( counter_width-1 downto 0 );
signal	r_adr		: std_logic_vector( counter_width-1 downto 0 );
signal	w_next_adr	: std_logic_vector( counter_width-1 downto 0 );
signal	r_next_adr	: std_logic_vector( counter_width-1 downto 0 );

signal	w_adr_to_r	: std_logic_vector( counter_width-1 downto 0 );
signal	r_adr_to_w	: std_logic_vector( counter_width-1 downto 0 );

signal	w_overflow	: std_logic;
signal	r_underflow	: std_logic;	 

signal	w_cnt		: std_logic_vector( counter_width-1 downto 0 );
signal	r_cnt		: std_logic_vector( counter_width-1 downto 0 );

signal	w_full_z	: std_logic;
signal	r_empty_z	: std_logic;	 
signal	r_empty_next	: std_logic;

signal	ef			: std_logic;

type stp_type	is ( s0, s1, s2, s3 );
signal	stp			: stp_type;

signal	dout_we0_x	: std_logic;
signal	dout_we1_x	: std_logic;

signal	flag_wri_paf		: std_logic;
signal	flag_wri_paf_z		: std_logic;

signal	flag_rdi_pae		: std_logic;
signal	flag_rdi_pae_z		: std_logic;

begin

	
pr_rst1: process( reset_p, wr_clk ) begin
	if( reset_p='1' ) then
		rst1 <= '1' after 1 ns;
	elsif( rising_edge( wr_clk ) ) then
		rst1 <= '0' after 1 ns;
	end if;
end process;

pr_rst2: process( reset_p, rd_clk ) begin
	if( reset_p='1' ) then
		rst2 <= '1' after 1 ns;
	elsif( rising_edge( rd_clk ) ) then
		rst2 <= '0' after 1 ns;
	end if;
end process;


retack_w: ctrl_retack_counter_m12 
	generic map(
	  counter_width	 => counter_width -- число разрядов счётчика
	)
	port map(
	
		rst1		=> rst1,		-- 1 - сброс, по такту clk1
		rst2		=> rst2,		-- 1 - сброс, по такту clk2
		
		---- Вход данных --- -
		clk1		=> wr_clk,
		data_in		=> w_adr,
		
		---- Выход данных ----
		clk2		=> rd_clk,
		data_out	=> w_adr_to_r
	
	);							 
	
retack_r: ctrl_retack_counter_m12 
	generic map(
	  counter_width	 => counter_width -- число разрядов счётчика
	)
	port map(
	
		rst1		=> rst1,		-- 1 - сброс, по такту clk1
		rst2		=> rst2,		-- 1 - сброс, по такту clk2
		
		---- Вход данных --- -
		clk1		=> rd_clk,
		data_in		=> r_adr,
		
		---- Выход данных ----
		clk2		=> wr_clk,
		data_out	=> r_adr_to_w
	
	);							 
	
pr_wr_adr: process( wr_clk ) begin
	if( rising_edge( wr_clk ) ) then
		if( rst1='1' ) then
			w_adr <= (others=>'0') after 1 ns;
			w_next_adr <= (0=>'1', others=>'0') after 1 ns;
			w_overflow <= '0' after  1 ns;
		elsif( data_en='1' ) then
			if( w_full='1' ) then	 
				w_adr <= w_next_adr after 1 ns;
				w_next_adr <= w_next_adr + 1 after 1 ns;
			else
				w_overflow <= '1' after  1 ns;
			end if;		   
		end if;
	end if;
end process;
		
		

		
w_full <= '0' when w_next_adr=r_adr_to_w else '1';
r_empty <= '0' when w_adr_to_r=r_adr else '1';
r_empty_next <= '0' when w_adr_to_r=r_next_adr else '1';
	
empty <= not r_empty;	
	
w_full_z <= w_full after 1 ns when rising_edge( wr_clk );
r_empty_z <= r_empty after 1 ns when rising_edge( rd_clk );
	
flag_wr.ff <= w_full;
flag_wr.ovr <= w_overflow;
flag_wr.ef <= r_empty_z after 1 ns when rising_edge( wr_clk ); 
flag_wr.und <= r_underflow after 1 ns when rising_edge( wr_clk ); 

flag_rd.ef <= ef;	   
flag_rd.und <= r_underflow;
flag_rd.ff <= w_full_z after 1 ns when rising_edge( rd_clk );
flag_rd.ovr <= w_overflow after 1 ns when rising_edge( rd_clk );


w_cnt <= w_adr - r_adr_to_w after 1 ns when rising_edge( wr_clk );
r_cnt <= w_adr_to_r - r_adr after 1 ns when rising_edge( rd_clk );

cnt_wr( counter_width-1 downto 0 ) <= w_cnt;
cnt_rd( counter_width-1 downto 0 ) <= r_cnt;

cnt_wr( 15 downto counter_width ) <= (others=>'0');
cnt_rd( 15 downto counter_width ) <= (others=>'0');

flag_wr.paf <= flag_wri_paf;

flag_wri_paf_z <= flag_wri_paf after 1 ns when rising_edge( rd_clk );

pr_flag_wr: process( rst1, wr_clk ) begin
	if( rising_edge( wr_clk ) ) then
		if( rst1='1' ) then
			--flag_wr.ef <= '0';
			flag_wr.pae <= '0' after 1 ns;
			flag_wr.hf <= '1' after 1 ns;
			
			
			flag_wri_paf <= '1' after 1 ns;
			--flag_wr.ff <= '1' after 1 ns;
		else
			if( conv_integer(w_cnt) > CNT_PAF ) then
				flag_wri_paf <= '0' after 1 ns;
			else
				flag_wri_paf <= '1' after 1 ns;	 
			end if;

			flag_wr.pae <= flag_rdi_pae_z after 1 ns;
			
			flag_wr.hf <= not w_cnt( counter_width-1 ) after 1 ns;
		end if;
	end if;
end process;

flag_rd.pae <= flag_rdi_pae;

flag_rdi_pae_z <= flag_rdi_pae after 1 ns when rising_edge( wr_clk );
			
pr_flag_rd: process( rst2, rd_clk ) begin
	if( rising_edge( rd_clk ) ) then
		if( rst2='1' ) then
			flag_rdi_pae <= '0' after 1 ns;
			flag_rd.hf <= '1' after 1 ns;
			flag_rd.paf <= '1' after 1 ns;
			--flag_rd.ff <= '1' after 1 ns;
		else
		  
			if( conv_integer(r_cnt) < CNT_PAE ) then
				flag_rdi_pae <= '0' after 1 ns;
			else
				flag_rdi_pae <= '1' after 1 ns;	 
			end if;			
			
			flag_rd.paf <= flag_wri_paf_z after 1 ns;
			
			flag_rd.hf <= not r_cnt( counter_width-1 ) after 1 ns;
		end if;
	end if;
end process;

				
addra( counter_width-1 downto 0 ) <= w_adr;
addrb( counter_width-1 downto 0 ) <= r_adr;

addra( 15 downto counter_width ) <= (others=>'0');
addrb( 15 downto counter_width ) <= (others=>'0');



ef <= r_empty_z;

pr_rd: process( rd_clk ) begin
	if( rising_edge( rd_clk ) ) then
		
		if( rt='1' or rst2='1' ) then
			r_adr <= (others=>'0') after 1 ns; 
			r_next_adr <= (0=>'1', others=>'0') after 1 ns;
		elsif( data_rd='1' and r_empty='1' ) then
			if( rt_mode='1' and r_empty_next='0' ) then
				r_adr <= (others=>'0') after 1 ns; 
				r_next_adr <= (0=>'1', others=>'0') after 1 ns;
			else
				r_next_adr <= r_next_adr + 1 after 1 ns;
				r_adr <= r_next_adr after 1 ns;
			end if;
		end if;
	end if;
end process;

dout_we0 <= '1';
dout_we1 <= data_rd after 1 ns when rising_edge( rd_clk );

pr_r_underflow: process( rd_clk ) begin
	if( rst2='1' ) then
		r_underflow <= '0' after 1 ns;
	elsif( data_rd='1' and r_empty='0' ) then
		r_underflow <= '1' after 1 ns;
	end if;
end process;
		
	
end cl_fifo_control_m12;
