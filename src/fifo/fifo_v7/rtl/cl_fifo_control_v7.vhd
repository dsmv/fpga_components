-------------------------------------------------------------------------------
--
-- Title       : cl_fifo_control_v7
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@mail.ru
--
-- Version     : 1.1
--
-------------------------------------------------------------------------------
--
-- Description : Узел перетактирования значения счётчика 
--				 Узел управления FIFO с ретрансмитом
--														 
--
-------------------------------------------------------------------------------
--
--  Version    1.1   11.09.2009
--				Добавлен выход empty
--			    Исправлен выход счётчиков cnt_wr, cnt_rd
--
-------------------------------------------------------------------------------
--
--  Version    1.0   23.06.2009
--
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;

entity ctrl_retack_counter is
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
end ctrl_retack_counter;


architecture ctrl_retack_counter of ctrl_retack_counter is


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
	
end ctrl_retack_counter;

library ieee;
use ieee.std_logic_1164.all;	   
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.adm2_pkg.all;

entity cl_fifo_control_v7 is
	generic (					 
		counter_width		: in integer;
		counter_pae			: in integer
	
	);	
	port(  
		reset			: in std_logic;		-- 0 - сброс
		
		wr_clk			: in std_logic;		-- тактовая частота	записи
		rd_clk			: in std_logic;		-- тактовая частота	чтения
		
		flag_wr			: out bl_fifo_flag;	-- флаги fifo, синхронно с clk_wr
		flag_rd			: out bl_fifo_flag;	-- флаги fifo, синхронно с clk_rd
		
		addra			: out std_logic_vector( counter_width-1 downto 0);	-- адрес записи
		addrb			: out std_logic_vector( counter_width-1 downto 0);	-- адрес чтеия	 
		
		cnt_wr			: out std_logic_vector( counter_width-1 downto 0 ); -- счётчик слов
		cnt_rd			: out std_logic_vector( counter_width-1 downto 0 ); -- счётчик слов		
		
		data_en			: in std_logic;		-- 1 - запись в fifo
		data_cs			: in std_logic;		-- 0 - чтение из fifo
		
		dout_we0		: out std_logic;	-- 1 - запись в выходной регистр 0
		dout_we1		: out std_logic;	-- 1 - запись в выходной регистр 1
		
		empty			: out std_logic;	-- 1 - FIFO пустое
		
		rt				: in std_logic;		-- 1 - переход на начало в произвольный момент
		rt_mode			: in std_logic		-- 1 - переход на начало после чтения всего содержимого FIFO
		);
		
end cl_fifo_control_v7;		

architecture cl_fifo_control_v7 of cl_fifo_control_v7 is


constant	CNT_ZERO			: std_logic_vector( counter_width-1 downto counter_pae ):=(others=>'0');
constant	CNT_ONE				: std_logic_vector( counter_width-1 downto counter_pae ):=(others=>'1');

component ctrl_retack_counter is
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


begin

	
pr_rst1: process( reset, wr_clk ) begin
	if( reset='0' ) then
		rst1 <= '1' after 1 ns;
	elsif( rising_edge( wr_clk ) ) then
		rst1 <= '0' after 1 ns;
	end if;
end process;

pr_rst2: process( reset, rd_clk ) begin
	if( reset='0' ) then
		rst2 <= '1' after 1 ns;
	elsif( rising_edge( rd_clk ) ) then
		rst2 <= '0' after 1 ns;
	end if;
end process;


retack_w: ctrl_retack_counter 
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
	
retack_r: ctrl_retack_counter 
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
		
		
--pr_rd_adr: process( rd_clk ) begin
--	if( rising_edge( rd_clk ) ) then
--		if( rst1='1' or rt='1' ) then
--			r_adr <= (others=>'0') after 1 ns;
--			r_underflow <= '0' after  1 ns;
--		elsif( data_cs='0' ) then
--			if( r_empty='1' ) then
--				r_adr <= r_adr + 1 after 1 ns;
--			else		  
--				if( rt_mode='1' ) then
--					r_adr <= (others=>'0') after 1 ns;
--				else
--					r_underflow<= '1' after  1 ns;
--				end if;
--			end if;		   
--		end if;
--	end if;
--end process;
		
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

cnt_wr <= w_cnt;
cnt_rd <= r_cnt;

pr_flag_wr: process( rst1, wr_clk ) begin
	if( rising_edge( wr_clk ) ) then
		if( rst1='1' ) then
			--flag_wr.ef <= '0';
			flag_wr.pae <= '0' after 1 ns;
			flag_wr.hf <= '1' after 1 ns;
			flag_wr.paf <= '1' after 1 ns;
			--flag_wr.ff <= '1' after 1 ns;
		else
			if( w_cnt( counter_width-1 downto counter_pae )=CNT_ZERO ) then
				flag_wr.pae <= '0' after 1 ns;
			else
				flag_wr.pae <= '1' after 1 ns;
			end if;
			
			if( w_cnt( counter_width-1 downto counter_pae )=CNT_ONE ) then
				flag_wr.paf <= '0' after 1 ns;
			else
				flag_wr.paf <= '1' after 1 ns;
			end if;
			
			flag_wr.hf <= not w_cnt( counter_width-1 ) after 1 ns;
		end if;
	end if;
end process;

			
pr_flag_rd: process( rst2, rd_clk ) begin
	if( rising_edge( rd_clk ) ) then
		if( rst2='1' ) then
			--flag_wr.ef <= '0';
			flag_rd.pae <= '0' after 1 ns;
			flag_rd.hf <= '1' after 1 ns;
			flag_rd.paf <= '1' after 1 ns;
			--flag_rd.ff <= '1' after 1 ns;
		else
			if( r_cnt( counter_width-1 downto counter_pae )=CNT_ZERO ) then
				flag_rd.pae <= '0' after 1 ns;
			else
				flag_rd.pae <= '1' after 1 ns;
			end if;
			
			if( r_cnt( counter_width-1 downto counter_pae )=CNT_ONE ) then
				flag_rd.paf <= '0' after 1 ns;
			else
				flag_rd.paf <= '1' after 1 ns;
			end if;
			
			flag_rd.hf <= not r_cnt( counter_width-1 ) after 1 ns;
		end if;
	end if;
end process;

				
addra <= w_adr;
addrb <= r_adr;


pr_rd: process( rd_clk ) begin
	if( rising_edge( rd_clk ) ) then
		
		case( stp ) is
			when s0 => 
				ef <= '0' after 1 ns;
				dout_we0_x <= '1' after 1 ns;			
				dout_we1_x <= '1' after 1 ns;			
				if( r_empty='1' ) then
					stp <= s1 after 1 ns;
				end if;
				
			when s1 => 
				--r_adr <= r_adr + 1 after 1 ns;
				r_next_adr <= r_next_adr + 1 after 1 ns;
				r_adr <= r_next_adr after 1 ns;
				
				stp <= s2 after 1 ns;
			 

			when s2 => 
				dout_we1_x <= '0' after 1 ns; 
				ef <= '1' after 1 ns;
				
				if( data_cs='0' ) then
					stp <= s0 after 1 ns;
					ef <= '0' after 1 ns;
				elsif( r_empty='1' ) then
					stp <= s3 after 1 ns;	  
					r_next_adr <= r_next_adr + 1 after 1 ns;
					r_adr <= r_next_adr after 1 ns;
					dout_we0_x <= '0' after 1 ns;
				end if;
			
			when s3 =>		
				dout_we0_x <= '0' after 1 ns;
				if( data_cs='0' and r_empty='1' ) then
					if( rt_mode='1' and r_empty_next='0' ) then
						r_adr <= (others=>'0') after 1 ns; 
						r_next_adr <= (0=>'1', others=>'0') after 1 ns;
					else
						r_next_adr <= r_next_adr + 1 after 1 ns;
						r_adr <= r_next_adr after 1 ns;
					end if;
				elsif( data_cs='0' and r_empty='0' ) then
					stp <= s2 after 1 ns;
--				elsif( rt='1' ) then
--						r_adr <= (others=>'0') after 1 ns; 
--						r_next_adr <= (0=>'1', others=>'0') after 1 ns;
				end if;
		end case;
			
		    	
		if( rt='1' or rst2='1' ) then
			stp <= s0 after 1 ns;	 
		end if;

		
		if( rt='1' or rst2='1' ) then
			r_adr <= (others=>'0') after 1 ns; 
			r_next_adr <= (0=>'1', others=>'0') after 1 ns;
		end if;

	end if;
end process;

dout_we0 <= dout_we0_x or not data_cs;
dout_we1 <= dout_we1_x or not data_cs;
	
end cl_fifo_control_v7;
