-------------------------------------------------------------------------------
--
-- Title       : cl_burst2axis
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------
--
--  Version    : 1.0
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

use work.axis_pkg.all;

entity cl_burst2axis_256 is
	port(
		clk					: in std_logic;
		reset_p				: in std_logic;
		
		--- AXI Burst Stream ---			 
		s00_axis_m			: in  M_AXIS_256U7_TYPE;
		s00_axis_s			: out S_AXIS_256U1_TYPE;
		
		--- AXI Stream ---		
		m00_axis_m			: out M_AXIS_256_TYPE;
		m00_tready			: in  std_logic
		
	
	);
end cl_burst2axis_256;

library unisim;
use unisim.vcomponents.all;

library	ieee;
use	ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

architecture cl_burst2axis_256 of cl_burst2axis_256 is

signal	rstp						: std_logic;
signal	data_i						: std_logic_vector( 255 downto 0 );
signal	data_o						: std_logic_vector( 255 downto 0 );
signal	data_we						: std_logic;
signal	data_ready					: std_logic;
signal	data_we_z					: std_logic;

signal	cnt							: std_logic_vector( 3 downto 0 );
signal	adr							: std_logic_vector( 3 downto 0 );
signal	adr0z						: std_logic_vector( 3 downto 0 );
signal	adr1z						: std_logic_vector( 3 downto 0 );
signal	adr2z						: std_logic_vector( 3 downto 0 );
signal	adr3z						: std_logic_vector( 3 downto 0 );

signal	data_rd						: std_logic;

signal	s_burst_ready				: std_logic;			

type	stp_type					is ( s0, s1, s2, s3 );
type	stw_type					is ( s0, s1, s2, s3, s4, s5 );
signal	stp							: stp_type;
signal	stw							: stw_type;

signal	cnt_rd						: std_logic_vector( 3 downto 0 );

signal	m_valid						: std_logic;
signal	m_ready						: std_logic;

begin		  
	
rstp <= reset_p	after 1 ns when rising_edge( clk );	
	
	
s00_axis_s.tready <= '1';	
s00_axis_s.tuser(0) <= s_burst_ready;	
	
--pr_ready: process begin										  
--	
--	s_burst_ready	<= '1' after 1 ns;
--	wait until rising_edge( clk ) and s00_axis_m.tvalid='1';
--	s_burst_ready	<= '0' after 1 ns;
--	wait until rising_edge( clk ); 
--	wait until rising_edge( clk ); 	   
--	--wait;
--	s_burst_ready	<= '1' after 1 ns;
--	wait until rising_edge( clk ); 
--	wait until rising_edge( clk ); 
--	wait until rising_edge( clk ); 
--	wait until rising_edge( clk ); 
--	wait until rising_edge( clk ); 
--end process;	
--

pr_ready: process( clk ) begin
	if( rising_edge( clk ) ) then
		case( stw ) is
			when s0 =>
				s_burst_ready	<= '1' after 1 ns;
				if( s00_axis_m.tvalid='1' ) then
					stw <= s1 after 1 ns;
				end if;
				
			when s1 =>
				s_burst_ready	<= '0' after 1 ns;
				stw <= s2 after 1 ns;
			
			when s2 =>
				if( cnt(3)='1' ) then
					stw <= s4 after 1 ns;
				else					 
					s_burst_ready	<= '1' after 1 ns;
					stw <= s3 after 1 ns;
				end if;
				
			when s3 =>
				if( s00_axis_m.tvalid='1' and s00_axis_m.tlast='1' ) then
					stw <= s0 after 1 ns;
				end if;
				
			when s4 =>
				--s_burst_ready	<= '0' after 1 ns;
				if( s00_axis_m.tvalid='1' and s00_axis_m.tlast='1' ) then
					if( cnt(3)='0' ) then		  
						s_burst_ready	<= '1' after 1 ns;
						stw <= s0 after 1 ns;
					else
						stw <= s5 after 1 ns;
					end if;
				end if;
				
			when s5 =>
				if( cnt(3)='0' ) then
					s_burst_ready	<= '1' after 1 ns;
					stw <= s0 after 1 ns;
				end if;	   
		end case;
		
		if( rstp='1' ) then
			stw <= s0 after 1 ns;
			s_burst_ready	<= '0' after 1 ns;
		end if;
			
		
				
		
	end if;
end process;	


data_we <= s00_axis_m.tvalid;
data_i <=  s00_axis_m.tdata;

data_we_z <= data_we after 1 ns when rising_edge( clk );

gen_srl: for ii in 0 to 63 generate
	
	xsrl0:  srl16e port map( q=> data_o( 0*64+ii ), clk=>clk, ce=>data_we, d=> data_i( 0*64+ii ), a3=>adr0z(3), a2=>adr0z(2), a1=>adr0z(1), a0=>adr0z(0) );
	xsrl1:  srl16e port map( q=> data_o( 1*64+ii ), clk=>clk, ce=>data_we, d=> data_i( 1*64+ii ), a3=>adr1z(3), a2=>adr1z(2), a1=>adr1z(1), a0=>adr1z(0) );
	xsrl2:  srl16e port map( q=> data_o( 2*64+ii ), clk=>clk, ce=>data_we, d=> data_i( 2*64+ii ), a3=>adr2z(3), a2=>adr2z(2), a1=>adr2z(1), a0=>adr2z(0) );
	xsrl3:  srl16e port map( q=> data_o( 3*64+ii ), clk=>clk, ce=>data_we, d=> data_i( 3*64+ii ), a3=>adr3z(3), a2=>adr3z(2), a1=>adr3z(1), a0=>adr3z(0) );

end generate;


adr0z <= adr;
adr1z <= adr;
adr2z <= adr;
adr3z <= adr;

pr_adr: process( clk ) begin
	if( rising_edge( clk ) ) then
		case( stp ) is
			when s0 => -- ожидание появления данных	--
				m_valid <= '0' after 1 ns;
				if( cnt( 3 downto 1 )/="000" ) then
					stp <= s1 after 1 ns;
				end if;
				if( data_we='1' ) then
					adr <= adr + 1 after 1 ns;
				end if;
				
			when s1 => -- предвыборка данных --
				if( data_we='0' ) then
					adr <= adr -1 after 1 ns;
				end if;
				stp <= s2 after 1 ns;
				
			when s2 => 		 
				m_valid <= '1' after 1 ns;
				if( data_we='1' and m_ready='0' ) then
					adr <= adr + 1 after 1 ns;
				elsif( data_we='0' and m_ready='1' ) then
					adr <= adr - 1 after 1 ns;
				end if;
				
				if( cnt( 3 downto 1 )="000" ) then
					stp <= s3 after 1 ns; 
					m_valid <= '0' after 1 ns;
				end if;		 
				
			when s3 => 
				m_valid <= '0' after 1 ns;
				if( cnt( 3 downto 1 )/="000" ) then
					stp <= s2 after 1 ns;
				end if;
				if( data_we='1' ) then
					adr <= adr + 1 after 1 ns;
				end if;
					
			
		end case;
		
		if( rstp='1' ) then
			stp <= s0 after 1 ns;
			adr <= "0000" after 1 ns;
		end if;
	end if;
end process;			  

m_ready <= m_valid and m00_tready;

--pr_adr: process( clk ) begin
--	if( rising_edge( clk ) ) then
--		if( rstp='1' ) then
--			adr <= "0000" after 1 ns;
--		elsif( data_rd='1' and data_we='0' ) then
--			adr <= adr - 1 after 1 ns;
--		elsif( data_rd='0' and data_we='1' ) then
--			adr <= adr + 1 after 1 ns;
--		end if;
--	end if;
--end process;	

pr_cnt: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( rstp='1' ) then
			cnt <= "0000" after 1 ns;
		elsif( data_we='1' and m_ready='0' ) then
			cnt <= cnt + 1 after 1 ns;
		elsif( data_we='0' and m_ready='1' ) then
			cnt <= cnt - 1 after 1 ns;
		end if;
	end if;
end process;

data_ready <= cnt(3) or cnt(2) or cnt(1) after 1 ns when rising_edge( clk );

data_rd <= data_ready and m00_tready;
--data_rd <= '0';

m00_axis_m.tdata  <= data_o after 1 ns;
m00_axis_m.tvalid <= m_valid;
m00_axis_m.tlast  <= '0';

end cl_burst2axis_256;
