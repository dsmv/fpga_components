-------------------------------------------------------------------------------
--
-- Title       : cl_fifo_x64_v7
-- Author      : Dmitry Smekhov	 Alex Sokolov
-- Company     : Instrumental Systems
-- E-mail      : 
--
-- Version     : 1.1
--
-------------------------------------------------------------------------------
--
-- Description : ���� FIFO x64
--				 � �������� ���������� FIFO_SIZE ��������
--               �� ������:
--                512x65_V5		(FIFO_SIZE = 512 )
--                1Kx65_V5	   	(FIFO_SIZE = 1024 )
--				  2Kx65_V5	   	(FIFO_SIZE = 2048 )
--				  4Kx65_V5	   	(FIFO_SIZE = 4096 )
--                8Kx65_V5	   	(FIFO_SIZE = 8192 )
--                16Kx65_V5   	(FIFO_SIZE = 16384 )
--				 
--                default - 1K
--
--				 ����������� 7 - �������������� ��� ������ �����������:
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
--  Version    1.1	30.08.2011  
--			   ����������� cnt_wr, cnt_rd ��������� �� 16 ���
--
-------------------------------------------------------------------------------
--
--  Version    1.0	25.04.2011 �� ������ cl_fifo_x64_v7 
--			   
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use work.adm2_pkg.all;

package cl_fifo_x64_v7_pkg is
	
component cl_fifo_x64_v7 is   
	generic(FIFO_SIZE : in integer:= 1024);
	 port(				
	 	-- �����
		 reset 				: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( 63 downto 0 ); -- ������
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 15 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( 63 downto 0 );   -- ������
		 data_cs			: in std_logic;			-- 0 - ������ �� fifo
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 15 downto 0 ); -- ������� ����

		 
		 rt					: in std_logic:='0';	-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic:='0'		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end component;

end package cl_fifo_x64_v7_pkg;


library ieee;
use ieee.std_logic_1164.all;	 
use work.adm2_pkg.all;

entity cl_fifo_x64_v7 is		  
	generic(FIFO_SIZE : in integer:= 1024);
	 port(				
	 	-- �����
		 reset 				: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( 63 downto 0 ); -- ������
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 15 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( 63 downto 0 );   -- ������
		 data_cs			: in std_logic;			-- 0 - ������ �� fifo
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 15 downto 0 ); -- ������� ����
		 
		 
		 rt					: in std_logic:='0';	-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic:='0'		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end cl_fifo_x64_v7;


architecture cl_fifo_x64_v7 of cl_fifo_x64_v7 is

component cl_fifo512x64_v7 is   
	 port(				
	 	-- �����
		 reset 				: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( 63 downto 0 ); -- ������
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 8 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( 63 downto 0 );   -- ������
		 data_cs			: in std_logic;			-- 0 - ������ �� fifo
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 8 downto 0 ); -- ������� ����

		 
		 rt					: in std_logic;		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end component;
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

		 
		 rt					: in std_logic;		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end component;
component cl_fifo2048x64_v7 is   
	 port(				
	 	-- �����
		 reset 				: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( 63 downto 0 ); -- ������
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 10 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( 63 downto 0 );   -- ������
		 data_cs			: in std_logic;			-- 0 - ������ �� fifo
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 10 downto 0 ); -- ������� ����

		 
		 rt					: in std_logic;		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end component;
component cl_fifo4096x64_v7 is   
	 port(				
	 	-- �����
		 reset 				: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( 63 downto 0 ); -- ������
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 11 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( 63 downto 0 );   -- ������
		 data_cs			: in std_logic;			-- 0 - ������ �� fifo
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 11 downto 0 ); -- ������� ����

		 
		 rt					: in std_logic;		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end component;
component cl_fifo8192x64_v7 is   
	 port(				
	 	-- �����
		 reset 				: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( 63 downto 0 ); -- ������
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 12 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( 63 downto 0 );   -- ������
		 data_cs			: in std_logic;			-- 0 - ������ �� fifo
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 12 downto 0 ); -- ������� ����

		 
		 rt					: in std_logic;		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end component;
component cl_fifo16384x64_v7 is   
	 port(				
	 	-- �����
		 reset 				: in std_logic;			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			: in std_logic;			-- �������� �������
		 data_in 			: in std_logic_vector( 63 downto 0 ); -- ������
		 data_en			: in std_logic;			-- 1 - ������ � fifo
		 flag_wr			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				: out std_logic_vector( 13 downto 0 ); -- ������� ����
		 
		 -- ������
		 clk_rd 			: in std_logic;			-- �������� �������
		 data_out 			: out std_logic_vector( 63 downto 0 );   -- ������
		 data_cs			: in std_logic;			-- 0 - ������ �� fifo
		 flag_rd			: out bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				: out std_logic_vector( 13 downto 0 ); -- ������� ����

		 
		 rt					: in std_logic;		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			: in std_logic		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );
end component;

begin

--fifo512: if FIFO_SIZE = 512 
--generate	 					   
--fifo: cl_fifo512x64_v7		   
--
--	 port map(				
--	 	-- �����
--		 reset 				=>reset,	-- 0 - �����
--		 					           
--	 	-- ������			   
--		 clk_wr 			=>clk_wr,	-- �������� �������
--		 data_in 			=>data_in ,  -- ������
--		 data_en			=>data_en,	-- 1 - ������ � fifo
--		 flag_wr			=>flag_wr,	-- ����� fifo, ��������� � clk_wr
--		 cnt_wr				=>cnt_wr,	-- ������� ����
--		 					           
--		 -- ������			  
--		 clk_rd 			=>clk_rd,	-- �������� �������
--		 data_out 			=>data_out,  -- ������
--		 data_cs			=>data_cs,	-- 0 - ������ �� fifo
--		 flag_rd			=>flag_rd,	-- ����� fifo, ��������� � clk_rd
--		 cnt_rd				=>cnt_rd,  	-- ������� ����
--							           
--		 					           
--		 rt					=>rt,		-- 1 - ������� �� ������ � ������������ ������
--		 rt_mode			=>rt_mode	-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
--	    );
--end generate;

--fifo1024: if FIFO_SIZE = 1024 
--generate	 
--fifo: cl_fifo1024x64_v7
--	 port map(				
--	 	-- �����
--		 reset 				=>reset,	-- 0 - �����
--		 					           
--	 	-- ������			   
--		 clk_wr 			=>clk_wr,	-- �������� �������
--		 data_in 			=>data_in ,  -- ������
--		 data_en			=>data_en,	-- 1 - ������ � fifo
--		 flag_wr			=>flag_wr,	-- ����� fifo, ��������� � clk_wr
--		 cnt_wr				=>cnt_wr,	-- ������� ����
--		 					           
--		 -- ������			  
--		 clk_rd 			=>clk_rd,	-- �������� �������
--		 data_out 			=>data_out,  -- ������
--		 data_cs			=>data_cs,	-- 0 - ������ �� fifo
--		 flag_rd			=>flag_rd,	-- ����� fifo, ��������� � clk_rd
--		 cnt_rd				=>cnt_rd,  	-- ������� ����
--							           
--		 					           
--		 rt					=>rt,		-- 1 - ������� �� ������ � ������������ ������
--		 rt_mode			=>rt_mode	-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
--	    );
--end generate;
--
fifo2048: if FIFO_SIZE = 2048 
generate	 
fifo: cl_fifo2048x64_v7
	 port map(				
	 	-- �����
		 reset 				=>reset,	-- 0 - �����
		 					           
	 	-- ������			   
		 clk_wr 			=>clk_wr,	-- �������� �������
		 data_in 			=>data_in ,  -- ������
		 data_en			=>data_en,	-- 1 - ������ � fifo
		 flag_wr			=>flag_wr,	-- ����� fifo, ��������� � clk_wr
		 cnt_wr				=>cnt_wr( 10 downto 0 ),	-- ������� ����
		 					           
		 -- ������			  
		 clk_rd 			=>clk_rd,	-- �������� �������
		 data_out 			=>data_out,  -- ������
		 data_cs			=>data_cs,	-- 0 - ������ �� fifo
		 flag_rd			=>flag_rd,	-- ����� fifo, ��������� � clk_rd
		 cnt_rd				=>cnt_rd( 10 downto 0 ),  	-- ������� ����
							           
		 					           
		 rt					=>rt,		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			=>rt_mode	-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
	    );
		
cnt_wr( 15 downto 11 ) <= (others=>'0');
cnt_rd( 15 downto 11 ) <= (others=>'0');

end generate;

fifo4096: if FIFO_SIZE = 4096 
generate	 
fifo: cl_fifo4096x64_v7
	 port map(				
	 	-- �����
		 reset 				=>reset,	-- 0 - �����
		 					           
	 	-- ������			   
		 clk_wr 			=>clk_wr,	-- �������� �������
		 data_in 			=>data_in ,  -- ������
		 data_en			=>data_en,	-- 1 - ������ � fifo
		 flag_wr			=>flag_wr,	-- ����� fifo, ��������� � clk_wr
		 cnt_wr				=>cnt_wr( 11 downto 0 ),	-- ������� ����
		 					           
		 -- ������			  
		 clk_rd 			=>clk_rd,	-- �������� �������
		 data_out 			=>data_out,  -- ������
		 data_cs			=>data_cs,	-- 0 - ������ �� fifo
		 flag_rd			=>flag_rd,	-- ����� fifo, ��������� � clk_rd
		 cnt_rd				=>cnt_rd( 11 downto  0 ),  	-- ������� ����
							           
		 					           
		 rt					=>rt,		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			=>rt_mode	-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
	    );

cnt_wr( 15 downto 12 ) <= (others=>'0');
cnt_rd( 15 downto 12 ) <= (others=>'0');

end generate;

fifo8192: if FIFO_SIZE = 8192
generate	 
fifo: cl_fifo8192x64_v7
	 port map(				
	 	-- �����
		 reset 				=>reset,	-- 0 - �����
		 					           
	 	-- ������			   
		 clk_wr 			=>clk_wr,	-- �������� �������
		 data_in 			=>data_in ,  -- ������
		 data_en			=>data_en,	-- 1 - ������ � fifo
		 flag_wr			=>flag_wr,	-- ����� fifo, ��������� � clk_wr
		 cnt_wr				=>cnt_wr( 12 downto 0 ),	-- ������� ����
		 					           
		 -- ������			  
		 clk_rd 			=>clk_rd,	-- �������� �������
		 data_out 			=>data_out,  -- ������
		 data_cs			=>data_cs,	-- 0 - ������ �� fifo
		 flag_rd			=>flag_rd,	-- ����� fifo, ��������� � clk_rd
		 cnt_rd				=>cnt_rd( 12 downto 0 ),  	-- ������� ����
							           
		 					           
		 rt					=>rt,		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			=>rt_mode	-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
	    );

cnt_wr( 15 downto 13 ) <= (others=>'0');
cnt_rd( 15 downto 13 ) <= (others=>'0');


end generate;

fifo16384: if FIFO_SIZE = 16384 
generate	 
fifo: cl_fifo16384x64_v7
	 port map(				
	 	-- �����
		 reset 				=>reset,	-- 0 - �����
		 					           
	 	-- ������			   
		 clk_wr 			=>clk_wr,	-- �������� �������
		 data_in 			=>data_in ,  -- ������
		 data_en			=>data_en,	-- 1 - ������ � fifo
		 flag_wr			=>flag_wr,	-- ����� fifo, ��������� � clk_wr
		 cnt_wr				=>cnt_wr( 13 downto 0 ),	-- ������� ����
		 					           
		 -- ������			  
		 clk_rd 			=>clk_rd,	-- �������� �������
		 data_out 			=>data_out,  -- ������
		 data_cs			=>data_cs,	-- 0 - ������ �� fifo
		 flag_rd			=>flag_rd,	-- ����� fifo, ��������� � clk_rd
		 cnt_rd				=>cnt_rd( 13 downto 0 ),  	-- ������� ����
							           
		 					           
		 rt					=>rt,		-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			=>rt_mode	-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
	    );

cnt_wr( 15 downto 14 ) <= (others=>'0');
cnt_rd( 15 downto 14 ) <= (others=>'0');


end generate;


end cl_fifo_x64_v7;
